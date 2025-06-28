// lib/screens/seller/seller_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/screens/seller/seller_order_detail_screen.dart'; // Use seller-specific detail screen

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('คำสั่งซื้อของร้าน',
              style: AppTextStyles.title.copyWith(color: AppColors.white)),
          backgroundColor: AppColors.primaryTeal,
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: const Center(
            child: Text('กรุณาเข้าสู่ระบบเพื่อดูคำสั่งซื้อของร้านคุณ')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('คำสั่งซื้อของร้าน',
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: StreamBuilder<List<app_order.Order>>(
        stream: firebaseService.getOrdersBySellerId(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    'เกิดข้อผิดพลาดในการโหลดคำสั่งซื้อ: ${snapshot.error}',
                    style: AppTextStyles.body));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('ยังไม่มีคำสั่งซื้อสำหรับร้านค้าของคุณ',
                    style: AppTextStyles.body));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Filter items to show only those belonging to this seller
              // This assumes ProductInOrder has a sellerId or you can infer it.
              // For simplicity, we'll show all items in the order for now,
              // but ideally, you'd filter or highlight the seller's items.

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.veryLightTeal,
                    child: const Icon(Icons.receipt_long_outlined,
                        color: AppColors.primaryTeal),
                  ),
                  title: Text('คำสั่งซื้อ #${order.id.substring(0, 8)}',
                      style: AppTextStyles.subtitle.copyWith(
                          fontSize: 16, color: AppColors.primaryTeal)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ลูกค้า: ${order.fullName}',
                          style: AppTextStyles.body.copyWith(fontSize: 14)),
                      Text(
                          'วันที่: ${order.orderDate.toDate().toLocal().toString().split('.')[0]}',
                          style: AppTextStyles.body.copyWith(fontSize: 14)),
                      Text(
                        'สถานะ: ${order.status.replaceAll('_', ' ').toUpperCase()}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: order.status == 'PENDING_PAYMENT'
                              ? AppColors.warningYellow
                              : (order.status == 'COMPLETED'
                                  ? AppColors.successGreen
                                  : AppColors.modernGrey),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                          'ยอดรวม (ทั้งออเดอร์): ฿${order.totalAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.body.copyWith(fontSize: 14)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: AppColors.lightModernGrey),
                  onTap: () {
                    // Use seller-specific order detail screen with status update functionality
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SellerOrderDetailScreen(order: order)),
                    );
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
