// lib/providers/eco_coins_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/eco_coin.dart';
import '../services/eco_coins_service.dart';

class EcoCoinsProvider with ChangeNotifier {
  final EcoCoinsService _ecoCoinsService = EcoCoinsService();

  EcoCoinBalance? _balance;
  List<EcoCoin> _transactions = [];
  List<EcoCoinMission> _missions = [];
  List<EcoCoinMissionProgress> _missionProgress = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  EcoCoinBalance? get balance => _balance;
  List<EcoCoin> get transactions => _transactions;
  List<EcoCoinMission> get missions => _missions;
  List<EcoCoinMissionProgress> get missionProgress => _missionProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream subscriptions
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Initialize provider with mock data only
  void initialize() {
    // Always use mock data to prevent hanging
    _loadMockData();
  }

  EcoCoinsProvider() {
    // Auto-initialize with mock data when created
    _loadMockData();
  }

  // Load mock data for development
  void _loadMockData() {
    _balance = EcoCoinsService.getMockBalance();
    _transactions = EcoCoinsService.getMockTransactions();
    _missions = EcoCoinsService.getMockMissions();
    _missionProgress = [];
    notifyListeners();
  }

  // Award coins (for testing purposes)
  Future<void> awardCoins({
    required int amount,
    required String source,
    String? description,
    String? orderId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _ecoCoinsService.awardCoins(
        amount: amount,
        source: source,
        description: description,
        orderId: orderId,
      );

      // Show success animation or notification here if needed
    } catch (e) {
      _setError('Failed to award coins: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Spend coins
  Future<bool> spendCoins({
    required int amount,
    required String source,
    String? description,
    String? orderId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _ecoCoinsService.spendCoins(
        amount: amount,
        source: source,
        description: description,
        orderId: orderId,
      );

      return success;
    } catch (e) {
      _setError('Failed to spend coins: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete mission
  Future<void> completeMission(String missionId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _ecoCoinsService.completeMission(missionId);

      // Show success animation or notification here if needed
    } catch (e) {
      _setError('Failed to complete mission: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods for common scenarios
  Future<void> awardPurchaseCoins(double purchaseAmount, String orderId) async {
    await _ecoCoinsService.awardPurchaseCoins(purchaseAmount, orderId);
  }

  Future<void> awardReviewCoins(String productId) async {
    await _ecoCoinsService.awardReviewCoins(productId);
  }

  Future<void> awardDailyLoginCoins() async {
    await _ecoCoinsService.awardDailyLoginCoins();
  }

  Future<void> awardEcoActivityCoins(
      String activityType, int coinAmount) async {
    await _ecoCoinsService.awardEcoActivityCoins(activityType, coinAmount);
  }

  // Get mission progress for specific mission
  EcoCoinMissionProgress? getMissionProgressById(String missionId) {
    try {
      return _missionProgress.firstWhere(
        (progress) => progress.missionId == missionId,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if mission is completed
  bool isMissionCompleted(String missionId) {
    final progress = getMissionProgressById(missionId);
    return progress?.isCompleted ?? false;
  }

  // Get available missions (not completed or repeatable)
  List<EcoCoinMission> get availableMissions {
    return _missions.where((mission) {
      if (mission.isRepeatable) return true;
      return !isMissionCompleted(mission.id);
    }).toList();
  }

  // Get completed missions
  List<EcoCoinMission> get completedMissions {
    return _missions.where((mission) {
      return isMissionCompleted(mission.id);
    }).toList();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Refresh all data
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      initialize();
    } else {
      _loadMockData();
    }
  }
}
