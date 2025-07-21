import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/promotion.dart';

class PromotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ดึงโปรโมชั่นทั้งหมดของร้านค้า
  Stream<List<Promotion>> getPromotionsBySeller(String sellerId) {
    return _firestore
        .collection('promotions')
        .where('sellerId', isEqualTo: sellerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Promotion.fromMap(doc.data())).toList());
  }

  // ดึงโปรโมชั่นเฉพาะสินค้าของร้าน
  Stream<List<Promotion>> getPromotionsByProduct(
      String sellerId, String productId) {
    return _firestore
        .collection('promotions')
        .where('sellerId', isEqualTo: sellerId)
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Promotion.fromMap(doc.data())).toList());
  }

  // สร้างโปรโมชั่นใหม่
  Future<void> createPromotion(Promotion promotion) async {
    await _firestore
        .collection('promotions')
        .doc(promotion.id)
        .set(promotion.toMap());
  }

  // ปิด/ลบโปรโมชั่น
  Future<void> deactivatePromotion(String promotionId) async {
    await _firestore
        .collection('promotions')
        .doc(promotionId)
        .update({'isActive': false});
  }
}
