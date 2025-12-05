// lib/screens/advanced_search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/widgets/modern_bottom_sheet.dart';

/// Advanced Search Screen แบบ Shopee/Lazada
/// มี Filter ครบครัน, Sort หลากหลาย, UI สวยงาม
class AdvancedSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const AdvancedSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Search & Filter State
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Filters
  String _selectedCategory = 'all';
  RangeValues _priceRange = const RangeValues(0, 10000);
  RangeValues _ecoScoreRange = const RangeValues(0, 100);
  final List<EcoLevel> _selectedEcoLevels = [];
  bool _inStockOnly = false;
  bool _organicOnly = false;

  // Sort
  String _sortBy =
      'relevance'; // relevance, price_low, price_high, newest, eco_score, rating

  // Categories
  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'ทั้งหมด', 'icon': Icons.grid_view},
    {'id': 'fruit', 'name': 'ผลไม้', 'icon': Icons.apple},
    {'id': 'vegetable', 'name': 'ผัก', 'icon': Icons.grass},
    {'id': 'meat', 'name': 'เนื้อสัตว์', 'icon': Icons.dinner_dining},
    {'id': 'rice', 'name': 'ข้าว', 'icon': Icons.rice_bowl},
    {'id': 'drink', 'name': 'เครื่องดื่ม', 'icon': Icons.local_drink},
    {'id': 'household', 'name': 'ของใช้', 'icon': Icons.home},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategory == 'all') {
      setState(() {
        _hasSearched = false;
        _products = [];
        _filteredProducts = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      Query dbQuery = FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true);

      // Category filter
      if (_selectedCategory != 'all') {
        dbQuery = dbQuery.where('category', isEqualTo: _selectedCategory);
      }

      // Price range
      dbQuery = dbQuery
          .where('price', isGreaterThanOrEqualTo: _priceRange.start)
          .where('price', isLessThanOrEqualTo: _priceRange.end);

      final snapshot = await dbQuery.limit(100).get();

      _products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      // Apply additional filters (client-side)
      _applyFilters();

      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    _filteredProducts = _products.where((product) {
      // Text search
      if (query.isNotEmpty) {
        final matchesName = product.name.toLowerCase().contains(query);
        final matchesDesc = product.description.toLowerCase().contains(query);
        if (!matchesName && !matchesDesc) return false;
      }

      // Eco Score range
      if (product.ecoScore < _ecoScoreRange.start ||
          product.ecoScore > _ecoScoreRange.end) {
        return false;
      }

      // Eco Level filter
      if (_selectedEcoLevels.isNotEmpty &&
          !_selectedEcoLevels.contains(product.ecoLevel)) {
        return false;
      }

      // In stock only
      if (_inStockOnly && product.stock <= 0) return false;

      // Organic only (check via ecoScore as proxy)
      if (_organicOnly && product.ecoScore < 80) return false;

      return true;
    }).toList();

    // Apply sorting
    _applySorting();
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'price_low':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        _filteredProducts.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'eco_score':
        _filteredProducts.sort((a, b) => b.ecoScore.compareTo(a.ecoScore));
        break;
      case 'rating':
        _filteredProducts
            .sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'relevance':
      default:
        // Already sorted by relevance from search
        break;
    }
  }

  void _showFilterBottomSheet() {
    ModernBottomSheet.show(
      context: context,
      title: 'ตัวกรองค้นหา',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Range
          ModernRangeSliderSection(
            title: 'ช่วงราคา',
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
            labelFormatter: (value) => '฿${value.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 24),

          // Eco Score Range
          ModernRangeSliderSection(
            title: 'คะแนนสิ่งแวดล้อม',
            values: _ecoScoreRange,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (values) {
              setState(() => _ecoScoreRange = values);
            },
            labelFormatter: (value) => value.toStringAsFixed(0),
          ),
          const SizedBox(height: 24),

          // Eco Levels
          Text('ระดับสินค้า',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EcoLevel.values.map((level) {
              final isSelected = _selectedEcoLevels.contains(level);
              String levelLabel;
              switch (level) {
                case EcoLevel.hero:
                  levelLabel = 'Hero (90-100)';
                  break;
                case EcoLevel.premium:
                  levelLabel = 'Premium (60-89)';
                  break;
                case EcoLevel.standard:
                  levelLabel = 'Standard (40-59)';
                  break;
                case EcoLevel.basic:
                  levelLabel = 'Basic (20-39)';
                  break;
              }
              return ModernFilterChip(
                label: levelLabel,
                isSelected: isSelected,
                selectedColor: level.color,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedEcoLevels.remove(level);
                    } else {
                      _selectedEcoLevels.add(level);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Additional Filters
          Text('ตัวกรองเพิ่มเติม',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('มีสินค้าในสต็อกเท่านั้น'),
            value: _inStockOnly,
            onChanged: (value) {
              setState(() => _inStockOnly = value ?? false);
            },
            activeColor: AppColors.primaryTeal,
          ),
          CheckboxListTile(
            title: const Text('ออร์แกนิกเท่านั้น'),
            value: _organicOnly,
            onChanged: (value) {
              setState(() => _organicOnly = value ?? false);
            },
            activeColor: AppColors.primaryTeal,
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              _priceRange = const RangeValues(0, 10000);
              _ecoScoreRange = const RangeValues(0, 100);
              _selectedEcoLevels.clear();
              _inStockOnly = false;
              _organicOnly = false;
            });
            Navigator.pop(context);
            _applyFilters();
          },
          child: const Text('ล้างค่า'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _applyFilters();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
          ),
          child: const Text('ใช้ตัวกรอง'),
        ),
      ],
    );
  }

  void _showSortBottomSheet() {
    final sortOptions = [
      {'id': 'relevance', 'name': 'เกี่ยวข้องมากสุด', 'icon': Icons.star},
      {'id': 'price_low', 'name': 'ราคาต่ำ → สูง', 'icon': Icons.arrow_upward},
      {
        'id': 'price_high',
        'name': 'ราคาสูง → ต่ำ',
        'icon': Icons.arrow_downward
      },
      {'id': 'newest', 'name': 'ใหม่ล่าสุด', 'icon': Icons.new_releases},
      {'id': 'eco_score', 'name': 'คะแนนสิ่งแวดล้อมสูงสุด', 'icon': Icons.eco},
      {'id': 'rating', 'name': 'รีวิวดีที่สุด', 'icon': Icons.star_rate},
    ];

    ModernBottomSheet.show(
      context: context,
      title: 'เรียงลำดับตาม',
      height: 450,
      child: Column(
        children: sortOptions.map((option) {
          final isSelected = _sortBy == option['id'];
          return ListTile(
            leading: Icon(
              option['icon'] as IconData,
              color:
                  isSelected ? AppColors.primaryTeal : AppColors.graySecondary,
            ),
            title: Text(
              option['name'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? AppColors.primaryTeal : AppColors.grayPrimary,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primaryTeal)
                : null,
            onTap: () {
              setState(() => _sortBy = option['id'] as String);
              Navigator.pop(context);
              _applySorting();
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ค้นหาสินค้า...',
              hintStyle: TextStyle(color: AppColors.graySecondary),
              prefixIcon: Icon(Icons.search, color: AppColors.graySecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.graySecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primaryTeal),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories Horizontal Scroll
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ModernFilterChip(
                    label: category['name'],
                    icon: category['icon'],
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedCategory = category['id']);
                      _performSearch();
                    },
                  ),
                );
              },
            ),
          ),

          // Filter & Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterBottomSheet,
                    icon: const Icon(Icons.filter_list, size: 20),
                    label: Text(
                      'ตัวกรอง${_getActiveFiltersCount() > 0 ? ' (${_getActiveFiltersCount()})' : ''}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSortBottomSheet,
                    icon: const Icon(Icons.sort, size: 20),
                    label: const Text('เรียงลำดับ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search,
                size: 80, color: AppColors.graySecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'ค้นหาสินค้าที่คุณต้องการ',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.graySecondary),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 80, color: AppColors.graySecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'ไม่พบสินค้าที่ค้นหา',
              style:
                  AppTextStyles.headline.copyWith(color: AppColors.grayPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองปรับเปลี่ยนคำค้นหาหรือตัวกรอง',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.graySecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return ProductCard(product: _filteredProducts[index]);
      },
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_priceRange.start > 0 || _priceRange.end < 10000) count++;
    if (_ecoScoreRange.start > 0 || _ecoScoreRange.end < 100) count++;
    if (_selectedEcoLevels.isNotEmpty) count++;
    if (_inStockOnly) count++;
    if (_organicOnly) count++;
    return count;
  }
}
