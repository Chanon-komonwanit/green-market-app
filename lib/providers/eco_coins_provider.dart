/// EcoCoinsProvider
/// Provider สำหรับจัดการระบบ Eco Coins, mission, balance, และ transaction
/// - ใช้ร่วมกับ EcoCoinsService
library;

// lib/providers/eco_coins_provider.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/eco_coin.dart';
import '../services/eco_coins_service.dart';
import '../utils/enhanced_error_handler.dart';
import '../utils/constants.dart';

/// EcoCoinProvider จัดการระบบ Eco Coins ทั้งหมด
/// เสมือนระบบธนาคารสิ่งแวดล้อม รวมถึงการจัดการภารกิจ และประวัติการทำธุรกรรม
/// พร้อมด้วยระบบการจัดการข้อผิดพลาดและการป้องกันความปลอดภัยขั้นสูง
class EcoCoinProvider extends ChangeNotifier {
  final EcoCoinsService _ecoCoinsService;
  final EnhancedErrorHandler _errorHandler = EnhancedErrorHandler();

  /// Constructor with dependency injection support
  /// Allows injecting a custom EcoCoinsService for testing
  EcoCoinProvider({EcoCoinsService? ecoCoinsService})
      : _ecoCoinsService = ecoCoinsService ?? EcoCoinsService();

  EcoCoinBalance? _balance;
  List<EcoCoin> _transactions = [];
  List<EcoCoinMission> _missions = [];
  List<EcoCoinMissionProgress> _missionProgress = [];

  bool _isLoading = false;
  String? _error;
  DateTime? _lastRefresh;
  Timer? _autoRefreshTimer;

  // Stream subscriptions for real-time updates
  StreamSubscription<EcoCoinBalance?>? _balanceSubscription;
  StreamSubscription<List<EcoCoin>>? _transactionsSubscription;
  StreamSubscription<List<EcoCoinMission>>? _missionsSubscription;
  StreamSubscription<List<EcoCoinMissionProgress>>? _progressSubscription;

  // Enhanced Security & Performance Features
  int _consecutiveFailures = 0;
  static const int maxConsecutiveFailures = 3;
  bool _isNetworkAvailable = true;
  final List<String> _pendingOperations = [];

  // Constants for better performance and error handling
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static const Duration _autoRefreshInterval = Duration(minutes: 10);
  static const Duration _operationTimeout = Duration(seconds: 30);

  // Getters
  EcoCoinBalance? get balance => _balance;
  List<EcoCoin> get transactions => _transactions;
  List<EcoCoin> get transactionsSafe => List.unmodifiable(_transactions);
  List<EcoCoinMission> get missions => _missions;
  List<EcoCoinMission> get missionsSafe => List.unmodifiable(_missions);
  List<EcoCoinMissionProgress> get missionProgress => _missionProgress;
  List<EcoCoinMissionProgress> get missionProgressSafe =>
      List.unmodifiable(_missionProgress);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isHealthy =>
      !hasError && _consecutiveFailures < maxConsecutiveFailures;
  bool get canPerformOperations => isHealthy && _isNetworkAvailable;

  // Enhanced Getters
  int get totalCoins => _balance?.totalCoins ?? 0;
  int get availableCoins => _balance?.availableCoins ?? 0;
  EcoCoinTier get currentTier => _balance?.currentTier ?? EcoCoinTier.bronze;
  bool get isCacheExpired =>
      _lastRefresh == null ||
      DateTime.now().difference(_lastRefresh!).compareTo(_cacheTimeout) > 0;

  /// Enhanced security loading state management
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Enhanced error handling with retry logic and security measures
  void _setError(String? error) {
    if (error != null) {
      _consecutiveFailures++;

      // Use the appropriate error handler method
      _errorHandler.handlePlatformError(
        Exception(error),
        StackTrace.current,
      );

      // Implement circuit breaker pattern
      if (_consecutiveFailures >= maxConsecutiveFailures) {
        _isNetworkAvailable = false;
        _scheduleRecovery();
      }
    } else {
      _consecutiveFailures = 0;
      _isNetworkAvailable = true;
    }

    _error = error;
    notifyListeners();
  }

  /// Schedule recovery attempt for circuit breaker pattern
  void _scheduleRecovery() {
    Timer(const Duration(minutes: 5), () {
      _consecutiveFailures = 0;
      _isNetworkAvailable = true;
      _setError(null);
    });
  }

