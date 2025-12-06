// lib/screens/seller/add_product_screen.dart
import 'dart:io'; // For File

import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart' as app_category;
import 'package:green_market/models/product.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/services/ai_eco_analysis_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull and other collection utilities

class _CategoryDropdownItem {
  final app_category.Category category;
  final String displayName;
  _CategoryDropdownItem(this.category, this.displayName);
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController =
      TextEditingController(); // Added stock controller
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _ecoJustificationController =
      TextEditingController();
  final TextEditingController _verificationVideoController =
      TextEditingController();

  // 🆕 New AI-related controllers
  final TextEditingController _manufacturingProcessController =
      TextEditingController();
  final TextEditingController _packagingTypeController =
      TextEditingController();
  final TextEditingController _wasteManagementController =
      TextEditingController();
  final List<String> _selectedCertificates = [];
  final List<String> _selectedMaterials = [];

  int _ecoScore = 50; // Default Eco Score
  EcoAnalysisResult? _aiAnalysisResult; // 🆕 AI Analysis Result
  bool _isAnalyzingWithAI = false; // 🆕 AI Analysis Loading State

  final List<XFile> _pickedProductImageFiles = []; // For 1-7 product images
  XFile? _pickedPromotionalImageFile; // For 1 promotional image
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  List<app_category.Category> _categories = [];
  final List<_CategoryDropdownItem> _categoryDropdownItems = [];
  bool _isLoadingCategories = true;

