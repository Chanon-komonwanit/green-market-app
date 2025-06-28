// lib/screens/seller/edit_product_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
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
  final _materialDescriptionController = TextEditingController();
  final _ecoJustificationController = TextEditingController();
  final _ecoScoreController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedCondition = 'ใหม่';
  bool _allowReturns = false;
  bool _isActive = true;
  bool _isLoading = false;

  List<Category> _categories = [];
  List<PlatformFile> _pickedProductImageFiles = [];
  PlatformFile? _pickedPromotionalImageFile;

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
    _materialDescriptionController.text = widget.product.materialDescription;
    _ecoJustificationController.text = widget.product.ecoJustification;
    _ecoScoreController.text = widget.product.ecoScore.toString();
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
      firebaseService.getCategories().listen((categories) {
        if (mounted) {
          setState(() {
            _categories = categories;
          });
        }
      });
    } catch (e) {
      showAppSnackBar(context, 'ไม่สามารถโหลดหมวดหมู่ได้', isError: true);
    }
  }

  Future<void> _pickProductImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _pickedProductImageFiles = result.files;
      });
    }
  }

  Future<void> _pickPromotionalImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _pickedPromotionalImageFile = result.files.first;
      });
    }
  }

  void _removeProductImage(int index) {
    setState(() {
      _pickedProductImageFiles.removeAt(index);
    });
  }

  void _removePromotionalImage() {
    setState(() {
      _pickedPromotionalImageFile = null;
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      showAppSnackBar(context, 'กรุณาเลือกหมวดหมู่สินค้า', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    List<String> uploadedImageUrls = [];
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final currentUserId = firebaseService.currentUser?.uid ?? '';
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
          final bytes = _pickedPromotionalImageFile!.bytes;
          if (bytes != null) {
            promotionalImageUrl = await firebaseService.uploadWebImage(
              bytes,
              storagePath,
            );
          }
        } else {
          if (_pickedPromotionalImageFile!.path != null) {
            promotionalImageUrl = await firebaseService.uploadImageFile(
              File(_pickedPromotionalImageFile!.path!),
              storagePath,
            );
          }
        }
      }

      // Merge new images with existing ones
      final allImageUrls = [
        ...widget.product.imageUrls,
        ...uploadedImageUrls,
      ];

      final updatedProduct = Product(
        id: widget.product.id,
        sellerId: widget.product.sellerId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        stock: int.parse(_stockQuantityController.text),
        categoryId: _selectedCategoryId!,
        categoryName:
            _categories.firstWhere((cat) => cat.id == _selectedCategoryId).name,
        imageUrls: allImageUrls,
        promotionalImageUrl: promotionalImageUrl,
        ecoScore: int.parse(_ecoScoreController.text),
        materialDescription: _materialDescriptionController.text.trim(),
        ecoJustification: _ecoJustificationController.text.trim(),
        verificationVideoUrl: widget.product.verificationVideoUrl,
        status: widget.product.status,
        rejectionReason: widget.product.rejectionReason,
        createdAt: widget.product.createdAt,
        approvedAt: widget.product.approvedAt,
        updatedAt: widget.product.updatedAt,
        stockQuantity: int.parse(_stockQuantityController.text),
        weight: _weightController.text.isNotEmpty
            ? double.parse(_weightController.text)
            : null,
        dimensions: _dimensionsController.text.trim().isNotEmpty
            ? _dimensionsController.text.trim()
            : null,
        keywords: _keywordsController.text
            .split(',')
            .map((k) => k.trim())
            .where((k) => k.isNotEmpty)
            .toList(),
        condition: _selectedCondition,
        allowReturns: _allowReturns,
        isActive: _isActive,
        isFeatured: widget.product.isFeatured,
        averageRating: widget.product.averageRating,
        reviewCount: widget.product.reviewCount,
        approvalStatus: widget.product.approvalStatus,
      );

      await firebaseService.updateProduct(updatedProduct);

      if (mounted) {
        showAppSnackBar(context, 'อัปเดตสินค้าสำเร็จ', isSuccess: true);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขสินค้า',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสินค้า *',
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
                  labelText: 'รายละเอียดสินค้า *',
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

              // Price and Stock in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'ราคา (บาท) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกราคา';
                        }
                        if (double.tryParse(value) == null) {
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
                        labelText: 'จำนวนสต็อก *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกจำนวนสต็อก';
                        }
                        if (int.tryParse(value) == null) {
                          return 'กรุณากรอกจำนวนที่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่สินค้า *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
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
                  if (value == null) {
                    return 'กรุณาเลือกหมวดหมู่สินค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Eco information
              Text('ข้อมูลด้านสิ่งแวดล้อม',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _ecoScoreController,
                decoration: const InputDecoration(
                  labelText: 'คะแนนด้านสิ่งแวดล้อม (1-100) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกคะแนนด้านสิ่งแวดล้อม';
                  }
                  final score = int.tryParse(value);
                  if (score == null || score < 1 || score > 100) {
                    return 'กรุณากรอกคะแนนระหว่าง 1-100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _materialDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดวัสดุ *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกรายละเอียดวัสดุ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ecoJustificationController,
                decoration: const InputDecoration(
                  labelText: 'เหตุผลด้านสิ่งแวดล้อม *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเหตุผลด้านสิ่งแวดล้อม';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Additional fields
              Text('ข้อมูลเพิ่มเติม',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

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

              TextFormField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: 'คำค้นหา (คั่นด้วยเครื่องหมายจุลภาค)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Condition dropdown
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'สภาพสินค้า',
                  border: OutlineInputBorder(),
                ),
                items: ['ใหม่', 'มือสอง (สภาพดี)', 'มือสอง (สภาพปกติ)']
                    .map((condition) {
                  return DropdownMenuItem(
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
              const SizedBox(height: 24),

              // Image upload sections
              Text('รูปภาพสินค้า',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Current images
              if (widget.product.imageUrls.isNotEmpty) ...[
                Text('รูปภาพปัจจุบัน:', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.product.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.product.imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // New product images
              if (_pickedProductImageFiles.isNotEmpty) ...[
                Text('รูปภาพใหม่ที่เลือก:', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedProductImageFiles.length,
                    itemBuilder: (context, index) {
                      final file = _pickedProductImageFiles[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? FutureBuilder<Uint8List?>(
                                      future: Future.value(file.bytes),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          return Image.memory(
                                            snapshot.data!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      },
                                    )
                                  : Image.file(
                                      File(file.path!),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeProductImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton.icon(
                onPressed: _pickProductImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('เพิ่มรูปภาพสินค้า'),
              ),
              const SizedBox(height: 24),

              // Promotional image section
              Text('รูปภาพโปรโมชัน',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Current promotional image
              if (widget.product.promotionalImageUrl != null) ...[
                Text('รูปภาพโปรโมชันปัจจุบัน:',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.product.promotionalImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // New promotional image
              if (_pickedPromotionalImageFile != null) ...[
                Text('รูปภาพโปรโมชันใหม่:', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? FutureBuilder<Uint8List?>(
                                future: Future.value(
                                    _pickedPromotionalImageFile!.bytes),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                              )
                            : Image.file(
                                File(_pickedPromotionalImageFile!.path!),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removePromotionalImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton.icon(
                onPressed: _pickPromotionalImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('เลือกรูปภาพโปรโมชัน'),
              ),
              const SizedBox(height: 32),

              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกการแก้ไข'),
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
    _materialDescriptionController.dispose();
    _ecoJustificationController.dispose();
    _ecoScoreController.dispose();
    super.dispose();
  }
}
