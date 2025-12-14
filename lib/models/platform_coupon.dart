// lib/models/platform_coupon.dart
// Platform-wide Coupons - Green Market Official Coupons

import 'package:cloud_firestore/cloud_firestore.dart';
import 'advanced_coupon.dart';

/// Source of Coupon
enum CouponSource {
  platform, // From Green Market
  shop, // From individual seller
  bank, // Bank promotion
  partner, // Partner brands
}

/// Platform Coupon Types
enum PlatformCouponType {
  welcome, // New user welcome
  festival, // Holiday/Festival special
  flash, // Limited time flash voucher
  memberExclusive, // Tier-based exclusive
  ecoHeroReward, // Eco hero achievement reward
  referral, // Referral program reward
  apology, // Service recovery
  birthday, // Birthday month special
  anniversary, // Account anniversary
  vipMonthly, // Monthly VIP benefit
}

/// Platform Coupon - Official coupons from Green Market
class PlatformCoupon extends AdvancedCoupon {
  final CouponSource source = CouponSource.platform;
  final PlatformCouponType platformType;
  final String? requiredTier; // bronze, silver, gold, platinum, diamond
  final int? requiredEcoScore; // Minimum eco score to claim
  final bool isNewUserOnly;
  final bool isOneTimeUse;
  final int? maxClaimsGlobal; // Total claims across all users
  final int currentClaimsGlobal;
  final List<String>? eligibleUserIds; // Specific users who can claim
  final Map<String, dynamic>? distributionRules;

  PlatformCoupon({
    required super.id,
    required super.code,
    required super.name,
    super.description,
    required super.type,
    required super.value,
    super.minPurchase,
    super.maxDiscount,
    super.usageLimit,
    super.usedCount,
    super.perUserLimit,
    super.startDate,
    super.endDate,
    super.isActive,
    super.autoApply,
    super.targetType,
    super.targetProductIds,
    super.targetCategories,
    super.requireMinItems,
    super.minItems,
    super.stackable,
    super.priority,
    required super.createdAt,
    required super.updatedAt,
    super.analyticsData,
    required this.platformType,
    this.requiredTier,
    this.requiredEcoScore,
    this.isNewUserOnly = false,
    this.isOneTimeUse = true,
    this.maxClaimsGlobal,
    this.currentClaimsGlobal = 0,
    this.eligibleUserIds,
    this.distributionRules,
  }) : super(sellerId: 'platform');

