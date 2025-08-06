// lib/screens/product_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/providers/cart_provider_enhanced.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/cart_screen.dart';
import 'package:green_market/screens/chat_screen.dart';
import 'package:green_market/screens/seller_shop_screen.dart';
// ↑ ใช้ไฟล์นี้เพราะมันเป็น wrapper ที่จะไปเรียก ShopeeStyleShopScreen
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
// import 'package:green_market/utils/app_text_styles.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  Widget _buildEcoScoreIndicator(EcoLevel level, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: level.color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level.icon,
            color: level.color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            level.name,
            style: AppTextStyles.body.copyWith(
              color: level.color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, Product product) {
    try {
      final cartProvider =
          Provider.of<CartProviderEnhanced>(context, listen: false);
      cartProvider.addItem(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} ถูกเพิ่มในตะกร้าแล้ว'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primaryTeal,
            action: SnackBarAction(
              label: 'ดูตะกร้า',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ));
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('เกิดข้อผิดพลาดในการเพิ่มไปยังตะกร้า'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _buyNow(BuildContext context, Product product) {
    try {
      final cartProvider =
          Provider.of<CartProviderEnhanced>(context, listen: false);
      cartProvider.addItem(product);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const CartScreen(navigateToCheckout: true),
      ));
    } catch (e) {
      print('Error in buy now: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('เกิดข้อผิดพลาดในการซื้อสินค้า'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Builder(
            builder: (context) {
              final user =
                  Provider.of<UserProvider>(context, listen: false).currentUser;
              if (user == null || user.id == widget.product.sellerId) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'แชทกับผู้ขาย',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId:
                            '${user.id}_${widget.product.sellerId}_${widget.product.id}',
                        productId: widget.product.id,
                        productName: widget.product.name,
                        productImageUrl: widget.product.imageUrls.isNotEmpty
                            ? widget.product.imageUrls.first
                            : '',
                        buyerId: user.id,
                        sellerId: widget.product.sellerId,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Product Images
            if (widget.product.imageUrls.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.product.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              widget.product.imageUrls[index],
                              fit: BoxFit
                                  .contain, // เปลี่ยนจาก cover เป็น contain
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 64,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Page indicator
                  if (widget.product.imageUrls.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.product.imageUrls.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? AppColors.primaryTeal
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 200,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 64,
                ),
              ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: AppTextStyles.title.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  _buildEcoScoreIndicator(widget.product.ecoLevel, context),
                  const SizedBox(height: 8),
                  Text(
                    '฿${widget.product.price.toStringAsFixed(2)}',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 20,
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 16),
                  if (widget.product.materialDescription.isNotEmpty) ...[
                    Text(
                      'วัสดุ:',
                      style: AppTextStyles.bodyBold,
                    ),
                    Text(
                      widget.product.materialDescription,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.product.ecoJustification.isNotEmpty) ...[
                    Text(
                      'เหตุผลความเป็นมิตรต่อสิ่งแวดล้อม:',
                      style: AppTextStyles.bodyBold,
                    ),
                    Text(
                      widget.product.ecoJustification,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Seller Information
                  FutureBuilder<Seller?>(
                    future: Provider.of<FirebaseService>(context, listen: false)
                        .getSellerFullDetails(widget.product.sellerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primaryTeal));
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const SizedBox();
                      }
                      final seller = snapshot.data!;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ข้อมูลผู้ขาย',
                                style: AppTextStyles.subtitle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryTeal,
                                    child: Text(
                                      seller.shopName.isNotEmpty
                                          ? seller.shopName[0].toUpperCase()
                                          : 'S',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          seller.shopName,
                                          style: AppTextStyles.bodyBold,
                                        ),
                                        if (seller
                                                .shopDescription?.isNotEmpty ==
                                            true)
                                          Text(
                                            seller.shopDescription!,
                                            style: AppTextStyles.caption,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SellerShopScreen(
                                                  sellerID: seller.id),
                                        ),
                                      );
                                    },
                                    child: const Text('ดูร้านค้า'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _addToCart(context, widget.product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('เพิ่มไปยังตะกร้า'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _buyNow(context, widget.product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('ซื้อเลย'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
