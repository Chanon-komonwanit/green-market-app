// lib/providers/coupon_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/user_coupon.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/models/cart_item.dart';

class CouponProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserCoupon> _userCoupons = [];
  List<ShopPromotion> _availablePromotions = [];
  UserCoupon? _appliedCoupon;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserCoupon> get userCoupons => _userCoupons;
  List<UserCoupon> get availableCoupons =>
      _userCoupons.where((c) => c.isUsable).toList();
  List<UserCoupon> get usedCoupons =>
      _userCoupons.where((c) => c.status == CouponStatus.used).toList();
  List<UserCoupon> get expiredCoupons =>
      _userCoupons.where((c) => c.status == CouponStatus.expired).toList();
  List<ShopPromotion> get availablePromotions => _availablePromotions;
  UserCoupon? get appliedCoupon => _appliedCoupon;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAppliedCoupon => _appliedCoupon != null;

  // โหลดโค้ดส่วนลดของผู้ใช้
  Future<void> loadUserCoupons() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('user_coupons')
          .where('userId', isEqualTo: user.uid)
          .orderBy('collectedAt', descending: true)
          .get();

      _userCoupons = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // โหลดข้อมูลโปรโมชั่น
        final promotionDoc = await _firestore
            .collection('promotions')
            .doc(data['promotionId'])
            .get();

        if (promotionDoc.exists) {
          final promotion = ShopPromotion.fromMap(promotionDoc.data()!);
          final coupon = UserCoupon.fromMap(data, promotion);
          _userCoupons.add(coupon);
        }
      }

      _updateCouponStatuses();
      _error = null;
    } catch (e) {
      _error = 'ไม่สามารถโหลดโค้ดส่วนลดได้: $e';
    } finally {
      _setLoading(false);
    }
  }

  // โหลดโปรโมชั่นที่ใช้ได้
  Future<void> loadAvailablePromotions({String? sellerId}) async {
    _setLoading(true);
    try {
      Query query = _firestore
          .collection('promotions')
          .where('isActive', isEqualTo: true)
          .where('isPublic', isEqualTo: true);

      if (sellerId != null) {
        query = query.where('sellerId', isEqualTo: sellerId);
      }

      final snapshot = await query.get();

      _availablePromotions = snapshot.docs
          .map((doc) =>
              ShopPromotion.fromMap(doc.data() as Map<String, dynamic>))
          .where((promo) => promo.isValid && promo.isTimeValid)
          .toList();

      _error = null;
    } catch (e) {
      _error = 'ไม่สามารถโหลดโปรโมชั่นได้: $e';
    } finally {
      _setLoading(false);
    }
  }

  // เก็บโค้ดส่วนลด
  Future<bool> collectCoupon(ShopPromotion promotion) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // ตรวจสอบว่าเคยเก็บแล้วหรือไม่
    final existingCoupon = _userCoupons.firstWhere(
      (c) =>
          c.promotionId == promotion.id && c.status == CouponStatus.available,
      orElse: () => UserCoupon(
        id: '',
        userId: '',
        promotionId: '',
        promotion: promotion,
        collectedAt: DateTime.now(),
      ),
    );

    if (existingCoupon.id.isNotEmpty) {
      _error = 'คุณมีโค้ดนี้อยู่แล้ว';
      notifyListeners();
      return false;
    }

    try {
      final couponId = _firestore.collection('user_coupons').doc().id;
      final newCoupon = UserCoupon(
        id: couponId,
        userId: user.uid,
        promotionId: promotion.id,
        promotion: promotion,
        collectedAt: DateTime.now(),
        status: CouponStatus.available,
      );

      await _firestore
          .collection('user_coupons')
          .doc(couponId)
          .set(newCoupon.toMap());

      _userCoupons.insert(0, newCoupon);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'ไม่สามารถเก็บโค้ดได้: $e';
      notifyListeners();
      return false;
    }
  }

  // ใช้โค้ดส่วนลด
  Future<bool> applyCoupon(UserCoupon coupon) async {
    if (!coupon.isUsable) {
      _error = 'โค้ดนี้ไม่สามารถใช้ได้';
      notifyListeners();
      return false;
    }

    _appliedCoupon = coupon;
    _error = null;
    notifyListeners();
    return true;
  }

  // ยกเลิกการใช้โค้ด
  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  // คำนวณส่วนลด
  DiscountCalculation? calculateDiscount(List<CartItem> cartItems) {
    if (_appliedCoupon == null) return null;

    final coupon = _appliedCoupon!;
    final promotion = coupon.promotion;
    double subtotal = cartItems.fold(0, (sum, item) => sum + item.totalPrice);

    // ตรวจสอบยอดขั้นต่ำ
    if (promotion.minimumPurchase != null &&
        subtotal < promotion.minimumPurchase!) {
      return null;
    }

    double discountAmount = 0;
    String details = '';

    switch (promotion.type) {
      case PromotionType.percentDiscount:
        discountAmount = subtotal * (promotion.discountPercent! / 100);
        if (promotion.maximumDiscount != null &&
            discountAmount > promotion.maximumDiscount!) {
          discountAmount = promotion.maximumDiscount!;
        }
        details = 'ส่วนลด ${promotion.discountPercent!.toInt()}%';
        if (promotion.maximumDiscount != null) {
          details += ' (สูงสุด ฿${promotion.maximumDiscount!.toInt()})';
        }
        break;

      case PromotionType.fixedDiscount:
        discountAmount = promotion.discountAmount!;
        if (discountAmount > subtotal) {
          discountAmount = subtotal;
        }
        details = 'ส่วนลด ฿${promotion.discountAmount!.toInt()}';
        break;

      case PromotionType.freeShipping:
        // จะจัดการใน shipping calculation
        discountAmount = 0;
        details = 'ฟรีค่าจัดส่ง';
        break;

      case PromotionType.buyXGetY:
        // คำนวณตามจำนวนสินค้า
        // TODO: implement buy X get Y logic
        details = 'ซื้อ ${promotion.buyQuantity} แถม ${promotion.getQuantity}';
        break;

      case PromotionType.flashSale:
        // Flash sale มักจะใช้กับสินค้าเฉพาะ
        details = 'Flash Sale';
        break;
    }

    return DiscountCalculation(
      originalAmount: subtotal,
      discountAmount: discountAmount,
      finalAmount: subtotal - discountAmount,
      coupon: coupon,
      calculationDetails: details,
    );
  }

  // ใช้โค้ดส่วนลด (เมื่อสั่งซื้อสำเร็จ)
  Future<bool> useCoupon(String orderId) async {
    if (_appliedCoupon == null) return false;

    try {
      final updatedCoupon = _appliedCoupon!.copyWith(
        status: CouponStatus.used,
        usedAt: DateTime.now(),
        orderId: orderId,
      );

      await _firestore
          .collection('user_coupons')
          .doc(_appliedCoupon!.id)
          .update(updatedCoupon.toMap());

      // อัพเดทใน local list
      final index = _userCoupons.indexWhere((c) => c.id == _appliedCoupon!.id);
      if (index != -1) {
        _userCoupons[index] = updatedCoupon;
      }

      _appliedCoupon = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'ไม่สามารถใช้โค้ดได้: $e';
      notifyListeners();
      return false;
    }
  }

  // ตรวจสอบโค้ดด้วยรหัส
  Future<UserCoupon?> findCouponByCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // หาโปรโมชั่นที่มีโค้ดนี้
      final promotionSnapshot = await _firestore
          .collection('promotions')
          .where('discountCode', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (promotionSnapshot.docs.isEmpty) return null;

      final promotion =
          ShopPromotion.fromMap(promotionSnapshot.docs.first.data());

      // ตรวจสอบว่าผู้ใช้มีโค้ดนี้หรือไม่
      final existingCoupon = _userCoupons.firstWhere(
        (c) => c.promotionId == promotion.id && c.isUsable,
        orElse: () => UserCoupon(
          id: '',
          userId: '',
          promotionId: '',
          promotion: promotion,
          collectedAt: DateTime.now(),
        ),
      );

      if (existingCoupon.id.isNotEmpty) {
        return existingCoupon;
      }

      // ถ้าไม่มี ให้เก็บโค้ดอัตโนมัติ
      final collected = await collectCoupon(promotion);
      if (collected) {
        return _userCoupons.firstWhere((c) => c.promotionId == promotion.id);
      }

      return null;
    } catch (e) {
      _error = 'ไม่สามารถค้นหาโค้ดได้: $e';
      notifyListeners();
      return null;
    }
  }

  // อัพเดทสถานะโค้ด
  void _updateCouponStatuses() {
    for (int i = 0; i < _userCoupons.length; i++) {
      final coupon = _userCoupons[i];
      if (coupon.status == CouponStatus.available) {
        if (!coupon.promotion.isValid || !coupon.promotion.isTimeValid) {
          _userCoupons[i] = coupon.copyWith(status: CouponStatus.expired);
        }
      }
    }
  }

  // ลบโค้ดที่หมดอายุ
  Future<void> cleanupExpiredCoupons() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final expiredCoupons =
          _userCoupons.where((c) => c.status == CouponStatus.expired).toList();

      for (final coupon in expiredCoupons) {
        await _firestore.collection('user_coupons').doc(coupon.id).delete();
      }

      _userCoupons.removeWhere((c) => c.status == CouponStatus.expired);
      notifyListeners();
    } catch (e) {
      _error = 'ไม่สามารถลบโค้ดที่หมดอายุได้: $e';
      notifyListeners();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // รีเซ็ตข้อมูล
  void reset() {
    _userCoupons.clear();
    _availablePromotions.clear();
    _appliedCoupon = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
