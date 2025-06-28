// lib/screens/eco_level_products_screen.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EcoLevelProductsScreen extends StatefulWidget {
  final EcoLevel ecoLevel;

  const EcoLevelProductsScreen({
    Key? key,
    required this.ecoLevel,
  }) : super(key: key);

  @override
  State<EcoLevelProductsScreen> createState() => _EcoLevelProductsScreenState();
}

class _EcoLevelProductsScreenState extends State<EcoLevelProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual ProductService call
      // final products = await ProductService.getProductsByEcoLevel(
      //   widget.ecoLevel,
      //   page: 1,
      //   limit: AppConstants.defaultPageSize,
      // );

      // Mock data for now
      final products = await _getMockProducts();

      setState(() {
        _products = products;
        _isLoading = false;
        _hasMore = products.length == AppConstants.defaultPageSize;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดสินค้า: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual ProductService call
      // final newProducts = await ProductService.getProductsByEcoLevel(
      //   widget.ecoLevel,
      //   page: _currentPage + 1,
      //   limit: AppConstants.defaultPageSize,
      // );

      // Mock data for now
      final newProducts = await _getMockProducts();

      setState(() {
        _products.addAll(newProducts);
        _isLoading = false;
        _hasMore = newProducts.length == AppConstants.defaultPageSize;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดสินค้าเพิ่มเติม: $e')),
        );
      }
    }
  }

  Future<List<Product>> _getMockProducts() async {
    // Mock delay to simulate network call
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate mock products for this eco level
    return List.generate(
        10,
        (index) => Product(
              id: 'product_${widget.ecoLevel.name}_$index',
              name: 'สินค้า ${widget.ecoLevel.name} ${index + 1}',
              description:
                  'รายละเอียดสินค้า ${widget.ecoLevel.name} ${index + 1}',
              price: 100.0 + (index * 50),
              imageUrls: ['https://via.placeholder.com/200'],
              sellerId: 'seller_$index',
              categoryId: 'category_$index',
              stock: 10 + index,
              materialDescription: 'วัสดุที่เป็นมิตรต่อสิ่งแวดล้อม',
              ecoJustification: 'เหตุผลด้านสิ่งแวดล้อม',
              createdAt: Timestamp.fromDate(
                  DateTime.now().subtract(Duration(days: index))),
              updatedAt: Timestamp.fromDate(DateTime.now()),
              ecoScore: _getScoreForLevel(widget.ecoLevel, index),
            ));
  }

  int _getScoreForLevel(EcoLevel level, int index) {
    switch (level) {
      case EcoLevel.basic:
        return 5 + (index % 15); // 5-19
      case EcoLevel.standard:
        return 20 + (index % 20); // 20-39
      case EcoLevel.premium:
        return 40 + (index % 20); // 40-59
      case EcoLevel.hero:
        return 60 + (index % 20); // 60-79
      case EcoLevel.platinum:
        return 80 + (index % 21); // 80-100
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.ecoLevel.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.ecoLevel.shortCode,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: widget.ecoLevel.color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section with level info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.padding),
            decoration: BoxDecoration(
              color: widget.ecoLevel.color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.borderRadius * 2),
                bottomRight: Radius.circular(AppTheme.borderRadius * 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.ecoLevel.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: AppTheme.smallPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ecoLevel.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppTheme.titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'คะแนนสิ่งแวดล้อม: ${widget.ecoLevel.scoreRange}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: AppTheme.captionFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.smallPadding),
                Text(
                  widget.ecoLevel.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.bodyFontSize,
                  ),
                ),
              ],
            ),
          ),
          // Products count
          if (_products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: Row(
                children: [
                  Text(
                    'พบสินค้า ${_products.length} รายการ',
                    style: TextStyle(
                      fontSize: AppTheme.captionFontSize,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showSortDialog,
                    icon: const Icon(Icons.sort, size: 16),
                    label: const Text('เรียงลำดับ'),
                    style: TextButton.styleFrom(
                      foregroundColor: widget.ecoLevel.color,
                    ),
                  ),
                ],
              ),
            ),
          // Products grid
          Expanded(
            child: _isLoading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.padding,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: AppTheme.smallPadding,
                            mainAxisSpacing: AppTheme.smallPadding,
                          ),
                          itemCount: _products.length +
                              (_isLoading && _hasMore ? 2 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _products.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return ProductCard(product: _products[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.ecoLevel.icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.padding),
          Text(
            'ยังไม่มีสินค้าในระดับ ${widget.ecoLevel.name}',
            style: TextStyle(
              fontSize: AppTheme.bodyFontSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.smallPadding),
          Text(
            'กลับมาดูใหม่ภายหลัง หรือลองดูสินค้าในระดับอื่น',
            style: TextStyle(
              fontSize: AppTheme.captionFontSize,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.largePadding),
          ElevatedButton(
            onPressed: _loadProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.ecoLevel.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('รีเฟรช'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตัวกรองสินค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('หมวดหมู่'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showCategoryFilter();
              },
            ),
            ListTile(
              title: const Text('ช่วงราคา'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showPriceRangeFilter();
              },
            ),
            ListTile(
              title: const Text('สภาพสินค้า'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showConditionFilter();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เรียงลำดับสินค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('ใหม่ล่าสุด'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sort by newest
              },
            ),
            ListTile(
              title: const Text('ราคาต่ำสุด'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sort by price low to high
              },
            ),
            ListTile(
              title: const Text('ราคาสูงสุด'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sort by price high to low
              },
            ),
            ListTile(
              title: const Text('คะแนนสิ่งแวดล้อมสูงสุด'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sort by eco score
              },
            ),
            ListTile(
              title: const Text('ยอดนิยม'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sort by popularity
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilter() {
    // TODO: Implement category filter
  }

  void _showPriceRangeFilter() {
    // TODO: Implement price range filter
  }

  void _showConditionFilter() {
    // TODO: Implement condition filter
  }
}
