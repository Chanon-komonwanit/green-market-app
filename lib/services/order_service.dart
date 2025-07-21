import '../models/order.dart' as order_model;
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final _orderRef = FirebaseFirestore.instance.collection('orders');

  Future<void> placeOrder(order_model.Order order) async {
    await _orderRef.add(order.toMap());
  }

  Stream<List<order_model.Order>> getUserOrders(String userId) {
    return _orderRef.where('userId', isEqualTo: userId).snapshots().map(
        (snap) => snap.docs
            .map((doc) => order_model.Order.fromFirestore(doc))
            .toList());
  }

  Stream<List<order_model.Order>> getAllOrders() {
    return _orderRef.snapshots().map((snap) =>
        snap.docs.map((doc) => order_model.Order.fromFirestore(doc)).toList());
  }

  Stream<List<order_model.Order>> getOrdersByStatus(String status) {
    return _orderRef.where('status', isEqualTo: status).snapshots().map(
        (snap) => snap.docs
            .map((doc) => order_model.Order.fromFirestore(doc))
            .toList());
  }

  Stream<List<order_model.Order>> getSellerOrders(String sellerId) {
    return _orderRef
        .where('sellerIds', arrayContains: sellerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => order_model.Order.fromFirestore(doc))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _orderRef
        .doc(orderId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteOrder(String orderId) async {
    await _orderRef.doc(orderId).delete();
  }

  Future<void> updateTracking(String orderId, String trackingNumber,
      String carrier, String? trackingUrl) async {
    await _orderRef.doc(orderId).update({
      'trackingNumber': trackingNumber,
      'shippingCarrier': carrier,
      if (trackingUrl != null) 'trackingUrl': trackingUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> uploadPaymentSlip(String orderId, String slipUrl) async {
    await _orderRef.doc(orderId).update({
      'paymentSlipUrl': slipUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> refundOrder(String orderId, {String? reason}) async {
    await _orderRef.doc(orderId).update({
      'status': 'refunded',
      if (reason != null) 'refundReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<order_model.Order?> getOrderById(String orderId) async {
    final doc = await _orderRef.doc(orderId).get();
    if (doc.exists) {
      return order_model.Order.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<order_model.Order>> searchOrdersByKeyword(String keyword) {
    // สมมติค้นหาเฉพาะ orderId หรือชื่อผู้รับ (fullName)
    return _orderRef
        .where('fullName', isGreaterThanOrEqualTo: keyword)
        .where('fullName', isLessThanOrEqualTo: '$keyword\uf8ff')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => order_model.Order.fromFirestore(doc))
            .toList());
  }
}
