// lib/providers/eco_coins_enhanced_provider.dart
// Enhanced Eco Coins Provider - Gamification Features
// เธ—เธณเธเธฒเธเธฃเนเธงเธกเธเธฑเธ EcoCoinProvider เน€เธ”เธดเธก เน€เธเธดเนเธกเธเธตเน€เธเธญเธฃเนเนเธซเธกเน

import 'package:flutter/foundation.dart';
import '../models/eco_coin.dart';
import '../models/eco_coin_enhanced.dart';
import '../services/eco_coins_enhanced_service.dart';
import '../utils/constants.dart';
import 'dart:async';

class EcoCoinsEnhancedProvider extends ChangeNotifier {
  final EcoCoinsEnhancedService _enhancedService = EcoCoinsEnhancedService();

  // ==================== STATE ====================

  // Check-in state
  DailyCheckIn? _todayCheckIn;
  List<DailyCheckIn> _checkInHistory = [];
  int _currentStreak = 0;
  bool _hasCheckedInToday = false;

  // Mini game state
  MiniGameReward? _lastGameReward;
  bool _hasPlayedGameToday = false;
  int _totalGamesPlayed = 0;

  // Redemption state
  List<RedemptionReward> _rewardCatalog = [];
  List<RedemptionRecord> _redemptionHistory = [];

  // Tier state
  EcoCoinTier _currentTier = EcoCoinTier.bronze;
  TierBenefits? _currentTierBenefits;

  // Loading states
  bool _isLoadingCheckIn = false;
  bool _isLoadingGame = false;
  bool _isLoadingRewards = false;
  bool _isRedeeming = false;

  // Error state
  String? _error;

  // ==================== GETTERS ====================

  // Check-in getters
  DailyCheckIn? get todayCheckIn => _todayCheckIn;
  List<DailyCheckIn> get checkInHistory => _checkInHistory;
  int get currentStreak => _currentStreak;
  bool get hasCheckedInToday => _hasCheckedInToday;

  // Game getters
  MiniGameReward? get lastGameReward => _lastGameReward;
  bool get hasPlayedGameToday => _hasPlayedGameToday;
  int get totalGamesPlayed => _totalGamesPlayed;

  // Redemption getters
  List<RedemptionReward> get rewardCatalog => _rewardCatalog;
  List<RedemptionRecord> get redemptionHistory => _redemptionHistory;

  // Tier getters
  EcoCoinTier get currentTier => _currentTier;
  TierBenefits? get currentTierBenefits => _currentTierBenefits;
  double get tierMultiplier => _currentTierBenefits?.coinEarnMultiplier ?? 1.0;

  // Loading getters
  bool get isLoadingCheckIn => _isLoadingCheckIn;
  bool get isLoadingGame => _isLoadingGame;
  bool get isLoadingRewards => _isLoadingRewards;
  bool get isRedeeming => _isRedeeming;

  String? get error => _error;

  // UI Helper getters
  List<RedemptionReward> get availableRewards => _rewardCatalog.where((r) => (r.stock ?? 0) > 0).toList();
  double get ecoCoinBalance => 0.0; // Placeholder

  // ==================== INITIALIZATION ====================

  Future<void> initialize(String userId) async {
    await Future.wait([
      loadCheckInStatus(),
      loadGameStatus(),
      loadRewardCatalog(),
      loadTierInfo(userId),
    ]);
  }

  // ==================== CHECK-IN FEATURES ====================

