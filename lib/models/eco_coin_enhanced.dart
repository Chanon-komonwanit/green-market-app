// lib/models/eco_coin_enhanced.dart
// Enhanced Eco Coins System - Shopee-style Features

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Daily Reward Configuration
class DailyReward {
  final int day; // Day number in streak
  final int coins;
  final String? bonusType; // 'double', 'triple', 'mystery'
  final bool isBonusDay;

  const DailyReward({
    required this.day,
    required this.coins,
    this.bonusType,
    this.isBonusDay = false,
  });

  factory DailyReward.fromMap(Map<String, dynamic> map) {
    return DailyReward(
      day: map['day'] as int,
      coins: map['coins'] as int,
      bonusType: map['bonusType'] as String?,
      isBonusDay: map['isBonusDay'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'coins': coins,
      'bonusType': bonusType,
      'isBonusDay': isBonusDay,
    };
  }
}

/// User's Daily Check-in Record
class DailyCheckIn {
  final String id;
  final String userId;
  final DateTime checkInDate;
  final int streakCount;
  final int coinsEarned;
  final String? bonusType;
  final Map<String, dynamic>? metadata;

  DailyCheckIn({
    required this.id,
    required this.userId,
    required this.checkInDate,
    required this.streakCount,
    required this.coinsEarned,
    this.bonusType,
    this.metadata,
  });

  factory DailyCheckIn.fromMap(Map<String, dynamic> map, String id) {
    return DailyCheckIn(
      id: id,
      userId: map['userId'] as String,
      checkInDate: (map['checkInDate'] as Timestamp).toDate(),
      streakCount: map['streakCount'] as int,
      coinsEarned: map['coinsEarned'] as int,
      bonusType: map['bonusType'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'streakCount': streakCount,
      'coinsEarned': coinsEarned,
      'bonusType': bonusType,
      'metadata': metadata,
    };
  }
}

/// Gamification Rewards
enum MiniGameType {
  spinWheel,
  scratchCard,
  luckyDraw,
  ecoQuiz,
  productMatch,
  dailyPuzzle,
}

class MiniGameReward {
  final String id;
  final String userId;
  final MiniGameType gameType;
  final int coinsWon;
  final DateTime playedAt;
  final Map<String, dynamic>? gameData;
  final bool isJackpot;

  MiniGameReward({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.coinsWon,
    required this.playedAt,
    this.gameData,
    this.isJackpot = false,
  });

  factory MiniGameReward.fromMap(Map<String, dynamic> map, String id) {
    return MiniGameReward(
      id: id,
      userId: map['userId'] as String,
      gameType: MiniGameType.values.firstWhere(
        (e) => e.name == map['gameType'],
        orElse: () => MiniGameType.spinWheel,
      ),
      coinsWon: map['coinsWon'] as int,
      playedAt: (map['playedAt'] as Timestamp).toDate(),
      gameData: map['gameData'] as Map<String, dynamic>?,
      isJackpot: map['isJackpot'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gameType': gameType.name,
      'coinsWon': coinsWon,
      'playedAt': Timestamp.fromDate(playedAt),
      'gameData': gameData,
      'isJackpot': isJackpot,
    };
  }
}

/// Tier Benefits Configuration
class TierBenefits {
  final EcoCoinTier tier;
  final double coinEarnMultiplier; // 1.0 = 100%, 1.5 = 150%
  final List<String> perks;
  final int freeShippingVouchersPerMonth;
  final int birthdayBonusCoins;
  final bool priorityCustomerService;
  final bool earlyAccessFlashSales;
  final bool exclusiveCoupons;
  final Map<String, dynamic>? additionalPerks;

  TierBenefits({
    required this.tier,
    required this.coinEarnMultiplier,
    required this.perks,
    this.freeShippingVouchersPerMonth = 0,
    this.birthdayBonusCoins = 0,
    this.priorityCustomerService = false,
    this.earlyAccessFlashSales = false,
    this.exclusiveCoupons = false,
    this.additionalPerks,
  });

