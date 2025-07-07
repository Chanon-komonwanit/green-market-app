// lib/services/shipping/shipping_analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/firebase_service.dart';

class ShippingAnalyticsService {
  final FirebaseService _firebaseService;

  ShippingAnalyticsService(this._firebaseService);

  /// Get shipping statistics for seller
  Future<Map<String, dynamic>> getSellerShippingStats(String sellerId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Get orders as a list
      final ordersStream = _firebaseService.getOrdersBySellerId(sellerId);
      final orders = await ordersStream.first;

      // Filter orders by time periods
      final thisMonth = orders
          .where((order) => order.orderDate.toDate().isAfter(startOfMonth))
          .toList();
      final thisWeek = orders
          .where((order) => order.orderDate.toDate().isAfter(startOfWeek))
          .toList();
      final today = orders
          .where((order) => _isSameDay(order.orderDate.toDate(), now))
          .toList();

      // Calculate statistics
      return {
        'total_orders': orders.length,
        'pending_shipment':
            orders.where((o) => o.status == 'processing').length,
        'in_transit': orders.where((o) => o.status == 'shipped').length,
        'delivered': orders.where((o) => o.status == 'delivered').length,
        'cancelled': orders.where((o) => o.status == 'cancelled').length,

        // Time-based stats
        'this_month': {
          'total': thisMonth.length,
          'delivered': thisMonth.where((o) => o.status == 'delivered').length,
          'revenue':
              thisMonth.fold(0.0, (total, order) => total + order.totalAmount),
        },
        'this_week': {
          'total': thisWeek.length,
          'delivered': thisWeek.where((o) => o.status == 'delivered').length,
          'revenue':
              thisWeek.fold(0.0, (total, order) => total + order.totalAmount),
        },
        'today': {
          'total': today.length,
          'delivered': today.where((o) => o.status == 'delivered').length,
          'revenue':
              today.fold(0.0, (total, order) => total + order.totalAmount),
        },

        // Shipping method breakdown
        'shipping_methods': _getShippingMethodBreakdown(orders),

        // Carrier breakdown
        'carriers': _getCarrierBreakdown(orders),

        // Average delivery time
        'avg_delivery_time': _calculateAverageDeliveryTime(orders),

        // Problem orders
        'problem_orders': _getProblemOrders(orders),

        // Performance metrics
        'on_time_delivery_rate': _calculateOnTimeDeliveryRate(orders),
        'customer_satisfaction': _calculateCustomerSatisfaction(orders),
      };
    } catch (e) {
      print('Error getting shipping stats: $e');
      return {};
    }
  }

  /// Get shipping trends over time
  Future<List<Map<String, dynamic>>> getShippingTrends(
    String sellerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final ordersStream = _firebaseService.getOrdersBySellerId(sellerId);
      final orders = await ordersStream.first;

      final filteredOrders = orders.where((order) {
        final orderDate = order.orderDate.toDate();
        return orderDate.isAfter(startDate) && orderDate.isBefore(endDate);
      }).toList();

      // Group by day/week/month depending on date range
      final duration = endDate.difference(startDate);
      final trends = <Map<String, dynamic>>[];

      if (duration.inDays <= 30) {
        // Daily trends
        for (var i = 0; i < duration.inDays; i++) {
          final date = startDate.add(Duration(days: i));
          final dayOrders = filteredOrders
              .where((order) => _isSameDay(order.orderDate.toDate(), date))
              .toList();

          trends.add({
            'date': date.toIso8601String(),
            'total_orders': dayOrders.length,
            'delivered': dayOrders.where((o) => o.status == 'delivered').length,
            'revenue': dayOrders.fold(
                0.0, (total, order) => total + order.totalAmount),
            'shipping_cost': dayOrders.fold(
                0.0, (total, order) => total + order.shippingFee),
          });
        }
      } else {
        // Weekly trends
        for (var i = 0; i < duration.inDays; i += 7) {
          final weekStart = startDate.add(Duration(days: i));
          final weekEnd = weekStart.add(const Duration(days: 7));

          final weekOrders = filteredOrders.where((order) {
            final orderDate = order.orderDate.toDate();
            return orderDate.isAfter(weekStart) && orderDate.isBefore(weekEnd);
          }).toList();

          trends.add({
            'week_start': weekStart.toIso8601String(),
            'total_orders': weekOrders.length,
            'delivered':
                weekOrders.where((o) => o.status == 'delivered').length,
            'revenue': weekOrders.fold(
                0.0, (total, order) => total + order.totalAmount),
            'shipping_cost': weekOrders.fold(
                0.0, (total, order) => total + order.shippingFee),
          });
        }
      }

      return trends;
    } catch (e) {
      print('Error getting shipping trends: $e');
      return [];
    }
  }

  /// Get regional shipping performance
  Future<Map<String, dynamic>> getRegionalShippingPerformance(
      String sellerId) async {
    try {
      final ordersStream = _firebaseService.getOrdersBySellerId(sellerId);
      final orders = await ordersStream.first;
      final regionalData = <String, Map<String, dynamic>>{};

      for (final order in orders) {
        final province = order.province;

        if (!regionalData.containsKey(province)) {
          regionalData[province] = {
            'total_orders': 0,
            'delivered': 0,
            'avg_delivery_time': 0.0,
            'total_revenue': 0.0,
            'shipping_costs': 0.0,
          };
        }

        final data = regionalData[province]!;
        data['total_orders'] = data['total_orders'] + 1;
        data['total_revenue'] = data['total_revenue'] + order.totalAmount;
        data['shipping_costs'] = data['shipping_costs'] + order.shippingFee;

        if (order.status == 'delivered') {
          data['delivered'] = data['delivered'] + 1;
        }
      }

      return regionalData;
    } catch (e) {
      print('Error getting regional performance: $e');
      return {};
    }
  }

  /// Get shipping cost analysis
  Future<Map<String, dynamic>> getShippingCostAnalysis(String sellerId) async {
    try {
      final ordersStream = _firebaseService.getOrdersBySellerId(sellerId);
      final orders = await ordersStream.first;

      final totalShippingCost =
          orders.fold(0.0, (total, order) => total + order.shippingFee);
      final totalRevenue =
          orders.fold(0.0, (total, order) => total + order.totalAmount);

      final costsByMethod = <String, double>{};
      final costsByCarrier = <String, double>{};

      for (final order in orders) {
        // By method
        if (order.shippingMethod != null) {
          costsByMethod[order.shippingMethod!] =
              (costsByMethod[order.shippingMethod!] ?? 0) + order.shippingFee;
        }

        // By carrier
        if (order.shippingCarrier != null) {
          costsByCarrier[order.shippingCarrier!] =
              (costsByCarrier[order.shippingCarrier!] ?? 0) + order.shippingFee;
        }
      }

      return {
        'total_shipping_cost': totalShippingCost,
        'shipping_cost_ratio':
            totalRevenue > 0 ? totalShippingCost / totalRevenue : 0,
        'avg_shipping_cost':
            orders.isNotEmpty ? totalShippingCost / orders.length : 0,
        'costs_by_method': costsByMethod,
        'costs_by_carrier': costsByCarrier,
        'free_shipping_count': orders.where((o) => o.shippingFee == 0).length,
        'highest_shipping_cost': orders.isNotEmpty
            ? orders.map((o) => o.shippingFee).reduce((a, b) => a > b ? a : b)
            : 0,
        'lowest_shipping_cost': orders.isNotEmpty
            ? orders.map((o) => o.shippingFee).reduce((a, b) => a < b ? a : b)
            : 0,
      };
    } catch (e) {
      print('Error getting cost analysis: $e');
      return {};
    }
  }

  // Helper methods
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Map<String, int> _getShippingMethodBreakdown(List<app_order.Order> orders) {
    final breakdown = <String, int>{};
    for (final order in orders) {
      if (order.shippingMethod != null) {
        breakdown[order.shippingMethod!] =
            (breakdown[order.shippingMethod!] ?? 0) + 1;
      }
    }
    return breakdown;
  }

  Map<String, int> _getCarrierBreakdown(List<app_order.Order> orders) {
    final breakdown = <String, int>{};
    for (final order in orders) {
      if (order.shippingCarrier != null) {
        breakdown[order.shippingCarrier!] =
            (breakdown[order.shippingCarrier!] ?? 0) + 1;
      }
    }
    return breakdown;
  }

  double _calculateAverageDeliveryTime(List<app_order.Order> orders) {
    final deliveredOrders = orders
        .where((o) =>
            o.status == 'delivered' &&
            o.shippedAt != null &&
            o.deliveredAt != null)
        .toList();

    if (deliveredOrders.isEmpty) return 0.0;

    final totalDays = deliveredOrders.fold(0.0, (total, order) {
      final shipped = order.shippedAt!.toDate();
      final delivered = order.deliveredAt!.toDate();
      return total + delivered.difference(shipped).inDays;
    });

    return totalDays / deliveredOrders.length;
  }

  List<Map<String, dynamic>> _getProblemOrders(List<app_order.Order> orders) {
    final problems = <Map<String, dynamic>>[];

    for (final order in orders) {
      final issues = <String>[];

      // Check for late delivery
      if (order.status == 'shipped' && order.shippedAt != null) {
        final daysSinceShipped =
            DateTime.now().difference(order.shippedAt!.toDate()).inDays;
        if (daysSinceShipped > 7) {
          issues.add('Late delivery');
        }
      }

      // Check for stuck in processing
      if (order.status == 'processing') {
        final daysSinceOrder =
            DateTime.now().difference(order.orderDate.toDate()).inDays;
        if (daysSinceOrder > 3) {
          issues.add('Stuck in processing');
        }
      }

      // Check for missing tracking
      if (order.status == 'shipped' && order.trackingNumber == null) {
        issues.add('Missing tracking number');
      }

      if (issues.isNotEmpty) {
        problems.add({
          'order_id': order.id,
          'issues': issues,
          'order_date': order.orderDate.toDate().toIso8601String(),
          'status': order.status,
        });
      }
    }

    return problems;
  }

  double _calculateOnTimeDeliveryRate(List<app_order.Order> orders) {
    final deliveredOrders =
        orders.where((o) => o.status == 'delivered').toList();
    if (deliveredOrders.isEmpty) return 0.0;

    final onTimeCount = deliveredOrders.where((order) {
      // Assume on-time if delivered within estimated time + 1 day buffer
      // This is a simplified calculation
      return true; // Would need more complex logic with actual delivery estimates
    }).length;

    return onTimeCount / deliveredOrders.length;
  }

  double _calculateCustomerSatisfaction(List<app_order.Order> orders) {
    // This would integrate with review system
    // For now, return a mock satisfaction score
    return 0.85; // 85% satisfaction
  }
}
