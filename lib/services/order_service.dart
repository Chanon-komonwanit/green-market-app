import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart' as order_model;
import '../models/product.dart';
import '../models/cart_item.dart';

/// Order validation result
class OrderValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  OrderValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// Order analytics data
class OrderAnalytics {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;
  final Map<String, int> ordersByDate;
  final double conversionRate;

  OrderAnalytics({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.ordersByStatus,
    required this.ordersByDate,
    required this.conversionRate,
  });
}

/// Order cache entry with expiry
class CachedOrder {
  final order_model.Order order;
  final DateTime cachedAt;

  CachedOrder(this.order, this.cachedAt);

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(minutes: 5);
}

/// Enhanced Order Service with comprehensive order management features
/// Provides validation, caching, state management, and analytics
class OrderService {
  static const String _tag = 'OrderService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  final CollectionReference _orderRef;
  final CollectionReference _productRef;

  // Caching
  static const int _maxCacheSize = 50;
  final Map<String, CachedOrder> _orderCache = {};

  // Performance tracking
  final Map<String, DateTime> _operationTimes = {};

  // Validation rules
  static const double _minOrderValue = 1.0;
  static const double _maxOrderValue = 1000000.0;
  static const int _maxItemsPerOrder = 50;

  // Order status constants
  static const List<String> validStatuses = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded',
    'failed'
  ];

  OrderService()
      : _orderRef = FirebaseFirestore.instance.collection('orders'),
        _productRef = FirebaseFirestore.instance.collection('products');

  /// Place order with comprehensive validation and processing
  Future<String?> placeOrder(order_model.Order order) async {
    try {
      _startOperationTimer('placeOrder');

      // Validate order
      final validation = await validateOrder(order);
      if (!validation.isValid) {
        _logError(
            'placeOrder', 'Validation failed: ${validation.errors.join(', ')}');
        _endOperationTimer('placeOrder');
        return null;
      }

      // Check user permissions
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != order.userId) {
        _logError('placeOrder', 'Unauthorized order placement');
        _endOperationTimer('placeOrder');
        return null;
      }

      // Check product availability and update stock
      if (!await _validateAndReserveStock(order)) {
        _logError('placeOrder', 'Stock validation failed');
        _endOperationTimer('placeOrder');
        return null;
      }

      // Generate order ID and prepare data
      final orderId = _orderRef.doc().id;
      final orderData = order.toMap();

      // Add metadata
      orderData.addAll({
        'id': orderId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'status': 'pending',
        'orderNumber': _generateOrderNumber(),
        'paymentStatus': 'pending',
        'totalItemCount': _calculateTotalItems(order),
      });

      // Begin transaction
      await _firestore.runTransaction((transaction) async {
        // Add order
        transaction.set(_orderRef.doc(orderId), orderData);

        // Update product stock
        for (final item in order.items) {
          final productRef = _productRef.doc(item.productId);
          transaction.update(productRef, {
            'stock': FieldValue.increment(-item.quantity),
            'orderCount': FieldValue.increment(1),
            'updatedAt': Timestamp.now(),
          });
        }

        // Log order placement
        transaction.set(_firestore.collection('order_logs').doc(), {
          'orderId': orderId,
          'action': 'placed',
          'userId': order.userId,
          'timestamp': Timestamp.now(),
          'metadata': {
            'totalAmount': order.totalAmount,
            'itemCount': order.items.length,
          },
        });
      });

      // Cache the order
      final enhancedOrder = order_model.Order.fromMap(orderData);
      _cacheOrder(orderId, enhancedOrder);

      // Send notifications (async)
      _sendOrderNotifications(orderId, order);

      _endOperationTimer('placeOrder');
      return orderId;
    } catch (e) {
      // Rollback stock if needed
      await _rollbackStock(order);
      _logError('placeOrder', e);
      _endOperationTimer('placeOrder');
      return null;
    }
  }

  /// Get user orders with enhanced filtering and caching
  Stream<List<order_model.Order>> getUserOrders(
    String userId, {
    String? status,
    int limit = 20,
    bool includeCompleted = true,
  }) {
    try {
      _startOperationTimer('getUserOrders');

      Query query = _orderRef.where('userId', isEqualTo: userId);

      // Apply status filter
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      // Exclude completed orders if requested
      if (!includeCompleted) {
        query = query.where('status',
            whereNotIn: ['delivered', 'cancelled', 'refunded']);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      return query.snapshots().map((snapshot) {
        _endOperationTimer('getUserOrders');
        final orders = snapshot.docs
            .map((doc) => order_model.Order.fromFirestore(doc))
            .toList();

        // Cache orders
        for (final order in orders) {
          _cacheOrder(order.id, order);
        }

        return orders;
      });
    } catch (e) {
      _logError('getUserOrders', e);
      _endOperationTimer('getUserOrders');
      return Stream.value([]);
    }
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

  /// Enhanced update order status with validation and notifications
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      _startOperationTimer('updateOrderStatus');

      // Validate status
      if (!validStatuses.contains(status)) {
        _logError('updateOrderStatus', 'Invalid status: $status');
        _endOperationTimer('updateOrderStatus');
        return false;
      }

      // Get current order
      final order = await getOrderById(orderId);
      if (order == null) {
        _logError('updateOrderStatus', 'Order not found: $orderId');
        _endOperationTimer('updateOrderStatus');
        return false;
      }

      // Check status transition validity
      if (!_isValidStatusTransition(order.status, status)) {
        _logError('updateOrderStatus',
            'Invalid status transition: ${order.status} -> $status');
        _endOperationTimer('updateOrderStatus');
        return false;
      }

      // Update order
      await _orderRef.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': status,
            'timestamp': Timestamp.now(),
            'updatedBy': _auth.currentUser?.uid,
          }
        ]),
      });

      // Handle status-specific actions
      await _handleStatusChange(order, status);

      // Remove from cache to force refresh
      _orderCache.remove(orderId);

      // Log status change
      await _logOrderActivity(orderId, 'status_changed', {
        'oldStatus': order.status,
        'newStatus': status,
        'updatedBy': _auth.currentUser?.uid,
      });

      _endOperationTimer('updateOrderStatus');
      return true;
    } catch (e) {
      _logError('updateOrderStatus', e);
      _endOperationTimer('updateOrderStatus');
      return false;
    }
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

  /// Get order by ID with caching
  Future<order_model.Order?> getOrderById(String orderId) async {
    try {
      _startOperationTimer('getOrderById');

      // Check cache first
      if (_orderCache.containsKey(orderId)) {
        final cached = _orderCache[orderId]!;
        if (!cached.isExpired) {
          _endOperationTimer('getOrderById');
          return cached.order;
        }
        _orderCache.remove(orderId);
      }

      final doc = await _orderRef.doc(orderId).get();
      if (!doc.exists) {
        _endOperationTimer('getOrderById');
        return null;
      }

      final order = order_model.Order.fromFirestore(doc);

      // Cache the result
      _cacheOrder(orderId, order);

      _endOperationTimer('getOrderById');
      return order;
    } catch (e) {
      _logError('getOrderById', e);
      _endOperationTimer('getOrderById');
      return null;
    }
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

  // VALIDATION METHODS

  /// Comprehensive order validation
  Future<OrderValidationResult> validateOrder(order_model.Order order) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Basic validation
    if (order.userId.trim().isEmpty) {
      errors.add('ข้อมูลผู้ใช้ไม่ถูกต้อง');
    }

    if (order.items.isEmpty) {
      errors.add('ต้องมีสินค้าในตะกร้าอย่างน้อย 1 รายการ');
    } else if (order.items.length > _maxItemsPerOrder) {
      errors.add(
          'จำนวนสินค้าในออเดอร์เกินกำหนด (สูงสุด $_maxItemsPerOrder รายการ)');
    }

    // Amount validation
    if (order.totalAmount < _minOrderValue) {
      errors.add('มูลค่าคำสั่งซื้อต้องมากกว่า $_minOrderValue บาท');
    } else if (order.totalAmount > _maxOrderValue) {
      errors.add('มูลค่าคำสั่งซื้อต้องไม่เกิน $_maxOrderValue บาท');
    }

    // Address validation
    if (order.addressLine1.trim().isEmpty) {
      errors.add('ที่อยู่จัดส่งจำเป็นต้องกรอก');
    }

    if (order.phoneNumber.trim().isEmpty) {
      errors.add('หมายเลขโทรศัพท์จำเป็นต้องกรอก');
    }

    // Product availability check
    for (final item in order.items) {
      try {
        final productDoc = await _productRef.doc(item.productId).get();
        if (!productDoc.exists) {
          errors.add('ไม่พบสินค้า: ${item.productName}');
          continue;
        }

        final productData = productDoc.data() as Map<String, dynamic>;
        final stock = productData['stock'] as int? ?? 0;
        final isActive = productData['isActive'] as bool? ?? false;

        if (!isActive) {
          errors.add('สินค้า ${item.productName} ไม่พร้อมจำหน่าย');
        } else if (stock < item.quantity) {
          errors
              .add('สินค้า ${item.productName} เหลือในสต็อกเพียง $stock ชิ้น');
        }

        // Warning for low stock
        if (stock < 10 && stock >= item.quantity) {
          warnings.add('สินค้า ${item.productName} เหลือในสต็อกน้อย');
        }
      } catch (e) {
        errors.add('ไม่สามารถตรวจสอบสินค้า: ${item.productName}');
      }
    }

    return OrderValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // HELPER METHODS

  /// Cache an order
  void _cacheOrder(String orderId, order_model.Order order) {
    if (_orderCache.length >= _maxCacheSize) {
      // Remove oldest entry
      final oldestKey = _orderCache.keys.first;
      _orderCache.remove(oldestKey);
    }
    _orderCache[orderId] = CachedOrder(order, DateTime.now());
  }

  /// Generate unique order number
  String _generateOrderNumber() {
    final now = DateTime.now();
    final random = Random();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '${random.nextInt(9999).toString().padLeft(4, '0')}';
  }

  /// Calculate total items in order
  int _calculateTotalItems(order_model.Order order) {
    return order.items.fold(0, (total, item) => total + item.quantity);
  }

  /// Validate and reserve stock for order items
  Future<bool> _validateAndReserveStock(order_model.Order order) async {
    try {
      for (final item in order.items) {
        final productDoc = await _productRef.doc(item.productId).get();
        if (!productDoc.exists) return false;

        final productData = productDoc.data() as Map<String, dynamic>;
        final stock = productData['stock'] as int? ?? 0;

        if (stock < item.quantity) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rollback stock on order failure
  Future<void> _rollbackStock(order_model.Order order) async {
    try {
      // This would only be called if stock was reserved but order failed
      // Implementation depends on your stock reservation strategy
    } catch (e) {
      _logError('_rollbackStock', e);
    }
  }

  /// Check if status transition is valid
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    // Define valid transitions
    const validTransitions = {
      'pending': ['confirmed', 'cancelled', 'failed'],
      'confirmed': ['processing', 'cancelled'],
      'processing': ['shipped', 'cancelled'],
      'shipped': ['delivered', 'cancelled'],
      'delivered': ['refunded'], // Only refund after delivery
      'cancelled': [], // Terminal state
      'refunded': [], // Terminal state
      'failed': ['pending'], // Can retry
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  /// Handle status-specific actions
  Future<void> _handleStatusChange(
      order_model.Order order, String newStatus) async {
    try {
      switch (newStatus) {
        case 'confirmed':
          // Send confirmation email/notification
          break;
        case 'shipped':
          // Send tracking information
          break;
        case 'delivered':
          // Update delivery confirmation
          // Award eco-coins if applicable
          break;
        case 'cancelled':
          // Restore stock
          await _restoreStock(order);
          break;
        case 'refunded':
          // Process refund
          break;
      }
    } catch (e) {
      _logError('_handleStatusChange', e);
    }
  }

  /// Restore stock when order is cancelled
  Future<void> _restoreStock(order_model.Order order) async {
    try {
      await _firestore.runTransaction((transaction) async {
        for (final item in order.items) {
          final productRef = _productRef.doc(item.productId);
          transaction.update(productRef, {
            'stock': FieldValue.increment(item.quantity),
            'updatedAt': Timestamp.now(),
          });
        }
      });
    } catch (e) {
      _logError('_restoreStock', e);
    }
  }

  /// Send order notifications
  Future<void> _sendOrderNotifications(
      String orderId, order_model.Order order) async {
    try {
      // Send notification to user
      await _firestore.collection('notifications').add({
        'userId': order.userId,
        'type': 'order_placed',
        'title': 'คำสั่งซื้อถูกสร้างแล้ว',
        'message': 'คำสั่งซื้อ #${order.id} ถูกสร้างเรียบร้อยแล้ว',
        'orderId': orderId,
        'createdAt': Timestamp.now(),
        'isRead': false,
      });

      // Send notification to sellers
      final sellerIds = order.items.map((item) => item.sellerId).toSet();
      for (final sellerId in sellerIds) {
        await _firestore.collection('notifications').add({
          'userId': sellerId,
          'type': 'new_order',
          'title': 'มีคำสั่งซื้อใหม่',
          'message': 'คุณมีคำสั่งซื้อใหม่ #${order.id}',
          'orderId': orderId,
          'createdAt': Timestamp.now(),
          'isRead': false,
        });
      }
    } catch (e) {
      _logError('_sendOrderNotifications', e);
    }
  }

  /// Log order activity
  Future<void> _logOrderActivity(
      String orderId, String action, Map<String, dynamic>? metadata) async {
    try {
      await _firestore.collection('order_activity_logs').add({
        'orderId': orderId,
        'action': action,
        'userId': _auth.currentUser?.uid,
        'timestamp': Timestamp.now(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      // Ignore logging errors
    }
  }

  /// Start operation timer for performance tracking
  void _startOperationTimer(String operation) {
    _operationTimes[operation] = DateTime.now();
  }

  /// End operation timer and log performance
  void _endOperationTimer(String operation) {
    final startTime = _operationTimes.remove(operation);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      if (kDebugMode) {
        print('[$_tag] $operation took ${duration.inMilliseconds}ms');
      }
    }
  }

  /// Log errors for debugging
  void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      print('[$_tag] Error in $operation: $error');
    }
  }

  /// Clear cache
  void clearCache() {
    _orderCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'orderCacheSize': _orderCache.length,
      'cacheHitRate': _orderCache.isNotEmpty
          ? _orderCache.values.where((o) => !o.isExpired).length /
              _orderCache.length
          : 0.0,
    };
  }
}
