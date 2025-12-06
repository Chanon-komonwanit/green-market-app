import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/services/product_view_tracking_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:intl/intl.dart';

/// หน้าร้านสาธารณะ - Public Shop Front
/// แสดงหน้าร้านของผู้ขายให้ผู้ซื้อเข้าชม พร้อมธีมที่กำหนดเอง
class PublicShopScreen extends StatefulWidget {
  final String sellerId;
  final String? sellerName;

  const PublicShopScreen({
    super.key,
    required this.sellerId,
    this.sellerName,
  });

  @override
  State<PublicShopScreen> createState() => _PublicShopScreenState();
}

class _PublicShopScreenState extends State<PublicShopScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductViewTrackingService _trackingService =
      ProductViewTrackingService();

  late TabController _tabController;

  bool _isLoading = true;
  bool _isFollowing = false;

  // Shop Data
  ShopCustomization? _shopSettings;
  Map<String, dynamic>? _sellerInfo;
  List<Product> _products = [];
  List<Product> _featuredProducts = [];

  // Stats
  int _followerCount = 0;
  int _totalProducts = 0;
  double _rating = 0.0;

  // Filters
  String _selectedCategory = 'all';
  String _sortBy = 'newest'; // newest, popular, price_low, price_high

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadShopData();
    _checkFollowingStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    try {
      // โหลดการตั้งค่าร้าน
      final shopDoc = await _firestore
          .collection('shop_settings')
          .doc(widget.sellerId)
          .get();

      if (shopDoc.exists) {
        _shopSettings = ShopCustomization.fromMap(shopDoc.data()!);
      }

      // โหลดข้อมูลผู้ขาย
      final sellerDoc =
          await _firestore.collection('users').doc(widget.sellerId).get();

      if (sellerDoc.exists) {
        _sellerInfo = sellerDoc.data();
      }

      // โหลดสินค้าทั้งหมด (เฉพาะที่อนุมัติแล้ว)
      final productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: widget.sellerId)
          .where('status', isEqualTo: 'approved')
          .get();

      _products = productsSnapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      _totalProducts = _products.length;

      // โหลดสินค้าแนะนำ
      if (_shopSettings != null &&
          _shopSettings!.featuredProductIds.isNotEmpty) {
        _featuredProducts = _products
            .where((p) => _shopSettings!.featuredProductIds.contains(p.id))
            .toList();
      }

      // โหลดสถิติร้าน
      await _loadShopStats();

      // จัดเรียงสินค้า
      _sortProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadShopStats() async {
    try {
      // โหลดจำนวนผู้ติดตาม
      final followersSnapshot = await _firestore
          .collection('shop_followers')
          .where('sellerId', isEqualTo: widget.sellerId)
          .get();

      _followerCount = followersSnapshot.docs.length;

      // โหลดคะแนนรีวิว (เฉลี่ยจากสินค้าทั้งหมด)
      double totalRating = 0;
      int reviewCount = 0;

      for (var product in _products) {
        if (product.rating > 0) {
          totalRating += product.rating;
          reviewCount++;
        }
      }

      if (reviewCount > 0) {
        _rating = totalRating / reviewCount;
      }
    } catch (e) {
      print('Error loading shop stats: $e');
    }
  }

  Future<void> _checkFollowingStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await _firestore
          .collection('shop_followers')
          .doc('${userId}_${widget.sellerId}')
          .get();

      if (mounted) {
        setState(() {
          _isFollowing = doc.exists;
        });
      }
    } catch (e) {
      print('Error checking following status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    try {
      final docRef = _firestore
          .collection('shop_followers')
          .doc('${userId}_${widget.sellerId}');

      if (_isFollowing) {
        await docRef.delete();
        setState(() {
          _isFollowing = false;
          _followerCount--;
        });
      } else {
        await docRef.set({
          'userId': userId,
          'sellerId': widget.sellerId,
          'followedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _isFollowing = true;
          _followerCount++;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? '✅ ติดตามร้านแล้ว' : 'ยกเลิกการติดตาม'),
          backgroundColor: _isFollowing ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _sortProducts() {
    switch (_sortBy) {
      case 'newest':
        _products.sort((a, b) {
          final aTime = a.createdAt ?? Timestamp.now();
          final bTime = b.createdAt ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });
        break;
      case 'popular':
        _products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        break;
      case 'price_low':
        _products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        _products.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'all') {
      return _products;
    }
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  Color get _primaryColor {
    if (_shopSettings?.colors.primary != null) {
      try {
        return Color(int.parse(
            '0xFF${_shopSettings!.colors.primary.replaceAll('#', '')}'));
      } catch (e) {
        return const Color(0xFF2E7D32);
      }
    }
    return const Color(0xFF2E7D32);
  }

  Color get _secondaryColor {
    if (_shopSettings?.colors.secondary != null) {
      try {
        return Color(int.parse(
            '0xFF${_shopSettings!.colors.secondary.replaceAll('#', '')}'));
      } catch (e) {
        return const Color(0xFF4CAF50);
      }
    }
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildShopHeader(),
                _buildShopStats(),
                if (_featuredProducts.isNotEmpty) _buildFeaturedProducts(),
                _buildProductsSection(),
              ],
            ),
    );
  }

  // ==================== APP BAR ====================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: _shopSettings?.banner?.imageUrl != null
            ? Image.network(
                _shopSettings!.banner!.imageUrl!,
                fit: BoxFit.cover,
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store, color: Colors.white, size: 60),
                      const SizedBox(height: 8),
                      Text(
                        _sellerInfo?['shopName'] ??
                            _sellerInfo?['displayName'] ??
                            'ร้านค้า',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ==================== SHOP HEADER ====================
  Widget _buildShopHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Shop Logo/Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryColor, width: 3),
                color: Colors.grey.shade200,
              ),
              child: _sellerInfo?['profileImage'] != null
                  ? ClipOval(
                      child: Image.network(
                        _sellerInfo!['profileImage'],
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.store, size: 40, color: _primaryColor),
            ),
            const SizedBox(width: 16),

            // Shop Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sellerInfo?['shopName'] ??
                        _sellerInfo?['displayName'] ??
                        'ร้านค้า',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_shopSettings?.banner?.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _shopSettings!.banner!.subtitle!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _rating > 0 ? _rating.toStringAsFixed(1) : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_followerCount ผู้ติดตาม',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleFollow,
                  icon: Icon(_isFollowing ? Icons.check : Icons.add, size: 16),
                  label: Text(_isFollowing ? 'กำลังติดตาม' : 'ติดตาม'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey : _primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Open chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ฟีเจอร์แชทกำลังพัฒนา')),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('แชท'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SHOP STATS ====================
  Widget _buildShopStats() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.inventory_2_outlined,
              _totalProducts.toString(),
              'สินค้า',
            ),
            _buildStatItem(
              Icons.star_outline,
              _rating > 0 ? _rating.toStringAsFixed(1) : 'N/A',
              'คะแนน',
            ),
            _buildStatItem(
              Icons.people_outline,
              _followerCount.toString(),
              'ผู้ติดตาม',
            ),
            _buildStatItem(
              Icons.thumb_up_outlined,
              '${(_rating * 20).toInt()}%',
              'ความพึงพอใจ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: _primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ==================== FEATURED PRODUCTS ====================
  Widget _buildFeaturedProducts() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'สินค้าแนะนำ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredProducts.length,
              itemBuilder: (context, index) {
                final product = _featuredProducts[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      _trackingService.trackProductView(
                        productId: product.id,
                        sellerId: widget.sellerId,
                        source: ViewSource.shop,
                      );
                      // TODO: Navigate to product detail
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==================== PRODUCTS SECTION ====================
  Widget _buildProductsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories & Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('ทั้งหมด', 'all'),
                        _buildCategoryChip('สินค้าใหม่', 'new'),
                        _buildCategoryChip('ลดราคา', 'sale'),
                        _buildCategoryChip('ยอดนิยม', 'popular'),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                      _sortProducts();
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'newest', child: Text('ใหม่ล่าสุด')),
                    const PopupMenuItem(
                        value: 'popular', child: Text('ยอดนิยม')),
                    const PopupMenuItem(
                        value: 'price_low', child: Text('ราคาต่ำ-สูง')),
                    const PopupMenuItem(
                        value: 'price_high', child: Text('ราคาสูง-ต่ำ')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Products Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _shopSettings?.layout.gridColumns ?? 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    _trackingService.trackProductView(
                      productId: product.id,
                      sellerId: widget.sellerId,
                      source: ViewSource.shop,
                    );
                    // TODO: Navigate to product detail
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: _primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? _primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
