// lib/screens/seller/my_products_screen.dart
// 🎯 Unified Product Management - Shopee/TikTok Shop Standard
// Merged features from my_products + professional_product_management

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/edit_product_screen.dart';
import 'package:green_market/screens/product_detail_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, price, stock, sold
  bool _sortAscending = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
      _filterProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _allProducts = [];
          _filteredProducts = [];
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      final products = snapshot.docs
          .map((doc) {
            try {
              return Product.fromFirestore(doc);
            } catch (e) {
              print('Error parsing product: $e');
              return null;
            }
          })
          .whereType<Product>()
          .toList();

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });

      _filterProducts();
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _allProducts = [];
        _filteredProducts = [];
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    List<Product> filtered = List.from(_allProducts);

    // Filter by tab
    switch (_tabController.index) {
      case 0: // ทั้งหมด
        break;
      case 1: // ใช้งาน
        filtered = filtered.where((p) => p.isActive && p.isApproved).toList();
        break;
      case 2: // ไม่ใช้งาน
        filtered = filtered.where((p) => !p.isActive).toList();
        break;
      case 3: // รออนุมัติ
        filtered = filtered.where((p) => !p.isApproved).toList();
        break;
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int compare = 0;
      switch (_sortBy) {
        case 'name':
          compare = a.name.compareTo(b.name);
          break;
        case 'price':
          compare = a.price.compareTo(b.price);
          break;
        case 'stock':
          compare = a.stock.compareTo(b.stock);
          break;
        case 'sold':
          compare = a.reviewCount.compareTo(b.reviewCount);
          break;
      }
      return _sortAscending ? compare : -compare;
    });

    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildProductsContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          _loadProducts();
        },
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสินค้า'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'จัดการสินค้า',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Toggle View
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          tooltip: _isGridView ? 'มุมมองรายการ' : 'มุมมองกริด',
        ),
        // Sort Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'เรียงลำดับ',
          onSelected: (value) {
            setState(() {
              if (_sortBy == value) {
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = value;
                _sortAscending = true;
              }
            });
            _filterProducts();
          },
          itemBuilder: (context) => [
            _buildSortMenuItem('name', 'ชื่อสินค้า', Icons.abc),
            _buildSortMenuItem('price', 'ราคา', Icons.attach_money),
            _buildSortMenuItem('stock', 'สต๊อก', Icons.inventory),
            _buildSortMenuItem('sold', 'ยอดขาย', Icons.trending_up),
          ],
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterProducts();
                },
                decoration: InputDecoration(
                  hintText: 'ค้นหาสินค้า...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _filterProducts();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: const TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'ทั้งหมด'),
                Tab(text: 'ใช้งาน'),
                Tab(text: 'ไม่ใช้งาน'),
                Tab(text: 'รออนุมัติ'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: const Color(0xFF2E7D32),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          SizedBox(height: 16),
          Text(
            'กำลังโหลดสินค้า...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: const Color(0xFF2E7D32),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _isGridView ? _buildGridView() : _buildListView(),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'ยังไม่มีสินค้า';
    IconData icon = Icons.inventory_2_outlined;

    switch (_tabController.index) {
      case 1:
        message = 'ไม่มีสินค้าที่ใช้งาน';
        break;
      case 2:
        message = 'ไม่มีสินค้าที่ไม่ใช้งาน';
        break;
      case 3:
        message = 'ไม่มีสินค้ารออนุมัติ';
        icon = Icons.pending_outlined;
        break;
    }

    if (_searchQuery.isNotEmpty) {
      message = 'ไม่พบสินค้าที่ค้นหา';
      icon = Icons.search_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildGridProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildListProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildGridProductCard(Product product) {
    final isLowStock = product.stock < 10;
    final stockColor = isLowStock ? Colors.red : Colors.grey[600]!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => _viewProduct(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: product.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrls[0]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imageUrls.isEmpty
                      ? const Icon(Icons.image, size: 50, color: Colors.grey)
                      : null,
                ),
                // Status Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildStatusBadge(product),
                ),
              ],
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '฿${NumberFormat('#,##0.00').format(product.price)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2,
                                size: 14, color: stockColor),
                            const SizedBox(width: 4),
                            Text(
                              'คงเหลือ ${product.stock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: stockColor,
                                fontWeight: isLowStock
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'แก้ไข',
                      onTap: () => _editProduct(product),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildToggleButton(product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListProductCard(Product product) {
    final isLowStock = product.stock < 10;
    final stockColor = isLowStock ? Colors.red : Colors.grey[600]!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => _viewProduct(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: product.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrls[0]),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrls.isEmpty
                        ? const Icon(Icons.image, size: 40, color: Colors.grey)
                        : null,
                  ),
                  // Status Badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildStatusBadge(product),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '฿${NumberFormat('#,##0.00').format(product.price)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.inventory_2, size: 14, color: stockColor),
                        const SizedBox(width: 4),
                        Text(
                          'คงเหลือ ${product.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: stockColor,
                            fontWeight: isLowStock
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _editProduct(product),
                    tooltip: 'แก้ไข',
                  ),
                  _buildToggleButton(product),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Product product) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    if (!product.isApproved) {
      bgColor = Colors.orange;
      textColor = Colors.white;
      text = 'รออนุมัติ';
      icon = Icons.pending;
    } else if (!product.isActive) {
      bgColor = Colors.grey;
      textColor = Colors.white;
      text = 'ปิด';
      icon = Icons.visibility_off;
    } else {
      bgColor = Colors.green;
      textColor = Colors.white;
      text = 'เปิด';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(Product product) {
    return InkWell(
      onTap: () => _toggleProductStatus(product),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: product.isActive ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          product.isActive ? Icons.visibility : Icons.visibility_off,
          size: 16,
          color: product.isActive ? Colors.green : Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _viewProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
    _loadProducts();
  }

  Future<void> _editProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: product),
      ),
    );
    _loadProducts();
  }

  Future<void> _toggleProductStatus(Product product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update({'isActive': !product.isActive});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product.isActive
                ? 'ปิดการใช้งานสินค้าแล้ว'
                : 'เปิดการใช้งานสินค้าแล้ว',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
