// lib/models/unified_promotion.dart
// Unified Promotion Model - รวมระบบโปรโมชั่นทั้งหมดให้เป็นหนึ่งเดียว
// แทนที่ promotion.dart และ ShopPromotion ใน shop_customization.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Unified Promotion Model สำหรับ Green Market
/// รองรับโปรโมชั่นหลากหลายรูปแบบ Flash Sale, Coupon, Buy X Get Y
class UnifiedPromotion {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String? imageUrl;
  final String? discountCode;
  final PromotionType type;
  final PromotionCategory category;

  // ส่วนลด
  final double? discountPercent;
  final double? discountAmount;
  final double? minimumPurchase;
  final double? maximumDiscount;

  // Buy X Get Y
  final int? buyQuantity;
  final int? getQuantity;

  // Flash Sale
  final double? originalPrice;
  final double? flashSalePrice;
  final int? flashSaleStock;
  final int flashSaleSold;

  // กรองสินค้า
  final List<String>? applicableProductIds;
  final List<String>? applicableCategoryIds;
  final List<String>? excludedProductIds;

  // การใช้งาน
  final int? usageLimit;
  final int? usageLimitPerUser;
  final int? maxUsagePerDay;
  final int usedCount;

  // วันเวลา
  final DateTime? startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  // สถานะ
  final bool isActive;
  final bool isPublic;
  final bool isFeatured;
  final bool isFlashSale;
  final bool requiresApproval;
  final bool showInPublicList;
  final bool allowStacking;

  // การแสดงผล
  final String? bannerText;
  final String? iconEmoji;
  final String? backgroundColor;
  final Priority priority;

  // ระบบติดตาม
  final String? trackingCode;
  final String? campaignName;
  final String? targetAudience;
  final String? terms;
  final Map<String, dynamic>? metadata;

  // ข้อมูลระบบ
  final DateTime createdAt;
  final DateTime? updatedAt;

