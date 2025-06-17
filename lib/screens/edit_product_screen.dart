// lib/screens/edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // สำหรับ kIsWeb และการจัดการ XFile

class EditProductScreen extends StatefulWidget {
  final Product product; // รับ Product ที่ต้องการแก้ไขเข้ามา
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _materialController;
  late TextEditingController _ecoJustificationController;
  late TextEditingController _verificationVideoController;

  late int _ecoScore; // Eco Score ที่จะแก้ไข
  XFile? _pickedImageFile; // <--- เปลี่ยนเป็น XFile? สำหรับรูปภาพที่เลือกใหม่
  List<String> _existingImageUrls =
      []; // สำหรับเก็บ URL รูปภาพเดิม (รองรับหลายรูปถ้า Product model มี)
  late int _level; // เพิ่ม state สำหรับ level
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นของ Controller และตัวแปรต่างๆ จาก Product ที่ส่งเข้ามา
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
        TextEditingController(text: widget.product.verificationVideoUrl);
    _ecoScore = widget.product.ecoScore;
    _existingImageUrls = List<String>.from(widget.product.imageUrls);
    _level = widget.product.level ?? 1; // กำหนดค่า level เริ่มต้น
  }

  @override
  void dispose() {
    // ต้อง dispose controllers เมื่อ widget ถูกทำลาย
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _materialController.dispose();
    _ecoJustificationController.dispose();
    _verificationVideoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = pickedFile; // เก็บ XFile ที่เลือกใหม่
        // _existingImageUrls.clear(); // พิจารณาว่าจะล้างรูปเก่าหรือไม่เมื่อเลือกรูปใหม่
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

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
        );
      }
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      List<String> finalImageUrls =
          List<String>.from(_existingImageUrls); // เริ่มต้นจากรูปเดิม

      // ถ้ามีการเลือกรูปภาพใหม่ ให้อัปโหลดรูปใหม่
      if (_pickedImageFile != null) {
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_pickedImageFile!.name}';
        String? newImageUrl;
        if (kIsWeb) {
          final bytes = await _pickedImageFile!.readAsBytes();
          newImageUrl = await firebaseService.uploadImageBytes(
              'product_images', fileName, bytes);
        } else {
          newImageUrl = await firebaseService.uploadImage(
              'product_images', _pickedImageFile!.path,
              fileName: fileName);
        }
        if (newImageUrl != null) {
          finalImageUrls
              .clear(); // ล้างรูปเก่าทั้งหมดเมื่อมีรูปใหม่อัปโหลดสำเร็จ
          finalImageUrls.add(newImageUrl);
        }
      }

      final updatedProduct = Product(
        id: widget.product.id, // ใช้ ID เดิมของสินค้า
        sellerId: widget.product.sellerId, // ใช้ Seller ID เดิม
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageUrls: finalImageUrls, // ใช้ List ของ URL ที่อัปเดตแล้ว
        ecoScore: _ecoScore,
        materialDescription: _materialController.text,
        ecoJustification: _ecoJustificationController.text,
        verificationVideoUrl: _verificationVideoController.text.isEmpty
            ? null
            : _verificationVideoController.text,
        isApproved:
            widget.product.isApproved, // สถานะอนุมัติไม่เปลี่ยนจากการแก้ไข
        level: _level, // ใช้ level ที่อาจมีการแก้ไข
        // categoryId and categoryName should be preserved or handled if editable
        categoryId: widget.product.categoryId,
        categoryName: widget.product.categoryName, createdAt: null,
        approvedAt: null,
      );

      await firebaseService.updateProduct(updatedProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการแก้ไขสำเร็จแล้ว!')),
        );
        Navigator.of(context).pop(); // กลับไปยังหน้า Seller Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการแก้ไขสินค้า: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.deleteProduct(widget.product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบสินค้าสำเร็จแล้ว!')),
        );
        Navigator.of(context).pop(); // กลับไปยังหน้า Seller Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบสินค้า: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขสินค้า',
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryTeal, // Use new primary color
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.errorRed),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('ยืนยันการลบ',
                    style: AppTextStyles.subtitle
                        .copyWith(color: AppColors.primaryTeal)),
                content: Text(
                    'คุณต้องการลบสินค้า "${widget.product.name}" ใช่หรือไม่?',
                    style: AppTextStyles.body),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('ยกเลิก',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.modernGrey))),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _deleteProduct();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: Text('ลบ',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.white))),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อสินค้า*',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                        labelStyle: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                      ),
                      style: AppTextStyles.body,
                      validator: (value) =>
                          value!.isEmpty ? 'กรุณาใส่ชื่อสินค้า' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'รายละเอียดสินค้า*',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                        labelStyle: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                      ),
                      style: AppTextStyles.body,
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'กรุณาใส่รายละเอียดสินค้า' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'ราคา (บาท)*',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                        labelStyle: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                      ),
                      style: AppTextStyles.body,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาใส่ราคา';
                        }
                        if (double.tryParse(value) == null) {
                          return 'กรุณาใส่ตัวเลขที่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _materialController,
                      decoration: InputDecoration(
                        labelText:
                            'วัสดุที่ใช้ (เช่น พลาสติกรีไซเคิล, ฝ้ายออร์แกนิก)*',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                        labelStyle: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                      ),
                      style: AppTextStyles.body,
                      validator: (value) =>
                          value!.isEmpty ? 'กรุณาใส่วัสดุที่ใช้' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ecoJustificationController,
                      decoration: InputDecoration(
                        labelText:
                            'เหตุผลที่สินค้านี้เป็นมิตรต่อสิ่งแวดล้อม (เช่น ลดขยะ, ประหยัดพลังงาน)*',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                        labelStyle: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                      ),
                      style: AppTextStyles.body,
                      maxLines: 2,
                      validator: (value) =>
                          value!.isEmpty ? 'กรุณาใส่เหตุผล' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _verificationVideoController,
                      decoration: InputDecoration(
                        labelText:
                            'ลิงก์วิดีโอ/รูปภาพยืนยัน (ถ้ามี)', // Optional field
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                        labelStyle: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                      ),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 24),
                    Text('ระดับ Eco Score (%): $_ecoScore',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.primaryTeal)),
                    Slider(
                      value: _ecoScore.toDouble(),
                      min: 1.0,
                      max: 100.0,
                      divisions: 99,
                      label: _ecoScore.toString(),
                      onChanged: (value) {
                        setState(() {
                          _ecoScore = value.toInt();
                        });
                      },
                      activeColor: EcoLevelExtension.fromScore(_ecoScore).color,
                      inactiveColor: AppColors.lightModernGrey,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _level,
                      decoration: InputDecoration(
                        labelText: 'ระดับสินค้า*',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                        labelStyle: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                      ),
                      style: AppTextStyles.body,
                      items: [1, 2, 3].map((levelValue) {
                        return DropdownMenuItem(
                            value: levelValue,
                            child: Text('ระดับ $levelValue',
                                style: AppTextStyles.body));
                      }).toList(),
                      onChanged: (value) => setState(() => _level = value!),
                      validator: (value) =>
                          value == null ? 'กรุณาเลือกระดับสินค้า' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.image_outlined, color: AppColors.white),
                      label: Text('เปลี่ยนรูปภาพสินค้า',
                          style: AppTextStyles.bodyBold
                              .copyWith(color: AppColors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        backgroundColor:
                            AppColors.lightTeal, // Use new accent color
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // แสดงรูปภาพที่เลือกใหม่ (ถ้ามี) หรือรูปภาพเดิม
                    if (_pickedImageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: kIsWeb
                            ? Row(children: [
                                Icon(Icons.image_outlined,
                                    color: AppColors.modernGrey),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(_pickedImageFile!.name,
                                        style: AppTextStyles.body,
                                        overflow: TextOverflow.ellipsis)),
                              ])
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.file(
                                  File(_pickedImageFile!.path),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      )
                    else if (_existingImageUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _existingImageUrls.map((url) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Stack(
                                children: [
                                  Image.network(
                                    url,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: AppColors.lightModernGrey
                                            // ignore: deprecated_member_use
                                            .withOpacity(0.3),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: const Icon(Icons.broken_image,
                                          color: AppColors.modernGrey,
                                          size: 40),
                                    ),
                                  ),
                                  // TODO: Add button to remove existing image if needed
                                  // Positioned(right: 0, top: 0, child: IconButton(icon: Icon(Icons.remove_circle, color: AppColors.errorRed), onPressed: () { /* remove logic */ }))
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: AppTextStyles.subtitle.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                        ),
                        child: Text('บันทึกการแก้ไข',
                            style: AppTextStyles.subtitle
                                .copyWith(color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 16), // Add some space at the bottom
                  ],
                ),
              ),
            ),
    );
  }
}
