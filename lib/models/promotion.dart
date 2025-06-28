// D:/Development/green_market/lib/models/promotion.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Promotion {
  final String id;
  final String title;
  final String code;
  final String discountType; // 'percentage' or 'fixed_amount'
  final double discountValue;
  final String description;
  final String image; // URL รูปภาพโปรโมชั่น
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  // --- Fields added based on TODO ---
  final double? minSpend; // ยอดใช้จ่ายขั้นต่ำ
  final List<String>? applicableProductIds; // ID สินค้าที่ร่วมรายการ
  final List<String>? applicableCategoryIds; // ID หมวดหมู่ที่ร่วมรายการ
  final int? usageLimit; // จำนวนครั้งที่ใช้ได้ทั้งหมด
  final int? usageLimitPerUser; // จำนวนครั้งที่ใช้ได้ต่อผู้ใช้หนึ่งคน

  Promotion({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.image,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.minSpend,
    this.applicableProductIds,
    this.applicableCategoryIds,
    this.usageLimit,
    this.usageLimitPerUser,
  });

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      code: map['code'] as String? ?? '',
      description: map['description'] as String? ?? '',
      image: map['image'] as String? ?? '',
      discountType: map['discountType'] as String,
      discountValue: (map['discountValue'] as num).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
      minSpend: (map['minSpend'] as num?)?.toDouble(),
      applicableProductIds: map['applicableProductIds'] != null
          ? List<String>.from(map['applicableProductIds'])
          : null,
      applicableCategoryIds: map['applicableCategoryIds'] != null
          ? List<String>.from(map['applicableCategoryIds'])
          : null,
      usageLimit: map['usageLimit'] as int?,
      usageLimitPerUser: map['usageLimitPerUser'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'description': description,
      'image': image,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'minSpend': minSpend,
      'applicableProductIds': applicableProductIds,
      'applicableCategoryIds': applicableCategoryIds,
      'usageLimit': usageLimit,
      'usageLimitPerUser': usageLimitPerUser,
    };
  }

  Promotion copyWith({
    String? id,
    String? title,
    String? code,
    String? description,
    String? image,
    String? discountType,
    double? discountValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    double? minSpend,
    List<String>? applicableProductIds,
    List<String>? applicableCategoryIds,
    int? usageLimit,
    int? usageLimitPerUser,
  }) {
    return Promotion(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      description: description ?? this.description,
      image: image ?? this.image,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      minSpend: minSpend ?? this.minSpend,
      applicableProductIds: applicableProductIds ?? this.applicableProductIds,
      applicableCategoryIds:
          applicableCategoryIds ?? this.applicableCategoryIds,
      usageLimit: usageLimit ?? this.usageLimit,
      usageLimitPerUser: usageLimitPerUser ?? this.usageLimitPerUser,
    );
  }

  // Getter สำหรับ backward compatibility
  String get imageUrl => image;
}
