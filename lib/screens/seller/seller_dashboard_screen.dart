// lib/screens/seller/seller_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/screens/seller/add_product_screen.dart'; // Import AddProductScreen
import 'package:green_market/screens/seller/my_products_screen.dart'; // Import MyProductsScreen
import 'package:green_market/screens/seller/seller_orders_screen.dart'; // Import SellerOrdersScreen
import 'package:green_market/screens/seller/shop_settings_screen.dart'; // Import ShopSettingsScreen
import 'package:green_market/utils/constants.dart';
// Import other necessary screens for seller, e.g., AddProductScreenForSeller, SellerOrdersScreen

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data for dashboard items
    final List<DashboardItem> dashboardItems = [
      DashboardItem(
        icon: Icons.inventory_2_outlined,
        title: 'สินค้าของฉัน',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyProductsScreen()),
          );
        },
      ),
      DashboardItem(
        icon: Icons.add_circle_outline,
        title: 'เพิ่มสินค้าใหม่',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
      ),
      DashboardItem(
        icon: Icons.receipt_long_outlined,
        title: 'คำสั่งซื้อของร้าน',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SellerOrdersScreen()),
          );
        },
      ),
      DashboardItem(
        icon: Icons.store_mall_directory_outlined,
        title: 'ตั้งค่าร้านค้า',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShopSettingsScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('แดชบอร์ดผู้ขาย',
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.2,
        ),
        itemCount: dashboardItems.length,
        itemBuilder: (context, index) {
          final item = dashboardItems[index];
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(item.icon, size: 48, color: AppColors.primaryTeal),
                  const SizedBox(height: 12),
                  Text(item.title,
                      style: AppTextStyles.bodyBold
                          .copyWith(color: AppColors.modernDarkGrey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DashboardItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  DashboardItem({required this.icon, required this.title, required this.onTap});
}