  final AIEcoAnalysisService _aiService = AIEcoAnalysisService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );
    try {
      final categories = await firebaseService.getCategories().first;
      if (mounted) {
        setState(() {
          _categories = categories.cast<app_category.Category>();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        _showSnackBar('โหลดหมวดหมู่ล้มเหลว: ${e.toString()}', isError: true);
      }
    } finally {
      _buildCategoryDropdownItems();
    }
  }

  void _buildCategoryDropdownItems() {
    _categoryDropdownItems.clear();
    // First, add top-level categories
    final topLevelCategories =
        _categories.where((cat) => cat.parentId == null).toList();
    topLevelCategories.sort((a, b) => a.name.compareTo(b.name));

    for (var topCat in topLevelCategories) {
      _categoryDropdownItems.add(_CategoryDropdownItem(topCat, topCat.name));
      // Then, add sub-categories
      final subCategories =
          _categories.where((cat) => cat.parentId == topCat.id).toList();
      subCategories.sort((a, b) => a.name.compareTo(b.name));
      for (var subCat in subCategories) {
        _categoryDropdownItems.add(
          _CategoryDropdownItem(subCat, '  - ${subCat.name}'),
        );
      }
    }
  }

  Future<void> _pickProductImages() async {
    if (_pickedProductImageFiles.length >= 7) {
      _showSnackBar('สามารถเลือกรูปภาพสินค้าได้สูงสุด 7 รูป', isError: true);
      return;
    }
    final List<XFile> selectedImages = await _picker.pickMultiImage(
      imageQuality: 70,
    );
    if (selectedImages.isNotEmpty) {
      if (mounted) {
        setState(() {
          final remainingSlots = 7 - _pickedProductImageFiles.length;
          _pickedProductImageFiles.addAll(selectedImages.take(remainingSlots));
        });
      }
    }
  }

  Future<void> _pickPromotionalImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (selectedImage != null) {
      if (mounted) {
        setState(() {
          _pickedPromotionalImageFile = selectedImage;
        });
      }
    }
  }

  void _removeProductImage(int index) {
    if (mounted) {
      setState(() {
        _pickedProductImageFiles.removeAt(index);
      });
    }
  }

  void _removePromotionalImage() {
    if (mounted) {
      setState(() {
        _pickedPromotionalImageFile = null;
      });
    }
  }

  /// 🤖 วิเคราะห์สินค้าด้วย AI
  Future<void> _analyzeWithAI() async {
    // 🔍 ตรวจสอบว่า AI เปิดใช้งานหรือไม่
    final aiSettings = await _aiService.getAISettings();
    
    if (!aiSettings.canUseAI()) {
      if (!aiSettings.aiEnabled) {
        _showSnackBar('⚠️ ระบบ AI ถูกปิดชั่วคราว กรุณาติดต่อทีมงาน', isError: true);
      } else {
        _showSnackBar('⚠️ ระบบ AI ถึงขีดจำกัดการใช้งานวันนี้ (${aiSettings.dailyLimit} ครั้ง)', isError: true);
      }
      return;
    }

    // ตรวจสอบข้อมูลพื้นฐานก่อน
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('กรุณากรอกชื่อสินค้าก่อนวิเคราะห์', isError: true);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar('กรุณากรอกคำอธิบายสินค้าก่อนวิเคราะห์', isError: true);
      return;
    }
    if (_ecoJustificationController.text.trim().isEmpty) {
      _showSnackBar('กรุณากรอกเหตุผลความเป็น Eco ก่อนวิเคราะห์', isError: true);
      return;
    }

    setState(() => _isAnalyzingWithAI = true);

    try {
      // เตรียมข้อมูลสำหรับ AI
      final productData = ProductEcoData(
        productName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        sellerClaimedScore: _ecoScore,
        sellerJustification: _ecoJustificationController.text.trim(),
        materials: _selectedMaterials.isNotEmpty
            ? _selectedMaterials
            : _materialController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        certificates: _selectedCertificates,
        manufacturingProcess: _manufacturingProcessController.text.trim(),
        packagingType: _packagingTypeController.text.trim(),
        wasteManagement: _wasteManagementController.text.trim(),
        category: _selectedCategoryName ?? '',
      );

      // เรียก AI วิเคราะห์
      final result = await _aiService.analyzeProduct(productData);

      if (mounted) {
        setState(() {
          _aiAnalysisResult = result;
          _isAnalyzingWithAI = false;
        });

        // แสดงผลการวิเคราะห์
        _showAIAnalysisDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzingWithAI = false);
        _showSnackBar('เกิดข้อผิดพลาดในการวิเคราะห์: $e', isError: true);
      }
    }
  }

  /// แสดงผลการวิเคราะห์จาก AI
  void _showAIAnalysisDialog(EcoAnalysisResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.purple),
            const SizedBox(width: 12),
            const Text('ผลการวิเคราะห์จาก AI'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI Eco Score
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getEcoLevelColor(result.ecoLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getEcoLevelColor(result.ecoLevel)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${result.aiEcoScore}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getEcoLevelColor(result.ecoLevel),
                      ),
                    ),
                    Text(
                      'AI Eco Score',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        _getEcoLevelText(result.ecoLevel),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getEcoLevelColor(result.ecoLevel),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Score Comparison
              if ((_ecoScore - result.aiEcoScore).abs() > 10) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'คะแนนที่คุณระบุ ($_ecoScore) แตกต่างจาก AI (${result.aiEcoScore}) ค่อนข้างมาก',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // AI Reasoning
              const Text(
                'เหตุผลจาก AI:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.aiReasoning,
                style: TextStyle(color: Colors.grey[700]),
              ),

              const SizedBox(height: 16),

              // Score Breakdown
              const Text(
                'รายละเอียดคะแนน:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...result.scoreBreakdown.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_getScoreBreakdownLabel(e.key)),
                        ),
                        Text(
                          '${e.value.toStringAsFixed(0)}/25',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),

              // AI Suggestions
              if (result.aiSuggestions.isNotEmpty) ...[
                const Text(
                  'คำแนะนำจาก AI:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.aiSuggestions.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.key + 1}. ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(e.value)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _ecoScore = result.aiEcoScore;
              });
              Navigator.pop(context);
              _showSnackBar('ใช้คะแนนจาก AI เรียบร้อยแล้ว', isSuccess: true);
            },
            child: const Text('ใช้คะแนนนี้'),
          ),
        ],
      ),
    );
  }

  Color _getEcoLevelColor(String level) {
    switch (level) {
      case 'champion':
        return Colors.purple;
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getEcoLevelText(String level) {
    switch (level) {
      case 'champion':
        return 'Eco Champion';
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      default:
        return 'Standard';
    }
  }

  String _getScoreBreakdownLabel(String key) {
    switch (key) {
      case 'materials':
        return 'วัสดุ';
      case 'manufacturing':
        return 'กระบวนการผลิต';
      case 'packaging':
        return 'บรรจุภัณฑ์';
      case 'wasteManagement':
        return 'การจัดการขยะ';
      case 'certificates':
        return 'ใบรับรอง';
      default:
        return key;
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_pickedProductImageFiles.isEmpty) {
      _showSnackBar('กรุณาเลือกรูปภาพสินค้าอย่างน้อย 1 รูป', isError: true);
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryName == null) {
      _showSnackBar('กรุณาเลือกหมวดหมู่สินค้า', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      _showSnackBar('ผู้ใช้ไม่ได้เข้าสู่ระบบ', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    List<String> uploadedImageUrls = []; // Track uploaded images for cleanup
    try {
      String? promotionalImageUrl;
      var uuid = const Uuid();

      // Upload product images
      for (var imageFile in _pickedProductImageFiles) {
        String extension = imageFile.name.split('.').last;
        String storagePath =
            'product_images/$currentUserId/${uuid.v4()}.$extension';

        String? imageUrl;
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          imageUrl = await firebaseService.uploadWebImage(
            bytes,
            storagePath,
          );
        } else {
          imageUrl = await firebaseService.uploadImageFile(
            File(imageFile.path),
            storagePath,
          );
        }
        uploadedImageUrls.add(imageUrl);
      }

      // Upload promotional image if selected
      if (_pickedPromotionalImageFile != null) {
        String extension = _pickedPromotionalImageFile!.name.split('.').last;
        String storagePath =
            'promotional_images/$currentUserId/promo_${uuid.v4()}.$extension';

        if (kIsWeb) {
          final bytes = await _pickedPromotionalImageFile!.readAsBytes();
          promotionalImageUrl = await firebaseService.uploadWebImage(
            bytes,
            storagePath,
          );
        } else {
          promotionalImageUrl = await firebaseService.uploadImageFile(
            File(_pickedPromotionalImageFile!.path),
            storagePath,
          );
        }
      }

      if (uploadedImageUrls.isEmpty) {
        _showSnackBar('ไม่สามารถอัปโหลดรูปภาพสินค้าได้', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final product = Product(
        id: '', // Firestore will generate ID
        sellerId: currentUserId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        stock: int.tryParse(_stockController.text.trim()) ??
            0, // Use stock controller
        imageUrls: uploadedImageUrls,
        promotionalImageUrl: promotionalImageUrl,
        materialDescription: _materialController.text.trim(),
        ecoJustification: _ecoJustificationController.text.trim(),
        ecoScore: _ecoScore,
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        status: 'pending_approval', // Initial status is pending approval
        createdAt: null, // Let Firestore set the server timestamp
        approvedAt: null, // Not approved yet
        rejectionReason: null, // No rejection reason initially
        verificationVideoUrl:
            _verificationVideoController.text.trim().isNotEmpty
                ? _verificationVideoController.text.trim()
                : null,
        // AI Analysis data (if analyzed)
        aiEcoScore: _aiAnalysisResult?.aiEcoScore,
        aiReasoning: _aiAnalysisResult?.aiReasoning,
        aiSuggestions: _aiAnalysisResult?.aiSuggestions,
        aiScoreBreakdown: _aiAnalysisResult?.scoreBreakdown,
        aiEcoLevel: _aiAnalysisResult?.ecoLevel,
        aiConfidence: _aiAnalysisResult?.confidence,
        aiAnalyzed: _aiAnalysisResult != null,
        aiAnalyzedAt: _aiAnalysisResult != null ? Timestamp.now() : null,
      );

      await firebaseService.submitProductRequest(product);

      _showSnackBar(
        'ส่งคำขอเพิ่มสินค้าเรียบร้อยแล้ว รอการอนุมัติจากแอดมิน',
        isSuccess: true,
      );
      _clearForm();
      if (mounted) {
        // Return `true` so the caller can detect success and refresh lists
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // If product creation fails, attempt to delete any images that were already uploaded
      for (var url in uploadedImageUrls) {
        await firebaseService.deleteImageByUrl(url);
      }
      _showSnackBar(
        'เกิดข้อผิดพลาดในการเพิ่มสินค้า: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.clear(); // Clear stock controller
    _materialController.clear();
    _ecoJustificationController.clear();
    _verificationVideoController.clear();
    setState(() {
      _ecoScore = 50;
      _pickedProductImageFiles.clear();
      _pickedPromotionalImageFile = null;
      _selectedCategoryId = null;
      _selectedCategoryName = null;
    });
  }

  void _showSnackBar(
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    showAppSnackBar(context, message, isSuccess: isSuccess, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เพิ่มสินค้าใหม่',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
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
                    _buildSectionCard(
                      title: 'ข้อมูลพื้นฐานสินค้า',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: buildInputDecoration(
                              context,
                              'ชื่อสินค้า*',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกชื่อสินค้า';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _isLoadingCategories
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _categoryDropdownItems.isEmpty
                                  ? const Text(
                                      'ไม่พบหมวดหมู่ (กรุณาติดต่อแอดมินเพื่อเพิ่มหมวดหมู่)',
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
                                      decoration: buildInputDecoration(
                                        context,
                                        'เลือกหมวดหมู่สินค้า*',
                                      ),
                                      hint: const Text('เลือกหมวดหมู่'),
                                      items: _categoryDropdownItems.map((item) {
                                        return DropdownMenuItem<String>(
                                          value: item.category.id,
                                          child: Text(
                                            item.displayName,
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategoryId = value;
                                          _selectedCategoryName = _categories
                                              .firstWhereOrNull(
                                                (cat) => cat.id == value,
                                              )
                                              ?.name;
                                        });
                                      },
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? 'กรุณาเลือกหมวดหมู่'
                                              : null,
                                    ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: buildInputDecoration(
                              context,
                              'รายละเอียดสินค้า*',
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกรายละเอียดสินค้า';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: buildInputDecoration(
                              context,
                              'ราคา (บาท)*',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกราคา';
                              }
                              final price = double.tryParse(value);
                              if (price == null) {
                                return 'กรุณากรอกราคาเป็นตัวเลขที่ถูกต้อง';
                              }
                              if (price <= 0) {
                                return 'ราคาต้องมากกว่า 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: buildInputDecoration(
                              context,
                              'จำนวนสินค้าในสต็อก*',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกจำนวนสินค้าในสต็อก';
                              }
                              final stock = int.tryParse(value);
                              if (stock == null || stock < 0) {
                                return 'กรุณากรอกจำนวนสินค้าที่ถูกต้อง (ตัวเลขไม่ติดลบ)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'รายละเอียดเชิงนิเวศและความยั่งยืน',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _materialController,
                            decoration: buildInputDecoration(
                              context,
                              'วัสดุที่ใช้ (เช่น พลาสติกรีไซเคิล, ฝ้ายออร์แกนิก)*',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกวัสดุที่ใช้';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ecoJustificationController,
                            decoration: buildInputDecoration(
                              context,
                              'เหตุผลที่สินค้านี้เป็นมิตรต่อสิ่งแวดล้อม*',
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาให้เหตุผลความเป็นมิตรต่อสิ่งแวดล้อม';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 🆕 Additional Eco Fields
                          TextFormField(
                            controller: _manufacturingProcessController,
                            decoration: buildInputDecoration(
                              context,
                              'กระบวนการผลิต (ถ้ามี)',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _packagingTypeController,
                            decoration: buildInputDecoration(
                              context,
                              'ประเภทบรรจุภัณฑ์ (ถ้ามี)',
                            ).copyWith(
                              hintText: 'เช่น กระดาษรีไซเคิล, ย่อยสลายได้',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _wasteManagementController,
                            decoration: buildInputDecoration(
                              context,
                              'การจัดการขยะ/รีไซเคิล (ถ้ามี)',
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Eco Score Slider
                          Text(
                            'ระดับ Eco Score (%): $_ecoScore',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _ecoScore.toDouble(),
                            min: 1.0,
                            max: 100.0,
                            divisions: 99,
                            label: _ecoScore.round().toString(),
                            onChanged: (double value) {
                              setState(() {
                                _ecoScore = value.round();
                              });
                            },
                            activeColor: EcoLevelExtension.fromScore(
                              _ecoScore,
                            ).color,
                            inactiveColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ระดับ: ${EcoLevelExtension.fromScore(_ecoScore).name}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: EcoLevelExtension.fromScore(_ecoScore)
                                      .color
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        EcoLevelExtension.fromScore(_ecoScore)
                                            .color,
                                  ),
                                ),
                                child: Text(
                                  EcoLevelExtension.fromScore(_ecoScore).name,
                                  style: TextStyle(
                                    color:
                                        EcoLevelExtension.fromScore(_ecoScore)
                                            .color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 🤖 AI Analysis Button
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.withOpacity(0.1),
                                  Colors.blue.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        color: Colors.purple, size: 28),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'วิเคราะห์ด้วย AI',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ให้ AI ช่วยวิเคราะห์ความเป็น Eco ของสินค้า พร้อมคำแนะนำปรับปรุง',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isAnalyzingWithAI
                                        ? null
                                        : _analyzeWithAI,
                                    icon: _isAnalyzingWithAI
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.psychology),
                                    label: Text(
                                      _isAnalyzingWithAI
                                          ? 'กำลังวิเคราะห์...'
                                          : 'วิเคราะห์ด้วย AI (ฟรี)',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_aiAnalysisResult != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'AI ให้คะแนน: ${_aiAnalysisResult!.aiEcoScore}/100 (${_aiAnalysisResult!.ecoLevel})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'สื่อและการยืนยัน',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _verificationVideoController,
                            decoration: buildInputDecoration(
                              context,
                              'ลิงก์วิดีโอ (ถ้ามี)',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickProductImages,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('เลือกรูปภาพสินค้า (1-7 รูป)'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          if (_pickedProductImageFiles.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: List<Widget>.generate(
                                  _pickedProductImageFiles.length,
                                  (index) {
                                    final file =
                                        _pickedProductImageFiles[index];
                                    return Chip(
                                      avatar: kIsWeb
                                          ? FutureBuilder<Uint8List>(
                                              future: file.readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return CircleAvatar(
                                                    backgroundImage:
                                                        MemoryImage(
                                                      snapshot.data!,
                                                    ),
                                                  );
                                                }
                                                return const CircleAvatar(
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                  ),
                                                );
                                              },
                                            )
                                          : CircleAvatar(
                                              backgroundImage: FileImage(
                                                File(file.path),
                                              ),
                                            ),
                                      label: Text(file.name),
                                      deleteIcon: const Icon(Icons.close),
                                      onDeleted: () =>
                                          _removeProductImage(index),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _pickPromotionalImage,
                            icon: const Icon(Icons.star_outline),
                            label: Text(
                              _pickedPromotionalImageFile == null
                                  ? 'เลือกรูปโปรโมต (1 รูป)'
                                  : 'เปลี่ยนรูปโปรโมต',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          if (_pickedPromotionalImageFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Chip(
                                avatar: kIsWeb
                                    ? FutureBuilder<Uint8List>(
                                        future: _pickedPromotionalImageFile!
                                            .readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return CircleAvatar(
                                              backgroundImage: MemoryImage(
                                                snapshot.data!,
                                              ),
                                            );
                                          }
                                          return const CircleAvatar(
                                            child: Icon(Icons.image_outlined),
                                          );
                                        },
                                      )
                                    : CircleAvatar(
                                        backgroundImage: FileImage(
                                          File(
                                            _pickedPromotionalImageFile!.path,
                                          ),
                                        ),
                                      ),
                                label: Text(
                                  _pickedPromotionalImageFile!.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: _removePromotionalImage,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'รูปภาพสินค้าจะแสดงในหน้ารายละเอียดสินค้า รูปโปรโมตอาจใช้แสดงในหน้าหลักหรือส่วนแนะนำ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addProduct,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3.0,
                                ),
                              )
                            : const Text('ส่งคำขอเพิ่มสินค้า'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            child,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose(); // Dispose stock controller
    _materialController.dispose();
    _ecoJustificationController.dispose();
    _verificationVideoController.dispose();
    _manufacturingProcessController.dispose();
    _packagingTypeController.dispose();
    _wasteManagementController.dispose();
    super.dispose();
  }
}
