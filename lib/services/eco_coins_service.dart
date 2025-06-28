// lib/services/eco_coins_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/eco_coin.dart';
import '../utils/constants.dart';

class EcoCoinsService {
  static final EcoCoinsService _instance = EcoCoinsService._internal();
  factory EcoCoinsService() => _instance;
  EcoCoinsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's Eco Coins balance
  Stream<EcoCoinBalance?> getEcoCoinBalance() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('eco_coin_balances')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        // สร้าง balance เริ่มต้นถ้ายังไม่มี
        _createInitialBalance(user.uid);
        return _getInitialBalance(user.uid);
      }
      return EcoCoinBalance.fromMap(doc.data()!, doc.id);
    });
  }

  // Get user's Eco Coins transaction history
  Stream<List<EcoCoin>> getEcoCoinsHistory({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('eco_coins')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EcoCoin.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get available missions for user
  Stream<List<EcoCoinMission>> getAvailableMissions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('eco_coin_missions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EcoCoinMission.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get user's mission progress
  Stream<List<EcoCoinMissionProgress>> getMissionProgress() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('eco_coin_mission_progress')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EcoCoinMissionProgress.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Award coins to user
  Future<void> awardCoins({
    required int amount,
    required String source,
    String? description,
    String? orderId,
    EcoCoinTransactionType type = EcoCoinTransactionType.earned,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // สร้าง transaction record
    final transactionRef = _firestore.collection('eco_coins').doc();
    final transaction = EcoCoin(
      id: transactionRef.id,
      userId: user.uid,
      amount: amount,
      type: type,
      source: source,
      description: description,
      orderId: orderId,
      createdAt: Timestamp.now(),
      expiredAt: type == EcoCoinTransactionType.earned
          ? Timestamp.fromDate(DateTime.now()
              .add(const Duration(days: 365))) // เหลียญหมดอายุใน 1 ปี
          : null,
    );

    batch.set(transactionRef, transaction.toMap());

    // อัพเดท balance
    final balanceRef = _firestore.collection('eco_coin_balances').doc(user.uid);
    batch.update(balanceRef, {
      'availableCoins': FieldValue.increment(amount),
      'totalCoins': FieldValue.increment(amount),
      'lifetimeEarned': FieldValue.increment(amount),
      'lastUpdated': Timestamp.now(),
    });

    await batch.commit();
  }

  // Spend coins
  Future<bool> spendCoins({
    required int amount,
    required String source,
    String? description,
    String? orderId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // ตรวจสอบว่ามีเหลียญเพียงพอหรือไม่
    final balanceDoc =
        await _firestore.collection('eco_coin_balances').doc(user.uid).get();

    if (!balanceDoc.exists) return false;

    final balance = EcoCoinBalance.fromMap(balanceDoc.data()!, balanceDoc.id);
    if (balance.availableCoins < amount) return false;

    final batch = _firestore.batch();

    // สร้าง transaction record
    final transactionRef = _firestore.collection('eco_coins').doc();
    final transaction = EcoCoin(
      id: transactionRef.id,
      userId: user.uid,
      amount: -amount, // ค่าลบสำหรับการใช้จ่าย
      type: EcoCoinTransactionType.spent,
      source: source,
      description: description,
      orderId: orderId,
      createdAt: Timestamp.now(),
    );

    batch.set(transactionRef, transaction.toMap());

    // อัพเดท balance
    final balanceRef = _firestore.collection('eco_coin_balances').doc(user.uid);
    batch.update(balanceRef, {
      'availableCoins': FieldValue.increment(-amount),
      'lifetimeSpent': FieldValue.increment(amount),
      'lastUpdated': Timestamp.now(),
    });

    await batch.commit();
    return true;
  }

  // Create initial balance for new user
  Future<void> _createInitialBalance(String userId) async {
    final balanceRef = _firestore.collection('eco_coin_balances').doc(userId);
    final initialBalance = EcoCoinBalance(
      userId: userId,
      totalCoins: 0,
      availableCoins: 0,
      expiredCoins: 0,
      lifetimeEarned: 0,
      lifetimeSpent: 0,
      currentTier: EcoCoinsConfig.tiers.first,
      coinsToNextTier: EcoCoinsConfig.tiers.length > 1
          ? EcoCoinsConfig.tiers[1].minCoins
          : 0,
      lastUpdated: Timestamp.now(),
    );

    await balanceRef.set(initialBalance.toMap());
  }

  // Get initial balance for new user
  EcoCoinBalance _getInitialBalance(String userId) {
    return EcoCoinBalance(
      userId: userId,
      totalCoins: 0,
      availableCoins: 0,
      expiredCoins: 0,
      lifetimeEarned: 0,
      lifetimeSpent: 0,
      currentTier: EcoCoinsConfig.tiers.first,
      coinsToNextTier: EcoCoinsConfig.tiers.length > 1
          ? EcoCoinsConfig.tiers[1].minCoins
          : 0,
      lastUpdated: Timestamp.now(),
    );
  }

  // Complete mission and award coins
  Future<void> completeMission(String missionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get mission details
    final missionDoc =
        await _firestore.collection('eco_coin_missions').doc(missionId).get();

    if (!missionDoc.exists) throw Exception('Mission not found');

    final mission = EcoCoinMission.fromMap(missionDoc.data()!, missionDoc.id);

    // Check if mission is already completed
    final progressQuery = await _firestore
        .collection('eco_coin_mission_progress')
        .where('userId', isEqualTo: user.uid)
        .where('missionId', isEqualTo: missionId)
        .where('isCompleted', isEqualTo: true)
        .get();

    if (progressQuery.docs.isNotEmpty && !mission.isRepeatable) {
      throw Exception('Mission already completed');
    }

    final batch = _firestore.batch();

    // Award coins
    await awardCoins(
      amount: mission.coinReward,
      source: 'mission_${mission.type.name}',
      description: 'ภารกิจ: ${mission.title}',
    );

    // Update mission progress
    final progressRef =
        _firestore.collection('eco_coin_mission_progress').doc();
    final progress = EcoCoinMissionProgress(
      id: progressRef.id,
      userId: user.uid,
      missionId: missionId,
      currentProgress: mission.requiredProgress,
      requiredProgress: mission.requiredProgress,
      isCompleted: true,
      completedAt: Timestamp.now(),
      createdAt: Timestamp.now(),
    );

    batch.set(progressRef, progress.toMap());
    await batch.commit();
  }

  // Helper methods for common coin earning scenarios
  Future<void> awardPurchaseCoins(double purchaseAmount, String orderId) async {
    final coinsEarned =
        (purchaseAmount / 100 * EcoCoinsConfig.coinsPer100Baht).floor();
    if (coinsEarned > 0) {
      await awardCoins(
        amount: coinsEarned,
        source: 'purchase',
        description: 'ซื้อสินค้า ฿${purchaseAmount.toStringAsFixed(2)}',
        orderId: orderId,
      );
    }
  }

  Future<void> awardReviewCoins(String productId) async {
    await awardCoins(
      amount: EcoCoinsConfig.coinsForReview,
      source: 'review',
      description: 'รีวิวสินค้า',
      orderId: productId,
    );
  }

  Future<void> awardDailyLoginCoins() async {
    await awardCoins(
      amount: EcoCoinsConfig.dailyLoginCoins,
      source: 'daily_login',
      description: 'เข้าสู่ระบบรายวัน',
    );
  }

  Future<void> awardEcoActivityCoins(
      String activityType, int coinAmount) async {
    await awardCoins(
      amount: coinAmount,
      source: 'eco_activity',
      description: 'กิจกรรมเพื่อสิ่งแวดล้อม: $activityType',
    );
  }

  // Mock data methods for development (ใช้เมื่อยังไม่มี user login)
  static EcoCoinBalance getMockBalance() {
    return EcoCoinBalance(
      userId: 'mock_user',
      totalCoins: 1250,
      availableCoins: 1250,
      expiredCoins: 0,
      lifetimeEarned: 2500,
      lifetimeSpent: 1250,
      currentTier: EcoCoinTier.getCurrentTier(1250),
      coinsToNextTier: EcoCoinTier.getNextTier(1250)?.minCoins != null
          ? EcoCoinTier.getNextTier(1250)!.minCoins - 1250
          : 0,
      lastUpdated: Timestamp.now(),
    );
  }

  static List<EcoCoin> getMockTransactions() {
    return [
      EcoCoin(
        id: 'mock_1',
        userId: 'mock_user',
        amount: 50,
        type: EcoCoinTransactionType.earned,
        source: 'purchase',
        description: 'ซื้อสินค้า ฿500.00',
        createdAt: Timestamp.now(),
      ),
      EcoCoin(
        id: 'mock_2',
        userId: 'mock_user',
        amount: 20,
        type: EcoCoinTransactionType.earned,
        source: 'eco_activity',
        description: 'กิจกรรมรีไซเคิล',
        createdAt: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      ),
      EcoCoin(
        id: 'mock_3',
        userId: 'mock_user',
        amount: -100,
        type: EcoCoinTransactionType.spent,
        source: 'discount',
        description: 'ใช้ส่วนลด ฿10',
        createdAt: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2))),
      ),
    ];
  }

  static List<EcoCoinMission> getMockMissions() {
    return [
      EcoCoinMission(
        id: 'mock_mission_1',
        title: 'ซื้อสินค้าเพื่อสิ่งแวดล้อม',
        description: 'ซื้อสินค้าที่มี Eco Level สูง 3 รายการ',
        coinReward: 50,
        type: EcoCoinMissionType.purchase,
        requiredProgress: 3,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        isActive: true,
        isRepeatable: false,
        createdAt: Timestamp.now(),
      ),
      EcoCoinMission(
        id: 'mock_mission_2',
        title: 'เช็คอินรายวัน',
        description: 'เข้าสู่ระบบติดต่อกัน 7 วัน',
        coinReward: 100,
        type: EcoCoinMissionType.daily,
        requiredProgress: 7,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        isActive: true,
        isRepeatable: true,
        createdAt: Timestamp.now(),
      ),
      EcoCoinMission(
        id: 'mock_mission_3',
        title: 'รีวิว 5 ดาว',
        description: 'ให้คะแนนรีวิวสินค้า 5 ครั้ง',
        coinReward: 25,
        type: EcoCoinMissionType.review,
        requiredProgress: 5,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        isActive: true,
        isRepeatable: false,
        createdAt: Timestamp.now(),
      ),
    ];
  }
}
