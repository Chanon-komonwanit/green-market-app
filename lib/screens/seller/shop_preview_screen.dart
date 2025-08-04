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

    return RefreshIndicator(
      onRefresh: _loadShopData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShopHeader(),
            const SizedBox(height: 24),
            _buildShopInfo(),
            const SizedBox(height: 24),
            _buildProductsSection(),
            const SizedBox(height: 80), // เผื่อ floating action button
          ],
        ),
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

  Widget _buildShopHeader() {
    final primaryColor = _getThemePrimaryColor();
    final secondaryColor = _getThemeSecondaryColor();
    final themeData = _getThemeData();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_getThemeBorderRadius()),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: _getThemeElevation(),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_getThemePadding()),
        child: Column(
          children: [
            // รูปร้าน
            Container(
              width: _getThemeImageSize(),
              height: _getThemeImageSize(),
              decoration: BoxDecoration(
                shape: _getThemeImageShape(),
                border: Border.all(
                  color: themeData['borderColor'] ?? Colors.white,
                  width: _getThemeBorderWidth(),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipPath(
                clipper: _getThemeImageShape() == BoxShape.circle ? null : null,
                child: ClipOval(
                  child: _seller!.shopImageUrl != null &&
                          _seller!.shopImageUrl!.isNotEmpty
                      ? Image.network(
                          _seller!.shopImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultShopImage(),
                        )
                      : _buildDefaultShopImage(),
                ),
              ),
            ),
            SizedBox(height: _getThemeSpacing()),
            // ชื่อร้าน
            Text(
              _seller!.shopName,
              style: TextStyle(
                fontSize: _getThemeTitleSize(),
                fontWeight: _getThemeFontWeight(),
                color: themeData['titleColor'] ?? Colors.white,
                fontFamily: themeData['fontFamily'] ?? 'Sarabun',
                letterSpacing: _getThemeLetterSpacing(),
              ),
              textAlign: TextAlign.center,
            ),
            // คำอธิบายร้าน
            if (_seller!.shopDescription != null &&
                _seller!.shopDescription!.isNotEmpty) ...[
              SizedBox(height: _getThemeSpacing() / 2),
              Text(
                _seller!.shopDescription!,
                style: TextStyle(
                  fontSize: _getThemeDescriptionSize(),
                  color: themeData['subtitleColor'] ?? Colors.white70,
                  fontFamily: themeData['fontFamily'] ?? 'Sarabun',
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultShopImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.store,
        size: 50,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildShopInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ข้อมูลร้านค้า',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'อีเมล', _seller!.contactEmail),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'เบอร์โทร', _seller!.contactPhone),
            if (_seller!.website != null && _seller!.website!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.language, 'เว็บไซต์', _seller!.website!),
            ],
            if (_seller!.socialMediaLink != null &&
                _seller!.socialMediaLink!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.share, 'โซเชียลมีเดีย', _seller!.socialMediaLink!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
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

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'สินค้าของเรา',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '(${_products.length} รายการ)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _products.isEmpty ? _buildNoProductsWidget() : _buildProductsGrid(),
      ],
    );
  }

  Widget _buildNoProductsWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีสินค้า',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'เพิ่มสินค้าเพื่อแสดงในร้านค้า',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount:
          _products.length > 6 ? 6 : _products.length, // แสดงสูงสุด 6 รายการ
      itemBuilder: (context, index) {
        return ProductCard(
          product: _products[index],
          onTap: () {
            // ไปที่หน้ารายละเอียดสินค้า
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (context) => ProductDetailScreen(product: _products[index]),
            // ));
          },
        );
      },
    );
  }

  Color _getThemePrimaryColor() {
    if (_shopCustomization?.theme != null) {
      // ใช้สีจากการตั้งค่าธีม
      return _getThemeColor(_shopCustomization!.theme);
    }
    return Theme.of(context).primaryColor;
  }

  Color _getThemeSecondaryColor() {
    if (_shopCustomization?.theme != null) {
      // ใช้สีจากการตั้งค่าธีม
      return _getThemeColor(_shopCustomization!.theme).withOpacity(0.7);
    }
    return Theme.of(context).colorScheme.secondary;
  }

  Color _getThemeColor(ScreenShopTheme theme) {
    switch (theme) {
      case ScreenShopTheme.greenEco:
        return const Color(0xFF2E7D32);
      case ScreenShopTheme.modernLuxury:
        return const Color(0xFF1A1A1A);
      case ScreenShopTheme.vibrantYouth:
        return const Color(0xFFE91E63);
      case ScreenShopTheme.minimalist:
        return const Color(0xFF424242);
      case ScreenShopTheme.techDigital:
        return const Color(0xFF0D47A1);
      case ScreenShopTheme.warmVintage:
        return const Color(0xFF8D6E63);
      case ScreenShopTheme.shopeeOrange:
        return const Color(0xFFEE4D2D);
      case ScreenShopTheme.lazadaBlue:
        return const Color(0xFF0F136D);
      case ScreenShopTheme.elegantGold:
        return const Color(0xFFB8860B);
      case ScreenShopTheme.freshMint:
        return const Color(0xFF00A896);
    }
  }

  // Helper functions สำหรับ theme styling
  Map<String, dynamic> _getThemeData() {
    if (_shopCustomization?.theme == null) {
      return _getDefaultThemeData();
    }

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.greenEco:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': Colors.white,
          'titleColor': Colors.white,
          'subtitleColor': Colors.white70,
        };
      case ScreenShopTheme.modernLuxury:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': const Color(0xFFD4AF37),
          'titleColor': const Color(0xFFD4AF37),
          'subtitleColor': const Color(0xFFD4AF37).withOpacity(0.8),
        };
      case ScreenShopTheme.minimalist:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': Colors.white,
          'titleColor': Colors.white,
          'subtitleColor': Colors.white70,
        };
      case ScreenShopTheme.techDigital:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': const Color(0xFF1976D2),
          'titleColor': Colors.white,
          'subtitleColor': const Color(0xFF1976D2),
        };
      case ScreenShopTheme.warmVintage:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': const Color(0xFFBCAAA4),
          'titleColor': const Color(0xFFBCAAA4),
          'subtitleColor': const Color(0xFFBCAAA4).withOpacity(0.8),
        };
      case ScreenShopTheme.vibrantYouth:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': Colors.white,
          'titleColor': Colors.white,
          'subtitleColor': Colors.white70,
        };
      case ScreenShopTheme.shopeeOrange:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': Colors.white,
          'titleColor': Colors.white,
          'subtitleColor': Colors.white70,
        };
      case ScreenShopTheme.lazadaBlue:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': const Color(0xFFFFD700),
          'titleColor': const Color(0xFFFFD700),
          'subtitleColor': const Color(0xFFFFD700).withOpacity(0.8),
        };
      case ScreenShopTheme.elegantGold:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': const Color(0xFFFFD700),
          'titleColor': const Color(0xFFFFD700),
          'subtitleColor': const Color(0xFFFFD700).withOpacity(0.8),
        };
      case ScreenShopTheme.freshMint:
        return {
          'fontFamily': 'Sarabun',
          'borderColor': Colors.white,
          'titleColor': Colors.white,
          'subtitleColor': Colors.white70,
        };
    }
  }

  Map<String, dynamic> _getDefaultThemeData() {
    return {
      'fontFamily': 'Sarabun',
      'borderColor': Colors.white,
      'titleColor': Colors.white,
      'subtitleColor': Colors.white70,
    };
  }

  double _getThemeBorderRadius() {
    if (_shopCustomization?.theme == null) return 16.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.greenEco:
        return 20.0; // Natural curves
      case ScreenShopTheme.modernLuxury:
        return 12.0; // Sharp edges
      case ScreenShopTheme.minimalist:
        return 8.0; // Clean lines
      case ScreenShopTheme.techDigital:
        return 4.0; // Sharp tech
      case ScreenShopTheme.warmVintage:
        return 24.0; // Soft vintage
      case ScreenShopTheme.vibrantYouth:
        return 18.0; // Playful
      case ScreenShopTheme.shopeeOrange:
        return 16.0; // Shopee modern
      case ScreenShopTheme.lazadaBlue:
        return 14.0; // Lazada professional
      case ScreenShopTheme.elegantGold:
        return 22.0; // Elegant luxury
      case ScreenShopTheme.freshMint:
        return 20.0; // Fresh natural
    }
  }

  double _getThemeElevation() {
    if (_shopCustomization?.theme == null) return 10.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return 16.0; // High elevation
      case ScreenShopTheme.minimalist:
        return 4.0; // Low elevation
      case ScreenShopTheme.techDigital:
        return 12.0; // Medium elevation
      default:
        return 10.0;
    }
  }

  double _getThemePadding() {
    if (_shopCustomization?.theme == null) return 20.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return 32.0; // Luxurious spacing
      case ScreenShopTheme.minimalist:
        return 16.0; // Minimal spacing
      case ScreenShopTheme.warmVintage:
        return 24.0; // Cozy spacing
      default:
        return 20.0;
    }
  }

  double _getThemeImageSize() {
    if (_shopCustomization?.theme == null) return 100.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return 120.0; // Larger for luxury
      case ScreenShopTheme.minimalist:
        return 80.0; // Smaller for minimal
      default:
        return 100.0;
    }
  }

  BoxShape _getThemeImageShape() {
    // ทุกธีมใช้รูปกลม
    return BoxShape.circle;
  }

  double _getThemeBorderWidth() {
    if (_shopCustomization?.theme == null) return 3.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return 4.0; // Thick border
      case ScreenShopTheme.minimalist:
        return 1.0; // Thin border
      case ScreenShopTheme.techDigital:
        return 2.0; // Tech border
      default:
        return 3.0;
    }
  }

  double _getThemeSpacing() {
    if (_shopCustomization?.theme == null) return 16.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return 24.0; // More spacing
      case ScreenShopTheme.minimalist:
        return 12.0; // Less spacing
      default:
        return 16.0;
    }
  }

  double _getThemeTitleSize() {
    if (_shopCustomization?.theme == null) return 24.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return 28.0; // Larger title
      case ScreenShopTheme.minimalist:
        return 20.0; // Smaller title
      case ScreenShopTheme.techDigital:
        return 22.0; // Tech size
      default:
        return 24.0;
    }
  }

  FontWeight _getThemeFontWeight() {
    if (_shopCustomization?.theme == null) return FontWeight.bold;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return FontWeight.w900; // Extra bold
      case ScreenShopTheme.minimalist:
        return FontWeight.w500; // Medium
      case ScreenShopTheme.warmVintage:
        return FontWeight.w600; // Semi-bold
      default:
        return FontWeight.bold;
    }
  }

  double _getThemeLetterSpacing() {
    if (_shopCustomization?.theme == null) return 0.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return 1.5; // Wide spacing
      case ScreenShopTheme.techDigital:
        return 0.5; // Tech spacing
      default:
        return 0.0;
    }
  }

  double _getThemeDescriptionSize() {
    if (_shopCustomization?.theme == null) return 16.0;

    switch (_shopCustomization!.theme) {
      case ScreenShopTheme.modernLuxury:
        return 18.0; // Larger description
      case ScreenShopTheme.minimalist:
        return 14.0; // Smaller description
      default:
        return 16.0;
    }
  }
}