  /// Start auto-refresh timer for enhanced data freshness
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      if (!_isLoading && canPerformOperations) {
        refresh();
      }
    });
  }

  /// Enhanced operation wrapper with timeout and validation
  Future<T?> _performOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration? timeout,
  }) async {
    if (!canPerformOperations) {
      throw Exception(
          'Operations temporarily disabled due to consecutive failures');
    }

    if (_pendingOperations.contains(operationName)) {
      throw Exception('Operation $operationName is already in progress');
    }

    _pendingOperations.add(operationName);
    try {
      return await operation().timeout(timeout ?? _operationTimeout);
    } catch (e) {
      _setError('$operationName failed: $e');
      return null;
    } finally {
      _pendingOperations.remove(operationName);
    }
  }

  /// Enhanced initialization with comprehensive error handling
  Future<void> initialize() async {
    await _performOperation('initialize', () async {
      _lastRefresh = DateTime.now();

      // Create completers to wait for initial data
      final balanceCompleter = Completer<void>();
      final transactionsCompleter = Completer<void>();
      final missionsCompleter = Completer<void>();
      final progressCompleter = Completer<void>();

      // Subscribe to real-time streams from service
      _balanceSubscription = _ecoCoinsService.getEcoCoinBalance().listen(
        (balance) {
          _balance = balance;
          if (!balanceCompleter.isCompleted) balanceCompleter.complete();
          notifyListeners();
        },
        onError: (error) => _setError('Balance stream error: $error'),
      );

      _transactionsSubscription = _ecoCoinsService.getEcoCoinsHistory().listen(
        (transactions) {
          _transactions = transactions;
          if (!transactionsCompleter.isCompleted)
            transactionsCompleter.complete();
          notifyListeners();
        },
        onError: (error) => _setError('Transactions stream error: $error'),
      );

      _missionsSubscription = _ecoCoinsService.getAvailableMissions().listen(
        (missions) {
          _missions = missions;
          if (!missionsCompleter.isCompleted) missionsCompleter.complete();
          notifyListeners();
        },
        onError: (error) => _setError('Missions stream error: $error'),
      );

      _progressSubscription = _ecoCoinsService.getMissionProgress().listen(
        (progress) {
          _missionProgress = progress;
          if (!progressCompleter.isCompleted) progressCompleter.complete();
          notifyListeners();
        },
        onError: (error) => _setError('Progress stream error: $error'),
      );

      _startAutoRefresh();

      // Wait for initial data from all streams with timeout
      try {
        await Future.wait([
          balanceCompleter.future,
          transactionsCompleter.future,
          missionsCompleter.future,
          progressCompleter.future,
        ]).timeout(const Duration(seconds: 2));
      } catch (e) {
        print('Warning: Timeout waiting for initial stream data: $e');
      }
    });
  }

  /// Enhanced award coins with comprehensive validation and error handling
  Future<void> awardCoins({
    required int amount,
    required String source,
    String? description,
    String? orderId,
  }) async {
    // Enhanced input validation
    if (amount <= 0) {
      _setError('Invalid coin amount: must be greater than 0');
      return;
    }

    if (source.trim().isEmpty) {
      _setError('Source cannot be empty');
      return;
    }

    await _performOperation('awardCoins', () async {
      _setLoading(true);
      _setError(null);

      await _ecoCoinsService.awardCoins(
        amount: amount,
        source: source,
        description: description,
        orderId: orderId,
      );

      // Refresh data after successful operation
      // Stream will auto-update balance
    });

    _setLoading(false);
  }

  /// Enhanced spend coins with comprehensive validation and error handling
  Future<bool> spendCoins({
    required int amount,
    required String source,
    String? description,
    String? orderId,
  }) async {
    // Enhanced input validation
    if (amount <= 0) {
      _setError('Invalid coin amount: must be greater than 0');
      return false;
    }

    if (source.trim().isEmpty) {
      _setError('Source cannot be empty');
      return false;
    }

    if (amount > availableCoins) {
      _setError(
          'Insufficient coins. Available: $availableCoins, Required: $amount');
      return false;
    }

    final result = await _performOperation('spendCoins', () async {
      _setLoading(true);
      _setError(null);

      final success = await _ecoCoinsService.spendCoins(
        amount: amount,
        source: source,
        description: description,
        orderId: orderId,
      );

      if (success) {
        // Stream will auto-update balance
      }

      return success;
    });

    _setLoading(false);
    return result ?? false;
  }

  /// Enhanced complete mission with validation
  Future<void> completeMission(String missionId) async {
    if (missionId.trim().isEmpty) {
      _setError('Mission ID cannot be empty');
      return;
    }

    // Check if mission exists and is available
    final mission = _missions.where((m) => m.id == missionId).firstOrNull;
    if (mission == null) {
      _setError('Mission not found');
      return;
    }

    if (isMissionCompleted(missionId)) {
      _setError('Mission already completed');
      return;
    }

    await _performOperation('completeMission', () async {
      _setLoading(true);
      _setError(null);

      await _ecoCoinsService.completeMission(missionId);
      // Stream will auto-update balance
    });

    _setLoading(false);
  }

  /// Enhanced helper methods for common scenarios with validation
  Future<void> awardPurchaseCoins(double purchaseAmount, String orderId) async {
    if (purchaseAmount <= 0) {
      _setError('Invalid purchase amount: must be greater than 0');
      return;
    }

    if (orderId.trim().isEmpty) {
      _setError('Order ID cannot be empty');
      return;
    }

    await _performOperation('awardPurchaseCoins', () async {
      await _ecoCoinsService.awardPurchaseCoins(purchaseAmount, orderId);
      // Stream will auto-update balance
    });
  }

  Future<void> awardReviewCoins(String productId) async {
    if (productId.trim().isEmpty) {
      _setError('Product ID cannot be empty');
      return;
    }

    await _performOperation('awardReviewCoins', () async {
      await _ecoCoinsService.awardReviewCoins(productId);
      // Stream will auto-update balance
    });
  }

  Future<void> awardDailyLoginCoins() async {
    await _performOperation('awardDailyLoginCoins', () async {
      await _ecoCoinsService.awardDailyLoginCoins();
      // Stream will auto-update balance
    });
  }

  Future<void> awardEcoActivityCoins(
      String activityType, int coinAmount) async {
    if (activityType.trim().isEmpty) {
      _setError('Activity type cannot be empty');
      return;
    }

    if (coinAmount <= 0) {
      _setError('Coin amount must be greater than 0');
      return;
    }

    await _performOperation('awardEcoActivityCoins', () async {
      await _ecoCoinsService.awardEcoActivityCoins(activityType, coinAmount);
      // Stream will auto-update balance
    });
  }

  /// Enhanced get mission progress with validation
  EcoCoinMissionProgress? getMissionProgressById(String missionId) {
    if (missionId.trim().isEmpty) {
      return null;
    }

    try {
      return _missionProgress.firstWhere(
        (progress) => progress.missionId == missionId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Enhanced mission completion check with validation
  bool isMissionCompleted(String missionId) {
    if (missionId.trim().isEmpty) {
      return false;
    }

    final progress = getMissionProgressById(missionId);
    return progress?.isCompleted ?? false;
  }

  /// Enhanced available missions with filtering and validation
  List<EcoCoinMission> get availableMissions {
    return _missions.where((mission) {
      // Check if mission is active and not expired
      if (!mission.isActive ||
          mission.validUntil.toDate().isBefore(DateTime.now())) {
        return false;
      }

      if (mission.isRepeatable) return true;
      return !isMissionCompleted(mission.id);
    }).toList();
  }

  /// Enhanced completed missions with validation
  List<EcoCoinMission> get completedMissions {
    return _missions.where((mission) {
      return isMissionCompleted(mission.id);
    }).toList();
  }

  /// Enhanced clear error with additional cleanup
  void clearError() {
    _setError(null);
    if (!_isNetworkAvailable && _consecutiveFailures < maxConsecutiveFailures) {
      _isNetworkAvailable = true;
    }
  }

  /// Enhanced refresh with cache management and error handling
  Future<void> refresh() async {
    if (_isLoading) {
      return; // Prevent multiple refresh calls
    }

    await _performOperation('refresh', () async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await initialize();
        } else {
          // For tests without Firebase, just update timestamp
          _lastRefresh = DateTime.now();
          notifyListeners();
        }
      } catch (e) {
        // Firebase not initialized - handle gracefully for tests
        _lastRefresh = DateTime.now();
        notifyListeners();
      }
    });
  }

  /// Enhanced dispose with cleanup
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _balanceSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _missionsSubscription?.cancel();
    _progressSubscription?.cancel();
    _pendingOperations.clear();
    super.dispose();
  }

  /// Additional utility methods for enhanced functionality

  /// Check if user can afford a certain amount of coins
  bool canAfford(int amount) {
    return availableCoins >= amount;
  }

  /// Get tier progress percentage
  double get tierProgressPercentage {
    final nextTier = currentTier.getNextTier();
    if (nextTier == null) return 1.0; // Max tier reached

    final currentTierMinCoins = currentTier.minCoins;
    final nextTierMinCoins = nextTier.minCoins;
    final userCoins = totalCoins;

    if (userCoins <= currentTierMinCoins) return 0.0;

    final progress = (userCoins - currentTierMinCoins) /
        (nextTierMinCoins - currentTierMinCoins);
    return progress.clamp(0.0, 1.0);
  }

  /// Get recent transactions (last 10)
  List<EcoCoin> get recentTransactions {
    final sortedTransactions = List<EcoCoin>.from(_transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedTransactions.take(10).toList();
  }

  /// Get transactions by type
  List<EcoCoin> getTransactionsByType(EcoCoinTransactionType type) {
    return _transactions
        .where((transaction) => transaction.type == type)
        .toList();
  }

  /// Calculate total coins earned this month
  int get coinsEarnedThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _transactions
        .where((transaction) =>
            transaction.type == EcoCoinTransactionType.earned &&
            transaction.createdAt.toDate().isAfter(startOfMonth))
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  /// Calculate total coins spent this month
  int get coinsSpentThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _transactions
        .where((transaction) =>
            transaction.type == EcoCoinTransactionType.spent &&
            transaction.createdAt.toDate().isAfter(startOfMonth))
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }
}
