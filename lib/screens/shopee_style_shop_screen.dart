// lib/screens/shopee_style_shop_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/screens/chat_screen.dart';
import 'package:green_market/screens/seller/complete_shop_theme_system.dart';

class ShopeeStyleShopScreen extends StatefulWidget {
  final String sellerId;
  final bool isOwner; // เป็นเจ้าของร้านหรือไม่

  const ShopeeStyleShopScreen({
    super.key,
    required this.sellerId,
    this.isOwner = false,
  });

  @override
  State<ShopeeStyleShopScreen> createState() => _ShopeeStyleShopScreenState();
}

class _ShopeeStyleShopScreenState extends State<ShopeeStyleShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Seller? _seller;
  ShopCustomization? _customization;
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // โหลดข้อมูลร้านค้า
      _seller = await firebaseService.getSellerFullDetails(widget.sellerId);

      // โหลดการปรับแต่งร้านค้า
      _customization =
          await firebaseService.getShopCustomization(widget.sellerId);

      // โหลดสินค้าทั้งหมด
      _products = await firebaseService.getProductsBySellerId(widget.sellerId);

      // โหลดสินค้าแนะนำ
      if (_customization?.featuredProductIds.isNotEmpty == true) {
        _featuredProducts = _products
            .where((p) => _customization!.featuredProductIds.contains(p.id))
            .toList();
      } else {
        // ถ้าไม่มีสินค้าแนะนำ ใช้สินค้า 6 อันแรก
        _featuredProducts = _products.take(6).toList();
      }

      // ตรวจสอบว่ากำลังติดตามร้านนี้หรือไม่
      if (!widget.isOwner) {
        _checkFollowStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลร้านค้า: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkFollowStatus() async {
    // TODO: Implement follow status check
    setState(() => _isFollowing = false);
  }

  Future<void> _toggleFollow() async {
    // TODO: Implement follow/unfollow functionality
    setState(() => _isFollowing = !_isFollowing);
  }

  Color _getThemeColor(String colorHex) {
    try {
      return Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('กำลังโหลดร้านค้า...'),
            ],
          ),
        ),
      );
    }

    if (_seller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่พบร้านค้า')),
        body: const Center(
          child: Text('ไม่พบข้อมูลร้านค้า'),
        ),
      );
    }

    final primaryColor = _customization != null
        ? _getThemeColor(_customization!.colors.primary)
        : AppColors.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildShopHeader(primaryColor),
          _buildShopInfo(),
          if (_customization?.banner?.isVisible == true) _buildPromoBanner(),
          _buildTabBar(),
          _buildTabContent(),
        ],
      ),
      floatingActionButton: widget.isOwner ? _buildOwnerFAB() : null,
    );
  }

  Widget _buildShopHeader(Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: _seller!.shopImageUrl != null
              ? Image.network(
                  _seller!.shopImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultShopHeader(primaryColor),
                )
              : _buildDefaultShopHeader(primaryColor),
        ),
      ),
      actions: [
        if (widget.isOwner)
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ShopCustomizationScreen(sellerId: widget.sellerId),
                ),
              ).then((_) => _loadShopData()); // รีเฟรชหลังจากแก้ไข
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'แก้ไขร้านค้า',
          ),
        IconButton(
          onPressed: () {
            // TODO: Share shop
          },
          icon: const Icon(Icons.share, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDefaultShopHeader(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.white.withOpacity(0.8)),
            const SizedBox(height: 8),
            Text(
              _seller!.shopName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfo() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.grayLight,
                  backgroundImage: _seller!.shopImageUrl != null
                      ? NetworkImage(_seller!.shopImageUrl!)
                      : null,
                  child: _seller!.shopImageUrl == null
                      ? Icon(Icons.store, color: AppColors.grayMedium)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _seller!.shopName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_seller!.rating.toStringAsFixed(1)} (${_seller!.totalRatings} รีวิว)',
                            style: TextStyle(color: AppColors.grayDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'สินค้าทั้งหมด ${_products.length} รายการ',
                        style: TextStyle(color: AppColors.grayMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_seller!.shopDescription?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                _seller!.shopDescription!,
                style: TextStyle(color: AppColors.grayDark),
              ),
            ],
            const SizedBox(height: 16),
            _buildShopActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildShopActions() {
    if (widget.isOwner) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ShopCustomizationScreen(sellerId: widget.sellerId),
                  ),
                ).then((_) => _loadShopData());
              },
              icon: const Icon(Icons.edit),
              label: const Text('แก้ไขร้านค้า'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleFollow,
            icon: Icon(_isFollowing ? Icons.favorite : Icons.favorite_border),
            label: Text(_isFollowing ? 'กำลังติดตาม' : 'ติดตามร้าน'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isFollowing ? Colors.red : AppColors.primary,
              side: BorderSide(
                color: _isFollowing ? Colors.red : AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาเข้าสู่ระบบก่อนส่งข้อความ'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (_seller == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ไม่พบข้อมูลร้านค้า'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: '${currentUser.uid}_${widget.sellerId}_shop',
                    productId: 'shop_general',
                    productName: _seller!.shopName,
                    productImageUrl: _seller!.shopImageUrl ?? '',
                    buyerId: currentUser.uid,
                    sellerId: widget.sellerId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text('แชท'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    final banner = _customization!.banner!;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getThemeColor(_customization!.colors.primary),
              _getThemeColor(_customization!.colors.secondary),
            ],
          ),
        ),
        child: banner.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  banner.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (banner.title != null)
                      Text(
                        banner.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (banner.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        banner.subtitle!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grayMedium,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'แนะนำ'),
            Tab(text: 'ใหม่ล่าสุด'),
            Tab(text: 'ขายดี'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildProductGrid(_products),
          _buildProductGrid(_featuredProducts),
          _buildProductGrid(_products
              .where((p) =>
                  DateTime.now()
                      .difference(p.createdAt?.toDate() ?? DateTime.now())
                      .inDays <
                  30)
              .toList()),
          _buildProductGrid(_products), // TODO: Sort by sales
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: AppColors.grayMedium),
            const SizedBox(height: 16),
            Text(
              'ไม่มีสินค้าในหมวดนี้',
              style: TextStyle(color: AppColors.grayMedium),
            ),
          ],
        ),
      );
    }

    final gridColumns = _customization?.layout.gridColumns ?? 2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns,
          crossAxisSpacing: _customization?.layout.cardSpacing ?? 8,
          mainAxisSpacing: _customization?.layout.cardSpacing ?? 8,
          childAspectRatio: 0.7,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget? _buildOwnerFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ShopCustomizationScreen(sellerId: widget.sellerId),
          ),
        ).then((_) => _loadShopData());
      },
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.palette),
      label: const Text('ปรับแต่งร้าน'),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
