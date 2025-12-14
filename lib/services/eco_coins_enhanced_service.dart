// lib/services/eco_coins_enhanced_service.dart
// Enhanced Eco Coins Service with Gamification Features
// ขยายความสามารถจาก EcoCoinsService เดิม ไม่ซ้ำซ้อน

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/eco_coin.dart';
import '../models/eco_coin_enhanced.dart';
import '../utils/constants.dart';
import 'eco_coins_service.dart';

class EcoCoinsEnhancedService {
  static final EcoCoinsEnhancedService _instance =
      EcoCoinsEnhancedService._internal();
  factory EcoCoinsEnhancedService() => _instance;
  EcoCoinsEnhancedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EcoCoinsService _baseService = EcoCoinsService();

  // ==================== DAILY CHECK-IN ====================

  /// Check if user has checked in today
  Future<bool> hasCheckedInToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _firestore
        .collection('daily_check_ins')
        .where('userId', isEqualTo: user.uid)
        .where('checkInDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Perform daily check-in and award coins
  Future<DailyCheckIn?> performDailyCheckIn() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (await hasCheckedInToday()) {
      throw Exception('Already checked in today');
    }

    // Get user's streak
    final streak = await _getCurrentStreak(user.uid);
    final newStreak = streak + 1;

    // Calculate coins based on streak (with bonuses)
    final coinsEarned = _calculateCheckInReward(newStreak);
    final bonusType = _getCheckInBonusType(newStreak);

    final checkInRef = _firestore.collection('daily_check_ins').doc();
    final checkIn = DailyCheckIn(
      id: checkInRef.id,
      userId: user.uid,
      checkInDate: DateTime.now(),
      streakCount: newStreak,
      coinsEarned: coinsEarned,
      bonusType: bonusType,
    );

    await checkInRef.set(checkIn.toMap());

    // Award coins using base service
    await _baseService.awardCoins(
      amount: coinsEarned,
      source: 'daily_check_in',
      description:
          'Daily Check-in Day $newStreak${bonusType != null ? " ($bonusType bonus)" : ""}',
    );

    return checkIn;
  }

  /// Get current check-in streak
  Future<int> _getCurrentStreak(String userId) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStart =
        DateTime(yesterday.year, yesterday.month, yesterday.day);

