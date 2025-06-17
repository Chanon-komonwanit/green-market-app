// lib/screens/admin/promotion_management_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/promotion.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  State<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen> {
  void _addOrEditPromotionDialog({Promotion? promotion}) {
    // TODO: Implement dialog for adding/editing promotions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'TODO: ${promotion == null ? "Add" : "Edit"} Promotion Dialog')),
    );
  }

  String _getPromotionTypeDisplay(PromotionType type) {
    switch (type) {
      case PromotionType.percentageDiscount:
        return 'ส่วนลด %';
      case PromotionType.fixedAmountDiscount:
        return 'ส่วนลด (บาท)';
      case PromotionType.freeShipping:
        return 'ส่งฟรี';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final DateFormat dateFormat = DateFormat('dd MMM yyyy', 'th');

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการโปรโมชัน/ส่วนลด',
            style: AppTextStyles.title.copyWith(color: AppColors.primaryTeal)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryTeal),
      ),
      body: StreamBuilder<List<Promotion>>(
        stream: firebaseService.getPromotions(),
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
                child: Text('ยังไม่มีโปรโมชันในระบบ',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.modernGrey)));
          }

          final promotions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                elevation: 1.5,
                child: ListTile(
                  leading: Icon(
                      promo.type == PromotionType.freeShipping
                          ? Icons.local_shipping_outlined
                          : Icons.sell_outlined,
                      color: promo.isActive
                          ? AppColors.primaryTeal
                          : AppColors.modernGrey),
                  title: Text(promo.code,
                      style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.primaryDarkGreen,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${promo.description}\nประเภท: ${_getPromotionTypeDisplay(promo.type)}\nมูลค่า: ${promo.value}${promo.type == PromotionType.percentageDiscount ? "%" : " บาท"}\nใช้ได้ถึง: ${dateFormat.format(promo.endDate)}\nสถานะ: ${promo.isActive ? "ใช้งาน" : "ไม่ใช้งาน"}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.modernGrey)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.modernDarkGrey),
                    onPressed: () =>
                        _addOrEditPromotionDialog(promotion: promo),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditPromotionDialog(),
        label: Text('เพิ่มโปรโมชัน',
            style: AppTextStyles.button.copyWith(color: AppColors.white)),
        icon: const Icon(Icons.add, color: AppColors.white),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }
}
