// D:/Development/green_market/lib/models/promotion.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Promotion {
  final String id;
  final String sellerId;
  final String title;
  final String code;
  final String discountType; // 'percentage' or 'fixed_amount'
  final double discountValue;
  final String description;
  final String image; // URL รูปภาพโปรโมชั่น
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  // --- Shopee-like & Coupon fields ---
  final String? bannerText; // ข้อความแบนเนอร์พิเศษ
  final bool isFeatured; // โปรโมชั่นเด่น
  final double? minSpend; // ยอดใช้จ่ายขั้นต่ำ
  final List<String>? applicableProductIds; // ID สินค้าที่ร่วมรายการ
  final List<String>? applicableCategoryIds; // ID หมวดหมู่ที่ร่วมรายการ
  final int? usageLimit; // จำนวนครั้งที่ใช้ได้ทั้งหมด
  final int? usageLimitPerUser; // จำนวนครั้งที่ใช้ได้ต่อผู้ใช้หนึ่งคน
  final bool isFlashSale; // เป็น Flash Sale หรือไม่
  final DateTime? flashSaleEnd; // เวลาสิ้นสุด Flash Sale
  final int? couponQuantity; // จำนวนคูปองที่แจก
  final int? couponUsed; // จำนวนคูปองที่ถูกใช้ไปแล้ว
  final String? couponCondition; // เงื่อนไขการใช้คูปอง
  final String?
      stockStatus; // สถานะคงเหลือสินค้า (เช่น 'in_stock', 'out_of_stock')

  Promotion({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.code,
    required this.description,
    required this.image,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.bannerText,
    this.isFeatured = false,
    this.minSpend,
    this.applicableProductIds,
    this.applicableCategoryIds,
    this.usageLimit,
    this.usageLimitPerUser,
    this.isFlashSale = false,
    this.flashSaleEnd,
    this.couponQuantity,
    this.couponUsed,
    this.couponCondition,
    this.stockStatus,
  });

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'] as String,
      sellerId: map['sellerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      code: map['code'] as String? ?? '',
      description: map['description'] as String? ?? '',
      image: map['image'] as String? ?? '',
      discountType: map['discountType'] as String,
      discountValue: (map['discountValue'] as num).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
      bannerText: map['bannerText'] as String?,
      isFeatured: map['isFeatured'] as bool? ?? false,
      minSpend: (map['minSpend'] as num?)?.toDouble(),
      applicableProductIds: map['applicableProductIds'] != null
          ? List<String>.from(map['applicableProductIds'])
          : null,
      applicableCategoryIds: map['applicableCategoryIds'] != null
          ? List<String>.from(map['applicableCategoryIds'])
          : null,
      usageLimit: map['usageLimit'] as int?,
      usageLimitPerUser: map['usageLimitPerUser'] as int?,
      isFlashSale: map['isFlashSale'] as bool? ?? false,
      flashSaleEnd: map['flashSaleEnd'] != null
          ? (map['flashSaleEnd'] as Timestamp).toDate()
          : null,
      couponQuantity: map['couponQuantity'] as int?,
      couponUsed: map['couponUsed'] as int?,
      couponCondition: map['couponCondition'] as String?,
      stockStatus: map['stockStatus'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'code': code,
      'description': description,
      'image': image,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'bannerText': bannerText,
      'isFeatured': isFeatured,
      'minSpend': minSpend,
      'applicableProductIds': applicableProductIds,
      'applicableCategoryIds': applicableCategoryIds,
      'usageLimit': usageLimit,
      'usageLimitPerUser': usageLimitPerUser,
      'isFlashSale': isFlashSale,
      'flashSaleEnd':
          flashSaleEnd != null ? Timestamp.fromDate(flashSaleEnd!) : null,
      'couponQuantity': couponQuantity,
      'couponUsed': couponUsed,
      'couponCondition': couponCondition,
      'stockStatus': stockStatus,
    };
  }

  Promotion copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? code,
    String? description,
    String? image,
    String? discountType,
    double? discountValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? bannerText,
    bool? isFeatured,
    double? minSpend,
    List<String>? applicableProductIds,
    List<String>? applicableCategoryIds,
    int? usageLimit,
    int? usageLimitPerUser,
    bool? isFlashSale,
    DateTime? flashSaleEnd,
    int? couponQuantity,
    int? couponUsed,
    String? couponCondition,
    String? stockStatus,
  }) {
    return Promotion(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      code: code ?? this.code,
      description: description ?? this.description,
      image: image ?? this.image,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      bannerText: bannerText ?? this.bannerText,
      isFeatured: isFeatured ?? this.isFeatured,
      minSpend: minSpend ?? this.minSpend,
      applicableProductIds: applicableProductIds ?? this.applicableProductIds,
      applicableCategoryIds:
          applicableCategoryIds ?? this.applicableCategoryIds,
      usageLimit: usageLimit ?? this.usageLimit,
      usageLimitPerUser: usageLimitPerUser ?? this.usageLimitPerUser,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      flashSaleEnd: flashSaleEnd ?? this.flashSaleEnd,
      couponQuantity: couponQuantity ?? this.couponQuantity,
      couponUsed: couponUsed ?? this.couponUsed,
      couponCondition: couponCondition ?? this.couponCondition,
      stockStatus: stockStatus ?? this.stockStatus,
    );
  }

  // Getter สำหรับ backward compatibility
  String get imageUrl => image;

  static Promotion mock() {
    return Promotion(
      id: 'mock-promo',
      sellerId: 'mock-seller',
      title: 'โปรโมชันพิเศษ',
      code: 'MOCK20',
      description: 'ลดราคาสินค้าทุกชิ้น 20%',
      image: 'https://via.placeholder.com/100',
      discountType: 'percentage',
      discountValue: 20,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 7)),
      bannerText: 'Flash Sale!',
      isFeatured: true,
      isFlashSale: true,
      flashSaleEnd: DateTime.now().add(const Duration(hours: 12)),
      couponQuantity: 100,
      couponUsed: 10,
      couponCondition: 'ใช้ได้เมื่อซื้อครบ 500 บาท',
      stockStatus: 'in_stock',
    );
  }
}