  factory PlatformCoupon.fromMap(Map<String, dynamic> map, String id) {
    return PlatformCoupon(
      id: id,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      type: CouponType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CouponType.percentage,
      ),
      value: (map['value'] as num).toDouble(),
      minPurchase: (map['minPurchase'] as num?)?.toDouble() ?? 0,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble() ?? 0,
      usageLimit: map['usageLimit'] as int? ?? 0,
      usedCount: map['usedCount'] as int? ?? 0,
      perUserLimit: map['perUserLimit'] as int? ?? 1,
      startDate: map['startDate'] != null
          ? (map['startDate'] as Timestamp).toDate()
          : null,
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] as bool? ?? true,
      autoApply: map['autoApply'] as bool? ?? false,
      targetType: CouponTargetType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => CouponTargetType.all,
      ),
      targetProductIds: List<String>.from(map['targetProductIds'] ?? []),
      targetCategories: List<String>.from(map['targetCategories'] ?? []),
      requireMinItems: map['requireMinItems'] as bool? ?? false,
      minItems: map['minItems'] as int? ?? 0,
      stackable: map['stackable'] as bool? ?? false,
      priority: map['priority'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      analyticsData: map['analyticsData'] as Map<String, dynamic>?,
      platformType: PlatformCouponType.values.firstWhere(
        (e) => e.name == map['platformType'],
        orElse: () => PlatformCouponType.welcome,
      ),
      requiredTier: map['requiredTier'] as String?,
      requiredEcoScore: map['requiredEcoScore'] as int?,
      isNewUserOnly: map['isNewUserOnly'] as bool? ?? false,
      isOneTimeUse: map['isOneTimeUse'] as bool? ?? true,
      maxClaimsGlobal: map['maxClaimsGlobal'] as int?,
      currentClaimsGlobal: map['currentClaimsGlobal'] as int? ?? 0,
      eligibleUserIds: map['eligibleUserIds'] != null
          ? List<String>.from(map['eligibleUserIds'])
          : null,
      distributionRules: map['distributionRules'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'source': source.name,
      'platformType': platformType.name,
      'requiredTier': requiredTier,
      'requiredEcoScore': requiredEcoScore,
      'isNewUserOnly': isNewUserOnly,
      'isOneTimeUse': isOneTimeUse,
      'maxClaimsGlobal': maxClaimsGlobal,
      'currentClaimsGlobal': currentClaimsGlobal,
      'eligibleUserIds': eligibleUserIds,
      'distributionRules': distributionRules,
    });
    return map;
  }

  /// Check if user is eligible to claim this coupon
  bool isEligibleForUser({
    required String userId,
    String? userTier,
    int? userEcoScore,
    bool? isNewUser,
    DateTime? accountCreatedAt,
  }) {
    // Check global claim limit
    if (maxClaimsGlobal != null && currentClaimsGlobal >= maxClaimsGlobal!) {
      return false;
    }

    // Check specific user list
    if (eligibleUserIds != null && !eligibleUserIds!.contains(userId)) {
      return false;
    }

    // Check new user requirement
    if (isNewUserOnly && isNewUser == false) {
      return false;
    }

    // Check tier requirement
    if (requiredTier != null && userTier != null) {
      final tierRank = {
        'bronze': 0,
        'silver': 1,
        'gold': 2,
        'platinum': 3,
        'diamond': 4,
      };
      final required = tierRank[requiredTier] ?? 0;
      final current = tierRank[userTier] ?? 0;
      if (current < required) return false;
    }

    // Check eco score requirement
    if (requiredEcoScore != null &&
        (userEcoScore == null || userEcoScore < requiredEcoScore!)) {
      return false;
    }

    return isValid();
  }

  /// Get display label for coupon type
  String get typeLabel {
    switch (platformType) {
      case PlatformCouponType.welcome:
        return '🎁 Welcome Coupon';
      case PlatformCouponType.festival:
        return '🎉 Festival Special';
      case PlatformCouponType.flash:
        return '⚡ Flash Voucher';
      case PlatformCouponType.memberExclusive:
        return '👑 Member Exclusive';
      case PlatformCouponType.ecoHeroReward:
        return '🌱 Eco Hero Reward';
      case PlatformCouponType.referral:
        return '🤝 Referral Reward';
      case PlatformCouponType.apology:
        return '💚 We\'re Sorry';
      case PlatformCouponType.birthday:
        return '🎂 Birthday Special';
      case PlatformCouponType.anniversary:
        return '🎊 Anniversary Gift';
      case PlatformCouponType.vipMonthly:
        return '⭐ VIP Monthly Benefit';
    }
  }

  /// Check if this is a limited-time flash coupon
  bool get isFlashCoupon => platformType == PlatformCouponType.flash;

  /// Get remaining time for flash coupon
  Duration? get remainingTime {
    if (!isFlashCoupon || endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return Duration.zero;
    return endDate!.difference(now);
  }

  /// Get percentage of global claims used
  double get claimPercentage {
    if (maxClaimsGlobal == null || maxClaimsGlobal == 0) return 0;
    return (currentClaimsGlobal / maxClaimsGlobal!) * 100;
  }

  /// Check if coupon is almost claimed out
  bool get isAlmostGone => claimPercentage >= 80;

  /// Create copy (removed @override to avoid signature mismatch)
  PlatformCoupon copyWithPlatform({
    String? code,
    String? name,
    String? description,
    CouponType? type,
    double? value,
    double? minPurchase,
    double? maxDiscount,
    int? usageLimit,
    int? usedCount,
    int? perUserLimit,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? autoApply,
    CouponTargetType? targetType,
    List<String>? targetProductIds,
    List<String>? targetCategories,
    bool? requireMinItems,
    int? minItems,
    bool? stackable,
    int? priority,
    PlatformCouponType? platformType,
    String? requiredTier,
    int? requiredEcoScore,
    bool? isNewUserOnly,
    bool? isOneTimeUse,
    int? maxClaimsGlobal,
    int? currentClaimsGlobal,
    List<String>? eligibleUserIds,
    Map<String, dynamic>? distributionRules,
  }) {
    return PlatformCoupon(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minPurchase: minPurchase ?? this.minPurchase,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      autoApply: autoApply ?? this.autoApply,
      targetType: targetType ?? this.targetType,
      targetProductIds: targetProductIds ?? this.targetProductIds,
      targetCategories: targetCategories ?? this.targetCategories,
      requireMinItems: requireMinItems ?? this.requireMinItems,
      minItems: minItems ?? this.minItems,
      stackable: stackable ?? this.stackable,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      analyticsData: analyticsData,
      platformType: platformType ?? this.platformType,
      requiredTier: requiredTier ?? this.requiredTier,
      requiredEcoScore: requiredEcoScore ?? this.requiredEcoScore,
      isNewUserOnly: isNewUserOnly ?? this.isNewUserOnly,
      isOneTimeUse: isOneTimeUse ?? this.isOneTimeUse,
      maxClaimsGlobal: maxClaimsGlobal ?? this.maxClaimsGlobal,
      currentClaimsGlobal: currentClaimsGlobal ?? this.currentClaimsGlobal,
      eligibleUserIds: eligibleUserIds ?? this.eligibleUserIds,
      distributionRules: distributionRules ?? this.distributionRules,
    );
  }

  /// Also provide standard copyWith for compatibility
  @override
  AdvancedCoupon copyWith({
    String? sellerId,
    String? code,
    String? name,
    String? description,
    CouponType? type,
    double? value,
    double? minPurchase,
    double? maxDiscount,
    int? usageLimit,
    int? usedCount,
    int? perUserLimit,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? autoApply,
    CouponTargetType? targetType,
    List<String>? targetProductIds,
    List<String>? targetCategories,
    bool? requireMinItems,
    int? minItems,
    bool? stackable,
    int? priority,
    DateTime? updatedAt,
    Map<String, dynamic>? analyticsData,
  }) {
    return copyWithPlatform(
      code: code,
      name: name,
      description: description,
      type: type,
      value: value,
      minPurchase: minPurchase,
      maxDiscount: maxDiscount,
      usageLimit: usageLimit,
      usedCount: usedCount,
      perUserLimit: perUserLimit,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      autoApply: autoApply,
      targetType: targetType,
      targetProductIds: targetProductIds,
      targetCategories: targetCategories,
      requireMinItems: requireMinItems,
      minItems: minItems,
      stackable: stackable,
      priority: priority,
    );
  }
}

