// test/mocks/mock_eco_coins_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/eco_coin.dart';
import 'package:green_market/services/eco_coins_service.dart';
import 'package:green_market/utils/constants.dart';

/// Professional Mock EcoCoinsService for testing
/// Simulates all service behaviors without Firebase dependency
class MockEcoCoinsService implements EcoCoinsService {
  // In-memory data storage
  EcoCoinBalance? _balance;
  final List<EcoCoin> _transactions = [];
  final List<EcoCoinMission> _missions = [];
  final List<EcoCoinMissionProgress> _missionProgress = [];

  // Stream controllers for real-time updates
  late final StreamController<EcoCoinBalance?> _balanceController;
  late final StreamController<List<EcoCoin>> _transactionsController;
  late final StreamController<List<EcoCoinMission>> _missionsController;
  late final StreamController<List<EcoCoinMissionProgress>> _progressController;

  // Test configuration
  bool shouldThrowError = false;
  String? errorMessage;
  int delayMs = 0;

  MockEcoCoinsService() {
    _initializeMockData();
    // Initialize stream controllers with onListen callback to emit initial data
    _balanceController = StreamController<EcoCoinBalance?>.broadcast(
      onListen: () => _balanceController.add(_balance),
    );
    _transactionsController = StreamController<List<EcoCoin>>.broadcast(
      onListen: () => _transactionsController.add(List.from(_transactions)),
    );
    _missionsController = StreamController<List<EcoCoinMission>>.broadcast(
      onListen: () => _missionsController.add(List.from(_missions)),
    );
    _progressController =
        StreamController<List<EcoCoinMissionProgress>>.broadcast(
      onListen: () => _progressController.add(List.from(_missionProgress)),
    );
  }

  void _initializeMockData() {
    // Initialize with default test data using correct model structure
    _balance = EcoCoinBalance(
      userId: 'test_user_123',
      totalCoins: 500,
      availableCoins: 400,
      expiredCoins: 0,
      lifetimeEarned: 1000,
      lifetimeSpent: 500,
      currentTier: EcoCoinTier.silver,
      coinsToNextTier: 500,
      lastUpdated: Timestamp.now(),
    );

    // Add sample missions with correct structure
    _missions.addAll([
      EcoCoinMission(
        id: 'mission_1',
        title: 'Daily Login',
        description: 'Login to the app',
        coinReward: 10,
        type: EcoCoinMissionType.daily,
        requiredProgress: 1,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        isActive: true,
        isRepeatable: true,
        createdAt: Timestamp.now(),
      ),
      EcoCoinMission(
        id: 'mission_2',
        title: 'Make a Purchase',
        description: 'Complete your first order',
        coinReward: 50,
        type: EcoCoinMissionType.purchase,
        requiredProgress: 1,
        validUntil:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        isActive: true,
        isRepeatable: false,
        createdAt: Timestamp.now(),
      ),
    ]);
    // Initial data will be emitted via onListen callbacks
  }

  void _emitUpdates() {
    _balanceController.add(_balance);
    _transactionsController.add(List.from(_transactions));
    _missionsController.add(List.from(_missions));
    _progressController.add(List.from(_missionProgress));
  }

  @override
  Stream<EcoCoinBalance?> getEcoCoinBalance() {
    return _balanceController.stream;
  }

  @override
  Stream<List<EcoCoin>> getEcoCoinsHistory({int limit = 50}) {
    return _transactionsController.stream
        .map((list) => list.take(limit).toList());
  }

  @override
  Stream<List<EcoCoinMission>> getAvailableMissions() {
    return _missionsController.stream;
  }

  @override
  Stream<List<EcoCoinMissionProgress>> getMissionProgress() {
    return _progressController.stream;
  }

  @override
  Future<void> awardCoins({
    required int amount,
    required String source,
    String? description,
    String? orderId,
    EcoCoinTransactionType type = EcoCoinTransactionType.earned,
  }) async {
    await _simulateDelay();
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }

    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    // Update balance
    if (_balance != null) {
      _balance = EcoCoinBalance(
        userId: _balance!.userId,
        totalCoins: _balance!.totalCoins + amount,
        availableCoins: _balance!.availableCoins + amount,
        expiredCoins: _balance!.expiredCoins,
        lifetimeEarned: _balance!.lifetimeEarned + amount,
        lifetimeSpent: _balance!.lifetimeSpent,
        currentTier: _balance!.currentTier,
        coinsToNextTier: _balance!.coinsToNextTier - amount,
        lastUpdated: Timestamp.now(),
      );
    }

    // Add transaction
    _transactions.insert(
      0,
      EcoCoin(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user_123',
        amount: amount,
        type: type,
        source: source,
        description: description,
        orderId: orderId,
        createdAt: Timestamp.now(),
      ),
    );

