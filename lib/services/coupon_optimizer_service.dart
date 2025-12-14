// lib/services/coupon_optimizer_service.dart
// Smart Coupon Optimization Engine - Auto-apply best coupons
// ขยายจาก CouponProvider เดิม เพิ่ม AI-powered optimization

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/advanced_coupon.dart';
import '../models/platform_coupon.dart';
import '../models/user_coupon.dart';
import '../models/shop_customization.dart';
import '../models/cart_item.dart' as cart_models;

class CouponOptimizer {
  final List<AdvancedCoupon> applicableCoupons;
  final List<cart_models.CartItem> cartItems;
  final double subtotal;

  CouponOptimizer({
    required this.applicableCoupons,
    required this.cartItems,
    required this.subtotal,
  });

  /// Find best single coupon
  CouponOptimization findBestSingle() {
    CouponOptimization? best;
    double maxSavings = 0;

    for (final coupon in applicableCoupons) {
      final optimization = _calculateOptimization([coupon]);
      if (optimization.totalSavings > maxSavings) {
        maxSavings = optimization.totalSavings;
        best = optimization;
      }
    }

    return best ?? CouponOptimization(coupons: [], totalSavings: 0);
  }

  /// Find best combination (stackable coupons)
  CouponOptimization findBestCombination() {
    final stackable = applicableCoupons.where((c) => c.stackable).toList();
    final nonStackable = applicableCoupons.where((c) => !c.stackable).toList();

    CouponOptimization? best;
    double maxSavings = 0;

    // Try all stackable combinations
    final combinations = _generateCombinations(stackable);
    for (final combo in combinations) {
      final optimization = _calculateOptimization(combo);
      if (optimization.totalSavings > maxSavings) {
        maxSavings = optimization.totalSavings;
        best = optimization;
      }
    }

    // Try each non-stackable alone
    for (final coupon in nonStackable) {
      final optimization = _calculateOptimization([coupon]);
      if (optimization.totalSavings > maxSavings) {
        maxSavings = optimization.totalSavings;
        best = optimization;
      }
    }

    return best ?? CouponOptimization(coupons: [], totalSavings: 0);
  }

  /// Calculate optimization for specific coupons
  CouponOptimization _calculateOptimization(List<AdvancedCoupon> coupons) {
    double totalSavings = 0;
    double currentSubtotal = subtotal;
    final breakdown = <CouponSavingsDetail>[];

    // Sort by priority
    coupons.sort((a, b) => b.priority.compareTo(a.priority));

    for (final coupon in coupons) {
      final savings = _calculateCouponSavings(coupon, currentSubtotal);
      if (savings > 0) {
        totalSavings += savings;
        currentSubtotal -= savings;
        breakdown.add(CouponSavingsDetail(
          coupon: coupon,
          savings: savings,
        ));
      }
    }

    return CouponOptimization(
      coupons: coupons,
      totalSavings: totalSavings,
      breakdown: breakdown,
      finalTotal: currentSubtotal,
    );
  }

  /// Calculate savings for single coupon
  double _calculateCouponSavings(AdvancedCoupon coupon, double amount) {
    if (amount < coupon.minPurchase) return 0;

    double savings = 0;
    switch (coupon.type) {
      case CouponType.percentage:
        savings = amount * (coupon.value / 100);
        if (coupon.maxDiscount > 0 && savings > coupon.maxDiscount) {
          savings = coupon.maxDiscount;
        }
        break;
      case CouponType.fixedAmount:
        savings = coupon.value;
        if (savings > amount) savings = amount;
        break;
      case CouponType.freeShipping:
        // Shipping savings would be calculated based on actual shipping cost
        savings = 0; // Would be set from cart shipping
        break;
      case CouponType.buyXGetY:
        // Would need product-specific logic
        savings = 0;
        break;
    }

    return savings;
  }

