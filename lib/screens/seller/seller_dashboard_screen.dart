// lib/screens/seller/seller_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:green_market/screens/seller/shop_template_selector_screen.dart';
import 'package:green_market/screens/seller/shop_customization_screen.dart';
import 'package:green_market/screens/seller/seller_notifications_screen.dart';
import 'package:green_market/screens/seller/shipping_management_screen.dart';
import 'package:green_market/screens/seller/enhanced_shipping_management_screen.dart';
import 'package:green_market/screens/seller/promotion_management_screen.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:green_market/screens/seller/shop_preview_screen.dart';
import 'package:green_market/screens/shopee_style_shop_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load seller stats
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .get();

        if (sellerDoc.exists) {
          setState(() {
            _dashboardData = sellerDoc.data() ?? {};
          });
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('ร้านค้าของฉัน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SellerNotificationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'ภาพรวม'),
            Tab(icon: Icon(Icons.inventory_2), text: 'สินค้า'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'คำสั่งซื้อ'),
            Tab(icon: Icon(Icons.local_shipping), text: 'การจัดส่ง'),
            Tab(icon: Icon(Icons.bar_chart), text: 'สถิติ'),
            Tab(icon: Icon(Icons.settings), text: 'ตั้งค่า'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProductsTab(),
                _buildOrdersTab(),
                _buildShippingTab(),
                _buildAnalyticsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('กรุณาเข้าสู่ระบบ'),
      );
    }

    return Container(
      color: const Color(0xFFF8FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 16),

            // Quick Stats
            _buildQuickStats(),
            const SizedBox(height: 16),

            // Today Summary
            _buildTodaySummary(),
            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 16),

            // Recent Orders
            _buildRecentOrders(),
            const SizedBox(height: 16),

            // ปุ่มเปิดหน้าร้านในโหมดเต็ม
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShopPreviewScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('เปิดหน้าร้านแบบเต็ม'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: user?.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user!.photoUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.store,
                                      size: 30, color: Color(0xFF2E7D32)),
                            ),
                          )
                        : const Icon(Icons.store,
                            size: 30, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สวัสดี ${user?.displayName ?? "เจ้าของร้าน"}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dashboardData['shopName'] ?? 'ร้านค้า Green Market',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'ผู้ขายที่ได้รับการยืนยัน',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'สินค้าทั้งหมด',
            '${_dashboardData['totalProducts'] ?? 0}',
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'คำสั่งซื้อวันนี้',
            '${_dashboardData['todayOrders'] ?? 0}',
            Icons.shopping_cart,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'ยอดขายวันนี้',
            '฿${_dashboardData['todaySales'] ?? 0}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'คะแนนร้าน',
            '${(_dashboardData['rating'] ?? 0.0).toStringAsFixed(1)}',
            Icons.star,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การดำเนินการด่วน',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.0,
          children: [
            _buildActionCard(
              'เพิ่มสินค้าใหม่',
              Icons.add_box,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddProductScreen()),
              ),
            ),
            _buildActionCard(
              'จัดการสินค้า',
              Icons.inventory,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyProductsScreen()),
              ),
            ),
            _buildActionCard(
              'คำสั่งซื้อใหม่',
              Icons.notifications_active,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SellerOrdersScreen()),
              ),
            ),
            _buildActionCard(
              'จัดการการจัดส่ง',
              Icons.local_shipping,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const EnhancedShippingManagementScreen()),
              ),
            ),
            _buildActionCard(
              'จัดการโปรโมชั่น',
              Icons.local_offer,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PromotionManagementScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'คำสั่งซื้อล่าสุด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('ดูทั้งหมด'),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('ยังไม่มีคำสั่งซื้อใหม่',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปประจำวัน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('การดูสินค้า:'),
              Text('${_dashboardData['todayViews'] ?? 0} ครั้ง'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ผู้ติดตามใหม่:'),
              Text('${_dashboardData['newFollowers'] ?? 0} คน'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('อัตราการแปลง:'),
              Text(
                  '${(_dashboardData['conversionRate'] ?? 0.0).toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return const MyProductsScreen();
  }

  Widget _buildOrdersTab() {
    return const SellerOrdersScreen();
  }

  Widget _buildShippingTab() {
    return const EnhancedShippingManagementScreen();
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถิติร้านค้า',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCards(),
          const SizedBox(height: 24),
          _buildSalesChart(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'ยอดขายรวม',
                '฿${_dashboardData['totalSales'] ?? 0}',
                Icons.monetization_on,
                Colors.green,
                '+12.5%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'คำสั่งซื้อรวม',
                '${_dashboardData['totalOrders'] ?? 0}',
                Icons.shopping_cart,
                Colors.blue,
                '+8.3%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'ลูกค้าใหม่',
                '${_dashboardData['newCustomers'] ?? 0}',
                Icons.person_add,
                Colors.orange,
                '+15.2%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'สินค้าขายดี',
                '${_dashboardData['topProducts'] ?? 0}',
                Icons.trending_up,
                Colors.purple,
                '+5.7%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                change,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'กราฟยอดขาย (7 วันล่าสุด)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('กราฟยอดขายจะแสดงที่นี่',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Container(
      color: const Color(0xFFF8FAFB),
      child: Column(
        children: [
          // Header สำหรับตั้งค่า
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ตั้งค่าร้านค้า',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'จัดการข้อมูลร้านค้าและธีมของคุณ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // ปุ่มตั้งค่าต่างๆ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ตั้งค่าข้อมูลร้าน
                  _buildSettingCard(
                    icon: Icons.store,
                    title: 'ข้อมูลร้านค้า',
                    subtitle: 'ชื่อร้าน, รายละเอียด, ข้อมูลติดต่อ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShopSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ตั้งค่าธีมร้าน
                  _buildSettingCard(
                    icon: Icons.palette,
                    title: 'ธีมร้านค้า',
                    subtitle: 'เลือกธีมสำเร็จรูปแบบ Shopee หรือปรับแต่งเอง',
                    onTap: () {
                      // แสดง Dialog ให้เลือกระหว่าง Template หรือ Custom
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('เลือกวิธีตั้งค่าธีม'),
                          content: const Text(
                              'คุณต้องการใช้ธีมสำเร็จรูปหรือปรับแต่งเองครับ?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ShopTemplateSelectorScreen(),
                                  ),
                                );
                              },
                              child: const Text('ธีมสำเร็จรูป 🎨'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ShopCustomizationScreen(
                                      sellerId: FirebaseAuth
                                              .instance.currentUser?.uid ??
                                          '',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('ปรับแต่งเอง ⚙️'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ตั้งค่าการจัดส่ง
                  _buildSettingCard(
                    icon: Icons.local_shipping,
                    title: 'การจัดส่ง',
                    subtitle: 'จัดการวิธีการและค่าจัดส่ง',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EnhancedShippingManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // การแจ้งเตือน
                  _buildSettingCard(
                    icon: Icons.notifications,
                    title: 'การแจ้งเตือน',
                    subtitle: 'ตั้งค่าการแจ้งเตือนคำสั่งซื้อและข้อความ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SellerNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ปุ่มดูหน้าร้าน
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // ตรวจสอบข้อมูลร้านก่อนเปิด
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          // แสดง loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            // ตรวจสอบว่ามีข้อมูลร้านหรือไม่
                            final sellerDoc = await FirebaseFirestore.instance
                                .collection('sellers')
                                .doc(user.uid)
                                .get();

                            Navigator.pop(context); // ปิด loading

                            if (sellerDoc.exists && sellerDoc.data() != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ShopPreviewScreen(),
                                ),
                              );
                            } else {
                              // ถ้าไม่มีข้อมูลร้าน แนะนำให้ตั้งค่าก่อน
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'กรุณาตั้งค่าข้อมูลร้านค้าก่อนดูหน้าร้าน'),
                                  backgroundColor: Colors.orange,
                                ),
                              );

                              // เปิดหน้าตั้งค่าร้าน
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ShopSettingsScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context); // ปิด loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('เกิดข้อผิดพลาด: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('ดูหน้าร้านของฉัน'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2E7D32),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
