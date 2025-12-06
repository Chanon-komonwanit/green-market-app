// lib/screens/seller/preview_my_shop_screen.dart
// หน้าดูตัวอย่างร้านค้าของตัวเอง (สำหรับผู้ขาย)
// แสดงเหมือน Public Shop + เพิ่มปุ่มแก้ไข

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/services/product_view_tracking_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/screens/seller/complete_shop_theme_system.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/edit_product_screen.dart';
import 'package:intl/intl.dart';

/// หน้าดูตัวอย่างร้านของตัวเอง - ผู้ขายสามารถแก้ไขได้
class PreviewMyShopScreen extends StatefulWidget {
  final String sellerId;
  final String? sellerName;

  const PreviewMyShopScreen({
    super.key,
    required this.sellerId,
    this.sellerName,
  });

  @override
  State<PreviewMyShopScreen> createState() => _PreviewMyShopScreenState();
}

class _PreviewMyShopScreenState extends State<PreviewMyShopScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;

  bool _isLoading = true;

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
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadShopData();
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

      // โหลดสินค้าทั้งหมด (รวมทั้ง pending)
      final productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: widget.sellerId)
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

      // โหลดคะแนนรีวิว
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
                _buildSellerActions(),
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
      actions: [
        // ปุ่มแก้ไขธีมร้าน
        IconButton(
          icon: const Icon(Icons.palette, color: Colors.white),
          tooltip: 'แก้ไขธีมร้าน',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CompleteShopThemeSystem(sellerId: widget.sellerId),
              ),
            );
            _loadShopData(); // Reload หลังแก้ไข
          },
        ),
        // ปุ่มรีเฟรช
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'รีเฟรช',
          onPressed: _loadShopData,
        ),
      ],
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
                            'ร้านค้าของฉัน',
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
                  Row(
                    children: [
                      Text(
                        _sellerInfo?['shopName'] ??
                            _sellerInfo?['displayName'] ??
                            'ร้านค้าของฉัน',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'เจ้าของร้าน',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                      const SizedBox(width: 12),
                      Icon(Icons.inventory_2, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalProducts สินค้า',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SELLER ACTIONS ====================
  Widget _buildSellerActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'โหมดแสดงตัวอย่าง - คุณคือเจ้าของร้าน',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('เพิ่มสินค้า'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompleteShopThemeSystem(
                            sellerId: widget.sellerId,
                          ),
                        ),
                      );
                      _loadShopData();
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('แก้ไขร้าน'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
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
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.inventory_2, '$_totalProducts', 'สินค้า'),
            _buildStatItem(Icons.people, '$_followerCount', 'ผู้ติดตาม'),
            _buildStatItem(
              Icons.star,
              _rating > 0 ? _rating.toStringAsFixed(1) : 'N/A',
              'คะแนน',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: _primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
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
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredProducts.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(product: _featuredProducts[index]),
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
        children: [
          // Filter & Sort
          _buildFilterBar(),

          // Products Grid
          if (_filteredProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'ยังไม่มีสินค้า',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return Stack(
                  children: [
                    ProductCard(product: product),
                    // Status Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(product.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(product.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Edit Button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProductScreen(product: product),
                            ),
                          );
                          _loadShopData(); // Reload after edit
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Category Filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('ทุกหมวดหมู่')),
                    DropdownMenuItem(
                        value: 'เสื้อผ้า', child: Text('เสื้อผ้า')),
                    DropdownMenuItem(value: 'อาหาร', child: Text('อาหาร')),
                    DropdownMenuItem(value: 'ของใช้', child: Text('ของใช้')),
                    DropdownMenuItem(value: 'อื่นๆ', child: Text('อื่นๆ')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'all';
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Sort
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('ใหม่สุด')),
                  DropdownMenuItem(value: 'popular', child: Text('ขายดี')),
                  DropdownMenuItem(
                      value: 'price_low', child: Text('ราคาต่ำ-สูง')),
                  DropdownMenuItem(
                      value: 'price_high', child: Text('ราคาสูง-ต่ำ')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value ?? 'newest';
                    _sortProducts();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending_approval':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'อนุมัติ';
      case 'pending_approval':
        return 'รอตรวจ';
      case 'rejected':
        return 'ไม่ผ่าน';
      default:
        return status;
    }
  }
}
