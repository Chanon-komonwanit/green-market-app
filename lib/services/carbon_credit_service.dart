// lib/services/carbon_credit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/carbon_credit.dart';

class CarbonCreditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collectionPath = 'carbon_credits';

  /// Create new carbon credit listing
  Future<String> createCarbonCredit({
    required double tonsCO2,
    required double pricePerTon,
    required CarbonCreditType type,
    required String projectName,
    required String description,
    required String certificateUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนสร้างรายการ');
      }

      final credit = CarbonCredit(
        id: '',
        sellerId: user.uid,
        sellerName: user.displayName ?? 'Unknown',
        tonsCO2: tonsCO2,
        pricePerTon: pricePerTon,
        type: type,
        status: CarbonCreditStatus.pending,
        projectName: projectName,
        description: description,
        certificateUrl: certificateUrl,
        createdAt: DateTime.now(),
      );

      if (!credit.validate()) {
        throw Exception('ข้อมูลไม่ถูกต้อง');
      }

      final docRef =
          await _firestore.collection(_collectionPath).add(credit.toMap());

      print('[SUCCESS] สร้างรายการคาร์บอนเครดิตสำเร็จ ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการสร้างรายการ: $e');
      rethrow;
    }
  }

  /// Get available carbon credits for purchase
  Stream<List<CarbonCredit>> getAvailableCredits({
    CarbonCreditType? filterType,
    double? maxPricePerTon,
  }) {
    Query query = _firestore
        .collection(_collectionPath)
        .where('status', isEqualTo: CarbonCreditStatus.available.name)
        .where('verifiedAt', isNotEqualTo: null);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }

    return query.orderBy('verifiedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  CarbonCredit.fromMap(doc.data() as Map<String, dynamic>))
              .where((credit) =>
                  maxPricePerTon == null ||
                  credit.pricePerTon <= maxPricePerTon)
              .toList(),
        );
  }

  /// Purchase carbon credit
  Future<bool> purchaseCarbonCredit({
    required String creditId,
    required double amount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนซื้อ');
      }

      final creditDoc =
          await _firestore.collection(_collectionPath).doc(creditId).get();

      if (!creditDoc.exists) {
        throw Exception('ไม่พบรายการคาร์บอนเครดิต');
      }

      final credit = CarbonCredit.fromMap(creditDoc.data()!);

      if (!credit.isAvailable) {
        throw Exception('รายการนี้ไม่พร้อมขาย');
      }

      if (credit.totalPrice > amount) {
        throw Exception('จำนวนเงินไม่เพียงพอ');
      }

      // Update credit status
      await _firestore.collection(_collectionPath).doc(creditId).update({
        'buyerId': user.uid,
        'buyerName': user.displayName ?? 'Unknown',
        'status': CarbonCreditStatus.sold.name,
        'soldAt': FieldValue.serverTimestamp(),
      });

      // Create transaction record
      await _firestore.collection('carbon_transactions').add({
        'creditId': creditId,
        'sellerId': credit.sellerId,
        'buyerId': user.uid,
        'tonsCO2': credit.tonsCO2,
        'totalPrice': credit.totalPrice,
        'transactionDate': FieldValue.serverTimestamp(),
        'type': 'purchase',
      });

      print('[SUCCESS] ซื้อคาร์บอนเครดิตสำเร็จ');
      return true;
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการซื้อ: $e');
      rethrow;
    }
  }

  /// Retire carbon credit (use for offset)
  Future<bool> retireCarbonCredit(String creditId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบ');
      }

      final creditDoc =
          await _firestore.collection(_collectionPath).doc(creditId).get();

      if (!creditDoc.exists) {
        throw Exception('ไม่พบรายการคาร์บอนเครดิต');
      }

      final credit = CarbonCredit.fromMap(creditDoc.data()!);

      if (credit.buyerId != user.uid) {
        throw Exception('คุณไม่ใช่เจ้าของคาร์บอนเครดิตนี้');
      }

      if (credit.status != CarbonCreditStatus.sold) {
        throw Exception('คาร์บอนเครดิตนี้ไม่สามารถใช้ได้');
      }

      // Update to retired status
      await _firestore.collection(_collectionPath).doc(creditId).update({
        'status': CarbonCreditStatus.retired.name,
        'retiredAt': FieldValue.serverTimestamp(),
      });

      // Create retirement record
      await _firestore.collection('carbon_retirements').add({
        'creditId': creditId,
        'userId': user.uid,
        'tonsCO2': credit.tonsCO2,
        'retiredAt': FieldValue.serverTimestamp(),
      });

      print('[SUCCESS] ใช้คาร์บอนเครดิตสำเร็จ');
      return true;
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการใช้: $e');
      rethrow;
    }
  }

  /// Get user's carbon credits (purchased)
  Stream<List<CarbonCredit>> getUserPurchasedCredits() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('soldAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CarbonCredit.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Get user's carbon credits (listed for sale)
  Stream<List<CarbonCredit>> getUserListedCredits() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CarbonCredit.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Get carbon offset statistics for user
  Future<Map<String, dynamic>> getUserCarbonStats(String userId) async {
    try {
      // Get retired credits
      final retiredCredits = await _firestore
          .collection(_collectionPath)
          .where('buyerId', isEqualTo: userId)
          .where('status', isEqualTo: CarbonCreditStatus.retired.name)
          .get();

      double totalOffset = 0.0;
      for (final doc in retiredCredits.docs) {
        final credit = CarbonCredit.fromMap(doc.data());
        totalOffset += credit.tonsCO2;
      }

      // Get purchased credits
      final purchasedCredits = await _firestore
          .collection(_collectionPath)
          .where('buyerId', isEqualTo: userId)
          .get();

      return {
        'totalOffset': totalOffset,
        'totalPurchased': purchasedCredits.docs.length,
        'totalRetired': retiredCredits.docs.length,
      };
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการดึงสถิติ: $e');
      return {
        'totalOffset': 0.0,
        'totalPurchased': 0,
        'totalRetired': 0,
      };
    }
  }

  /// Admin: Verify carbon credit
  Future<bool> verifyCarbonCredit(String creditId) async {
    try {
      await _firestore.collection(_collectionPath).doc(creditId).update({
        'status': CarbonCreditStatus.available.name,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      print('[SUCCESS] ตรวจสอบคาร์บอนเครดิตสำเร็จ');
      return true;
    } catch (e) {
      print('[ERROR] เกิดข้อผิดพลาดในการตรวจสอบ: $e');
      return false;
    }
  }

  /// Admin: Get pending credits for verification
  Stream<List<CarbonCredit>> getPendingCredits() {
    return _firestore
        .collection(_collectionPath)
        .where('status', isEqualTo: CarbonCreditStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CarbonCredit.fromMap(doc.data()))
              .toList(),
        );
  }
}
