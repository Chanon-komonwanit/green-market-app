// lib/screens/seller/edit_product_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:green_market/models/category.dart' as app_category;
import 'package:green_market/models/product.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _keywordsController = TextEditingController();

  bool _isLoading = false;
  String? _selectedCategoryId;
  List<app_category.Category> _categories = [];
  List<PlatformFile> _pickedProductImageFiles = [];
  PlatformFile? _pickedPromotionalImageFile;
  String _selectedCondition = 'ใหม่';
  bool _allowReturns = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _nameController.text = widget.product.name;
    _descriptionController.text = widget.product.description;
    _priceController.text = widget.product.price.toString();
    _stockQuantityController.text = widget.product.stockQuantity.toString();
    _weightController.text = widget.product.weight?.toString() ?? '';
    _dimensionsController.text = widget.product.dimensions ?? '';
    _keywordsController.text = widget.product.keywords?.join(', ') ?? '';
    _selectedCategoryId = widget.product.categoryId;
    _selectedCondition = widget.product.condition ?? 'ใหม่';
    _allowReturns = widget.product.allowReturns;
    _isActive = widget.product.isActive;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final categoriesStream = firebaseService.getCategories();
      categoriesStream.listen((categories) {
        if (mounted) {
          setState(() {
            _categories = categories;
          });
        }
      });
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการโหลดหมวดหมู่', isError: true);
    }
  }

  Future<void> _pickProductImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _pickedProductImageFiles = result.files;
        });
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ', isError: true);
    }
  }

  Future<void> _pickPromotionalImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.size <= 5 * 1024 * 1024) {
        setState(() {
          _pickedPromotionalImageFile = result.files.single;
        });
      } else {
        _showSnackBar('ไฟล์ต้องมีขนาดไม่เกิน 5MB', isError: true);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ', isError: true);
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.currentUser?.id;

    if (currentUserId == null) {
      _showSnackBar('ไม่พบข้อมูลผู้ใช้', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    List<String> uploadedImageUrls = [];
    try {
      String? promotionalImageUrl = widget.product.promotionalImageUrl;
      var uuid = const Uuid();

      // Upload new product images if selected
      for (var imageFile in _pickedProductImageFiles) {
        String extension = imageFile.name.split('.').last;
        String storagePath =
            'product_images/$currentUserId/${uuid.v4()}.$extension';

        String? imageUrl;
        if (kIsWeb) {
          final bytes = imageFile.bytes;
          if (bytes != null) {
            imageUrl = await firebaseService.uploadWebImage(
              bytes,
              storagePath,
            );
          }
        } else {
          if (imageFile.path != null) {
            imageUrl = await firebaseService.uploadImageFile(
              File(imageFile.path!),
              storagePath,
            );
          }
        }
        if (imageUrl != null) {
          uploadedImageUrls.add(imageUrl);
        }
      }

      // Upload new promotional image if selected
      if (_pickedPromotionalImageFile != null) {
        String extension = _pickedPromotionalImageFile!.name.split('.').last;
        String storagePath =
            'promotional_images/$currentUserId/promo_${uuid.v4()}.$extension';

        if (kIsWeb) {
          final bytes = _pickedPromotionalImageFile!.bytes!;
          promotionalImageUrl = await firebaseService.uploadWebImage(
            bytes,
            storagePath,
          );
        } else {
          promotionalImageUrl = await firebaseService.uploadImageFile(
            File(_pickedPromotionalImageFile!.path!),
            storagePath,
          );
        }
      }

      // Use new images if uploaded, otherwise keep existing images
      List<String> finalImageUrls = uploadedImageUrls.isNotEmpty
          ? uploadedImageUrls
          : widget.product.imageUrls;

      final updatedProduct = Product(
        id: widget.product.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stock: int.parse(_stockQuantityController.text.trim()),
        categoryId: _selectedCategoryId!,
        sellerId: currentUserId,
        imageUrls: finalImageUrls,
        ecoScore: widget.product.ecoScore,
        materialDescription: widget.product.materialDescription,
        ecoJustification: widget.product.ecoJustification,
        stockQuantity: int.parse(_stockQuantityController.text.trim()),
        createdAt: widget.product.createdAt,
        updatedAt: Timestamp.now(),
        weight: double.tryParse(_weightController.text.trim()),
        dimensions: _dimensionsController.text.trim().isNotEmpty
            ? _dimensionsController.text.trim()
            : null,
        keywords: _keywordsController.text
            .split(',')
            .map((k) => k.trim())
            .where((k) => k.isNotEmpty)
            .toList(),
        promotionalImageUrl: promotionalImageUrl,
        condition: _selectedCondition,
        allowReturns: _allowReturns,
        isActive: _isActive,
        isFeatured: widget.product.isFeatured,
        averageRating: widget.product.averageRating,
        reviewCount: widget.product.reviewCount,
        approvalStatus: widget.product.approvalStatus,
        rejectionReason: widget.product.rejectionReason,
      );

      await firebaseService.updateProduct(updatedProduct);
      _showSnackBar('อัปเดตสินค้าสำเร็จ', isSuccess: true);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการอัปเดตสินค้า: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    showAppSnackBar(context, message, isError: isError, isSuccess: isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แก้ไขสินค้า',
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสินค้า',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อสินค้า';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียดสินค้า',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกรายละเอียดสินค้า';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and Stock
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'ราคา (บาท)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกราคา';
                              }
                              if (double.tryParse(value) == null ||
                                  double.parse(value) <= 0) {
                                return 'กรุณากรอกราคาที่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stockQuantityController,
                            decoration: const InputDecoration(
                              labelText: 'จำนวนในสต็อก',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกจำนวน';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) < 0) {
                                return 'กรุณากรอกจำนวนที่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'หมวดหมู่',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาเลือกหมวดหมู่';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Images
                    Text('รูปภาพสินค้าปัจจุบัน:',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (widget.product.imageUrls.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.product.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.product.imageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _pickProductImages,
                      icon: const Icon(Icons.photo_library),
                      label: Text(_pickedProductImageFiles.isEmpty
                          ? 'เลือกรูปภาพใหม่'
                          : 'เลือกแล้ว ${_pickedProductImageFiles.length} รูป'),
                    ),
                    const SizedBox(height: 16),

                    // Show selected new images
                    if (_pickedProductImageFiles.isNotEmpty) ...[
                      Text('รูปภาพใหม่ที่เลือก:',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickedProductImageFiles.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.memory(
                                        _pickedProductImageFiles[index].bytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_pickedProductImageFiles[index]
                                            .path!),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Promotional Image
                    if (widget.product.promotionalImageUrl != null) ...[
                      Text('รูปภาพโปรโมชันปัจจุบัน:',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.product.promotionalImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton.icon(
                      onPressed: _pickPromotionalImage,
                      icon: const Icon(Icons.photo),
                      label: Text(_pickedPromotionalImageFile == null
                          ? 'เลือกรูปภาพโปรโมชันใหม่'
                          : 'เลือกแล้ว'),
                    ),
                    const SizedBox(height: 16),

                    // Show selected promotional image
                    if (_pickedPromotionalImageFile != null) ...[
                      Text('รูปภาพโปรโมชันใหม่:',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.memory(
                                  _pickedPromotionalImageFile!.bytes!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_pickedPromotionalImageFile!.path!),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Additional Fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'น้ำหนัก (กิโลกรัม)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _dimensionsController,
                            decoration: const InputDecoration(
                              labelText: 'ขนาด (ซม.)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Condition
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'สภาพสินค้า',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          ['ใหม่', 'มือสอง', 'ปรับปรุงแล้ว'].map((condition) {
                        return DropdownMenuItem<String>(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCondition = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Keywords
                    TextFormField(
                      controller: _keywordsController,
                      decoration: const InputDecoration(
                        labelText: 'คำสำคัญ (แยกด้วยจุลภาค)',
                        border: OutlineInputBorder(),
                        hintText: 'เช่น: อินทรีย์, ผัก, สด',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Switches
                    SwitchListTile(
                      title: const Text('อนุญาตให้คืนสินค้า'),
                      value: _allowReturns,
                      onChanged: (value) {
                        setState(() {
                          _allowReturns = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('เปิดใช้งานสินค้า'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.white)
                            : const Text('อัปเดตสินค้า',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }
}
