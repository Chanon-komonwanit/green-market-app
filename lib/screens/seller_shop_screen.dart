// lib/screens/seller_shop_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/product_card.dart'; // Assuming you have a ProductCard widget
import 'package:provider/provider.dart';

class SellerShopScreen extends StatefulWidget {
  final String sellerId;

  const SellerShopScreen({super.key, required this.sellerId});

  @override
  State<SellerShopScreen> createState() => _SellerShopScreenState();
}

class _SellerShopScreenState extends State<SellerShopScreen> {
  Map<String, dynamic>? _shopDetails;
  String? _sellerDisplayName;
  bool _isLoadingShopInfo = true;

  @override
  void initState() {
    super.initState();
    _loadShopAndSellerInfo();
  }

  Future<void> _loadShopAndSellerInfo() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final shopData = await firebaseService.getShopDetails(widget.sellerId);
      final sellerName =
          await firebaseService.getUserDisplayName(widget.sellerId);
      if (mounted) {
        setState(() {
          _shopDetails = shopData;
          _sellerDisplayName = sellerName;
          _isLoadingShopInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingShopInfo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลร้านค้า: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final String shopName =
        _shopDetails?['shopName'] ?? _sellerDisplayName ?? 'ร้านค้าของผู้ขาย';
    final String? shopImageUrl = _shopDetails?['shopImageUrl'];
    final String shopDescription =
        _shopDetails?['shopDescription'] ?? 'ยินดีต้อนรับสู่ร้านค้าของเรา';

    return Scaffold(
      appBar: AppBar(
        title: Text(shopName,
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _isLoadingShopInfo
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryTeal)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.lightModernGrey,
                          backgroundImage:
                              shopImageUrl != null && shopImageUrl.isNotEmpty
                                  ? NetworkImage(shopImageUrl)
                                  : null,
                          child: (shopImageUrl == null || shopImageUrl.isEmpty)
                              ? const Icon(Icons.storefront,
                                  size: 50, color: AppColors.modernGrey)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(shopName,
                            style: AppTextStyles.title.copyWith(
                                fontSize: 22, color: AppColors.primaryTeal),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(shopDescription,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.modernGrey),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        const Divider(),
                        Text('สินค้าทั้งหมดของร้าน',
                            style: AppTextStyles.subtitle
                                .copyWith(color: AppColors.modernDarkGrey)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
          ),
          StreamBuilder<List<Product>>(
            stream: firebaseService.getProductsBySeller(widget.sellerId).map(
                (products) => products
                    .where((p) => p.isApproved)
                    .toList() // Only show approved products
                ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _isLoadingShopInfo) {
                // Already handled by _isLoadingShopInfo for the initial load
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                                style: AppTextStyles.body))));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('ร้านนี้ยังไม่มีสินค้าที่อนุมัติแล้ว',
                                style: AppTextStyles.body))));
              }

              final products = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7, // Adjust as needed for ProductCard
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return ProductCard(product: products[index]);
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
