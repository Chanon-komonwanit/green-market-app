// lib/screens/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/screens/buyer_order_detail_screen.dart';
import 'package:green_market/screens/order_tracking_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/order_utils.dart'; // Import order_utils
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return AppColors.warningOrange;
      case 'awaiting_confirmation':
        return AppColors.primaryTeal;
      case 'processing':
        return AppColors.primaryTeal;
      case 'shipped':
        return AppColors.primaryGreen;
      case 'delivered':
        return AppColors.primaryGreen;
      case 'cancelled':
        return AppColors.errorRed;
      default:
        return AppColors.modernGrey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending_payment':
        return Icons.payment_outlined;
      case 'awaiting_confirmation':
        return Icons.hourglass_top_outlined;
      case 'processing':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outline_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูคำสั่งซื้อ'));
    }

    return Scaffold(
      // AppBar is handled by MainScreen
      // appBar: AppBar(
      //   title: const Text('ประวัติคำสั่งซื้อ'),
      // ),
      body: StreamBuilder<List<app_order.Order>>(
        stream: firebaseService.getOrdersByUserId(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('คุณยังไม่มีคำสั่งซื้อ'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final order = orders[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                child: ListTile(
                  leading: Icon(_getStatusIcon(order.status),
                      color: _getStatusColor(order.status), size: 30),
                  title: Text('คำสั่งซื้อ #${order.id.substring(0, 8)}',
                      style: AppTextStyles.subtitleBold),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'วันที่: ${DateFormat('dd MMM yyyy, HH:mm', 'th_TH').format(order.orderDate.toDate())}'),
                      Text('ยอดรวม: ฿${order.totalAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyBold
                              .copyWith(color: AppColors.primaryGreen)),
                      Text(
                          'สถานะ: ${getOrderStatusText(order.status)}', // Use utility function
                          style: AppTextStyles.bodySmall.copyWith(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.w600)),
                      // Show tracking number if available
                      if (order.trackingNumber != null &&
                          order.trackingNumber!.isNotEmpty)
                        Text('หมายเลขติดตาม: ${order.trackingNumber}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.primaryTeal)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Track Package Button for shipped orders
                      if ((order.status == 'shipped' ||
                              order.status == 'delivered') &&
                          (order.trackingNumber != null ||
                              order.trackingUrl != null))
                        IconButton(
                          icon: Icon(Icons.track_changes,
                              color: AppColors.primaryTeal),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderTrackingScreen(order: order),
                              ),
                            );
                          },
                          tooltip: 'ติดตามพัสดุ',
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          BuyerOrderDetailScreen(order: order),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
