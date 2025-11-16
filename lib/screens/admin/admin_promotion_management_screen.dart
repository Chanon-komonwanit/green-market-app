// lib/screens/admin/admin_promotion_management_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/unified_promotion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminPromotionManagementScreen extends StatelessWidget {
  const AdminPromotionManagementScreen(
      {super.key}); // Changed to StatelessWidget
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการโปรโมชั่น',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<UnifiedPromotion>>(
        stream: firebaseService.getPromotions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีโปรโมชั่น'));
          }

          final promotions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promotion = promotions[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10)), // Corrected: Already correct
                child: ListTile(
                  // Corrected: Already correct // Corrected: Use withAlpha
                  leading: CircleAvatar(
                    // Corrected: Use withAlpha // Corrected: Already correct // Corrected: Already correct // Corrected: Already correct // Corrected: Already correct // Corrected: Use withAlpha
                    backgroundColor: theme.colorScheme
                        .secondary // Corrected: Use withAlpha // Corrected: Already correct // Corrected: Already correct // Corrected: Already correct // Corrected: Already correct
                        .withAlpha((0.1 * 255).round()), // Use withAlpha
                    child: Icon(Icons.local_offer,
                        color: theme.colorScheme.secondary),
                  ),
                  title: Text(promotion.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('รหัส: ${promotion.discountCode ?? "ไม่มี"}'),
                      Text(
                          'ส่วนลด: ${promotion.discountPercent != null ? '${promotion.discountPercent}%' : promotion.discountAmount != null ? '${promotion.discountAmount} บาท' : 'ไม่กำหนด'}'),
                      Text(
                          'เริ่ม: ${promotion.startDate != null ? DateFormat('dd MMM yyyy').format(promotion.startDate!) : "ไม่กำหนด"}'),
                      Text(
                          'สิ้นสุด: ${promotion.endDate != null ? DateFormat('dd MMM yyyy').format(promotion.endDate!) : "ไม่กำหนด"}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () =>
                            _showPromotionDialog(context, promotion: promotion),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outlined,
                            color: Colors.red),
                        onPressed: () => _deletePromotion(
                            context, firebaseService, promotion.id),
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
        onPressed: () => _showPromotionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deletePromotion(BuildContext context, FirebaseService firebaseService,
      String promoId) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบโปรโมชั่นนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Assuming you add a deletePromotion method to FirebaseService
                await firebaseService
                    .deletePromotion(promoId); // Actual deletion
                showAppSnackBar(context, 'ลบโปรโมชั่นสำเร็จ', isSuccess: true);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                    isError: true);
              }
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _showPromotionDialog(BuildContext context,
      {UnifiedPromotion? promotion}) {
    // Corrected: Already correct
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: promotion?.title ?? '');
    final codeController =
        TextEditingController(text: promotion?.discountCode ?? '');
    final descriptionController =
        TextEditingController(text: promotion?.description ?? '');
    String? selectedDiscountType = promotion?.discountPercent != null
        ? 'percentage'
        : promotion?.discountAmount != null
            ? 'fixed'
            : null;
    final discountController = TextEditingController(
        text: (promotion?.discountPercent ?? promotion?.discountAmount ?? '')
            .toString());
    String selectedImageUrl = promotion?.imageUrl ?? '';

    // For dates, you'd typically use a date picker and store DateTime objects
    // For simplicity, we'll just show text fields here.
    final startDateController = TextEditingController(
        text: promotion?.startDate != null
            ? DateFormat('yyyy-MM-dd').format(promotion!.startDate!)
            : '');
    final endDateController = TextEditingController(
        text: promotion?.endDate != null
            ? DateFormat('yyyy-MM-dd').format(promotion!.endDate!)
            : '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                  promotion == null ? 'เพิ่มโปรโมชั่นใหม่' : 'แก้ไขโปรโมชั่น'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                          controller: titleController,
                          decoration:
                              buildInputDecoration(context, 'ชื่อโปรโมชั่น'),
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณากรอกชื่อ' : null),
                      const SizedBox(height: 10),

                      // Image selection section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'รูปภาพโปรโมชั่น',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (selectedImageUrl.isNotEmpty)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      selectedImageUrl,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.all(4),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedImageUrl = '';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  // สำหรับ demo ให้ใช้ placeholder image
                                  setState(() {
                                    selectedImageUrl =
                                        'https://via.placeholder.com/400x200/4CAF50/FFFFFF?text=Promotion+Image';
                                  });
                                },
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.grey[300]!,
                                        style: BorderStyle.solid),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate,
                                          size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('แตะเพื่อเลือกรูปภาพ',
                                          style: TextStyle(color: Colors.grey)),
                                      Text('(Demo: จะใช้รูป placeholder)',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: descriptionController,
                          decoration: buildInputDecoration(
                              context, 'คำอธิบายโปรโมชั่น'),
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedDiscountType,
                        decoration:
                            buildInputDecoration(context, 'ประเภทส่วนลด'),
                        items: const [
                          DropdownMenuItem(
                              value: 'percentage', child: Text('เปอร์เซ็นต์')),
                          DropdownMenuItem(
                              value: 'fixed_amount',
                              child: Text('จำนวนเงินคงที่')),
                        ],
                        onChanged: (value) {
                          selectedDiscountType = value;
                        },
                        validator: (v) =>
                            v == null ? 'กรุณาเลือกประเภทส่วนลด' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: codeController,
                          decoration:
                              buildInputDecoration(context, 'รหัสโปรโมชั่น'),
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณากรอกรหัส' : null),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: discountController,
                          decoration: buildInputDecoration(context, 'ส่วนลด'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.isEmpty || double.tryParse(v) == null
                                  ? 'กรุณากรอกส่วนลดที่ถูกต้อง'
                                  : null),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: startDateController,
                          decoration: buildInputDecoration(
                              context, 'วันที่เริ่มต้น (YYYY-MM-DD)'),
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณากรอกวันที่เริ่มต้น' : null),
                      const SizedBox(height: 10),
                      TextFormField(
                          // Consider using a date picker for better UX
                          controller: endDateController,
                          decoration: buildInputDecoration(
                              context, 'วันที่สิ้นสุด (YYYY-MM-DD)'),
                          validator: (v) =>
                              v!.isEmpty ? 'กรุณากรอกวันที่สิ้นสุด' : null),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('ยกเลิก')),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final firebaseService =
                        Provider.of<FirebaseService>(context, listen: false);
                    try {
                      final newPromo = UnifiedPromotion(
                        id: promotion?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        sellerId: 'admin', // ระบุว่าโปรนี้สร้างโดยแอดมิน
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        type: PromotionType.percentage, // Default type
                        category: PromotionCategory.general,
                        discountCode: codeController.text.trim(),
                        discountPercent: selectedDiscountType == 'percentage'
                            ? double.parse(discountController.text.trim())
                            : null,
                        discountAmount: selectedDiscountType == 'fixed'
                            ? double.parse(discountController.text.trim())
                            : null,
                        imageUrl: selectedImageUrl,
                        startDate: DateFormat('yyyy-MM-dd')
                            .parse(startDateController.text.trim()),
                        endDate: DateFormat('yyyy-MM-dd')
                            .parse(endDateController.text.trim()),
                        createdAt: promotion?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                        isActive: true, // Default to active
                      );
                      if (promotion == null) {
                        await firebaseService.addPromotion(newPromo);
                        showAppSnackBar(context, 'เพิ่มโปรโมชั่นสำเร็จ',
                            isSuccess: true);
                      } else {
                        await firebaseService.updatePromotion(newPromo);
                        showAppSnackBar(context, 'แก้ไขโปรโมชั่นสำเร็จ',
                            isSuccess: true);
                      }
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (e) {
                      showAppSnackBar(
                          context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                          isError: true);
                    }
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
