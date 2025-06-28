// lib/screens/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' // Assuming Order model exists
    as app_order; // ใช้ Order model ของเรา
import 'package:green_market/main_app_shell.dart'; // For navigating back to home
import 'package:green_market/utils/constants.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final app_order.Order order; // รับข้อมูลคำสั่งซื้อที่สำเร็จ
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Removed deprecated withOpacity
        // AppBar will use app's theme
        title: const Text('ยืนยันคำสั่งซื้อ'), // Corrected: Already correct
        automaticallyImplyLeading: false, // ไม่แสดงปุ่มย้อนกลับอัตโนมัติ
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 100, color: AppColors.primaryGreen),
              const SizedBox(height: 20),
              Text(
                  order.paymentMethod == 'cash_on_delivery'
                      ? 'สั่งซื้อสินค้าสำเร็จ!'
                      : 'การชำระเงินของคุณได้รับการยืนยันแล้ว!', // Or a more general success message
                  style: AppTextStyles.title // Corrected: Already correct
                      .copyWith(color: AppColors.primaryGreen)),
              const SizedBox(height: 10),
              Text(
                  'คำสั่งซื้อ #${order.id.substring(0, 8)}', // Corrected: Use withAlpha
                  style: AppTextStyles.subtitle),
              const SizedBox(height: 20),
              Text('คุณสามารถตรวจสอบสถานะคำสั่งซื้อได้ที่หน้าประวัติคำสั่งซื้อ',
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.modernGrey)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // กลับไปหน้าแรกสุด (Home Screen)
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const MainAppShell()),
                      (route) => false);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen),
                child: Text('กลับสู่หน้าหลัก',
                    style: AppTextStyles.subtitle
                        .copyWith(color: AppColors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
