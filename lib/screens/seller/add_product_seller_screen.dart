// lib/screens/seller/add_product_seller_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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

class AddProductSellerScreen extends StatefulWidget {
  const AddProductSellerScreen({super.key});

  @override
  State<AddProductSellerScreen> createState() => _AddProductSellerScreenState();
}

class _AddProductSellerScreenState extends State<AddProductSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _ecoJustificationController =
      TextEditingController();
  final TextEditingController _verificationVideoController =
      TextEditingController();
  int _ecoScore =
      50; // Default Eco Score for seller, can be adjusted by admin later
  XFile? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedCategoryId;
  String? _selectedCategoryName; // To store the name of the selected category
  List<app_category.Category> _categories = [];
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
      // Assuming getCategories returns a Stream, take the first emission
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
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'เลือกรูปภาพสำเร็จ: ${pickedFile.name} (Preview อาจไม่แสดงบน Web)')),
        );
      }
    }
  }

  Future<void> _addProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนเพิ่มสินค้า')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกหมวดหมู่สินค้า')),
        );
      }
      return;
    }
    if (_pickedImageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้า')),
        );
      }
      return;
    }

    _formKey.currentState!.save();
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      String? imageUrl;

      if (_pickedImageFile != null) {
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

      // Calculate level based on ecoScore (seller sets initial, admin can adjust)
      int calculatedLevel;
      if (_ecoScore <= 40) {
        calculatedLevel = 1;
      } else if (_ecoScore <= 70) {
        calculatedLevel = 2;
      } else {
        calculatedLevel = 3;
      }

      final newProduct = Product(
        id: '', // Firestore will generate ID
        sellerId: user.uid, // Seller's ID
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageUrls: imageUrl != null ? [imageUrl] : [],
        level: calculatedLevel,
        ecoScore: _ecoScore, // Seller sets initial eco-score
        materialDescription: _materialController.text,
        ecoJustification: _ecoJustificationController.text,
        verificationVideoUrl: _verificationVideoController.text.isEmpty
            ? null
            : _verificationVideoController.text,
        isApproved: false, // Products added by sellers need admin approval
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName, // Add selected category name
        // createdAt and approvedAt will be set by Firestore/server or during approval
      );

      await firebaseService.addProduct(newProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('สินค้าของคุณถูกส่งเพื่อรอการอนุมัติแล้ว!')),
        );
      }
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเพิ่มสินค้า: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _materialController.clear();
    _ecoJustificationController.clear();
    _verificationVideoController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _pickedImageFile = null;
      _ecoScore = 50; // Reset Eco Score to default for seller
      _selectedCategoryId = null;
      _selectedCategoryName = null;
    });
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppColors.primaryTeal, width: 2.0)),
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.modernGrey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มสินค้าใหม่',
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
              // Similar to _buildSectionCard in AdminPanelScreen, but simplified for now
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
                        const Text(
                            'ไม่พบหมวดหมู่สินค้า (กรุณาติดต่อผู้ดูแลระบบ)')
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: _inputDecoration('เลือกหมวดหมู่สินค้า'),
                          hint: const Text('เลือกหมวดหมู่'),
                          items:
                              _categories.map((app_category.Category category) {
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.name,
                                  style: AppTextStyles.body),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                              // Find and store the category name
                              _selectedCategoryName = _categories
                                  .firstWhere((cat) => cat.id == value,
                                      orElse: () => app_category.Category(
                                          id: '',
                                          name: '',
                                          imageUrl: '',
                                          createdAt: Timestamp.now()))
                                  .name;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                          style: AppTextStyles.body,
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
                          decoration: _inputDecoration(
                              'วัสดุที่ใช้ (เช่น พลาสติกรีไซเคิล)'),
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
                      Text('ระดับ Eco Score ที่คุณประเมิน (%): $_ecoScore',
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
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined,
                            color: AppColors.white),
                        label: Text('เลือกรูปภาพสินค้า',
                            style: AppTextStyles.bodyBold
                                .copyWith(color: AppColors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lightTeal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0))),
                      ),
                      if (_pickedImageFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: kIsWeb
                              ? Row(children: [
                                  Icon(Icons.image_outlined,
                                      color: AppColors.modernGrey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          'เลือกรูปภาพ: ${_pickedImageFile!.name}',
                                          style: AppTextStyles.body,
                                          overflow: TextOverflow.ellipsis))
                                ])
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                      File(_pickedImageFile!.path),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addProduct,
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
                      : Text('ส่งสินค้าเพื่อรออนุมัติ',
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
