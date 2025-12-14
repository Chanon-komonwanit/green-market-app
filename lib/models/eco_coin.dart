// lib/models/eco_coin.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class EcoCoin {
  final String id;
  final String userId;
  final int amount;
  final EcoCoinTransactionType type;
  final String
      source; // เช่น 'purchase', 'review', 'daily_login', 'eco_activity'
  final String? description;
  final String? orderId; // ถ้าเกี่ยวข้องกับคำสั่งซื้อ
  final Timestamp createdAt;
  final Timestamp? expiredAt; // เหลียญอาจมีอายุ
  final bool isActive;

  EcoCoin({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.source,
    this.description,
    this.orderId,
    required this.createdAt,
    this.expiredAt,
    this.isActive = true,
  });

  factory EcoCoin.fromMap(Map<String, dynamic> map, String id) {
    // Enhanced validation
    if (id.isEmpty) {
      throw ArgumentError('EcoCoin id cannot be empty');
    }

    final userId = map['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('EcoCoin userId cannot be null or empty');
    }

    final source = map['source'] as String?;
    if (source == null || source.isEmpty) {
      throw ArgumentError('EcoCoin source cannot be null or empty');
    }

    return EcoCoin(
      id: id,
      userId: userId,
      amount: (map['amount'] as num).toInt(),
      type: EcoCoinTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EcoCoinTransactionType.earned,
      ),
      source: source,
      description: map['description'] as String?,
      orderId: map['orderId'] as String?,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      expiredAt: map['expiredAt'] as Timestamp?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'source': source,
      'description': description,
      'orderId': orderId,
      'createdAt': createdAt,
      'expiredAt': expiredAt,
      'isActive': isActive,
    };
  }

  EcoCoin copyWith({
    String? id,
    String? userId,
    int? amount,
    EcoCoinTransactionType? type,
    String? source,
    String? description,
    String? orderId,
    Timestamp? createdAt,
    Timestamp? expiredAt,
    bool? isActive,
  }) {
    return EcoCoin(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      source: source ?? this.source,
      description: description ?? this.description,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      expiredAt: expiredAt ?? this.expiredAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods สำหรับ business logic
  bool get isExpired =>
      expiredAt != null && expiredAt!.toDate().isBefore(DateTime.now());
  bool get isEarned => type == EcoCoinTransactionType.earned;
  bool get isSpent => type == EcoCoinTransactionType.spent;
  bool get isValid => isActive && !isExpired;

  // Get absolute amount (always positive)
  int get absoluteAmount => amount.abs();

  // Validation method
  bool validate() {
    if (id.isEmpty) return false;
    if (userId.isEmpty) return false;
    if (source.isEmpty) return false;
    if (amount == 0) return false;
    return true;
  }
}

class EcoCoinBalance {
  final String userId;
  final int totalCoins;
  final int availableCoins;
  final int expiredCoins;
  final int lifetimeEarned;
  final int lifetimeSpent;
  final EcoCoinTier currentTier;
  final int coinsToNextTier;
  final Timestamp lastUpdated;

  EcoCoinBalance({
    required this.userId,
    required this.totalCoins,
    required this.availableCoins,
    required this.expiredCoins,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
    required this.currentTier,
    required this.coinsToNextTier,
    required this.lastUpdated,
  });

  factory EcoCoinBalance.fromMap(Map<String, dynamic> map, String userId) {
    // Enhanced validation
    if (userId.isEmpty) {
      throw ArgumentError('EcoCoinBalance userId cannot be empty');
    }

    // Safe parsing with validation
    final totalCoins = _parsePositiveInt(map['totalCoins']);
    final availableCoins = _parsePositiveInt(map['availableCoins']);
    final expiredCoins = _parsePositiveInt(map['expiredCoins']);
    final lifetimeEarned = _parsePositiveInt(map['lifetimeEarned']);
    final lifetimeSpent = _parsePositiveInt(map['lifetimeSpent']);

    // Business logic validation
    if (availableCoins > totalCoins) {
      throw StateError('Available coins cannot exceed total coins');
    }

    if (lifetimeSpent > lifetimeEarned) {
      throw StateError('Lifetime spent cannot exceed lifetime earned');
    }

    final currentTier = EcoCoinTierExtension.getCurrentTier(totalCoins);
    final nextTier = currentTier.getNextTier();
    final coinsToNextTier = nextTier != null
        ? (nextTier.minCoins - totalCoins).clamp(0, double.infinity).toInt()
        : 0;

    return EcoCoinBalance(
      userId: userId,
      totalCoins: totalCoins,
      availableCoins: availableCoins,
      expiredCoins: expiredCoins,
      lifetimeEarned: lifetimeEarned,
      lifetimeSpent: lifetimeSpent,
      currentTier: currentTier,
      coinsToNextTier: coinsToNextTier,
      lastUpdated: map['lastUpdated'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Helper method สำหรับ safe parsing
  static int _parsePositiveInt(dynamic value) {
    final parsed = (value as num?)?.toInt() ?? 0;
    return parsed < 0 ? 0 : parsed; // Never return negative
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCoins': totalCoins,
      'availableCoins': availableCoins,
      'expiredCoins': expiredCoins,
      'lifetimeEarned': lifetimeEarned,
      'lifetimeSpent': lifetimeSpent,
      'lastUpdated': lastUpdated,
    };
  }

  EcoCoinBalance copyWith({
    String? userId,
    int? totalCoins,
    int? availableCoins,
    int? expiredCoins,
    int? lifetimeEarned,
    int? lifetimeSpent,
    EcoCoinTier? currentTier,
    int? coinsToNextTier,
    Timestamp? lastUpdated,
  }) {
    return EcoCoinBalance(
      userId: userId ?? this.userId,
      totalCoins: totalCoins ?? this.totalCoins,
      availableCoins: availableCoins ?? this.availableCoins,
      expiredCoins: expiredCoins ?? this.expiredCoins,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      lifetimeSpent: lifetimeSpent ?? this.lifetimeSpent,
      currentTier: currentTier ?? this.currentTier,
      coinsToNextTier: coinsToNextTier ?? this.coinsToNextTier,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper methods สำหรับ business logic
  bool hasEnoughCoins(int amount) => availableCoins >= amount;

  bool get canUpgradeTier =>
      coinsToNextTier > 0 && coinsToNextTier <= availableCoins;

  double get balancePercentage {
    if (lifetimeEarned == 0) return 0.0;
    return (availableCoins / lifetimeEarned) * 100;
  }

  double get spendingRate {
    if (lifetimeEarned == 0) return 0.0;
    return (lifetimeSpent / lifetimeEarned) * 100;
  }

  bool get isHealthy => availableCoins > 0 && balancePercentage > 20;

  // Validation method
  bool validate() {
    if (userId.isEmpty) return false;
    if (totalCoins < 0 || availableCoins < 0) return false;
    if (availableCoins > totalCoins) return false;
    if (lifetimeSpent > lifetimeEarned) return false;
    return true;
  }

  // Get tier progress percentage (0-100)
  double getTierProgress() {
    final nextTier = currentTier.getNextTier();
    if (nextTier == null) return 100.0; // Max tier reached

    final currentMin = currentTier.minCoins;
    final nextMin = nextTier.minCoins;
    final range = nextMin - currentMin;
    final progress = totalCoins - currentMin;

    return (progress / range * 100).clamp(0.0, 100.0);
  }
}

// Eco Coin Mission/Task
enum EcoCoinMissionType {
  daily,
  weekly,
  monthly,
  purchase,
  review,
  special,
  ecoActivity,
}

extension EcoCoinMissionTypeExtension on EcoCoinMissionType {
  String get displayName {
    switch (this) {
      case EcoCoinMissionType.daily:
        return 'ภารกิจรายวัน';
      case EcoCoinMissionType.weekly:
        return 'ภารกิจรายสัปดาห์';
      case EcoCoinMissionType.monthly:
        return 'ภารกิจรายเดือน';
      case EcoCoinMissionType.purchase:
        return 'ภารกิจซื้อของ';
      case EcoCoinMissionType.review:
        return 'ภารกิจรีวิว';
      case EcoCoinMissionType.special:
        return 'ภารกิจพิเศษ';
      case EcoCoinMissionType.ecoActivity:
        return 'กิจกรรมเพื่อสิ่งแวดล้อม';
    }
  }
}

class EcoCoinMission {
  final String id;
  final String title;
  final String description;
  final int coinReward;
  final EcoCoinMissionType type;
  final int requiredProgress;
  final Timestamp validUntil;
  final bool isActive;
  final bool isRepeatable;
  final Timestamp createdAt;

  EcoCoinMission({
    required this.id,
    required this.title,
    required this.description,
    required this.coinReward,
    required this.type,
    required this.requiredProgress,
    required this.validUntil,
    this.isActive = true,
    this.isRepeatable = false,
    required this.createdAt,
  });

  // Helper getters for UI
  IconData get icon {
    switch (type) {
      case EcoCoinMissionType.daily:
        return Icons.today;
      case EcoCoinMissionType.weekly:
        return Icons.date_range;
      case EcoCoinMissionType.monthly:
        return Icons.calendar_month;
      case EcoCoinMissionType.purchase:
        return Icons.shopping_cart;
      case EcoCoinMissionType.review:
        return Icons.star_rate;
      case EcoCoinMissionType.special:
        return Icons.emoji_events;
      case EcoCoinMissionType.ecoActivity:
        return Icons.eco;
    }
  }

  Color get color {
    switch (type) {
      case EcoCoinMissionType.daily:
        return Colors.blue;
      case EcoCoinMissionType.weekly:
        return Colors.green;
      case EcoCoinMissionType.monthly:
        return Colors.purple;
      case EcoCoinMissionType.purchase:
        return Colors.orange;
      case EcoCoinMissionType.review:
        return Colors.amber;
      case EcoCoinMissionType.special:
        return Colors.red;
      case EcoCoinMissionType.ecoActivity:
        return AppColors.primaryTeal;
    }
  }

  factory EcoCoinMission.fromMap(Map<String, dynamic> map, String id) {
    return EcoCoinMission(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String,
      coinReward: (map['coinReward'] as num).toInt(),
      type: EcoCoinMissionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EcoCoinMissionType.special,
      ),
      requiredProgress: (map['requiredProgress'] as num).toInt(),
      validUntil: map['validUntil'] as Timestamp,
      isActive: map['isActive'] as bool? ?? true,
      isRepeatable: map['isRepeatable'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'coinReward': coinReward,
      'type': type.name,
      'requiredProgress': requiredProgress,
      'validUntil': validUntil,
      'isActive': isActive,
      'isRepeatable': isRepeatable,
      'createdAt': createdAt,
    };
  }
}

// User's Mission Progress
class EcoCoinMissionProgress {
  final String id;
  final String userId;
  final String missionId;
  final int currentProgress;
  final int requiredProgress;
  final bool isCompleted;
  final Timestamp? completedAt;
  final Timestamp createdAt;

  EcoCoinMissionProgress({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.currentProgress,
    required this.requiredProgress,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  factory EcoCoinMissionProgress.fromMap(Map<String, dynamic> map, String id) {
    return EcoCoinMissionProgress(
      id: id,
      userId: map['userId'] as String,
      missionId: map['missionId'] as String,
      currentProgress: (map['currentProgress'] as num).toInt(),
      requiredProgress: (map['requiredProgress'] as num).toInt(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] as Timestamp?,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'missionId': missionId,
      'currentProgress': currentProgress,
      'requiredProgress': requiredProgress,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'createdAt': createdAt,
    };
  }
}