    final snapshot = await _firestore
        .collection('daily_check_ins')
        .where('userId', isEqualTo: userId)
        .where('checkInDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(yesterdayStart))
        .orderBy('checkInDate', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final lastCheckIn = DailyCheckIn.fromMap(
        snapshot.docs.first.data(), snapshot.docs.first.id);
    return lastCheckIn.streakCount;
  }

  /// Calculate check-in reward based on streak
  int _calculateCheckInReward(int streak) {
    if (streak == 1) return 5;
    if (streak <= 3) return 10;
    if (streak <= 7) return 15;
    if (streak <= 14) return 25;
    if (streak <= 30) return 50;
    return 100; // 30+ days = jackpot
  }

  /// Get bonus type for streak milestones
  String? _getCheckInBonusType(int streak) {
    if (streak == 7) return 'weekly_bonus';
    if (streak == 30) return 'monthly_jackpot';
    if (streak % 10 == 0) return 'milestone_bonus';
    return null;
  }

  /// Get check-in history
  Stream<List<DailyCheckIn>> getCheckInHistory({int limit = 30}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('daily_check_ins')
        .where('userId', isEqualTo: user.uid)
        .orderBy('checkInDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyCheckIn.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ==================== MINI GAMES ====================

  /// Play spin wheel game
  Future<MiniGameReward> playSpinWheel() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if already played today
    if (await _hasPlayedGameToday(user.uid, MiniGameType.spinWheel)) {
      throw Exception('Already played Spin Wheel today');
    }

    // Random reward (weighted)
    final coinsWon = _generateSpinWheelReward();
    final isJackpot = coinsWon >= 1000;

    final rewardRef = _firestore.collection('mini_game_rewards').doc();
    final reward = MiniGameReward(
      id: rewardRef.id,
      userId: user.uid,
      gameType: MiniGameType.spinWheel,
      coinsWon: coinsWon,
      playedAt: DateTime.now(),
      isJackpot: isJackpot,
    );

    await rewardRef.set(reward.toMap());

    // Award coins
    await _baseService.awardCoins(
      amount: coinsWon,
      source: 'spin_wheel',
      description: isJackpot ? '🎰 JACKPOT! Spin Wheel' : 'Spin Wheel Game',
    );

    return reward;
  }

  /// Check if user played game today
  Future<bool> _hasPlayedGameToday(String userId, MiniGameType gameType) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _firestore
        .collection('mini_game_rewards')
        .where('userId', isEqualTo: userId)
        .where('gameType', isEqualTo: gameType.name)
        .where('playedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Generate random spin wheel reward (weighted probabilities)
  int _generateSpinWheelReward() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    if (random < 1) return 1000; // 1% chance - Jackpot
    if (random < 5) return 500; // 4% chance
    if (random < 15) return 200; // 10% chance
    if (random < 30) return 100; // 15% chance
    if (random < 60) return 50; // 30% chance
    return 10; // 40% chance
  }

  // ==================== AUTO-EARN SYSTEM ====================

  /// Track and reward auto-earn trigger
  Future<void> trackAutoEarn(AutoEarnTrigger trigger) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final rule = AutoEarnRule.defaultRules.firstWhere(
      (r) => r.trigger == trigger,
      orElse: () =>
          const AutoEarnRule(trigger: AutoEarnTrigger.appOpen, baseCoins: 0),
    );

    if (rule.baseCoins == 0) return;

    // Check daily limit
    final todayCount = await _getAutoEarnCountToday(user.uid, trigger);
    if (todayCount >= rule.maxPerDay) return;

    // Award coins
    await _baseService.awardCoins(
      amount: rule.baseCoins,
      source: 'auto_earn_${trigger.name}',
      description: _getAutoEarnDescription(trigger),
    );

    // Track event
    await _firestore.collection('auto_earn_events').add({
      'userId': user.uid,
      'trigger': trigger.name,
      'coinsEarned': rule.baseCoins,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get auto-earn count today for specific trigger
  Future<int> _getAutoEarnCountToday(
      String userId, AutoEarnTrigger trigger) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _firestore
        .collection('auto_earn_events')
        .where('userId', isEqualTo: userId)
        .where('trigger', isEqualTo: trigger.name)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  String _getAutoEarnDescription(AutoEarnTrigger trigger) {
    switch (trigger) {
      case AutoEarnTrigger.appOpen:
        return 'App Launch Bonus';
      case AutoEarnTrigger.dailyCheckIn:
        return 'Daily Check-in';
      case AutoEarnTrigger.viewProduct:
        return 'Product View';
      case AutoEarnTrigger.addToCart:
        return 'Add to Cart';
      case AutoEarnTrigger.shareProduct:
        return 'Share Product';
      case AutoEarnTrigger.followShop:
        return 'Follow Shop';
      case AutoEarnTrigger.writeReview:
        return 'Write Review';
      case AutoEarnTrigger.completeProfile:
        return 'Complete Profile';
      case AutoEarnTrigger.firstPurchase:
        return 'First Purchase Bonus';
      case AutoEarnTrigger.referralSuccess:
        return 'Referral Success';
      case AutoEarnTrigger.ecoActivity:
        return 'Eco Activity';
    }
  }

  // ==================== REDEMPTION SYSTEM ====================

  /// Get available redemption rewards
  Stream<List<RedemptionReward>> getRedemptionCatalog({
    RewardCategory? category,
  }) {
    Query query = _firestore
        .collection('redemption_rewards')
        .where('isActive', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => RedemptionReward.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
        .where((reward) => reward.isAvailable)
        .toList());
  }

  /// Redeem reward with coins
  Future<RedemptionRecord> redeemReward(
    String rewardId, {
    Map<String, dynamic>? deliveryInfo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get reward details
    final rewardDoc =
        await _firestore.collection('redemption_rewards').doc(rewardId).get();

    if (!rewardDoc.exists) throw Exception('Reward not found');

    final reward = RedemptionReward.fromMap(rewardDoc.data()!, rewardDoc.id);

    if (!reward.isAvailable) throw Exception('Reward not available');

    // Spend coins using base service
    final success = await _baseService.spendCoins(
      amount: reward.coinsCost,
      source: 'redemption',
      description: 'Redeemed: ${reward.name}',
    );

    if (!success) throw Exception('Insufficient coins');

    // Create redemption record
    final recordRef = _firestore.collection('redemption_records').doc();
    final record = RedemptionRecord(
      id: recordRef.id,
      userId: user.uid,
      rewardId: rewardId,
      coinsSpent: reward.coinsCost,
      redeemedAt: DateTime.now(),
      deliveryInfo: deliveryInfo,
    );

    await recordRef.set(record.toMap());

    // Update stock if applicable
    if (reward.stock != null) {
      await _firestore.collection('redemption_rewards').doc(rewardId).update({
        'stock': FieldValue.increment(-1),
      });
    }

    return record;
  }

  /// Get user's redemption history
  Stream<List<RedemptionRecord>> getRedemptionHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('redemption_records')
        .where('userId', isEqualTo: user.uid)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RedemptionRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ==================== TIER BENEFITS ====================

  /// Get benefits for user's current tier
  TierBenefits getTierBenefits(EcoCoinTier tier) {
    return TierBenefits.forTier(tier);
  }

  /// Calculate coins with tier multiplier
  int calculateCoinsWithMultiplier(int baseCoins, EcoCoinTier tier) {
    final benefits = getTierBenefits(tier);
    return (baseCoins * benefits.coinEarnMultiplier).round();
  }

  /// Check if user is eligible for tier upgrade
  Future<EcoCoinTier?> checkTierUpgrade(String userId) async {
    final balanceDoc =
        await _firestore.collection('eco_coin_balances').doc(userId).get();

    if (!balanceDoc.exists) return null;

    final balance = EcoCoinBalance.fromMap(balanceDoc.data()!, balanceDoc.id);
    final totalCoins = balance.lifetimeEarned;

    // Check if eligible for upgrade
    for (final tier in EcoCoinTier.values.reversed) {
      if (totalCoins >= tier.minCoins &&
          tier.index > balance.currentTier.index) {
        // Upgrade tier
        await _firestore.collection('eco_coin_balances').doc(userId).update({
          'currentTier': tier.name,
          'coinsToNextTier': _calculateCoinsToNextTier(totalCoins, tier),
        });
        return tier;
      }
    }

    return null;
  }

  int _calculateCoinsToNextTier(int currentCoins, EcoCoinTier currentTier) {
    final nextTierIndex = currentTier.index + 1;
    if (nextTierIndex >= EcoCoinTier.values.length) return 0;

    final nextTier = EcoCoinTier.values[nextTierIndex];
    return nextTier.minCoins - currentCoins;
  }
}
