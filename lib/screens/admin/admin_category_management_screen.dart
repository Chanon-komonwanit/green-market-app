// lib/screens/admin/admin_category_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:green_market/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:provider/provider.dart';
import 'dart:io';

class AdminCategoryManagementScreen extends StatefulWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  State<AdminCategoryManagementScreen> createState() =>
      _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState
    extends State<AdminCategoryManagementScreen> {
  final TextEditingController _categoryNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Category? _editingCategory;

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  void _showCategoryDialog({Category? category}) {
    _editingCategory = category;
    _categoryNameController.text = category?.name ?? '';

    XFile? pickedImageFile;
    bool isLoadingDialog = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                  category == null ? 'เพิ่มหมวดหมู่ใหม่' : 'แก้ไขหมวดหมู่'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _categoryNameController,
                      decoration: buildInputDecoration(context, 'ชื่อหมวดหมู่'),
                      autofocus: true,
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
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.modernGrey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: pickedImageFile != null
                            ? (kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: pickedImageFile!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    },
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.file(
                                      File(pickedImageFile!.path),
                                      fit: BoxFit.cover,
                                    ),
                                  ))
                            : (category?.imageUrl != null &&
                                    category!.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      category.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                  Icons
                                                      .add_photo_alternate_outlined,
                                                  size: 40,
                                                  color: AppColors.modernGrey),
                                              SizedBox(height: 8),
                                              Text('แตะเพื่อเลือกรูปภาพ',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .modernGrey)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            size: 40,
                                            color: AppColors.modernGrey),
                                        SizedBox(height: 8),
                                        Text('แตะเพื่อเลือกรูปภาพ',
                                            style: TextStyle(
                                                color: AppColors.modernGrey)),
                                      ],
                                    ),
                                  )),
                      ),
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
                  onPressed: isLoadingDialog
                      ? null
                      : () async {
                          if (_categoryNameController.text.trim().isEmpty) {
                            showAppSnackBar(context, 'กรุณากรอกชื่อหมวดหมู่',
                                isError: true);
                            return;
                          }

                          setDialogState(() {
                            isLoadingDialog = true;
                          });

                          final firebaseService = Provider.of<FirebaseService>(
                              context,
                              listen: false);
                          try {
                            String imageUrl = category?.imageUrl ?? '';

                            // Upload new image if selected
                            if (pickedImageFile != null) {
                              String fileName =
                                  'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
                              if (kIsWeb) {
                                final bytes =
                                    await pickedImageFile!.readAsBytes();
                                imageUrl =
                                    await firebaseService.uploadImageBytes(
                                  'category_images',
                                  fileName,
                                  bytes,
                                );
                              } else {
                                imageUrl = await firebaseService.uploadImage(
                                  'category_images',
                                  pickedImageFile!.path,
                                  fileName: fileName,
                                );
                              }
                            }

                            if (_editingCategory == null) {
                              // Add new category
                              final newCategory = Category(
                                id: firebaseService
                                    .generateNewDocId('categories'),
                                name: _categoryNameController.text.trim(),
                                imageUrl: imageUrl,
                                createdAt: Timestamp.now(),
                              );
                              await firebaseService.addCategory(newCategory);
                              showAppSnackBar(context, 'เพิ่มหมวดหมู่สำเร็จ',
                                  isSuccess: true);
                            } else {
                              // Update existing category
                              final updatedCategory =
                                  _editingCategory!.copyWith(
                                name: _categoryNameController.text.trim(),
                                imageUrl: imageUrl,
                              );
                              await firebaseService
                                  .updateCategory(updatedCategory);
                              showAppSnackBar(context, 'แก้ไขหมวดหมู่สำเร็จ',
                                  isSuccess: true);
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            showAppSnackBar(
                                context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                                isError: true);
                          } finally {
                            setDialogState(() {
                              isLoadingDialog = false;
                            });
                          }
                        },
                  child: isLoadingDialog
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCategory(String categoryId) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('ยืนยันการลบ'),
            content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบหมวดหมู่นี้?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('ลบ'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await firebaseService.deleteCategory(categoryId);
        showAppSnackBar(context, 'ลบหมวดหมู่สำเร็จ', isSuccess: true);
      } catch (e) {
        showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการหมวดหมู่',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<Category>>(
        stream: firebaseService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีหมวดหมู่ในระบบ'));
          }

          final categories = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(category.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () =>
                            _showCategoryDialog(category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outlined,
                            color: Colors.red),
                        onPressed: () => _deleteCategory(category.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
