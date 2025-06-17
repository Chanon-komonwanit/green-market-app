// lib/screens/category_management_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart' as app_category;
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // For File
import 'package:flutter/foundation.dart' show kIsWeb; // For kIsWeb
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showCategoryDialog(
      {app_category.Category? categoryToEdit}) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final formKeyDialog = GlobalKey<FormState>();
    TextEditingController nameController =
        TextEditingController(text: categoryToEdit?.name ?? '');
    XFile? pickedImageFile;
    String? existingImageUrl = categoryToEdit?.imageUrl;
    bool isLoadingDialog = false;

    await showDialog(
      context: context,
      barrierDismissible: !isLoadingDialog,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
                categoryToEdit == null ? 'เพิ่มหมวดหมู่ใหม่' : 'แก้ไขหมวดหมู่',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.primaryTeal)),
            content: SingleChildScrollView(
              child: Form(
                key: formKeyDialog,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อหมวดหมู่',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกชื่อหมวดหมู่';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('รูปภาพหมวดหมู่:', style: AppTextStyles.body),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: isLoadingDialog
                          ? null
                          : () async {
                              final XFile? image = await _picker.pickImage(
                                  source: ImageSource.gallery);
                              if (image != null) {
                                setDialogState(() {
                                  pickedImageFile = image;
                                });
                              }
                            },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.lightModernGrey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: pickedImageFile != null
                            ? (kIsWeb
                                ? Image.network(pickedImageFile!.path,
                                    fit: BoxFit.contain)
                                : Image.file(File(pickedImageFile!.path),
                                    fit: BoxFit.contain))
                            : (existingImageUrl != null &&
                                    existingImageUrl.isNotEmpty
                                ? Image.network(existingImageUrl,
                                    fit: BoxFit.contain)
                                : const Center(
                                    child: Icon(Icons.add_a_photo_outlined,
                                        size: 50,
                                        color: AppColors.modernGrey))),
                      ),
                    ),
                    if (pickedImageFile == null && categoryToEdit == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('กรุณาเลือกรูปภาพ',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.errorRed)),
                      )
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              if (isLoadingDialog)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child:
                      CircularProgressIndicator(color: AppColors.primaryTeal),
                )
              else ...[
                TextButton(
                  child: Text('ยกเลิก',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.modernGrey)),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
                  child: Text(categoryToEdit == null ? 'เพิ่ม' : 'บันทึก',
                      style: AppTextStyles.bodyBold
                          .copyWith(color: AppColors.white)),
                  onPressed: () async {
                    if (formKeyDialog.currentState!.validate()) {
                      if (pickedImageFile == null && categoryToEdit == null) {
                        // Ensure image is picked for new category
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'กรุณาเลือกรูปภาพสำหรับหมวดหมู่ใหม่')));
                        return;
                      }
                      setDialogState(() => isLoadingDialog = true);
                      String? imageUrl = existingImageUrl;
                      if (pickedImageFile != null) {
                        var uuid = const Uuid();
                        String extension =
                            pickedImageFile!.name.split('.').last;
                        String fileName = '${uuid.v4()}.$extension';
                        try {
                          if (kIsWeb) {
                            final bytes = await pickedImageFile!.readAsBytes();
                            imageUrl = await firebaseService.uploadWebImage(
                                'category_images', fileName, bytes);
                          } else {
                            imageUrl = await firebaseService.uploadImage(
                                'category_images', pickedImageFile!.path,
                                fileName: fileName);
                          }
                          // If editing and new image uploaded, delete old one
                          if (categoryToEdit != null &&
                              categoryToEdit.imageUrl.isNotEmpty &&
                              categoryToEdit.imageUrl != imageUrl) {
                            await firebaseService
                                .deleteImageByUrl(categoryToEdit.imageUrl);
                          }
                        } catch (e) {
                          setDialogState(() => isLoadingDialog = false);
                          if (mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                    content: Text('อัปโหลดรูปภาพล้มเหลว: $e')));
                          }
                          return;
                        }
                      }

                      final categoryData = app_category.Category(
                        id: categoryToEdit?.id ??
                            '', // Firestore will generate ID if empty
                        name: nameController.text,
                        imageUrl: imageUrl ?? '',
                        createdAt: categoryToEdit?.createdAt ??
                            Timestamp.now(), // Keep original or set new
                      );

                      try {
                        if (categoryToEdit == null) {
                          await firebaseService.addCategory(categoryData);
                        } else {
                          await firebaseService.updateCategory(categoryData);
                        }
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
                        }
                      } finally {
                        setDialogState(() => isLoadingDialog = false);
                      }
                    }
                  },
                ),
              ]
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการหมวดหมู่สินค้า',
            style: AppTextStyles.title.copyWith(color: AppColors.primaryTeal)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryTeal),
      ),
      body: StreamBuilder<List<app_category.Category>>(
        stream: firebaseService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: AppTextStyles.body));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('ยังไม่มีหมวดหมู่สินค้า',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.modernGrey)));
          }
          final categories = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                elevation: 1.5,
                child: ListTile(
                  leading: category.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.network(
                            category.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    size: 50, color: AppColors.modernGrey),
                          ),
                        )
                      : const Icon(Icons.category_outlined,
                          size: 40, color: AppColors.modernGrey),
                  title: Text(category.name,
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.primaryDarkGreen)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primaryTeal),
                        onPressed: () =>
                            _showCategoryDialog(categoryToEdit: category),
                        tooltip: 'แก้ไข',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.errorRed),
                        onPressed: () async {
                          final confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) =>
                                AlertDialog(
                              title: const Text('ยืนยันการลบ'),
                              content: Text(
                                  'คุณต้องการลบหมวดหมู่ "${category.name}" ใช่หรือไม่? สินค้าในหมวดนี้จะไม่ถูกลบ แต่จะไม่แสดงหมวดหมู่นี้อีกต่อไป'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('ยกเลิก'),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.errorRed),
                                  child: const Text('ยืนยันลบ'),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                ),
                              ],
                            ),
                          );
                          if (confirmDelete == true) {
                            try {
                              // Optionally delete the image from storage
                              if (category.imageUrl.isNotEmpty) {
                                await firebaseService
                                    .deleteImageByUrl(category.imageUrl);
                              }
                              await firebaseService.deleteCategory(category.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'ลบหมวดหมู่ "${category.name}" สำเร็จแล้ว'),
                                      backgroundColor: AppColors.successGreen),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'เกิดข้อผิดพลาดในการลบหมวดหมู่: $e'),
                                      backgroundColor: AppColors.errorRed),
                                );
                              }
                            }
                          }
                        },
                        tooltip: 'ลบ',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        label: Text('เพิ่มหมวดหมู่',
            style: AppTextStyles.button.copyWith(color: AppColors.white)),
        icon: const Icon(Icons.add, color: AppColors.white),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }
}