    // Emit updated data
    _emitUpdates();
  }

  @override
  Future<bool> spendCoins({
    required int amount,
    required String source,
    String? description,
    String? orderId,
  }) async {
    await _simulateDelay();
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }

    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    if (_balance == null || _balance!.availableCoins < amount) {
      return false;
    }

    // Update balance
    _balance = EcoCoinBalance(
      userId: _balance!.userId,
      totalCoins: _balance!.totalCoins,
      availableCoins: _balance!.availableCoins - amount,
      expiredCoins: _balance!.expiredCoins,
      lifetimeEarned: _balance!.lifetimeEarned,
      lifetimeSpent: _balance!.lifetimeSpent + amount,
      currentTier: _balance!.currentTier,
      coinsToNextTier: _balance!.coinsToNextTier,
      lastUpdated: Timestamp.now(),
    );

    // Add transaction
    _transactions.insert(
      0,
      EcoCoin(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user_123',
        amount: amount,
        type: EcoCoinTransactionType.spent,
        source: source,
        description: description,
        orderId: orderId,
        createdAt: Timestamp.now(),
      ),
    );

    // Emit updated data
    _emitUpdates();

    return true;
  }

  Future<void> updateMissionProgress({
    required String missionId,
    required int progress,
  }) async {
    await _simulateDelay();
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }

    final mission = _missions.firstWhere((m) => m.id == missionId);
    final existingIndex =
        _missionProgress.indexWhere((p) => p.missionId == missionId);

    if (existingIndex != -1) {
      _missionProgress[existingIndex] = EcoCoinMissionProgress(
        id: _missionProgress[existingIndex].id,
        userId: 'test_user_123',
        missionId: missionId,
        currentProgress: progress,
        requiredProgress: mission.requiredProgress,
        isCompleted: progress >= mission.requiredProgress,
        completedAt:
            progress >= mission.requiredProgress ? Timestamp.now() : null,
        createdAt: _missionProgress[existingIndex].createdAt,
      );
    } else {
      _missionProgress.add(
        EcoCoinMissionProgress(
          id: 'progress_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'test_user_123',
          missionId: missionId,
          currentProgress: progress,
          requiredProgress: mission.requiredProgress,
          isCompleted: progress >= mission.requiredProgress,
          completedAt:
              progress >= mission.requiredProgress ? Timestamp.now() : null,
          createdAt: Timestamp.now(),
        ),
      );
    }

    // Emit updated progress
    _emitUpdates();
  }

  @override
  Future<void> completeMission(String missionId) async {
    await _simulateDelay();
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }

    final mission = _missions.firstWhere((m) => m.id == missionId);
    await awardCoins(
      amount: mission.coinReward,
      source: 'mission_completion',
      description: 'Completed: ${mission.title}',
    );

    final progressIndex =
        _missionProgress.indexWhere((p) => p.missionId == missionId);
    if (progressIndex != -1) {
      _missionProgress[progressIndex] = EcoCoinMissionProgress(
        id: _missionProgress[progressIndex].id,
        userId: 'test_user_123',
        missionId: missionId,
        currentProgress: mission.requiredProgress,
        requiredProgress: mission.requiredProgress,
        isCompleted: true,
        completedAt: Timestamp.now(),
        createdAt: _missionProgress[progressIndex].createdAt,
      );

      // Emit updated progress
      _emitUpdates();
    }
  }

  @override
  Future<void> awardPurchaseCoins(double purchaseAmount, String orderId) async {
    final coins = (purchaseAmount * 0.01).round(); // 1% cashback
    await awardCoins(
      amount: coins,
      source: 'purchase',
      description: 'Purchase reward',
      orderId: orderId,
    );
  }

  @override
  Future<void> awardReviewCoins(String productId) async {
    await awardCoins(
      amount: 5,
      source: 'review',
      description: 'Product review reward',
    );
  }

  @override
  Future<void> awardDailyLoginCoins() async {
    await awardCoins(
      amount: 10,
      source: 'daily_login',
      description: 'Daily login reward',
    );
  }

  @override
  Future<void> awardEcoActivityCoins(
    String activityId,
    int coinsAwarded,
  ) async {
    await awardCoins(
      amount: coinsAwarded,
      source: 'eco_activity',
      description: 'Eco activity reward',
    );
  }

  // Helper methods for testing
  Future<void> _simulateDelay() async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }

  void reset() {
    _transactions.clear();
    _missions.clear();
    _missionProgress.clear();
    _initializeMockData();
    shouldThrowError = false;
    errorMessage = null;
    delayMs = 0;
  }

  void setBalance(EcoCoinBalance balance) {
    _balance = balance;
    _emitUpdates();
  }

  void dispose() {
    _balanceController.close();
    _transactionsController.close();
    _missionsController.close();
    _progressController.close();
  }

  EcoCoinBalance? getBalance() => _balance;
  List<EcoCoin> getTransactions() => List.unmodifiable(_transactions);
  List<EcoCoinMission> getMissions() => List.unmodifiable(_missions);
  List<EcoCoinMissionProgress> getProgressList() =>
      List.unmodifiable(_missionProgress);
}
