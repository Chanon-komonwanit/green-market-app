// lib/screens/buyer_order_list_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/screens/buyer_order_detail_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BuyerOrderListScreen extends StatelessWidget {
  const BuyerOrderListScreen({super.key});

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'รอการชำระเงิน';
      case 'pending_delivery':
        return 'รอการจัดส่ง';
      case 'processing':
        return 'กำลังเตรียมจัดส่ง';
      case 'shipped':
        return 'จัดส่งแล้ว';
      case 'delivered':
        return 'จัดส่งสำเร็จ';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orangeAccent;
      case 'pending_delivery':
      case 'processing':
        return Colors.blueAccent;
      case 'shipped':
        return AppColors.accentGreen;
      case 'delivered':
        return AppColors.primaryGreen;
      case 'cancelled':
        return AppColors.errorRed;
      default:
        return AppColors.darkGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
          child: Text('กรุณาเข้าสู่ระบบเพื่อดูคำสั่งซื้อของคุณ'));
    }
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      // AppBar is part of HomeScreen now for this tab
      // appBar: AppBar(
      //   title: const Text('ประวัติคำสั่งซื้อ'),
      // ),
      body: StreamBuilder<List<app_order.Order>>(
        stream: firebaseService.getOrdersForUser(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      // ignore: deprecated_member_use
                      size: 80,
                      // ignore: deprecated_member_use
                      color: AppColors.darkGrey.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  Text('คุณยังไม่มีคำสั่งซื้อ', style: AppTextStyles.subtitle),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          final DateFormat dateFormat = DateFormat('dd MMM yyyy, HH:mm');

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          BuyerOrderDetailScreen(order: order),
                    ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'คำสั่งซื้อ #${order.id.substring(0, 8)}',
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status)
                                    // ignore: deprecated_member_use
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(order.status),
                                style: AppTextStyles.body.copyWith(
                                    color: _getStatusColor(order.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'วันที่สั่ง: ${dateFormat.format(order.orderDate.toDate().toLocal())}',
                          style: AppTextStyles.body.copyWith(
                              fontSize: 12, color: AppColors.darkGrey),
                        ),
                        const Divider(height: 16),
                        // Display first product image and name as a preview
                        if (order.items.isNotEmpty)
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  order.items[0].imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => const Icon(
                                      Icons.image,
                                      size: 50,
                                      color: AppColors.lightGrey),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  order.items[0].productName +
                                      (order.items.length > 1
                                          ? ' และอื่นๆ'
                                          : ''),
                                  style:
                                      AppTextStyles.body.copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${order.items.length} รายการ',
                              style: AppTextStyles.body.copyWith(
                                  fontSize: 14, color: AppColors.darkGrey),
                            ),
                            Text(
                              'ยอดรวม: ฿${order.totalAmount.toStringAsFixed(2)}',
                              style: AppTextStyles.price.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