  /// Generate all combinations of stackable coupons
  List<List<AdvancedCoupon>> _generateCombinations(
      List<AdvancedCoupon> coupons) {
    if (coupons.isEmpty) return [[]];
    if (coupons.length == 1) return [[], coupons];

    final combinations = <List<AdvancedCoupon>>[];
    for (var i = 0; i < (1 << coupons.length); i++) {
      final combo = <AdvancedCoupon>[];
      for (var j = 0; j < coupons.length; j++) {
        if ((i & (1 << j)) != 0) {
          combo.add(coupons[j]);
        }
      }
      if (combo.isNotEmpty) combinations.add(combo);
    }
    return combinations;
  }
}

/// Optimization result
class CouponOptimization {
  final List<AdvancedCoupon> coupons;
  final double totalSavings;
  final List<CouponSavingsDetail> breakdown;
  final double? finalTotal;

  CouponOptimization({
    required this.coupons,
    required this.totalSavings,
    this.breakdown = const [],
    this.finalTotal,
  });

  bool get hasCoupons => coupons.isNotEmpty;
  int get couponCount => coupons.length;
}

/// Savings detail for each coupon
class CouponSavingsDetail {
  final AdvancedCoupon coupon;
  final double savings;

  CouponSavingsDetail({
    required this.coupon,
    required this.savings,
  });
}

/// Main Coupon Optimizer Service
class CouponOptimizerService {
  static final CouponOptimizerService _instance =
      CouponOptimizerService._internal();
  factory CouponOptimizerService() => _instance;
  CouponOptimizerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== PLATFORM COUPONS ====================

  /// Get all available platform coupons for user
  Future<List<PlatformCoupon>> getAvailablePlatformCoupons({
    String? userTier,
    int? userEcoScore,
    bool? isNewUser,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('platform_coupons')
        .where('isActive', isEqualTo: true)
        .get();

    final coupons = snapshot.docs
        .map((doc) => PlatformCoupon.fromMap(doc.data(), doc.id))
        .where((coupon) => coupon.isEligibleForUser(
              userId: user.uid,
              userTier: userTier,
              userEcoScore: userEcoScore,
              isNewUser: isNewUser,
            ))
        .toList();

    return coupons;
  }

  /// Claim platform coupon
  Future<bool> claimPlatformCoupon(String couponId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Check if already claimed
      final existingClaim = await _firestore
          .collection('coupon_claims')
          .where('userId', isEqualTo: user.uid)
          .where('couponId', isEqualTo: couponId)
          .limit(1)
          .get();

      if (existingClaim.docs.isNotEmpty) {
        throw Exception('Already claimed this coupon');
      }

      // Create claim record
      await _firestore.collection('coupon_claims').add({
        'userId': user.uid,
        'couponId': couponId,
        'source': CouponSource.platform.name,
        'claimedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Increment global claim count
      await _firestore.collection('platform_coupons').doc(couponId).update({
        'currentClaimsGlobal': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error claiming coupon: $e');
      return false;
    }
  }

  // ==================== AUTO-APPLY LOGIC ====================

  /// Auto-apply best coupons to cart
  Future<CouponOptimization> autoApplyBestCoupons(
    List<cart_models.CartItem> cartItems,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return CouponOptimization(coupons: [], totalSavings: 0);
    }

    // Get all user's available coupons
    final userCoupons = await _getUserCoupons();
    final platformCoupons = await getAvailablePlatformCoupons();

    // Combine all coupons
    final allCoupons = <AdvancedCoupon>[
      ...userCoupons.map((uc) => uc.promotion as AdvancedCoupon),
      ...platformCoupons,
    ];

    // Filter applicable coupons
    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    final applicable = allCoupons.where((coupon) {
      return subtotal >= coupon.minPurchase;
    }).toList();

    // Find best combination
    final optimizer = CouponOptimizer(
      applicableCoupons: applicable,
      cartItems: cartItems,
      subtotal: subtotal,
    );

    return optimizer.findBestCombination();
  }

  /// Get user's coupons
  Future<List<UserCoupon>> _getUserCoupons() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('user_coupons')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: CouponStatus.available.name)
        .get();

    final coupons = <UserCoupon>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final promotionDoc = await _firestore
          .collection('promotions')
          .doc(data['promotionId'])
          .get();

      if (promotionDoc.exists && promotionDoc.data() != null) {
        try {
          final promotionData = promotionDoc.data()!;
          promotionData['id'] = promotionDoc.id; // Add id to map
          final promotion = ShopPromotion.fromMap(promotionData);
          coupons.add(UserCoupon.fromMap(data, promotion));
        } catch (e) {
          // Skip if promotion can't be parsed
          print('Error parsing promotion: $e');
        }
      }
    }

    return coupons;
  }

