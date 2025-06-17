// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/utils/constants.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
              product: product), // Pass the whole product object
        ));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Hero(
                tag: 'product_image_${product.id}', // Unique tag
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: product.imageUrls.isNotEmpty
                      ? Image.network(
                          product.imageUrls[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image,
                                  size: 50, color: AppColors.lightModernGrey),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primaryTeal,
                                strokeWidth: 2.0,
                              ),
                            );
                          },
                        )
                      : Container(
                          // ignore: deprecated_member_use
                          color: AppColors.lightModernGrey.withOpacity(0.3),
                          child: const Icon(Icons.image_not_supported,
                              size: 50, color: AppColors.modernGrey),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: AppTextStyles.bodyBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('฿${product.price.toStringAsFixed(2)}',
                      style: AppTextStyles.price.copyWith(
                          fontSize: 16, color: AppColors.primaryGreen)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(product.ecoLevel.icon,
                          color: product.ecoLevel.color, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.ecoLevel.name,
                          style: AppTextStyles.caption.copyWith(
                              color: product.ecoLevel.color,
                              fontWeight: FontWeight.w600),
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
