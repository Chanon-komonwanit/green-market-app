// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/utils/constants.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                  product: product), // Pass the whole product object
            ));
          },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: product.imageUrls.isNotEmpty
                    ? Stack(
                        children: [
                          PageView.builder(
                            itemCount: product.imageUrls.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                product.imageUrls[index],
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        size: 50,
                                        color: AppColors.lightModernGrey),
                                fit: BoxFit
                                    .contain, // เปลี่ยนจาก cover เป็น contain
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: AppColors.primaryTeal,
                                      strokeWidth: 2.0,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          // Indicator สำหรับรูปหลายรูป
                          if (product.imageUrls.length > 1)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withAlpha((0.6 * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${product.imageUrls.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : Container(
                        color: AppColors.lightModernGrey.withAlpha(77),
                        child: const Icon(Icons.image_not_supported,
                            size: 50, color: AppColors.modernGrey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodyBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '฿${product.price.toStringAsFixed(2)}',
                    style: AppTextStyles.price
                        .copyWith(fontSize: 16, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        product.ecoLevel.icon,
                        color: product.ecoLevel.color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.ecoLevel.name,
                          style: AppTextStyles.caption.copyWith(
                            color: product.ecoLevel.color,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}