  UnifiedPromotion({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.type,
    this.category = PromotionCategory.general,
    this.imageUrl,
    this.discountCode,
    this.discountPercent,
    this.discountAmount,
    this.minimumPurchase,
    this.maximumDiscount,
    this.buyQuantity,
    this.getQuantity,
    this.originalPrice,
    this.flashSalePrice,
    this.flashSaleStock,
    this.flashSaleSold = 0,
    this.applicableProductIds,
    this.applicableCategoryIds,
    this.excludedProductIds,
    this.usageLimit,
    this.usageLimitPerUser,
    this.maxUsagePerDay,
    this.usedCount = 0,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isActive = true,
    this.isPublic = true,
    this.isFeatured = false,
    this.isFlashSale = false,
    this.requiresApproval = false,
    this.showInPublicList = true,
    this.allowStacking = false,
    this.bannerText,
    this.iconEmoji,
    this.backgroundColor,
    this.priority = Priority.normal,
    this.trackingCode,
    this.campaignName,
    this.targetAudience,
    this.terms,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor from Firestore document
  factory UnifiedPromotion.fromFirestore(DocumentSnapshot doc) {
    return UnifiedPromotion.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Factory constructor from Map with document ID
  factory UnifiedPromotion.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UnifiedPromotion(
      id: docId ?? map['id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: PromotionType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? 'percentage'),
        orElse: () => PromotionType.percentage,
      ),
      category: PromotionCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (map['category'] ?? 'general'),
        orElse: () => PromotionCategory.general,
      ),
      imageUrl: map['imageUrl'] ?? map['image'],
      discountCode: map['discountCode'] ?? map['code'],
      discountPercent:
          (map['discountPercent'] ?? map['discountValue'])?.toDouble(),
      discountAmount: (map['discountAmount'])?.toDouble(),
      minimumPurchase: (map['minimumPurchase'] ?? map['minSpend'])?.toDouble(),
      maximumDiscount: (map['maximumDiscount'])?.toDouble(),
      buyQuantity: (map['buyQuantity'])?.toInt(),
      getQuantity: (map['getQuantity'])?.toInt(),
      originalPrice: (map['originalPrice'])?.toDouble(),
      flashSalePrice: (map['flashSalePrice'])?.toDouble(),
      flashSaleStock: (map['flashSaleStock'])?.toInt(),
      flashSaleSold: (map['flashSaleSold'] ?? 0).toInt(),
      applicableProductIds: map['applicableProductIds']?.cast<String>(),
      applicableCategoryIds:
          (map['applicableCategoryIds'] ?? map['applicableCategories'])
              ?.cast<String>(),
      excludedProductIds: map['excludedProductIds']?.cast<String>(),
      usageLimit: (map['usageLimit'])?.toInt(),
      usageLimitPerUser: (map['usageLimitPerUser'])?.toInt(),
      maxUsagePerDay: (map['maxUsagePerDay'])?.toInt(),
      usedCount: (map['usedCount'] ?? 0).toInt(),
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
      startTime: _parseTimeOfDay(map['startTime']),
      endTime: _parseTimeOfDay(map['endTime']),
      isActive: map['isActive'] ?? true,
      isPublic: map['isPublic'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      isFlashSale: map['isFlashSale'] ?? false,
      requiresApproval: map['requiresApproval'] ?? false,
      showInPublicList: map['showInPublicList'] ?? true,
      allowStacking: map['allowStacking'] ?? false,
      bannerText: map['bannerText'],
      iconEmoji: map['iconEmoji'],
      backgroundColor: map['backgroundColor'],
      priority: Priority.values.firstWhere(
        (e) => e.toString().split('.').last == (map['priority'] ?? 'normal'),
        orElse: () => Priority.normal,
      ),
      trackingCode: map['trackingCode'],
      campaignName: map['campaignName'],
      targetAudience: map['targetAudience'],
      terms: map['terms'] ?? map['couponCondition'],
      metadata: map['metadata'] ?? map['customFields'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'imageUrl': imageUrl,
      'discountCode': discountCode,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'minimumPurchase': minimumPurchase,
      'maximumDiscount': maximumDiscount,
      'buyQuantity': buyQuantity,
      'getQuantity': getQuantity,
      'originalPrice': originalPrice,
      'flashSalePrice': flashSalePrice,
      'flashSaleStock': flashSaleStock,
      'flashSaleSold': flashSaleSold,
      'applicableProductIds': applicableProductIds,
      'applicableCategoryIds': applicableCategoryIds,
      'excludedProductIds': excludedProductIds,
      'usageLimit': usageLimit,
      'usageLimitPerUser': usageLimitPerUser,
      'maxUsagePerDay': maxUsagePerDay,
      'usedCount': usedCount,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'startTime': startTime != null ? _timeOfDayToMap(startTime!) : null,
      'endTime': endTime != null ? _timeOfDayToMap(endTime!) : null,
      'isActive': isActive,
      'isPublic': isPublic,
      'isFeatured': isFeatured,
      'isFlashSale': isFlashSale,
      'requiresApproval': requiresApproval,
      'showInPublicList': showInPublicList,
      'allowStacking': allowStacking,
      'bannerText': bannerText,
      'iconEmoji': iconEmoji,
      'backgroundColor': backgroundColor,
      'priority': priority.toString().split('.').last,
      'trackingCode': trackingCode,
      'campaignName': campaignName,
      'targetAudience': targetAudience,
      'terms': terms,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Convert to Firestore document format (excludes id)
  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  /// Check if promotion is currently valid
  bool get isValid {
    if (!isActive) return false;

    final now = DateTime.now();

    // Check date range
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    // Check time range (if same day)
    if (startTime != null && endTime != null) {
      final nowTime = TimeOfDay.fromDateTime(now);
      final startMinutes = startTime!.hour * 60 + startTime!.minute;
      final endMinutes = endTime!.hour * 60 + endTime!.minute;
      final nowMinutes = nowTime.hour * 60 + nowTime.minute;

      if (nowMinutes < startMinutes || nowMinutes > endMinutes) return false;
    }

    // Check usage limits
    if (usageLimit != null && usedCount >= usageLimit!) return false;

    // Check flash sale stock
    if (isFlashSale &&
        flashSaleStock != null &&
        flashSaleSold >= flashSaleStock!) {
      return false;
    }

    return true;
  }

  /// Calculate discount for given amount
  double calculateDiscount(double amount) {
    if (!isValid) return 0.0;
    if (minimumPurchase != null && amount < minimumPurchase!) return 0.0;

    double discount = 0.0;

    switch (type) {
      case PromotionType.percentage:
        if (discountPercent != null) {
          discount = amount * (discountPercent! / 100);
          if (maximumDiscount != null) {
            discount =
                discount > maximumDiscount! ? maximumDiscount! : discount;
          }
        }
        break;
      case PromotionType.fixedAmount:
        discount = discountAmount ?? 0.0;
        break;
      case PromotionType.buyXGetY:
        // Logic for buy X get Y would depend on cart items
        break;
      case PromotionType.flashSale:
        if (originalPrice != null && flashSalePrice != null) {
          discount = originalPrice! - flashSalePrice!;
        }
        break;
      case PromotionType.freeShipping:
      case PromotionType.giftWithPurchase:
        // These types don't provide monetary discount
        discount = 0.0;
        break;
    }

    return discount > amount ? amount : discount;
  }

  /// Copy with new values
  UnifiedPromotion copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    PromotionType? type,
    PromotionCategory? category,
    String? imageUrl,
    String? discountCode,
    double? discountPercent,
    double? discountAmount,
    double? minimumPurchase,
    double? maximumDiscount,
    int? buyQuantity,
    int? getQuantity,
    double? originalPrice,
    double? flashSalePrice,
    int? flashSaleStock,
    int? flashSaleSold,
    List<String>? applicableProductIds,
    List<String>? applicableCategoryIds,
    List<String>? excludedProductIds,
    int? usageLimit,
    int? usageLimitPerUser,
    int? maxUsagePerDay,
    int? usedCount,
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isActive,
    bool? isPublic,
    bool? isFeatured,
    bool? isFlashSale,
    bool? requiresApproval,
    bool? showInPublicList,
    bool? allowStacking,
    String? bannerText,
    String? iconEmoji,
    String? backgroundColor,
    Priority? priority,
    String? trackingCode,
    String? campaignName,
    String? targetAudience,
    String? terms,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnifiedPromotion(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      discountCode: discountCode ?? this.discountCode,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      minimumPurchase: minimumPurchase ?? this.minimumPurchase,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      buyQuantity: buyQuantity ?? this.buyQuantity,
      getQuantity: getQuantity ?? this.getQuantity,
      originalPrice: originalPrice ?? this.originalPrice,
      flashSalePrice: flashSalePrice ?? this.flashSalePrice,
      flashSaleStock: flashSaleStock ?? this.flashSaleStock,
      flashSaleSold: flashSaleSold ?? this.flashSaleSold,
      applicableProductIds: applicableProductIds ?? this.applicableProductIds,
      applicableCategoryIds:
          applicableCategoryIds ?? this.applicableCategoryIds,
      excludedProductIds: excludedProductIds ?? this.excludedProductIds,
      usageLimit: usageLimit ?? this.usageLimit,
      usageLimitPerUser: usageLimitPerUser ?? this.usageLimitPerUser,
      maxUsagePerDay: maxUsagePerDay ?? this.maxUsagePerDay,
      usedCount: usedCount ?? this.usedCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      isFeatured: isFeatured ?? this.isFeatured,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      showInPublicList: showInPublicList ?? this.showInPublicList,
      allowStacking: allowStacking ?? this.allowStacking,
      bannerText: bannerText ?? this.bannerText,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      priority: priority ?? this.priority,
      trackingCode: trackingCode ?? this.trackingCode,
      campaignName: campaignName ?? this.campaignName,
      targetAudience: targetAudience ?? this.targetAudience,
      terms: terms ?? this.terms,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a mock promotion for testing
  static UnifiedPromotion mock() {
    return UnifiedPromotion(
      id: 'mock-promo-1',
      sellerId: 'mock-seller',
      title: 'โปรโมชั่นพิเศษ Green Market',
      description: 'ลดราคา 20% สำหรับสินค้าเป็นมิตรกับสิ่งแวดล้อม',
      type: PromotionType.percentage,
      category: PromotionCategory.general,
      discountPercent: 20.0,
      minimumPurchase: 200.0,
      maximumDiscount: 100.0,
      iconEmoji: '🌱',
      backgroundColor: '#E8F5E8',
      createdAt: DateTime.now(),
    );
  }

  // Helper methods
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final hour = value['hour'] as int?;
      final minute = value['minute'] as int?;
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  static Map<String, dynamic> _timeOfDayToMap(TimeOfDay time) {
    return {
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedPromotion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UnifiedPromotion(id: $id, title: $title, type: $type, isValid: $isValid)';
  }
}

/// ประเภทโปรโมชั่น
enum PromotionType {
  percentage, // ส่วนลดเปอร์เซ็นต์
  fixedAmount, // ส่วนลดจำนวนเงิน
  buyXGetY, // ซื้อ X ได้ Y
  flashSale, // ลดราคาพิเศษ
  freeShipping, // ส่งฟรี
  giftWithPurchase, // แถมของ
}

/// หมวดหมู่โปรโมชั่น
enum PromotionCategory {
  general, // ทั่วไป
  seasonal, // ตามฤดูกาล
  clearance, // เคลียร์สินค้า
  newProduct, // สินค้าใหม่
  membership, // สำหรับสมาชิก
  firstTime, // ลูกค้าใหม่
  loyalty, // ลูกค้าเก่า
  bulk, // ซื้อจำนวนมาก
}

/// ระดับความสำคัญ
enum Priority {
  low, // ต่ำ
  normal, // ปกติ
  high, // สูง
  urgent, // เร่งด่วน
}
