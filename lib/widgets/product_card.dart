// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/utils/constants.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  PageController? _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.product.imageUrls.length > 1) {
      _pageController = PageController();
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap ??
          () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                  product: widget.product), // Pass the whole product object
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
                child: widget.product.imageUrls.isNotEmpty
                    ? Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: widget.product.imageUrls.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final imageUrl = widget.product.imageUrls[index];
                              print(
                                  '[IMAGE] DEBUG ProductCard: Loading image $index for product ${widget.product.name}');
                              print(
                                  '[IMAGE] DEBUG ProductCard: Image URL: $imageUrl');

                              return Image.network(
                                imageUrl,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                      '[ERROR] DEBUG ProductCard: Error loading image $imageUrl');
                                  print(
                                      '[ERROR] DEBUG ProductCard: Error: $error');
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image,
                                            size: 50, color: Colors.grey),
                                        Text('ไม่สามารถโหลดรูปได้',
                                            style: TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  );
                                },
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    print(
                                        '[SUCCESS] DEBUG ProductCard: Image loaded successfully: $imageUrl');
                                    return child;
                                  }
                                  print(
                                      '[LOADING] DEBUG ProductCard: Loading progress for $imageUrl: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
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

                          // Page indicators (จุดแสดงตำแหน่งรูป)
                          if (widget.product.imageUrls.length > 1)
                            Positioned(
                              bottom: 24,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.product.imageUrls.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Indicator สำหรับรูปหลายรูป
                          if (widget.product.imageUrls.length > 1)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withAlpha((0.7 * 255).round()),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${_currentImageIndex + 1}/${widget.product.imageUrls.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
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
                    widget.product.name,
                    style: AppTextStyles.bodyBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '฿${widget.product.price.toStringAsFixed(2)}',
                    style: AppTextStyles.price
                        .copyWith(fontSize: 16, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        widget.product.ecoLevel.icon,
                        color: widget.product.ecoLevel.color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.product.ecoLevel.name,
                          style: AppTextStyles.caption.copyWith(
                            color: widget.product.ecoLevel.color,
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
