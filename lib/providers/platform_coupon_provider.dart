// lib/providers/platform_coupon_provider.dart
// Platform Coupon & Optimizer Provider
// จัดการคูปองทั้งหมด + Auto-optimization

import 'package:flutter/foundation.dart';
import '../models/platform_coupon.dart';
import '../models/advanced_coupon.dart';
import '../models/cart_item.dart' as cart_models;
import '../services/coupon_optimizer_service.dart';
import 'dart:async';

class PlatformCouponProvider extends ChangeNotifier {
  final CouponOptimizerService _optimizerService = CouponOptimizerService();

  // ==================== STATE ====================

  // Platform coupons
  List<PlatformCoupon> _platformCoupons = [];
  final List<PlatformCoupon> _claimedCoupons = [];
  List<PlatformCoupon> _flashCoupons = [];

  // Optimization
  CouponOptimization? _currentOptimization;
  List<AdvancedCoupon> _appliedCoupons = [];

  // Recommendations
  List<AdvancedCoupon> _recommendedCoupons = [];

  // Loading states
  bool _isLoading = false;
  bool _isClaiming = false;
  bool _isOptimizing = false;

  // Error state
  String? _error;

  // Flash coupon stream
  StreamSubscription? _flashCouponsSub;

  // ==================== GETTERS ====================

  List<PlatformCoupon> get platformCoupons => _platformCoupons;
  List<PlatformCoupon> get claimedCoupons => _claimedCoupons;
  List<PlatformCoupon> get flashCoupons => _flashCoupons;

  CouponOptimization? get currentOptimization => _currentOptimization;
  List<AdvancedCoupon> get appliedCoupons => _appliedCoupons;
  double get totalSavings => _currentOptimization?.totalSavings ?? 0.0;

  List<AdvancedCoupon> get recommendedCoupons => _recommendedCoupons;

  bool get isLoading => _isLoading;
  bool get isClaiming => _isClaiming;
  bool get isOptimizing => _isOptimizing;

  String? get error => _error;

  // Flash coupon helpers
  bool get hasFlashCoupons => _flashCoupons.isNotEmpty;
  int get flashCouponCount => _flashCoupons.length;

  // ==================== INITIALIZATION ====================

  Future<void> initialize({
    String? userTier,
    int? userEcoScore,
    bool? isNewUser,
  }) async {
    await loadPlatformCoupons(
      userTier: userTier,
      userEcoScore: userEcoScore,
      isNewUser: isNewUser,
    );
    _startFlashCouponStream();
  }

  void _startFlashCouponStream() {
    _flashCouponsSub = _optimizerService.getFlashCouponsStream().listen(
      (coupons) {
        _flashCoupons = coupons;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Flash coupon stream error: $error');
      },
    );
  }

  // ==================== PLATFORM COUPONS ====================

  /// Load available platform coupons
  Future<void> loadPlatformCoupons({
    String? userTier,
    int? userEcoScore,
    bool? isNewUser,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _platformCoupons = await _optimizerService.getAvailablePlatformCoupons(
        userTier: userTier,
        userEcoScore: userEcoScore,
        isNewUser: isNewUser,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load coupons: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Claim a platform coupon
  Future<bool> claimCoupon(String couponId) async {
    _isClaiming = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _optimizerService.claimPlatformCoupon(couponId);
      if (success) {
        // Move to claimed list
        final coupon = _platformCoupons.firstWhere((c) => c.id == couponId);
        _claimedCoupons.add(coupon);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Failed to claim coupon: $e';
      notifyListeners();
      return false;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }

  // ==================== FLASH COUPONS ====================

  /// Hunt for flash coupon (limited time/quantity)
  Future<bool> huntFlashCoupon(String couponId) async {
    _isClaiming = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _optimizerService.huntFlashCoupon(couponId);
      if (success) {
        // Reload to update availability
        await loadPlatformCoupons();
      } else {
        _error = 'Flash coupon sold out!';
      }
      return success;
    } catch (e) {
      _error = 'Hunt failed: $e';
      notifyListeners();
      return false;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }

  // ==================== AUTO-OPTIMIZATION ====================

  /// Auto-apply best coupons to cart
  Future<void> optimizeCartCoupons(List<cart_models.CartItem> cartItems) async {
    if (cartItems.isEmpty) {
      _currentOptimization = null;
      _appliedCoupons = [];
      notifyListeners();
      return;
    }

    _isOptimizing = true;
    _error = null;
    notifyListeners();

    try {
      _currentOptimization =
          await _optimizerService.autoApplyBestCoupons(cartItems);
      _appliedCoupons = _currentOptimization?.coupons ?? [];
      notifyListeners();
    } catch (e) {
      _error = 'Optimization failed: $e';
      notifyListeners();
    } finally {
      _isOptimizing = false;
      notifyListeners();
    }
  }

  /// Apply specific coupons manually
  void applyManualCoupons(List<AdvancedCoupon> coupons) {
    _appliedCoupons = coupons;
    // Would recalculate optimization
    notifyListeners();
  }

  /// Clear applied coupons
  void clearAppliedCoupons() {
    _appliedCoupons = [];
    _currentOptimization = null;
    notifyListeners();
  }

  // ==================== RECOMMENDATIONS ====================

  /// Get personalized coupon recommendations
  Future<void> loadRecommendations({
    List<String>? categories,
    double? averageOrderValue,
  }) async {
    try {
      _recommendedCoupons = await _optimizerService.getRecommendedCoupons(
        categories: categories,
        averageOrderValue: averageOrderValue,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recommendations: $e');
    }
  }

  // ==================== FILTERS ====================

  /// Get coupons by type
  List<PlatformCoupon> getCouponsByType(PlatformCouponType type) {
    return _platformCoupons.where((c) => c.platformType == type).toList();
  }

  /// Get new user coupons
  List<PlatformCoupon> getNewUserCoupons() {
    return _platformCoupons.where((c) => c.isNewUserOnly).toList();
  }

  /// Get eco hero exclusive coupons
  List<PlatformCoupon> getEcoHeroCoupons() {
    return _platformCoupons
        .where((c) => c.platformType == PlatformCouponType.ecoHeroReward)
        .toList();
  }

  /// Get expiring soon coupons
  List<PlatformCoupon> getExpiringSoonCoupons({int daysThreshold = 7}) {
    final now = DateTime.now();
    return _platformCoupons.where((c) {
      if (c.endDate == null) return false;
      final daysUntilExpiry = c.endDate!.difference(now).inDays;
      return daysUntilExpiry <= daysThreshold && daysUntilExpiry >= 0;
    }).toList();
  }

  // ==================== UTILITY ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _flashCouponsSub?.cancel();
    super.dispose();
  }
}
