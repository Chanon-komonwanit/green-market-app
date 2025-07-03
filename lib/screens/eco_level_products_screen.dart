// lib/screens/eco_level_products_screen.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EcoLevelProductsScreen extends StatefulWidget {
  final EcoLevel ecoLevel;

  const EcoLevelProductsScreen({
    super.key,
    required this.ecoLevel,
  });

  @override
  State<EcoLevelProductsScreen> createState() => _EcoLevelProductsScreenState();
}

class _EcoLevelProductsScreenState extends State<EcoLevelProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  final List<Map<String, dynamic>> _rawProducts = []; // For sorting
  bool _isLoading = true;
  bool _hasMore = true;
  String _selectedSortType = 'newest';
  final List<String> _selectedCategories = [];
  double _minPrice = 0;
  double _maxPrice = 10000;
  final List<String> _selectedConditions = [];

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
      // Query products by eco level with filters
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'approved')
          .where('ecoLevel',
              isEqualTo: widget.ecoLevel.toString().split('.').last);

      // Apply category filter
      if (_selectedCategories.isNotEmpty) {
        query = query.where('category', whereIn: _selectedCategories);
      }

      // Apply condition filter
      if (_selectedConditions.isNotEmpty) {
        query = query.where('condition', whereIn: _selectedConditions);
      }

      // Apply price range filter
      query = query
          .where('price', isGreaterThanOrEqualTo: _minPrice)
          .where('price', isLessThanOrEqualTo: _maxPrice);

      // Apply sorting
      switch (_selectedSortType) {
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'price_low':
          query = query.orderBy('price', descending: false);
          break;
        case 'price_high':
          query = query.orderBy('price', descending: true);
          break;
        case 'eco_score':
          query = query.orderBy('ecoScore', descending: true);
          break;
        case 'popularity':
          query = query.orderBy('averageRating', descending: true);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      final querySnapshot = await query.limit(20).get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      setState(() {
        _products = products;
        _isLoading = false;
        _hasMore = products.length == 20;
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
      // Get the last document for pagination
      final lastDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(_products.last.id)
          .get();

      // Query more products by eco level with filters
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'approved')
          .where('ecoLevel',
              isEqualTo: widget.ecoLevel.toString().split('.').last);

      // Apply filters (same as _loadProducts)
      if (_selectedCategories.isNotEmpty) {
        query = query.where('category', whereIn: _selectedCategories);
      }
      if (_selectedConditions.isNotEmpty) {
        query = query.where('condition', whereIn: _selectedConditions);
      }
      query = query
          .where('price', isGreaterThanOrEqualTo: _minPrice)
          .where('price', isLessThanOrEqualTo: _maxPrice);

      // Apply sorting
      switch (_selectedSortType) {
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'price_low':
          query = query.orderBy('price', descending: false);
          break;
        case 'price_high':
          query = query.orderBy('price', descending: true);
          break;
        case 'eco_score':
          query = query.orderBy('ecoScore', descending: true);
          break;
        case 'popularity':
          query = query.orderBy('averageRating', descending: true);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      final querySnapshot =
          await query.startAfterDocument(lastDoc).limit(20).get();

      final newProducts = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      setState(() {
        _products.addAll(newProducts);
        _isLoading = false;
        _hasMore = newProducts.length == 20;
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
              leading: _selectedSortType == 'newest'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _sortBy('newest');
              },
            ),
            ListTile(
              title: const Text('ราคาต่ำสุด'),
              leading: _selectedSortType == 'price_low'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _sortBy('price_low');
              },
            ),
            ListTile(
              title: const Text('ราคาสูงสุด'),
              leading: _selectedSortType == 'price_high'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _sortBy('price_high');
              },
            ),
            ListTile(
              title: const Text('คะแนนสิ่งแวดล้อมสูงสุด'),
              leading: _selectedSortType == 'eco_score'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _sortBy('eco_score');
              },
            ),
            ListTile(
              title: const Text('ยอดนิยม'),
              leading: _selectedSortType == 'popularity'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _sortBy('popularity');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกหมวดหมู่'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  'อาหารออร์แกนิค',
                  'เครื่องใช้ในบ้าน',
                  'แฟชั่นและเครื่องแต่งกาย',
                  'ความงามและสุขภาพ',
                  'ของใช้เด็ก',
                  'กีฬาและการออกกำลังกาย',
                  'อิเล็กทรอนิกส์',
                  'หนังสือและสื่อการเรียนรู้',
                ]
                    .map((category) => CheckboxListTile(
                          title: Text(category),
                          value: _selectedCategories.contains(category),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showPriceRangeFilter() {
    double tempMinPrice = _minPrice;
    double tempMaxPrice = _maxPrice;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('กรองตามราคา'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'ราคา: ฿${tempMinPrice.toInt()} - ฿${tempMaxPrice.toInt()}'),
                RangeSlider(
                  values: RangeValues(tempMinPrice, tempMaxPrice),
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  labels: RangeLabels(
                    '฿${tempMinPrice.toInt()}',
                    '฿${tempMaxPrice.toInt()}',
                  ),
                  onChanged: (RangeValues values) {
                    setDialogState(() {
                      tempMinPrice = values.start;
                      tempMaxPrice = values.end;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _minPrice = tempMinPrice;
                _maxPrice = tempMaxPrice;
              });
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showConditionFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกสภาพสินค้า'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                'ใหม่',
                'มือสอง - สภาพดีมาก',
                'มือสอง - สภาพดี',
                'มือสอง - สภาพปกติ',
              ]
                  .map((condition) => CheckboxListTile(
                        title: Text(condition),
                        value: _selectedConditions.contains(condition),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedConditions.add(condition);
                            } else {
                              _selectedConditions.remove(condition);
                            }
                          });
                        },
                      ))
                  .toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _sortBy(String sortType) {
    setState(() {
      _selectedSortType = sortType;

      switch (sortType) {
        case 'newest':
          _products.sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!); // Newest first
          });
          break;
        case 'price_low':
          _products.sort((a, b) => a.price.compareTo(b.price)); // Low to high
          break;
        case 'price_high':
          _products.sort((a, b) => b.price.compareTo(a.price)); // High to low
          break;
        case 'eco_score':
          _products.sort((a, b) =>
              b.ecoScore.compareTo(a.ecoScore)); // Highest eco score first
          break;
        case 'popularity':
          _products.sort((a, b) {
            // Sort by average rating first, then by review count
            final ratingCompare = b.averageRating.compareTo(a.averageRating);
            return ratingCompare != 0
                ? ratingCompare
                : b.reviewCount.compareTo(a.reviewCount);
          });
          break;
      }
    });
  }

  void _applyFilters() {
    // Reload products with filters applied
    _loadProducts();
  }
}
