// lib/screens/seller/shop_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/widgets/product_card.dart';

class ShopPreviewScreen extends StatefulWidget {
  final String? sellerId;

  const ShopPreviewScreen({
    super.key,
    this.sellerId,
  });

  @override
  State<ShopPreviewScreen> createState() => _ShopPreviewScreenState();
}

class _ShopPreviewScreenState extends State<ShopPreviewScreen> {
  bool _isLoading = true;
  Seller? _seller;
  List<Product> _products = [];
  ShopCustomization? _shopCustomization;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      String? sellerId = widget.sellerId;
      sellerId ??= FirebaseAuth.instance.currentUser?.uid;

      if (sellerId == null) {
        throw 'ไม่พบข้อมูลผู้ใช้';
      }

      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // โหลดข้อมูลร้านค้า
      final seller = await firebaseService.getSellerFullDetails(sellerId);
      if (seller == null) {
        throw 'ไม่พบข้อมูลร้านค้า';
      }

      // โหลดสินค้า
      final products = await firebaseService.getProductsBySellerId(sellerId);

      // โหลดการตั้งค่าธีม (ถ้ามี)
      ShopCustomization? customization;
      try {
        customization = await firebaseService.getShopCustomization(sellerId);
      } catch (e) {
        // ไม่มีการตั้งค่าธีม ใช้ธีมเริ่มต้น
        customization = null;
      }

