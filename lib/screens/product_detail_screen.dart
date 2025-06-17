// product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/providers/cart_provider.dart';
import 'package:green_market/screens/cart_screen.dart';
import 'package:green_market/screens/chat_screen.dart'; // Assuming ChatScreen exists
import 'package:green_market/screens/seller_shop_screen.dart'; // Import SellerShopScreen
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/product_card.dart'; // Import ProductCard
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  Widget _buildEcoScoreIndicator(EcoLevel level, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: level.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level == EcoLevel.hero
                ? Icons.shield_outlined // Changed for better visual
                : level == EcoLevel.moderate
                    ? Icons.eco_outlined
                    : Icons.energy_savings_leaf_outlined,
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

  void _chatWithSeller(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อเริ่มแชท')),
      );
      return;
    }

    if (currentUser.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณไม่สามารถแชทกับตัวเองได้')),
      );
      return;
    }

    // final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    // String? sellerName = await firebaseService.getUserDisplayName(product.sellerId);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChatScreen(
        productId: product.id,
        productName: product.name,
        productImageUrl:
            product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
        buyerId: currentUser.uid,
        sellerId: product.sellerId,
        // sellerName: sellerName, // Pass seller name if fetched
      ),
    ));
  }

  void _buyNow(BuildContext context, Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(product); // Add to cart first
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const CartScreen(navigateToCheckout: true),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ถูกเพิ่มในตะกร้า เตรียมชำระเงิน'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name,
            style: AppTextStyles.title
                .copyWith(fontSize: 18)), // Slightly smaller title
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (product.imageUrls.isNotEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.4, // Responsive height
                child: Hero(
                    // Apply Hero to the PageView or the first image for transition from ProductCard
                    tag:
                        'product_image_${product.id}', // Match the tag in ProductCard
                    child: PageView.builder(
                      // Image Carousel
                      itemCount: product.imageUrls.length,
                      itemBuilder: (context, index) {
                        // If you want individual hero animations for each image in carousel,
                        // you would need more complex tag management.
                        // For simplicity, the main Hero is on the PageView or first image.
                        return Image.network(
                          product.imageUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primaryGreen,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            // ignore: deprecated_member_use
                            color: AppColors.lightModernGrey.withOpacity(0.3),
                            child: const Icon(Icons.broken_image,
                                color: AppColors.modernGrey, size: 100),
                          ),
                        );
                      },
                    )),
              )
            else
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                // ignore: deprecated_member_use
                color: AppColors.lightModernGrey.withOpacity(0.3),
                child: const Icon(Icons.image_not_supported,
                    color: AppColors.modernGrey, size: 100),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    style: AppTextStyles.headline.copyWith(
                        fontSize: 24, color: AppColors.primaryDarkGreen),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '฿${product.price.toStringAsFixed(2)}',
                    style: AppTextStyles.price
                        .copyWith(fontSize: 28, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  Center(
                      child:
                          _buildEcoScoreIndicator(product.ecoLevel, context)),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>?>(
                    // Changed to Map for shop details
                    future: firebaseService.getShopDetails(product.sellerId),
                    builder: (context, shopSnapshot) {
                      String sellerDisplayName = "กำลังโหลด...";
                      if (shopSnapshot.connectionState ==
                          ConnectionState.done) {
                        if (shopSnapshot.hasData && shopSnapshot.data != null) {
                          sellerDisplayName = shopSnapshot.data!['shopName'] ??
                              shopSnapshot.data!['displayName'] ??
                              product.sellerId;
                        } else {
                          sellerDisplayName =
                              product.sellerId; // Fallback to ID if no name
                        }
                      }
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SellerShopScreen(
                                      sellerId: product.sellerId)));
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_outlined,
                                color: AppColors.modernGrey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('ขายโดย: $sellerDisplayName',
                                  style: AppTextStyles.body.copyWith(
                                      decoration: TextDecoration.underline,
                                      color: AppColors.primaryTeal)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'รายละเอียดสินค้า',
                    style: AppTextStyles.subtitle
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style:
                        AppTextStyles.body.copyWith(height: 1.5, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  if (product.materialDescription.isNotEmpty) ...[
                    Text(
                      'วัสดุและการผลิต',
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.materialDescription,
                      style: AppTextStyles.body
                          .copyWith(height: 1.5, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (product.ecoJustification.isNotEmpty) ...[
                    Text(
                      'ความเป็นมิตรต่อสิ่งแวดล้อม',
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.ecoJustification,
                      style: AppTextStyles.body
                          .copyWith(height: 1.5, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // TODO: Add video player for product.verificationVideoUrl if available
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'สินค้าอื่นๆ จากร้านนี้',
                    style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: StreamBuilder<List<Product>>(
                      stream: firebaseService
                          .getProductsBySeller(product.sellerId)
                          .map((products) => products
                              .where((p) => p.id != product.id && p.isApproved)
                              .take(6)
                              .toList()),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryTeal));
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('ไม่สามารถโหลดสินค้าจากร้านนี้ได้',
                                  style: AppTextStyles.caption));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                              child: Text('ไม่มีสินค้าอื่นจากร้านนี้',
                                  style: AppTextStyles.caption));
                        }
                        final relatedProducts = snapshot.data!;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: relatedProducts.length,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 170,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == relatedProducts.length - 1
                                      ? 0
                                      : 12.0,
                                  left: index == 0 ? 0 : 0,
                                ),
                                child: ProductCard(
                                  product: relatedProducts[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 10.0), // Adjusted padding
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('แชทเลย'),
              onPressed: () {
                _chatWithSeller(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10), // Adjusted padding
                textStyle: AppTextStyles.body, // Adjusted text style
              ),
            ),
            const SizedBox(width: 10), // Adjusted spacing
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
                label: const Text('เพิ่มในรถเข็น'),
                onPressed: () {
                  cartProvider.addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} ถูกเพิ่มลงในตะกร้าแล้ว'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'ดูตะกร้า',
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  const CartScreen(navigateToCheckout: false)));
                        },
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10), // Adjusted padding
                  side: const BorderSide(color: AppColors.primaryTeal),
                  foregroundColor: AppColors.primaryTeal,
                  textStyle: AppTextStyles.body, // Adjusted text style
                ),
              ),
            ),
            const SizedBox(width: 10), // Adjusted spacing
            Expanded(
              child: ElevatedButton(
                onPressed: () => _buyNow(context, product),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10), // Adjusted padding
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                  textStyle: AppTextStyles.bodyBold, // Adjusted text style
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
