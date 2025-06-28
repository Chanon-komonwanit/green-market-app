// lib/screens/admin/approval_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart' as app_category;
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart'; // Assuming AppTextStyles, AppColors, EcoLevelExtension are here
import 'package:green_market/screens/admin/admin_product_detail_screen.dart'; // Import the new screen
import 'package:provider/provider.dart';

class ApprovalListScreen extends StatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  List<app_category.Category> _allCategories = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _showApproveDialog(BuildContext context, Product product,
      FirebaseService firebaseService) async {
    final TextEditingController ecoScoreController =
        TextEditingController(text: product.ecoScore.toString());
    String? selectedCategoryIdInDialog = product.categoryId;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text('อนุมัติสินค้า: ${product.name}',
              style: AppTextStyles.subtitle
                  .copyWith(color: AppColors.primaryTeal)),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: ListBody(
                children: <Widget>[
                  Text('ผู้ขายเสนอ Eco Score: ${product.ecoScore}%',
                      style: AppTextStyles.body),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ecoScoreController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ยืนยัน/แก้ไข Eco Score (%)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                              color: AppColors.primaryTeal, width: 2.0)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอก Eco Score';
                      }
                      final score = int.tryParse(value);
                      if (score == null || score < 1 || score > 100) {
                        return 'Eco Score ต้องอยู่ระหว่าง 1-100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_allCategories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedCategoryIdInDialog,
                      decoration: InputDecoration(
                        labelText: 'หมวดหมู่สินค้า',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                      ),
                      hint: const Text('เลือกหมวดหมู่'),
                      items:
                          _allCategories.map((app_category.Category category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name, style: AppTextStyles.body),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedCategoryIdInDialog = value;
                      },
                      validator: (value) =>
                          value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _allCategories.isEmpty
                            ? 'กำลังโหลดหมวดหมู่...'
                            : 'ไม่พบหมวดหมู่สินค้า',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.modernGrey)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal),
              child: Text('ยืนยันอนุมัติ',
                  style:
                      AppTextStyles.bodyBold.copyWith(color: AppColors.white)),
              onPressed: () async {
                if (dialogFormKey.currentState!.validate()) {
                  final finalEcoScore = int.parse(ecoScoreController.text);
                  final selectedCategory = _allCategories.firstWhere(
                    (cat) => cat.id == selectedCategoryIdInDialog,
                    orElse: () => app_category.Category(
                        id: selectedCategoryIdInDialog ?? '',
                        name: 'ไม่ระบุหมวดหมู่',
                        imageUrl: '',
                        createdAt: Timestamp.now()),
                  );
                  await firebaseService.approveProductWithDetails(
                    product.id,
                    finalEcoScore,
                    categoryId: selectedCategoryIdInDialog!,
                    categoryName: selectedCategory.name,
                  );
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${product.name} ได้รับการอนุมัติแล้ว'),
                          backgroundColor: AppColors.successGreen),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectProductDialog(
      Product product, FirebaseService firebaseService) async {
    String? rejectionReason;

    final bool? confirmReject = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('ปฏิเสธสินค้า: ${product.name}',
              style:
                  AppTextStyles.subtitle.copyWith(color: AppColors.errorRed)),
          content: TextField(
            onChanged: (value) {
              rejectionReason = value;
            },
            decoration: const InputDecoration(
              hintText: 'ระบุเหตุผลการปฏิเสธ (ไม่บังคับ)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.modernGrey)),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
              child: const Text('ยืนยันการปฏิเสธ'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmReject == true) {
      try {
        await firebaseService.rejectProduct(product.id, rejectionReason ?? '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${product.name} ถูกปฏิเสธแล้ว'),
                backgroundColor: AppColors.warningOrange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('เกิดข้อผิดพลาดในการปฏิเสธสินค้า: ${e.toString()}'),
                backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
    _loadAllCategories();
  }

  void _refreshList() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAllCategories() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final categories = await firebaseService.getCategories().first;
      if (mounted) {
        setState(() {
          _allCategories = categories;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดหมวดหมู่ทั้งหมด: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return StreamBuilder<List<Product>>(
      stream: firebaseService.getPendingApprovalProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal));
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่มีสินค้าที่รอการอนุมัติ'));
        }

        final allProducts = snapshot.data!;
        final filteredProducts = allProducts.where((product) {
          final productName = product.name.toLowerCase();
          return productName.contains(_searchQuery);
        }).toList();

        if (filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'ค้นหาสินค้าที่รออนุมัติ (ชื่อสินค้า)',
                    hintText: 'พิมพ์ชื่อสินค้า...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primaryTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                            color: AppColors.primaryTeal, width: 2.0)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.modernGrey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const Expanded(
                child: Center(child: Text('ไม่พบสินค้าที่ตรงกับคำค้นหา')),
              ),
            ],
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'ค้นหาสินค้าที่รออนุมัติ (ชื่อสินค้า)',
                  hintText: 'พิมพ์ชื่อสินค้า...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primaryTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                          color: AppColors.primaryTeal, width: 2.0)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.modernGrey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 16.0),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final categoryName = _allCategories.isNotEmpty
                      ? _allCategories
                          .firstWhere((cat) => cat.id == product.categoryId,
                              orElse: () => app_category.Category(
                                  id: '',
                                  name: 'ไม่ระบุ',
                                  imageUrl: '',
                                  createdAt: Timestamp.now()))
                          .name
                      : 'ไม่ระบุ';

                  return FutureBuilder<String?>(
                    future:
                        firebaseService.getUserDisplayName(product.sellerId),
                    builder: (context, sellerSnapshot) {
                      String sellerDisplayName = sellerSnapshot.data ??
                          product.sellerId.substring(0, 8);
                      if (sellerSnapshot.connectionState ==
                              ConnectionState
                                  .waiting && // Corrected: Already correct
                          !sellerSnapshot.hasData) {
                        // Corrected: Already correct
                        sellerDisplayName = "กำลังโหลดชื่อผู้ขาย...";
                      }

                      if (_searchQuery.isNotEmpty &&
                          !product.name.toLowerCase().contains(_searchQuery) &&
                          !sellerDisplayName
                              .toLowerCase()
                              .contains(_searchQuery)) {
                        return const SizedBox.shrink();
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminProductDetailScreen(
                                product: product,
                                onApprovedOrRejected: _refreshList,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    product.imageUrls.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              product.imageUrls[0],
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                      width: 100,
                                                      height: 100,
                                                      decoration: BoxDecoration(
                                                          color: AppColors
                                                              .lightModernGrey,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0)),
                                                      child: const Icon(
                                                          Icons.broken_image,
                                                          size: 50,
                                                          color: AppColors
                                                              .modernGrey)),
                                            ),
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                                color:
                                                    AppColors.lightModernGrey,
                                                borderRadius:
                                                    BorderRadius.circular(8.0)),
                                            child: const Icon(
                                                Icons.image_not_supported,
                                                size: 50,
                                                color: AppColors.modernGrey)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(product.name,
                                              style: AppTextStyles.subtitle
                                                  .copyWith(
                                                      color:
                                                          AppColors.primaryTeal,
                                                      fontWeight: FontWeight
                                                          .bold)), // Corrected: Already correct
                                          const SizedBox(height: 4),
                                          Text('ผู้ขาย: $sellerDisplayName',
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                      fontSize:
                                                          14, // Corrected: Already correct
                                                      color: AppColors
                                                          .modernDarkGrey)),
                                          Text(
                                              'Eco Score (ผู้ขายเสนอ): ${product.ecoScore}%',
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                      fontSize: 14,
                                                      color: AppColors
                                                          .modernGrey)),
                                          Text(
                                              'หมวดหมู่ (ผู้ขายเสนอ): $categoryName',
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                      fontSize: 14,
                                                      color: AppColors
                                                          .modernGrey)),
                                          Text(
                                              'ราคา: ฿${product.price.toStringAsFixed(2)}',
                                              style: AppTextStyles.bodyBold
                                                  .copyWith(
                                                      fontSize: 15,
                                                      color: AppColors
                                                          .primaryTeal)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (product.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                        'รายละเอียด: ${product.description}',
                                        style: AppTextStyles.body
                                            .copyWith(fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                if (product.materialDescription.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                        'วัสดุ: ${product.materialDescription}',
                                        style: AppTextStyles.body
                                            .copyWith(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                if (product.ecoJustification.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                        'เหตุผล Eco: ${product.ecoJustification}',
                                        style: AppTextStyles.body
                                            .copyWith(fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.cancel_outlined,
                                          size: 18, color: AppColors.errorRed),
                                      label: Text('ปฏิเสธ',
                                          style: AppTextStyles.bodyBold
                                              .copyWith(
                                                  color: AppColors.errorRed,
                                                  fontSize: 14)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.errorRed),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _rejectProductDialog(
                                          product, firebaseService),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 18),
                                      label: Text('อนุมัติ',
                                          style: AppTextStyles.bodyBold
                                              .copyWith(
                                                  color: AppColors.white,
                                                  fontSize: 14)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.successGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showApproveDialog(
                                          context, product, firebaseService),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