      if (mounted) {
        setState(() {
          _seller = seller;
          _products = products;
          _shopCustomization = customization;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_seller?.shopName ?? 'ตัวอย่างร้านค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShopData,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังโหลดข้อมูลร้านค้า...'),
                ],
              ),
            )
          : _error != null
              ? _buildErrorWidget()
              : _buildShopContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'เกิดข้อผิดพลาด',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red[700],
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadShopData,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildShopContent() {
    if (_seller == null) {
      return _buildNoDataWidget();
    }

    // ใช้ธีมจาก customization หรือธีมเริ่มต้น
    final theme = _shopCustomization?.theme ?? ScreenShopTheme.greenEco;
    final template = ShopTemplate.getTemplate(theme);

    return RefreshIndicator(
      onRefresh: _loadShopData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Shop Header แบบใหม่ตามธีม
          _buildThemedShopHeader(template),

          // Shop Banner (ถ้ามี)
          if (_shopCustomization?.banner?.isVisible == true)
            _buildShopBanner(template),

          // Shop Info
          _buildShopInfo(template),

          // Eco Hero Products Section
          _buildEcoHeroProductsSection(template),

          // Shop Promotions Section
          _buildPromotionsSection(template),

          // Products Section
          _buildProductsSection(template),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีข้อมูลร้านค้า',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณาตั้งค่าข้อมูลร้านค้าก่อน',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.settings),
            label: const Text('ไปที่การตั้งค่า'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemedShopHeader(ShopTemplate template) {
    final primaryColor =
        Color(int.parse('0xFF${template.colors.primary.substring(1)}'));
    final secondaryColor =
        Color(int.parse('0xFF${template.colors.secondary.substring(1)}'));

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: PatternPainter(template.theme),
                  ),
                ),
              ),
              // Shop Info
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    // Shop Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _seller!.shopImageUrl != null &&
                                _seller!.shopImageUrl!.isNotEmpty
                            ? NetworkImage(_seller!.shopImageUrl!)
                            : null,
                        backgroundColor: Colors.white,
                        child: _seller!.shopImageUrl == null ||
                                _seller!.shopImageUrl!.isEmpty
                            ? Icon(template.theme.icon,
                                size: 40, color: primaryColor)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Shop Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _seller!.shopName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            template.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_seller!.rating.toStringAsFixed(1)} (${_seller!.totalRatings})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.inventory_2,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_products.length} สินค้า',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopBanner(ShopTemplate template) {
    final banner = _shopCustomization!.banner!;
    final primaryColor =
        Color(int.parse('0xFF${template.colors.primary.substring(1)}'));
    final secondaryColor =
        Color(int.parse('0xFF${template.colors.secondary.substring(1)}'));

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (banner.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  banner.imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (banner.buttonText != null)
                    ElevatedButton(
                      onPressed: () {
                        // Handle banner button action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        banner.buttonText!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfo(ShopTemplate template) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  template.theme.icon,
                  color: Color(
                      int.parse('0xFF${template.colors.primary.substring(1)}')),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลร้านค้า',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(
                              '0xFF${template.colors.primary.substring(1)}')),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(
                        int.parse('0xFF${template.colors.accent.substring(1)}'))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(int.parse(
                          '0xFF${template.colors.accent.substring(1)}'))
                      .withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow2(
                    Icons.location_on,
                    'ที่อยู่',
                    _seller!.address ?? "ไม่ระบุ",
                    template,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow2(
                    Icons.phone,
                    'โทรศัพท์',
                    _seller!.phoneNumber,
                    template,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow2(
                    Icons.access_time,
                    'เวลาทำการ',
                    'จันทร์-เสาร์ 9:00-18:00',
                    template,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow2(
      IconData icon, String label, String value, ShopTemplate template) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
              Color(int.parse('0xFF${template.colors.primary.substring(1)}')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoHeroProductsSection(ShopTemplate template) {
    final primaryColor =
        Color(int.parse('0xFF${template.colors.primary.substring(1)}'));
    final accentColor =
        Color(int.parse('0xFF${template.colors.accent.substring(1)}'));

    // เลือกสินค้าคะแนน Eco สูงสุด 3 ชิ้น (ใช้ price หรือ criteria อื่น)
    final ecoHeroProducts = _products
        .where((product) => product.price >= 100) // สินค้าราคาสูง = คุณภาพดี
        .take(3)
        .toList();

    if (ecoHeroProducts.isEmpty && _products.isNotEmpty) {
      // ถ้าไม่มีสินค้าตามเงื่อนไข ให้เอา 3 ตัวแรก
      ecoHeroProducts.addAll(_products.take(3));
    }

    if (ecoHeroProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header สำหรับ Eco Hero
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, accentColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🌟 ECO HERO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'TOP 3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'สินค้าเป็นมิตรกับสิ่งแวดล้อมระดับสูงสุด',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all eco hero products
                    },
                    child: const Text(
                      'ดูทั้งหมด',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Products Grid
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: ecoHeroProducts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < ecoHeroProducts.length - 1 ? 8 : 0,
                        ),
                        child: _buildEcoHeroProductCard(product, template),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcoHeroProductCard(Product product, ShopTemplate template) {
    final accentColor =
        Color(int.parse('0xFF${template.colors.accent.substring(1)}'));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        color: Colors.green.withOpacity(0.05),
      ),
      child: Column(
        children: [
          // Eco Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  'ECO ${(product.price / 100).toStringAsFixed(1)}⭐',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Product Image
          Container(
            height: 80,
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: product.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrls.first,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.image,
                    size: 32,
                    color: Colors.grey[400],
                  ),
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '฿${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsSection(ShopTemplate template) {
    final primaryColor =
        Color(int.parse('0xFF${template.colors.primary.substring(1)}'));

    // สร้างโปรโมชั่นตัวอย่าง (ในอนาคตจะดึงจาก database)
    final promotions = [
      {
        'title': 'ส่วนลด 20%',
        'subtitle': 'สินค้าเป็นมิตรสิ่งแวดล้อม',
        'code': 'ECO20',
        'icon': Icons.percent,
        'color': Colors.red,
      },
      {
        'title': 'ซื้อ 2 แถม 1',
        'subtitle': 'สินค้าออร์แกนิกเฉพาะ',
        'code': 'BUY2GET1',
        'icon': Icons.add_circle,
        'color': Colors.orange,
      },
      {
        'title': 'ฟรี! ค่าจัดส่ง',
        'subtitle': 'เมื่อซื้อครบ 500 บาท',
        'code': 'FREESHIP',
        'icon': Icons.local_shipping,
        'color': Colors.blue,
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'โปรโมชั่นพิเศษ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to all promotions
                  },
                  child: Text(
                    'ดูทั้งหมด',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  final promo = promotions[index];
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(
                      right: index < promotions.length - 1 ? 12 : 0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          promo['color'] as Color,
                          (promo['color'] as Color).withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (promo['color'] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background Pattern
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.1,
                            child: CustomPaint(
                              painter: PatternPainter(template.theme),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    promo['icon'] as IconData,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      promo['code'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                promo['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                promo['subtitle'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  // Copy coupon code or apply
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'คัดลอกโค้ด ${promo['code']} แล้ว!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: promo['color'] as Color,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'คัดลอกโค้ด',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(ShopTemplate template) {
    final primaryColor =
        Color(int.parse('0xFF${template.colors.primary.substring(1)}'));

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'สินค้าของเรา',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to full product list
                  },
                  child: Text(
                    'ดูทั้งหมด',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_products.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ยังไม่มีสินค้า',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _products.length > 6 ? 6 : _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _buildThemedProductCard(product, template);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemedProductCard(Product product, ShopTemplate template) {
    final primaryColor =
        Color(int.parse('0xFF${template.colors.primary.substring(1)}'));
    final accentColor =
        Color(int.parse('0xFF${template.colors.accent.substring(1)}'));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[100],
              ),
              child: product.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        product.imageUrls.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey[400],
                    ),
            ),
          ),
          // Product Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '฿${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pattern painter สำหรับ background
class PatternPainter extends CustomPainter {
  final ScreenShopTheme theme;

  PatternPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // วาดลวดลายตามธีม
    switch (theme) {
      case ScreenShopTheme.shopeeClassic:
      case ScreenShopTheme.fashionBoutique:
        _drawDiagonalLines(canvas, size, paint);
        break;
      case ScreenShopTheme.techStore:
      case ScreenShopTheme.luxuryBrand:
        _drawGridPattern(canvas, size, paint);
        break;
      case ScreenShopTheme.beautyCosmetic:
      case ScreenShopTheme.naturalOrganic:
        _drawCirclePattern(canvas, size, paint);
        break;
      default:
        _drawDotPattern(canvas, size, paint);
    }
  }

  void _drawDiagonalLines(Canvas canvas, Size size, Paint paint) {
    for (double i = 0; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  void _drawGridPattern(Canvas canvas, Size size, Paint paint) {
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  void _drawCirclePattern(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 8, paint);
      }
    }
  }

  void _drawDotPattern(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 25) {
      for (double y = 0; y < size.height; y += 25) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
