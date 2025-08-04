import 'package:flutter/material.dart';
import 'package:green_market/widgets/order_status_badge.dart';

/// Example usage of OrderStatusBadge in a widget tree
class OrderStatusBadgeDemo extends StatelessWidget {
  const OrderStatusBadgeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Status Badge Demo')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const OrderStatusBadge(status: 'pending_payment'),
          const SizedBox(height: 16),
          const OrderStatusBadge(status: 'processing'),
          const SizedBox(height: 16),
          const OrderStatusBadge(status: 'shipped'),
          const SizedBox(height: 16),
          const OrderStatusBadge(status: 'delivered'),
          const SizedBox(height: 16),
          const OrderStatusBadge(status: 'cancelled'),
          const SizedBox(height: 16),
          const OrderStatusBadge(status: 'unknown'),
        ],
      ),
    );
  }
}