  /// Load today's check-in status
  Future<void> loadCheckInStatus() async {
    _isLoadingCheckIn = true;
    _error = null;
    notifyListeners();

    try {
      _hasCheckedInToday = await _enhancedService.hasCheckedInToday();

      final historyStream = _enhancedService.getCheckInHistory();
      historyStream.listen((history) {
        _checkInHistory = history;
        if (history.isNotEmpty) {
          _currentStreak = history.first.streakCount;
          if (_isSameDay(history.first.checkInDate, DateTime.now())) {
            _todayCheckIn = history.first;
          }
        }
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load check-in status: $e';
    } finally {
      _isLoadingCheckIn = false;
      notifyListeners();
    }
  }

  /// Perform daily check-in
  Future<bool> performCheckIn() async {
    if (_hasCheckedInToday) return false;

    _isLoadingCheckIn = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _enhancedService.performDailyCheckIn();
      if (result != null) {
        _todayCheckIn = result;
        _hasCheckedInToday = true;
        _currentStreak = result.streakCount;
        _checkInHistory.insert(0, result);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Check-in failed: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoadingCheckIn = false;
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ==================== MINI GAME FEATURES ====================

  /// Load game status
  Future<void> loadGameStatus() async {
    _isLoadingGame = true;
    notifyListeners();

    try {
      // Load from service (could be cached in Firestore)
      _hasPlayedGameToday = false; // Would check from service
      _totalGamesPlayed = 0; // Would load from user stats
    } catch (e) {
      _error = 'Failed to load game status: $e';
    } finally {
      _isLoadingGame = false;
      notifyListeners();
    }
  }

  /// Play spin wheel game
  Future<MiniGameReward?> playSpinWheel() async {
    if (_hasPlayedGameToday) return null;

    _isLoadingGame = true;
    _error = null;
    notifyListeners();

    try {
      final reward = await _enhancedService.playSpinWheel();
      _lastGameReward = reward;
      _hasPlayedGameToday = true;
      _totalGamesPlayed++;
      notifyListeners();
      return reward;
    } catch (e) {
      _error = 'Game failed: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoadingGame = false;
      notifyListeners();
    }
  }

  // ==================== AUTO-EARN TRACKING ====================

  /// Track auto-earn trigger
  Future<void> trackAutoEarn(AutoEarnTrigger trigger) async {
    try {
      await _enhancedService.trackAutoEarn(trigger);
      // No UI update needed, happens in background
    } catch (e) {
      debugPrint('Auto-earn tracking failed: $e');
    }
  }

  // ==================== REDEMPTION FEATURES ====================

  /// Load reward catalog
  Future<void> loadRewardCatalog() async {
    _isLoadingRewards = true;
    notifyListeners();

    try {
      final catalogStream = _enhancedService.getRedemptionCatalog();
      catalogStream.listen((catalog) {
        _rewardCatalog = catalog;
        notifyListeners();
      });

      final historyStream = _enhancedService.getRedemptionHistory();
      historyStream.listen((history) {
        _redemptionHistory = history;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load rewards: $e';
    } finally {
      _isLoadingRewards = false;
      notifyListeners();
    }
  }

  /// Redeem a reward
  Future<bool> redeemReward(String rewardId) async {
    _isRedeeming = true;
    _error = null;
    notifyListeners();

    try {
      final record = await _enhancedService.redeemReward(rewardId);
      _redemptionHistory.insert(0, record);

      // Update catalog stock
      final rewardIndex = _rewardCatalog.indexWhere((r) => r.id == rewardId);
      if (rewardIndex != -1) {
        final reward = _rewardCatalog[rewardIndex];
        if (reward.stock != null) {
          _rewardCatalog[rewardIndex] = RedemptionReward(
            id: reward.id,
            name: reward.name,
            description: reward.description,
            category: reward.category,
            coinsCost: reward.coinsCost,
            imageUrl: reward.imageUrl,
            stock: reward.stock! - 1,
            isActive: reward.isActive,
            validUntil: reward.validUntil,
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Redemption failed: $e';
      notifyListeners();
      return false;
    } finally {
      _isRedeeming = false;
      notifyListeners();
    }
  }

  // ==================== TIER SYSTEM ====================

  /// Load user's tier information
  Future<void> loadTierInfo(String userId) async {
    try {
      final newTier = await _enhancedService.checkTierUpgrade(userId);
      if (newTier != null && newTier != _currentTier) {
        _currentTier = newTier;
      }
      _currentTierBenefits = _enhancedService.getTierBenefits(_currentTier);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load tier info: $e');
    }
  }

  /// Calculate coins with tier multiplier
  int calculateCoinsWithBonus(int baseCoins) {
    return _enhancedService.calculateCoinsWithMultiplier(
      baseCoins,
      _currentTier,
    );
  }

  // ==================== UTILITY ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
