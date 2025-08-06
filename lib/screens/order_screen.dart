import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'chat_screen.dart';

class OrderScreen extends StatelessWidget {
  final String userId;
  final OrderService _orderService = OrderService();

  OrderScreen({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('คำสั่งซื้อของฉัน')),
      body: StreamBuilder<List<Order>>(
        stream: _orderService.getUserOrders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีคำสั่งซื้อ'));
          }
          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final firstItem =
                  order.items.isNotEmpty ? order.items.first : null;
              return ListTile(
                title: Text('Order #${order.id}'),
                subtitle: Text('สถานะ: ${order.status}'),
                trailing: firstItem != null
                    ? IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        tooltip: 'แชทกับผู้ขาย',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId:
                                    '${order.userId}_${firstItem.sellerId}_${firstItem.productId}',
                                productId: firstItem.productId,
                                productName: firstItem.productName,
                                productImageUrl: firstItem.imageUrl,
                                buyerId: order.userId,
                                sellerId: firstItem.sellerId,
                              ),
                            ),
                          );
                        },
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/order-detail',
                    arguments: {
                      'order': order,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
