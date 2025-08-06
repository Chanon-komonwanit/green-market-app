// lib/models/user_coupon.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_market/models/shop_customization.dart';

enum CouponStatus {
  available, // ใช้ได้
  used, // ใช้แล้ว
  expired, // หมดอายุ
  disabled, // ปิดใช้งาน
}

class UserCoupon {
  final String id;
  final String userId;
  final String promotionId;
  final ShopPromotion promotion;
  final DateTime collectedAt;
  final DateTime? usedAt;
  final String? orderId; // รหัสคำสั่งซื้อที่ใช้
  final CouponStatus status;
  final DateTime? notificationSentAt;
  final bool isNotificationRead;

  UserCoupon({
    required this.id,
    required this.userId,
    required this.promotionId,
    required this.promotion,
    required this.collectedAt,
    this.usedAt,
    this.orderId,
    this.status = CouponStatus.available,
    this.notificationSentAt,
    this.isNotificationRead = false,
  });

  factory UserCoupon.fromMap(
      Map<String, dynamic> map, ShopPromotion promotion) {
    return UserCoupon(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      promotionId: map['promotionId'] ?? '',
      promotion: promotion,
      collectedAt: map['collectedAt']?.toDate() ?? DateTime.now(),
      usedAt: map['usedAt']?.toDate(),
      orderId: map['orderId'],
      status: CouponStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => CouponStatus.available,
      ),
      notificationSentAt: map['notificationSentAt']?.toDate(),
      isNotificationRead: map['isNotificationRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'promotionId': promotionId,
      'collectedAt': Timestamp.fromDate(collectedAt),
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'orderId': orderId,
      'status': status.toString().split('.').last,
      'notificationSentAt': notificationSentAt != null
          ? Timestamp.fromDate(notificationSentAt!)
          : null,
      'isNotificationRead': isNotificationRead,
    };
  }

  // ตรวจสอบว่าโค้ดใช้ได้หรือไม่
  bool get isUsable {
    if (status != CouponStatus.available) return false;
    if (!promotion.isValid) return false;
    if (!promotion.isTimeValid) return false;
    return true;
  }

  // วันหมดอายุ
  DateTime? get expiryDate => promotion.endDate;

  // วันที่จะหมดอายุ
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // สถานะสีแสดงผล
  Color get statusColor {
    switch (status) {
      case CouponStatus.available:
        return const Color(0xFF4CAF50); // เขียว
      case CouponStatus.used:
        return const Color(0xFF757575); // เทา
      case CouponStatus.expired:
        return const Color(0xFFFF5722); // แดง
      case CouponStatus.disabled:
        return const Color(0xFF9E9E9E); // เทาอ่อน
    }
  }

  // ข้อความสถานะ
  String get statusText {
    switch (status) {
      case CouponStatus.available:
        if (daysUntilExpiry != null && daysUntilExpiry! <= 3) {
          return 'หมดอายุใน $daysUntilExpiry วัน';
        }
        return 'ใช้ได้';
      case CouponStatus.used:
        return 'ใช้แล้ว';
      case CouponStatus.expired:
        return 'หมดอายุ';
      case CouponStatus.disabled:
        return 'ปิดใช้งาน';
    }
  }

  // สำเนาโค้ดพร้อมสถานะใหม่
  UserCoupon copyWith({
    String? id,
    String? userId,
    String? promotionId,
    ShopPromotion? promotion,
    DateTime? collectedAt,
    DateTime? usedAt,
    String? orderId,
    CouponStatus? status,
    DateTime? notificationSentAt,
    bool? isNotificationRead,
  }) {
    return UserCoupon(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      promotionId: promotionId ?? this.promotionId,
      promotion: promotion ?? this.promotion,
      collectedAt: collectedAt ?? this.collectedAt,
      usedAt: usedAt ?? this.usedAt,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      notificationSentAt: notificationSentAt ?? this.notificationSentAt,
      isNotificationRead: isNotificationRead ?? this.isNotificationRead,
    );
  }
}

// การคำนวณส่วนลด
class DiscountCalculation {
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final UserCoupon coupon;
  final String calculationDetails;

  DiscountCalculation({
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.coupon,
    required this.calculationDetails,
  });

  double get discountPercentage =>
      originalAmount > 0 ? (discountAmount / originalAmount) * 100 : 0;

  bool get hasDiscount => discountAmount > 0;
}