  static TierBenefits forTier(EcoCoinTier tier) {
    switch (tier) {
      case EcoCoinTier.bronze:
        return TierBenefits(
          tier: tier,
          coinEarnMultiplier: 1.0,
          perks: [
            'Basic rewards',
            'Earn 1 coin per ฿10 spent',
          ],
        );

      case EcoCoinTier.silver:
        return TierBenefits(
          tier: tier,
          coinEarnMultiplier: 1.5,
          perks: [
            'All Bronze benefits',
            'Early access to flash sales (5 mins)',
            'Earn 1.5 coins per ฿10 spent',
            'Exclusive monthly coupons',
          ],
          earlyAccessFlashSales: true,
          exclusiveCoupons: true,
        );

      case EcoCoinTier.gold:
        return TierBenefits(
          tier: tier,
          coinEarnMultiplier: 2.0,
          perks: [
            'All Silver benefits',
            'Free shipping vouchers (2/month)',
            'Earn 2 coins per ฿10 spent',
            'Birthday rewards (500 coins)',
            'Priority customer service',
          ],
          freeShippingVouchersPerMonth: 2,
          birthdayBonusCoins: 500,
          priorityCustomerService: true,
          earlyAccessFlashSales: true,
          exclusiveCoupons: true,
        );

      case EcoCoinTier.platinum:
        return TierBenefits(
          tier: tier,
          coinEarnMultiplier: 3.0,
          perks: [
            'All Gold benefits',
            'VIP flash sales access',
            'Free shipping vouchers (5/month)',
            'Earn 3 coins per ฿10 spent',
            'Quarterly rewards (2000 coins)',
            'Dedicated account manager',
          ],
          freeShippingVouchersPerMonth: 5,
          birthdayBonusCoins: 2000,
          priorityCustomerService: true,
          earlyAccessFlashSales: true,
          exclusiveCoupons: true,
        );
    }
  }
}

/// Redemption Catalog Item
enum RewardCategory {
  coupons,
  freeShipping,
  exclusiveProducts,
  partnerRewards,
  ecoImpact,
  physicalGoods,
}

class RedemptionReward {
  final String id;
  final String name;
  final String description;
  final int coinsCost;
  final RewardCategory category;
  final String? imageUrl;
  final int? stock; // null = unlimited
  final DateTime? validUntil;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  RedemptionReward({
    required this.id,
    required this.name,
    required this.description,
    required this.coinsCost,
    required this.category,
    this.imageUrl,
    this.stock,
    this.validUntil,
    this.isActive = true,
    this.metadata,
  });

  factory RedemptionReward.fromMap(Map<String, dynamic> map, String id) {
    return RedemptionReward(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String,
      coinsCost: map['coinsCost'] as int,
      category: RewardCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => RewardCategory.coupons,
      ),
      imageUrl: map['imageUrl'] as String?,
      stock: map['stock'] as int?,
      validUntil: map['validUntil'] != null
          ? (map['validUntil'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] as bool? ?? true,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'coinsCost': coinsCost,
      'category': category.name,
      'imageUrl': imageUrl,
      'stock': stock,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  bool get isAvailable => isActive && (stock == null || stock! > 0);
}

/// User's Redemption History
class RedemptionRecord {
  final String id;
  final String userId;
  final String rewardId;
  final int coinsSpent;
  final DateTime redeemedAt;
  final String status; // 'pending', 'completed', 'cancelled'
  final Map<String, dynamic>? deliveryInfo;

  RedemptionRecord({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.coinsSpent,
    required this.redeemedAt,
    this.status = 'pending',
    this.deliveryInfo,
  });

  factory RedemptionRecord.fromMap(Map<String, dynamic> map, String id) {
    return RedemptionRecord(
      id: id,
      userId: map['userId'] as String,
      rewardId: map['rewardId'] as String,
      coinsSpent: map['coinsSpent'] as int,
      redeemedAt: (map['redeemedAt'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'pending',
      deliveryInfo: map['deliveryInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'coinsSpent': coinsSpent,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      'status': status,
      'deliveryInfo': deliveryInfo,
    };
  }
}

/// Auto-Earn Configuration
enum AutoEarnTrigger {
  appOpen,
  dailyCheckIn,
  viewProduct,
  addToCart,
  shareProduct,
  followShop,
  writeReview,
  completeProfile,
  firstPurchase,
  referralSuccess,
  ecoActivity,
}

class AutoEarnRule {
  final AutoEarnTrigger trigger;
  final int baseCoins;
  final int maxPerDay;
  final bool requiresVerification;
  final Map<String, dynamic>? conditions;

  const AutoEarnRule({
    required this.trigger,
    required this.baseCoins,
    this.maxPerDay = 999,
    this.requiresVerification = false,
    this.conditions,
  });

  static List<AutoEarnRule> get defaultRules => [
        AutoEarnRule(
            trigger: AutoEarnTrigger.appOpen, baseCoins: 1, maxPerDay: 3),
        AutoEarnRule(
            trigger: AutoEarnTrigger.dailyCheckIn, baseCoins: 5, maxPerDay: 1),
        AutoEarnRule(
            trigger: AutoEarnTrigger.viewProduct, baseCoins: 1, maxPerDay: 10),
        AutoEarnRule(
            trigger: AutoEarnTrigger.addToCart, baseCoins: 2, maxPerDay: 5),
        AutoEarnRule(
            trigger: AutoEarnTrigger.shareProduct, baseCoins: 5, maxPerDay: 3),
        AutoEarnRule(
            trigger: AutoEarnTrigger.followShop, baseCoins: 10, maxPerDay: 5),
        AutoEarnRule(
            trigger: AutoEarnTrigger.writeReview,
            baseCoins: 20,
            maxPerDay: 3,
            requiresVerification: true),
        AutoEarnRule(
            trigger: AutoEarnTrigger.completeProfile,
            baseCoins: 50,
            maxPerDay: 1),
        AutoEarnRule(
            trigger: AutoEarnTrigger.firstPurchase,
            baseCoins: 100,
            maxPerDay: 1),
        AutoEarnRule(
            trigger: AutoEarnTrigger.referralSuccess,
            baseCoins: 200,
            maxPerDay: 10),
      ];
}