  // ==================== RECOMMENDATIONS ====================

  /// Get personalized coupon recommendations
  Future<List<AdvancedCoupon>> getRecommendedCoupons({
    List<String>? categories,
    double? averageOrderValue,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // Get all available coupons
    final userCoupons = await _getUserCoupons();
    final platformCoupons = await getAvailablePlatformCoupons();

    final allCoupons = <AdvancedCoupon>[
      ...userCoupons.map((uc) => uc.promotion as AdvancedCoupon),
      ...platformCoupons,
    ];

    // Score and sort by relevance
    final scored = allCoupons.map((coupon) {
      var score = 0.0;

      // Check if expiring soon (higher priority)
      if (coupon.endDate != null) {
        final daysUntilExpiry =
            coupon.endDate!.difference(DateTime.now()).inDays;
        if (daysUntilExpiry <= 7) score += 20;
      }

      // Match categories
      if (categories != null && coupon.targetCategories.isNotEmpty) {
        final matchingCategories = coupon.targetCategories
            .where((cat) => categories.contains(cat))
            .length;
        score += matchingCategories * 10;
      }

      // Match typical order value
      if (averageOrderValue != null &&
          averageOrderValue >= coupon.minPurchase) {
        score += 15;
      }

      // Highest value
      if (coupon.type == CouponType.fixedAmount) {
        score += coupon.value / 10;
      } else if (coupon.type == CouponType.percentage) {
        score += coupon.value;
      }

      return MapEntry(coupon, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((entry) => entry.key).take(10).toList();
  }

  // ==================== FLASH COUPONS ====================

  /// Get active flash coupons
  Stream<List<PlatformCoupon>> getFlashCouponsStream() {
    return _firestore
        .collection('platform_coupons')
        .where('platformType', isEqualTo: PlatformCouponType.flash.name)
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlatformCoupon.fromMap(doc.data(), doc.id))
            .where((coupon) => coupon.isValid())
            .toList());
  }

  /// Hunt for flash coupon (limited availability)
  Future<bool> huntFlashCoupon(String couponId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Use transaction to ensure atomic claim
      return await _firestore.runTransaction<bool>((transaction) async {
        final couponRef =
            _firestore.collection('platform_coupons').doc(couponId);
        final couponDoc = await transaction.get(couponRef);

        if (!couponDoc.exists) return false;

        final coupon = PlatformCoupon.fromMap(couponDoc.data()!, couponId);

        // Check if still available
        if (coupon.maxClaimsGlobal != null &&
            coupon.currentClaimsGlobal >= coupon.maxClaimsGlobal!) {
          return false;
        }

        // Claim it
        transaction.update(couponRef, {
          'currentClaimsGlobal': FieldValue.increment(1),
        });

        transaction.set(_firestore.collection('coupon_claims').doc(), {
          'userId': user.uid,
          'couponId': couponId,
          'source': CouponSource.platform.name,
          'claimedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });

        return true;
      });
    } catch (e) {
      print('Error hunting flash coupon: $e');
      return false;
    }
  }
}

