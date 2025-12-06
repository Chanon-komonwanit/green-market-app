import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ระบบจัดการสต็อกสินค้าขั้นสูง - Advanced Stock Management
/// รองรับ: Low stock alert, Bulk update, Stock history, Auto restock
class AdvancedStockManagementScreen extends StatefulWidget {
  const AdvancedStockManagementScreen({super.key});

  @override
  State<AdvancedStockManagementScreen> createState() =>
      _AdvancedStockManagementScreenState();
}

class _AdvancedStockManagementScreenState
    extends State<AdvancedStockManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String sellerId = FirebaseAuth.instance.currentUser!.uid;

  List<ProductStock> _products = [];
  bool _isLoading = true;

  // Settings
  int _lowStockThreshold = 10;
  bool _autoAlertEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProducts();
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc =
          await _firestore.collection('seller_settings').doc(sellerId).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _lowStockThreshold = data['lowStockThreshold'] ?? 10;
          _autoAlertEnabled = data['autoStockAlert'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _firestore.collection('seller_settings').doc(sellerId).set({
        'lowStockThreshold': _lowStockThreshold,
        'autoStockAlert': _autoAlertEnabled,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกการตั้งค่าเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('stock', descending: false)
          .get();

      List<ProductStock> products = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        products.add(ProductStock(
          id: doc.id,
          name: data['name'] ?? '',
          image: (data['images'] as List?)?.firstOrNull,
          stock: (data['stock'] as num?)?.toInt() ?? 0,
          price: (data['price'] as num?)?.toDouble() ?? 0,
          sold: (data['sold'] as num?)?.toInt() ?? 0,
          isActive: data['isActive'] ?? true,
          lastUpdated:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  List<ProductStock> get _lowStockProducts {
    return _products
        .where((p) => p.stock <= _lowStockThreshold && p.stock > 0)
        .toList();
  }

  List<ProductStock> get _outOfStockProducts {
    return _products.where((p) => p.stock == 0).toList();
  }

  List<ProductStock> get _inStockProducts {
    return _products.where((p) => p.stock > _lowStockThreshold).toList();
  }

  Future<void> _updateStock(ProductStock product, int newStock) async {
    try {
      await _firestore.collection('products').doc(product.id).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log stock change
      await _firestore.collection('stock_history').add({
        'productId': product.id,
        'sellerId': sellerId,
        'oldStock': product.stock,
        'newStock': newStock,
        'change': newStock - product.stock,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        product.stock = newStock;
        product.lastUpdated = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ อัปเดตสต็อกเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _showUpdateStockDialog(ProductStock product) async {
    final controller = TextEditingController(text: product.stock.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('อัปเดตสต็อก: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สต็อกปัจจุบัน: ${product.stock} ชิ้น'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'จำนวนสต็อกใหม่',
                border: OutlineInputBorder(),
                suffixText: 'ชิ้น',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text);
              if (newStock != null && newStock >= 0) {
                Navigator.pop(context, newStock);
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateStock(product, result);
    }
  }

  Future<void> _bulkUpdateStock() async {
    // Select multiple products
    final selectedProducts = await showDialog<List<ProductStock>>(
      context: context,
      builder: (context) => _BulkSelectDialog(products: _products),
    );

    if (selectedProducts == null || selectedProducts.isEmpty) return;

    // Get adjustment amount
    final controller = TextEditingController();
    final adjustment = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปรับสต็อกทั้งหมด'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('เลือก ${selectedProducts.length} รายการ'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'เพิ่ม/ลด จำนวน (ใช้ - สำหรับลด)',
                border: OutlineInputBorder(),
                hintText: 'เช่น +10 หรือ -5',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('ปรับสต็อก'),
          ),
        ],
      ),
    );

    if (adjustment != null) {
      // Update all selected products
      for (var product in selectedProducts) {
        final newStock = (product.stock + adjustment).clamp(0, 999999);
        await _updateStock(product, newStock);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ อัปเดต ${selectedProducts.length} รายการเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการสต็อกสินค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ทั้งหมด'),
                  const SizedBox(width: 4),
                  _buildBadge(_products.length, Colors.blue),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, size: 16),
                  const SizedBox(width: 4),
                  const Text('ใกล้หมด'),
                  const SizedBox(width: 4),
                  _buildBadge(_lowStockProducts.length, Colors.orange),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, size: 16),
                  const SizedBox(width: 4),
                  const Text('หมดแล้ว'),
                  const SizedBox(width: 4),
                  _buildBadge(_outOfStockProducts.length, Colors.red),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16),
                  const SizedBox(width: 4),
                  const Text('มีสต็อก'),
                  const SizedBox(width: 4),
                  _buildBadge(_inStockProducts.length, Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(_products),
                _buildProductList(_lowStockProducts),
                _buildProductList(_outOfStockProducts),
                _buildProductList(_inStockProducts),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bulkUpdateStock,
        icon: const Icon(Icons.edit),
        label: const Text('ปรับสต็อกแบบกลุ่ม'),
      ),
    );
  }

  Widget _buildBadge(int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductList(List<ProductStock> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'ไม่มีสินค้า',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildProductCard(products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductStock product) {
    final stockColor = product.stock == 0
        ? Colors.red
        : product.stock <= _lowStockThreshold
            ? Colors.orange
            : Colors.green;

    final stockStatus = product.stock == 0
        ? 'หมดแล้ว'
        : product.stock <= _lowStockThreshold
            ? 'ใกล้หมด'
            : 'มีสต็อก';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: stockColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showUpdateStockDialog(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.image != null
                    ? Image.network(
                        product.image!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '฿${product.price.toStringAsFixed(0)} • ขายแล้ว ${product.sold}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                product.stock == 0
                                    ? Icons.block
                                    : product.stock <= _lowStockThreshold
                                        ? Icons.warning_amber
                                        : Icons.check_circle,
                                size: 14,
                                color: stockColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                stockStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: stockColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'อัปเดต ${_getTimeAgo(product.lastUpdated)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stock counter
              Column(
                children: [
                  Text(
                    '${product.stock}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                  const Text(
                    'ชิ้น',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ชม.ที่แล้ว';
    } else {
      return '${diff.inDays} วันที่แล้ว';
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚙️ ตั้งค่าการจัดการสต็อก'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('เกณฑ์สต็อกต่ำ'),
                  subtitle:
                      Text('แจ้งเตือนเมื่อสต็อกต่ำกว่า $_lowStockThreshold'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      controller: TextEditingController(
                          text: _lowStockThreshold.toString()),
                      onChanged: (value) {
                        final num = int.tryParse(value);
                        if (num != null && num > 0) {
                          setDialogState(() {
                            _lowStockThreshold = num;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: 'ชิ้น',
                      ),
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('แจ้งเตือนอัตโนมัติ'),
                  subtitle: const Text('แจ้งเตือนเมื่อสต็อกต่ำ'),
                  value: _autoAlertEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      _autoAlertEnabled = value;
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSettings();
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}

// ==================== BULK SELECT DIALOG ====================
class _BulkSelectDialog extends StatefulWidget {
  final List<ProductStock> products;

  const _BulkSelectDialog({required this.products});

  @override
  State<_BulkSelectDialog> createState() => _BulkSelectDialogState();
}

class _BulkSelectDialogState extends State<_BulkSelectDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('เลือกสินค้า'),
          const Spacer(),
          Text(
            '${_selectedIds.length} รายการ',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.products.length,
          itemBuilder: (context, index) {
            final product = widget.products[index];
            final isSelected = _selectedIds.contains(product.id);

            return CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(product.id);
                  } else {
                    _selectedIds.remove(product.id);
                  }
                });
              },
              title: Text(product.name),
              subtitle: Text('สต็อก: ${product.stock} ชิ้น'),
              secondary: product.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.image!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.image),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  final selected = widget.products
                      .where((p) => _selectedIds.contains(p.id))
                      .toList();
                  Navigator.pop(context, selected);
                },
          child: const Text('ถัดไป'),
        ),
      ],
    );
  }
}

// ==================== MODELS ====================
class ProductStock {
  final String id;
  final String name;
  final String? image;
  int stock;
  final double price;
  final int sold;
  final bool isActive;
  DateTime lastUpdated;

  ProductStock({
    required this.id,
    required this.name,
    this.image,
    required this.stock,
    required this.price,
    required this.sold,
    required this.isActive,
    required this.lastUpdated,
  });
}
