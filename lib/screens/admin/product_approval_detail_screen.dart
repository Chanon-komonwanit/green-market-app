// lib/screens/admin/product_approval_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:green_market/models/category.dart' as app_category;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/seller.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback onApprovedOrRejected; // Callback to refresh the list

  const AdminProductDetailScreen(
      {super.key, required this.product, required this.onApprovedOrRejected});

  @override
  State<AdminProductDetailScreen> createState() =>
      _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  List<app_category.Category> _allCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadAllCategories();
  }

  Future<void> _loadAllCategories() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final categories = await firebaseService.getCategories().first;
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดหมวดหมู่: $e')),
        );
      }
    }
  }

  Future<void> _showApproveDialog() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final TextEditingController ecoScoreController =
        TextEditingController(text: widget.product.ecoScore.toString());
    String? selectedCategoryIdInDialog = widget.product.categoryId;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text('อนุมัติสินค้า: ${widget.product.name}',
              style: AppTextStyles.subtitle
                  .copyWith(color: AppColors.primaryTeal)),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: ListBody(
                children: <Widget>[
                  Text('ผู้ขายเสนอ Eco Score: ${widget.product.ecoScore}%',
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
                  if (_isLoadingCategories)
                    const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryTeal))
                  else if (_allCategories.isNotEmpty)
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
                            child:
                                Text(category.name, style: AppTextStyles.body));
                      }).toList(),
                      onChanged: (value) => selectedCategoryIdInDialog = value,
                      validator: (value) =>
                          value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                    )
                  else
                    Text('ไม่พบหมวดหมู่สินค้า',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey)),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: Text('ยกเลิก',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.modernGrey)),
                onPressed: () => Navigator.of(dialogContext).pop()),
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
                          createdAt: Timestamp.now()));
                  try {
                    await firebaseService.approveProductWithDetails(
                      widget.product.id,
                      finalEcoScore,
                      categoryId: selectedCategoryIdInDialog!,
                      categoryName: selectedCategory.name,
                    );
                    widget.onApprovedOrRejected();
                    Navigator.of(dialogContext).pop(); // Close dialog
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              '${widget.product.name} ได้รับการอนุมัติแล้ว'),
                          backgroundColor: AppColors.successGreen));
                      Navigator.of(context).pop(); // Go back from detail screen
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'เกิดข้อผิดพลาดในการอนุมัติ: ${e.toString()}'),
                          backgroundColor: AppColors.errorRed));
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectProductDialog() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    String? rejectionReason;

    final bool? confirmReject = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('ปฏิเสธสินค้า: ${widget.product.name}',
              style:
                  AppTextStyles.subtitle.copyWith(color: AppColors.errorRed)),
          content: TextField(
            onChanged: (value) => rejectionReason = value,
            decoration: const InputDecoration(
                hintText: 'ระบุเหตุผลการปฏิเสธ (ไม่บังคับ)',
                border: OutlineInputBorder()),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('ยกเลิก'),
                onPressed: () => Navigator.of(dialogContext).pop(false)),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
              child: const Text('ยืนยันการปฏิเสธ'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmReject == true) {
      try {
        await firebaseService.rejectProduct(
            widget.product.id, rejectionReason ?? '');
        widget.onApprovedOrRejected(); // Call callback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${widget.product.name} ถูกปฏิเสธแล้ว'),
                backgroundColor: AppColors.warningOrange),
          );
          Navigator.of(context).pop(); // Go back to the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('เกิดข้อผิดพลาดในการปฏิเสธ: ${e.toString()}'),
                backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter =
        NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final sellerProposedCategoryName =
        _allCategories.isNotEmpty && !_isLoadingCategories
            ? _allCategories
                .firstWhere((cat) => cat.id == widget.product.categoryId,
                    orElse: () => app_category.Category(
                        id: '',
                        name: 'N/A',
                        imageUrl: '',
                        createdAt: Timestamp.now()))
                .name
            : widget.product.categoryName ?? 'ไม่ระบุ';

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดสินค้า (Admin)',
            style: AppTextStyles.title.copyWith(color: AppColors.primaryTeal)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryTeal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.product.imageUrls.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                    height: 250.0, autoPlay: false, enlargeCenterPage: true),
                items: widget.product.imageUrls
                    .map((item) => Center(
                            child: Image.network(
                          item,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image,
                                  size: 100, color: AppColors.modernGrey),
                        )))
                    .toList(),
              )
            else
              Container(
                  height: 250,
                  color: AppColors.lightModernGrey,
                  child: const Center(
                      child: Icon(Icons.image_not_supported,
                          size: 100, color: AppColors.modernGrey))),
            const SizedBox(height: 16),
            Text(widget.product.name,
                style: AppTextStyles.headline
                    .copyWith(color: AppColors.primaryDarkGreen)),
            const SizedBox(height: 8),
            Text('ราคา: ${currencyFormatter.format(widget.product.price)}',
                style: AppTextStyles.price.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Eco Score (ผู้ขายเสนอ): ${widget.product.ecoScore}%',
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            Text('หมวดหมู่ (ผู้ขายเสนอ): $sellerProposedCategoryName',
                style: AppTextStyles.body),
            const SizedBox(height: 16),
            _buildDetailSection(
                'รายละเอียดสินค้า:', widget.product.description),
            _buildDetailSection(
                'วัสดุที่ใช้:', widget.product.materialDescription),
            _buildDetailSection('เหตุผลความเป็นมิตรต่อสิ่งแวดล้อม:',
                widget.product.ecoJustification),
            if (widget.product.verificationVideoUrl != null &&
                widget.product.verificationVideoUrl!.isNotEmpty)
              _buildDetailSection(
                  'ลิงก์ยืนยัน:', widget.product.verificationVideoUrl!),
            const SizedBox(height: 24),
            _buildSellerInfoSection(widget.product.sellerId),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined,
                    color: AppColors.errorRed),
                label: Text('ปฏิเสธ',
                    style: AppTextStyles.bodyBold
                        .copyWith(color: AppColors.errorRed)),
                onPressed: _rejectProductDialog,
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline,
                    color: AppColors.white),
                label: Text('อนุมัติ',
                    style: AppTextStyles.bodyBold
                        .copyWith(color: AppColors.white)),
                onPressed: _showApproveDialog,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.subtitle
                  .copyWith(color: AppColors.primaryTeal)),
          const SizedBox(height: 4),
          Text(content,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.modernDarkGrey)),
        ],
      ),
    );
  }

  Widget _buildSellerInfoSection(String sellerId) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    return FutureBuilder<Seller?>(
      future: firebaseService.getSellerFullDetails(sellerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('ไม่พบข้อมูลผู้ขาย');
        }
        final seller = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),
            Text('ข้อมูลผู้ขาย',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.primaryTeal)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: seller.shopImageUrl != null
                      ? NetworkImage(seller.shopImageUrl!)
                      : null,
                  child: seller.shopImageUrl == null
                      ? const Icon(Icons.storefront)
                      : null,
                ),
                title: Text(seller.shopName, style: AppTextStyles.bodyBold),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (seller.createdAt != null)
                      Text(
                          'สมัครเมื่อ: ${DateFormat('dd MMM yyyy').format(seller.createdAt!.toDate())}'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
