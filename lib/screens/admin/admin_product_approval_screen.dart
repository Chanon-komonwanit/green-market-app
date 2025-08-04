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

  void _approveProductRequest(String requestId, Product product) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    // Prompt for Eco Score and Category
    int ecoScore = product.ecoScore > 0
        ? product.ecoScore
        : 50; // Default to 50 if not set or 0
    Category? selectedCategory;

    // Try to find existing category if product has one
    if (_categories.isNotEmpty) {
      try {
        if (product.categoryId.isNotEmpty) {
          selectedCategory = _categories.firstWhere(
            (cat) => cat.id == product.categoryId,
          );
        }
      } catch (e) {
        // Category not found, leave as null
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isApproving = false;
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('อนุมัติคำขอสินค้า'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'สินค้า: ${product.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('ตั้งค่า Eco Score: $ecoScore'),
                  Slider(
                    value: ecoScore.toDouble(),
                    min: 1.0,
                    max: 100.0,
                    divisions: 99,
                    label: ecoScore.round().toString(),
                    onChanged: isApproving
                        ? null
                        : (value) {
                            setDialogState(() {
                              ecoScore = value.round();
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Category>(
                    decoration: const InputDecoration(labelText: 'หมวดหมู่'),
                    value: selectedCategory,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: isApproving
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          },
                    validator: (value) =>
                        value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCategory == null) {
                    showAppSnackBar(context, 'กรุณาเลือกหมวดหมู่',
                        isError: true);
                    return;
                  }

                  print("Starting approval process for request: $requestId");
                  setDialogState(() => isApproving = true);

                  try {
                    await firebaseService.approveProductRequest(
                      requestId,
                      ecoScore: ecoScore,
                      categoryId: selectedCategory!.id,
                      categoryName: selectedCategory!.name,
                    );

                    print("Product approved successfully");
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    if (context.mounted) {
                      showAppSnackBar(context, 'อนุมัติคำขอสินค้าสำเร็จ',
                          isSuccess: true);
                    }
                  } catch (e) {
                    print("Error approving product: $e");
                    setDialogState(() => isApproving = false);
                    if (context.mounted) {
                      showAppSnackBar(
                          context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                          isError: true);
                    }
                  }
                },
                child: isApproving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('อนุมัติ'),
              ),
            ],
          );
        });
      },
    );
  }

  void _rejectProductRequest(String requestId, Product product) async {
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
                  await firebaseService.rejectProductRequest(
                      requestId, reasonController.text.trim());
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  showAppSnackBar(context, 'ปฏิเสธคำขอสินค้าสำเร็จ',
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
    print("AdminProductApprovalScreen build() called");
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('อนุมัติสินค้า',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('product_requests')
            .snapshots(),
        builder: (context, snapshot) {
          print(
              "StreamBuilder called - ConnectionState: ${snapshot.connectionState}");

          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoadingCategories) {
            print("Showing loading indicator");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error in StreamBuilder: ${snapshot.error}");
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            print("No data in snapshot");
            return const Center(child: Text('ไม่มีข้อมูล'));
          }

          final allDocs = snapshot.data!.docs;
          print("Total documents in product_requests: ${allDocs.length}");

          // Filter for pending requests - temporarily show all statuses
          final pendingDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'];
            print("Document status: $status");
            return status == 'pending' ||
                status == 'submitted'; // Try both statuses
          }).toList();

          print("Pending documents: ${pendingDocs.length}");

          if (pendingDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีคำขอสินค้าที่รอการอนุมัติ',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'คำขอทั้งหมด: ${allDocs.length} รายการ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (allDocs.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        print("Debug button pressed - showing all requests:");
                        for (final doc in allDocs) {
                          final data = doc.data() as Map<String, dynamic>;
                          print(
                              "Doc ID: ${doc.id}, Status: ${data['status']}, Product: ${data['productData']?['name']}");
                        }
                      },
                      child: const Text('แสดงคำขอทั้งหมด (Debug)'),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: pendingDocs.length,
            itemBuilder: (context, index) {
              final doc = pendingDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              print("Building item $index with data: ${data.keys.toList()}");

              // Try to extract product data from the request
              final productData = data['productData'] as Map<String, dynamic>?;

              if (productData != null) {
                // Use productData if available
                final name = productData['name'] ?? 'ไม่ระบุชื่อสินค้า';
                final price = productData['price']?.toDouble() ?? 0.0;
                final imageUrls =
                    List<String>.from(productData['imageUrls'] ?? []);
                final sellerId = data['sellerId'] ?? 'ไม่ระบุผู้ขาย';
                final timestamp = data['timestamp'] as Timestamp?;
                final status = data['status'] ?? 'ไม่ระบุสถานะ';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'pending'
                                    ? Colors.orange.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status == 'pending'
                                    ? 'รอการอนุมัติ'
                                    : 'ส่งแล้ว',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: status == 'pending'
                                      ? Colors.orange.shade800
                                      : Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Product image and details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: imageUrls.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrls.first,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                    Icons.image_not_supported,
                                                    size: 40),
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      size: 40),
                            ),
                            const SizedBox(width: 16),

                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money,
                                          size: 18, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        '฿${NumberFormat("#,##0.00").format(price)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person,
                                          size: 18, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'ผู้ขาย: ${sellerId.substring(0, sellerId.length > 10 ? 10 : sellerId.length)}...',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 18, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'วันที่ส่ง: ${timestamp != null ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()) : 'ไม่ระบุ'}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Create a temporary Product object for approval
                                  try {
                                    final tempProduct =
                                        Product.fromMap(productData);
                                    _approveProductRequest(doc.id, tempProduct);
                                  } catch (e) {
                                    showAppSnackBar(context,
                                        'ไม่สามารถโหลดข้อมูลสินค้าได้: $e',
                                        isError: true);
                                  }
                                },
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.white),
                                label: const Text('อนุมัติ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  try {
                                    final tempProduct =
                                        Product.fromMap(productData);
                                    _rejectProductRequest(doc.id, tempProduct);
                                  } catch (e) {
                                    showAppSnackBar(context,
                                        'ไม่สามารถโหลดข้อมูลสินค้าได้: $e',
                                        isError: true);
                                  }
                                },
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                label: const Text('ปฏิเสธ'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Fallback for raw data display
                print("No productData found, showing raw data");
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ข้อมูลดิบ (Raw Data)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: ${doc.id}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'สถานะ: ${data['status'] ?? 'ไม่ระบุ'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ข้อมูลทั้งหมด:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