/// Coupon Claim Record
class CouponClaimRecord {
  final String id;
  final String userId;
  final String couponId;
  final CouponSource source;
  final DateTime claimedAt;
  final DateTime? usedAt;
  final String? orderId;
  final double? discountAmount;
  final String status; // 'active', 'used', 'expired'

  CouponClaimRecord({
    required this.id,
    required this.userId,
    required this.couponId,
    required this.source,
    required this.claimedAt,
    this.usedAt,
    this.orderId,
    this.discountAmount,
    this.status = 'active',
  });

  factory CouponClaimRecord.fromMap(Map<String, dynamic> map, String id) {
    return CouponClaimRecord(
      id: id,
      userId: map['userId'] as String,
      couponId: map['couponId'] as String,
      source: CouponSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => CouponSource.platform,
      ),
      claimedAt: (map['claimedAt'] as Timestamp).toDate(),
      usedAt:
          map['usedAt'] != null ? (map['usedAt'] as Timestamp).toDate() : null,
      orderId: map['orderId'] as String?,
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'couponId': couponId,
      'source': source.name,
      'claimedAt': Timestamp.fromDate(claimedAt),
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'orderId': orderId,
      'discountAmount': discountAmount,
      'status': status,
    };
  }

  bool get isUsed => status == 'used';
  bool get isExpired => status == 'expired';
  bool get isActive => status == 'active';
}
