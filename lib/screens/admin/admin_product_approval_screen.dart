// lib/screens/admin/admin_product_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:green_market/models/category.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminProductApprovalScreen extends StatefulWidget {
  const AdminProductApprovalScreen({super.key});

  @override
  State<AdminProductApprovalScreen> createState() =>
      _AdminProductApprovalScreenState();
}

class _AdminProductApprovalScreenState
    extends State<AdminProductApprovalScreen> {
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  bool _isApproving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final categories = await firebaseService.getCategories().first;
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        showAppSnackBar(context, 'โหลดหมวดหมู่ล้มเหลว: ${e.toString()}',
            isError: true);
      }
    }
  }

  void _approveProduct(Product product) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    // Prompt for Eco Score and Category
    int? ecoScore = product.ecoScore; // Default to existing if any
    Category? selectedCategory;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('อนุมัติสินค้า'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ตั้งค่า Eco Score: ${ecoScore ?? 'N/A'}'),
                Slider(
                  value: ecoScore?.toDouble() ?? 50.0,
                  min: 1.0,
                  max: 100.0,
                  divisions: 99,
                  label: ecoScore?.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      ecoScore = value.round();
                    });
                  },
                ),
                DropdownButtonFormField<Category>(
                  decoration: const InputDecoration(labelText: 'หมวดหมู่'),
                  value: selectedCategory,
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (ecoScore == null || selectedCategory == null) {
                    showAppSnackBar(context, 'กรุณากรอกข้อมูลให้ครบถ้วน',
                        isError: true);
                    return;
                  }
                  setState(() => _isApproving = true);
                  try {
                    await firebaseService.approveProductWithDetails(
                      product.id,
                      ecoScore!,
                      categoryId: selectedCategory!.id,
                      categoryName: selectedCategory!.name,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } // Corrected: Already correct
                    showAppSnackBar(context, 'อนุมัติสินค้าสำเร็จ',
                        isSuccess: true);
                  } catch (e) {
                    setState(() => _isApproving = false);
                    showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                        isError: true);
                  }
                },
                child: _isApproving
                    ? const CircularProgressIndicator()
                    : const Text('อนุมัติ'),
              ),
            ],
          );
        });
      },
    );
  }

  void _rejectProduct(Product product) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    TextEditingController reasonController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ปฏิเสธสินค้า'),
          content: TextField(
            controller: reasonController,
            decoration:
                const InputDecoration(labelText: 'เหตุผลในการปฏิเสธ (จำเป็น)'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  showAppSnackBar(context, 'กรุณากรอกเหตุผลในการปฏิเสธ',
                      isError: true);
                  return;
                }
                try {
                  await firebaseService.rejectProduct(
                      product.id, reasonController.text.trim());
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  showAppSnackBar(context, 'ปฏิเสธสินค้าสำเร็จ',
                      isSuccess: true);
                } catch (e) {
                  showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                      isError: true);
                }
              },
              child: const Text('ปฏิเสธ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('อนุมัติสินค้า',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getPendingApprovalProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoadingCategories) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีสินค้าที่รอการอนุมัติ'));
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: (product.imageUrls.isNotEmpty &&
                          product.imageUrls.first.isNotEmpty)
                      ? Image.network(
                          product.imageUrls.first,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 50),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ) // Corrected: Already correct
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(product.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผู้ขาย: ${product.sellerId.substring(0, 8)}...'),
                      Text(
                          'ราคา: ฿${NumberFormat("#,##0.00").format(product.price)}'),
                      Text(
                          'วันที่ส่ง: ${DateFormat('dd MMM yyyy').format(product.createdAt?.toDate() ?? DateTime.now())}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        onPressed: () => _approveProduct(product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.red), // Corrected: Already correct
                        onPressed: () => _rejectProduct(product),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(product: product),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
