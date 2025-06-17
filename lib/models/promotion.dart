// lib/models/promotion.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PromotionType {
  percentageDiscount, // ลดเป็นเปอร์เซ็นต์
  fixedAmountDiscount, // ลดเป็นจำนวนเงินบาท
  freeShipping, // ส่งฟรี
  // Add more types as needed, e.g., buyOneGetOne
}

String promotionTypeToString(PromotionType type) {
  switch (type) {
    case PromotionType.percentageDiscount:
      return 'percentage_discount';
    case PromotionType.fixedAmountDiscount:
      return 'fixed_amount_discount';
    case PromotionType.freeShipping:
      return 'free_shipping';
  }
}

PromotionType promotionTypeFromString(String? typeString) {
  switch (typeString) {
    case 'percentage_discount':
      return PromotionType.percentageDiscount;
    case 'fixed_amount_discount':
      return PromotionType.fixedAmountDiscount;
    case 'free_shipping':
      return PromotionType.freeShipping;
    default:
      return PromotionType.percentageDiscount; // Default or handle error
  }
}

class Promotion {
  final String id;
  final String code; // โค้ดโปรโมชันที่ผู้ใช้กรอก
  final String description;
  final PromotionType type;
  final double value; // ค่าของส่วนลด (เช่น 10 สำหรับ 10% หรือ 50 สำหรับ 50 บาท)
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int usageLimit; // จำกัดจำนวนครั้งที่ใช้ได้ทั้งหมด
  final int usedCount; // จำนวนครั้งที่ถูกใช้ไปแล้ว
  // TODO: Add more fields like minSpend, applicableProducts/Categories, etc.

  Promotion({
    required this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.usageLimit = 0, // 0 means unlimited
    this.usedCount = 0,
  });

  factory Promotion.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Promotion(
      id: doc.id,
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      type: promotionTypeFromString(data['type'] as String?),
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      isActive: data['isActive'] as bool? ?? true,
      usageLimit: (data['usageLimit'] as num?)?.toInt() ?? 0,
      usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'description': description,
      'type': promotionTypeToString(type),
      'value': value,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      // 'createdAt': FieldValue.serverTimestamp(), // if adding new
    };
  }
}
