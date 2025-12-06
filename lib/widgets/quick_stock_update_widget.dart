// lib/widgets/quick_stock_update_widget.dart
// Quick Stock Update Widget - อัปเดตสต็อกเร็วจาก Dashboard

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:logger/logger.dart';

class QuickStockUpdateWidget extends StatefulWidget {
  const QuickStockUpdateWidget({super.key});

  @override
  State<QuickStockUpdateWidget> createState() => _QuickStockUpdateWidgetState();
}

class _QuickStockUpdateWidgetState extends State<QuickStockUpdateWidget> {
  final _firebaseService = FirebaseService();
  final _logger = Logger();

  bool _isLoading = true;
  List<Product> _lowStockProducts = [];
  final Map<String, TextEditingController> _stockControllers = {};
  String? _sellerId;

  @override
  void initState() {
    super.initState();
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (_sellerId != null) {
      _loadLowStockProducts();
    }
  }

  @override
  void dispose() {
    for (var controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLowStockProducts() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await _firebaseService.getLowStockProducts(_sellerId!, threshold: 20);
      _lowStockProducts = data.map((d) => Product.fromMap(d)).toList();

      // Initialize controllers
      for (var product in _lowStockProducts) {
        _stockControllers[product.id] =
            TextEditingController(text: '${product.stock}');
      }
    } catch (e) {
      _logger.e('Error loading low stock products: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStock(Product product, int newStock) async {
    try {
      await _firebaseService.quickUpdateProductStock(product.id, newStock);

      setState(() {
        final index = _lowStockProducts.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _lowStockProducts[index] = product.copyWith(stock: newStock);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตสต็อก "${product.name}" สำเร็จ'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error updating stock: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตไม่สำเร็จ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warning.withOpacity(0.1), Colors.white],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory,
                      color: AppColors.warning, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'อัปเดตสต็อกด่วน',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'สินค้าที่สต็อกเหลือน้อย',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadLowStockProducts,
                  tooltip: 'รีเฟรช',
                ),
              ],
            ),
          ),

          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_lowStockProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle,
                        size: 48, color: Colors.green[400]),
                    const SizedBox(height: 8),
                    const Text(
                      'สต็อกทุกรายการเพียงพอ',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Warning banner
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.warning.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        'พบสินค้าสต็อกต่ำ ${_lowStockProducts.length} รายการ',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Products list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lowStockProducts.length,
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    return _buildProductStockRow(_lowStockProducts[index]);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProductStockRow(Product product) {
    final controller = _stockControllers[product.id]!;
    final isLowStock = product.stock < 5;
    final isOutOfStock = product.stock == 0;

    return Row(
      children: [
        // Product image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrls.isNotEmpty
              ? Image.network(
                  product.imageUrls.first,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.inventory_2),
                ),
        ),
        const SizedBox(width: 12),

        // Product info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red.withOpacity(0.1)
                          : isLowStock
                              ? AppColors.warning.withOpacity(0.1)
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOutOfStock
                          ? 'หมดสต็อก'
                          : isLowStock
                              ? 'สต็อกต่ำ'
                              : 'สต็อกปกติ',
                      style: TextStyle(
                        fontSize: 10,
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                                ? AppColors.warning
                                : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ปัจจุบัน: ${product.stock}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOutOfStock
                          ? Colors.red
                          : isLowStock
                              ? AppColors.warning
                              : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Stock input
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onSubmitted: (value) {
              final newStock = int.tryParse(value);
              if (newStock != null && newStock != product.stock) {
                _updateStock(product, newStock);
              }
            },
          ),
        ),

        const SizedBox(width: 8),

        // Update button
        IconButton(
          onPressed: () {
            final newStock = int.tryParse(controller.text);
            if (newStock != null && newStock != product.stock) {
              _updateStock(product, newStock);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กรุณาใส่จำนวนสต็อกที่ถูกต้อง')),
              );
            }
          },
          icon: const Icon(Icons.check_circle, color: AppColors.primary),
          tooltip: 'อัปเดต',
        ),
      ],
    );
  }
}
