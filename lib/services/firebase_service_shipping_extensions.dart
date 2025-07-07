// lib/services/firebase_service_shipping_extensions.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/firebase_service.dart';
import 'package:logger/logger.dart';

/// Extension methods for FirebaseService specifically for shipping functionality
extension FirebaseServiceShippingExtensions on FirebaseService {
  /// Update order shipping information
  Future<void> updateOrderShippingInfo(
      String orderId, Map<String, dynamic> shippingInfo) async {
    try {
      await firestore.collection('orders').doc(orderId).update(shippingInfo);
      logger.i("Order shipping info updated for $orderId");
    } catch (e) {
      logger.e("Error updating order shipping info: $e");
      rethrow;
    }
  }

  /// Get shipping statistics with optional filters
  Future<Map<String, dynamic>> getShippingStatistics({
    String? sellerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = firestore
          .collection('orders')
          .where('status', whereIn: ['shipped', 'delivered']);

      if (sellerId != null) {
        query = query.where('sellerIds', arrayContains: sellerId);
      }

      if (startDate != null) {
        query = query.where('orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('orderDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final ordersSnapshot = await query.get();

      final orders = ordersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      return {
        'totalOrders': orders.length,
        'totalShippingFees': orders.fold(
            0.0, (total, order) => total + (order['shippingFee'] ?? 0.0)),
        'averageShippingFee': orders.isEmpty
            ? 0.0
            : orders.fold(0.0,
                    (total, order) => total + (order['shippingFee'] ?? 0.0)) /
                orders.length,
        'ordersByCarrier': _groupOrdersByCarrier(orders),
      };
    } catch (e) {
      logger.e("Error getting shipping statistics: $e");
      return {};
    }
  }

  Map<String, int> _groupOrdersByCarrier(List<Map<String, dynamic>> orders) {
    final Map<String, int> carrierCounts = {};
    for (final order in orders) {
      final carrier = order['shippingCarrier'] ?? 'Unknown';
      carrierCounts[carrier] = (carrierCounts[carrier] ?? 0) + 1;
    }
    return carrierCounts;
  }

  /// Get orders that need shipping label printing
  Future<List<app_order.Order>> getOrdersNeedingLabels(String sellerId) async {
    try {
      final snapshot = await firestore
          .collection('orders')
          .where('sellerIds', arrayContains: sellerId)
          .where('status', whereIn: ['confirmed', 'processing'])
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return app_order.Order.fromMap(data);
      }).toList();
    } catch (e) {
      logger.e("Error getting orders needing labels: $e");
      return [];
    }
  }

  /// Add tracking event
  Future<void> addTrackingEvent(
      String trackingNumber, Map<String, dynamic> eventData) async {
    try {
      await firestore.collection('tracking_events').add({
        'trackingNumber': trackingNumber,
        'timestamp': Timestamp.now(),
        ...eventData,
      });
      logger.i("Tracking event added for $trackingNumber");
    } catch (e) {
      logger.e("Error adding tracking event: $e");
      rethrow;
    }
  }

  /// Get tracking events for a specific tracking number
  Future<List<Map<String, dynamic>>> getTrackingEvents(
      String trackingNumber) async {
    try {
      final snapshot = await firestore
          .collection('tracking_events')
          .where('trackingNumber', isEqualTo: trackingNumber)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      logger.e("Error getting tracking events: $e");
      return [];
    }
  }
}
