// lib/screens/seller/edit_product_seller_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart' as app_category;
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductSellerScreen extends StatefulWidget {
  final Product product;
  const EditProductSellerScreen({super.key, required this.product});

  @override
  State<EditProductSellerScreen> createState() =>
      _EditProductSellerScreenState();
}

class _EditProductSellerScreenState extends State<EditProductSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _materialController;
  late TextEditingController _ecoJustificationController;
  late TextEditingController _verificationVideoController;
  late int _ecoScore;
  XFile? _pickedImageFile;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedCategoryId;
// To store the name of the selected category
  List<app_category.Category> _categories = [];
  bool _isLoadingCategories = true;
  late bool _wasInitiallyApproved;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _materialController =
        TextEditingController(text: widget.product.materialDescription);
    _ecoJustificationController =
        TextEditingController(text: widget.product.ecoJustification);
    _verificationVideoController =
        TextEditingController(text: widget.product.verificationVideoUrl ?? '');
    _ecoScore = widget.product.ecoScore;
    _selectedCategoryId = widget.product.categoryId;
// Initialize category name
    _wasInitiallyApproved = widget.product.isApproved;
    if (widget.product.imageUrls.isNotEmpty) {
      _existingImageUrl = widget.product.imageUrls[0];
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดหมวดหมู่: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = pickedFile;
        _existingImageUrl = null; // Clear existing image if new one is picked
      });
    }
  }

  Future<void> _updateProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกหมวดหมู่สินค้า')));
      return;
    }
    if (_pickedImageFile == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้า')));
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    String? oldImageUrlToDelete;

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      String? imageUrl = _existingImageUrl;

      if (_pickedImageFile != null) {
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
          oldImageUrlToDelete = _existingImageUrl;
        }
        var uuid = const Uuid();
        String extension = _pickedImageFile!.name.split('.').last;
        String fileName = '${uuid.v4()}.$extension';
        if (kIsWeb) {
          final bytes = await _pickedImageFile!.readAsBytes();
          imageUrl = await firebaseService.uploadImageBytes(
              'product_images', fileName, bytes);
        } else {
          imageUrl = await firebaseService.uploadImage(
              'product_images', _pickedImageFile!.path,
              fileName: fileName);
        }
      }

      // Use a consistent way to calculate level, ideally from FirebaseService or Product model
      int calculatedLevel; // = firebaseService._calculateLevelFromEcoScore(_ecoScore); (if accessible)
      if (_ecoScore >= 70) {
        calculatedLevel = 3;
        // ignore: curly_braces_in_flow_control_structures
      } else if (_ecoScore >= 35)
        // ignore: curly_braces_in_flow_control_structures
        calculatedLevel = 2;
      // ignore: curly_braces_in_flow_control_structures
      else if (_ecoScore >= 1)
        // ignore: curly_braces_in_flow_control_structures
        calculatedLevel = 1;
      // ignore: curly_braces_in_flow_control_structures
      else
        // ignore: curly_braces_in_flow_control_structures
        calculatedLevel = 0;
      // If product was approved and is now edited, it needs re-approval.
      bool newApprovalStatus =
          _wasInitiallyApproved ? false : widget.product.isApproved;

      // Ensure categoryName is updated if categoryId changed
      String? finalCategoryName = widget.product.categoryName;
      if (_selectedCategoryId != null &&
          _selectedCategoryId != widget.product.categoryId) {
        final selectedCategory = _categories.firstWhere(
            (cat) => cat.id == _selectedCategoryId,
            orElse: () => app_category.Category(
                id: '', name: '', imageUrl: '', createdAt: Timestamp.now()));
        finalCategoryName = selectedCategory.name;
      } else if (_selectedCategoryId == null) {
        // If category is deselected (should not happen with validator)
        finalCategoryName = null;
      }

      final updatedProduct = Product(
        id: widget.product.id,
        sellerId: user.uid,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageUrls: imageUrl != null ? [imageUrl] : [],
        level: calculatedLevel,
        ecoScore: _ecoScore,
        materialDescription: _materialController.text,
        ecoJustification: _ecoJustificationController.text,
        verificationVideoUrl: _verificationVideoController.text.isEmpty
            ? null
            : _verificationVideoController.text,
        isApproved: newApprovalStatus,
        categoryId: _selectedCategoryId,
        categoryName: finalCategoryName, // Use updated category name
        createdAt: widget.product.createdAt, // Keep original creation date
        // If product is approved (either was already or admin approves it), set approvedAt.
        approvedAt: newApprovalStatus
            ? widget.product.approvedAt
            : null, // Reset approvedAt if re-approval needed or never approved
      );

      await firebaseService.updateProduct(updatedProduct);

      if (oldImageUrlToDelete != null && oldImageUrlToDelete != imageUrl) {
        // Check if old image is different from new one
        await firebaseService.deleteImageByUrl(oldImageUrlToDelete);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'อัปเดตสินค้าเรียบร้อยแล้ว${newApprovalStatus == false && _wasInitiallyApproved ? " และส่งรอการอนุมัติใหม่" : ""}')),
        );
        Navigator.of(context).pop(); // Go back after successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:
                const BorderSide(color: AppColors.primaryTeal, width: 2.0)),
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.modernGrey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขสินค้า',
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ข้อมูลสินค้า",
                          style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('ชื่อสินค้า'),
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null),
                      const SizedBox(height: 12),
                      if (_isLoadingCategories)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                    color: AppColors.primaryTeal)))
                      else if (_categories.isEmpty)
                        const Text('ไม่พบหมวดหมู่สินค้า')
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: _inputDecoration('เลือกหมวดหมู่สินค้า'),
                          items:
                              _categories.map((app_category.Category category) {
                            return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name,
                                    style: AppTextStyles.body));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _descriptionController,
                          decoration: _inputDecoration('รายละเอียดสินค้า'),
                          maxLines: 3,
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณากรอกรายละเอียดสินค้า' : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _priceController,
                          decoration: _inputDecoration('ราคา (บาท)'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'กรุณากรอกราคา';
                            if (double.tryParse(v) == null) {
                              return 'ราคาไม่ถูกต้อง';
                            }
                            if (double.parse(v) <= 0) {
                              return 'ราคาต้องมากกว่า 0';
                            }
                            return null;
                          }),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _materialController,
                          decoration: _inputDecoration('วัสดุที่ใช้'),
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณากรอกวัสดุ' : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _ecoJustificationController,
                          decoration: _inputDecoration(
                              'เหตุผลความเป็นมิตรต่อสิ่งแวดล้อม'),
                          maxLines: 2,
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณาให้เหตุผล' : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _verificationVideoController,
                          decoration: _inputDecoration(
                              'ลิงก์วิดีโอ/รูปภาพยืนยัน (ถ้ามี)')),
                      const SizedBox(height: 20),
                      Text('ระดับ Eco Score (%): $_ecoScore',
                          style: AppTextStyles.bodyBold
                              .copyWith(color: AppColors.primaryTeal)),
                      Slider(
                        value: _ecoScore.toDouble(),
                        min: 1.0,
                        max: 100.0,
                        divisions: 99,
                        label: _ecoScore.toString(),
                        onChanged: (value) =>
                            setState(() => _ecoScore = value.toInt()),
                        activeColor:
                            EcoLevelExtension.fromScore(_ecoScore).color,
                        inactiveColor: AppColors.lightModernGrey,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined,
                                color: AppColors.white),
                            label: Text(
                                _pickedImageFile != null ||
                                        _existingImageUrl != null
                                    ? 'เปลี่ยนรูปภาพ'
                                    : 'เลือกรูปภาพ',
                                style: AppTextStyles.bodyBold
                                    .copyWith(color: AppColors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lightTeal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0))),
                          ),
                          const SizedBox(width: 10),
                          if (_pickedImageFile != null)
                            Expanded(
                                child: Text('ใหม่: ${_pickedImageFile!.name}',
                                    style: AppTextStyles.caption,
                                    overflow: TextOverflow.ellipsis))
                          else if (_existingImageUrl != null)
                            Expanded(
                                child: Text(
                                    'ปัจจุบัน: ${_existingImageUrl!.split('/').last.split('?').first.substring(17)}...',
                                    style: AppTextStyles.caption,
                                    overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      if (_pickedImageFile != null && !kIsWeb)
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.file(File(_pickedImageFile!.path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover)))
                      else if (_pickedImageFile == null &&
                          _existingImageUrl != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(_existingImageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                        Icons.broken_image,
                                        size: 100)))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      textStyle: AppTextStyles.subtitle.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.bold)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 3.0))
                      : Text('บันทึกการเปลี่ยนแปลง',
                          style: AppTextStyles.subtitle
                              .copyWith(color: AppColors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
