// lib/screens/seller/seller_dashboard_screen_premium.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:green_market/screens/seller/seller_notifications_screen.dart';
import 'package:green_market/screens/seller/enhanced_shipping_management_screen.dart';
import 'package:green_market/screens/seller/promotion_management_screen.dart';
import 'package:green_market/screens/seller/shop_customization_screen.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/screens/seller/shop_preview_screen.dart';

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
        // โหลดข้อมูลจริงแบบ Parallel จาก Firebase
        final results = await Future.wait([
          // ข้อมูลผู้ขาย
          FirebaseFirestore.instance.collection('sellers').doc(user.uid).get(),

          // จำนวนสินค้าทั้งหมด
          FirebaseFirestore.instance
              .collection('products')
              .where('sellerId', isEqualTo: user.uid)
              .get(),

          // คำสั่งซื้อทั้งหมด
          FirebaseFirestore.instance
              .collection('orders')
              .where('sellerId', isEqualTo: user.uid)
              .get(),
        ]);

        final sellerDoc = results[0] as DocumentSnapshot;
        final productsQuery = results[1] as QuerySnapshot;
        final ordersQuery = results[2] as QuerySnapshot;

        // คำนวณสถิติจากข้อมูลจริง
        double totalRevenue = 0;
        double todayRevenue = 0;
        int newOrders = 0;
        int pendingOrders = 0;
        int processingOrders = 0;
        int completedOrders = 0;
        int todayOrders = 0;
        int cancelledOrders = 0;

        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);

        for (var orderDoc in ordersQuery.docs) {
          final orderData = orderDoc.data() as Map<String, dynamic>;
          final status = orderData['status'] as String? ?? '';
          final total = (orderData['total'] as num?)?.toDouble() ?? 0.0;
          final orderDate = (orderData['createdAt'] as Timestamp?)?.toDate();

          // คำนวณยอดขายรวม
          if (status == 'completed') {
            totalRevenue += total;
          }

          // คำนวณยอดขายวันนี้
          if (orderDate != null &&
              orderDate.isAfter(startOfToday) &&
              status == 'completed') {
            todayRevenue += total;
            todayOrders++;
          }

          // นับสถานะคำสั่งซื้อ
          switch (status) {
            case 'pending':
              pendingOrders++;
              break;
            case 'confirmed':
            case 'processing':
              processingOrders++;
              break;
            case 'completed':
              completedOrders++;
              break;
            case 'cancelled':
              cancelledOrders++;
              break;
            default:
              newOrders++;
          }

          // คำสั่งซื้อใหม่ (สถานะใหม่หรือรอดำเนินการ)
          if (status == 'new' || status == 'pending') {
            newOrders++;
          }
        }

        setState(() {
          _dashboardData = {
            // ข้อมูลร้านค้า
            'shopName': sellerDoc.exists ? sellerDoc.get('shopName') : null,
            'shopDescription':
                sellerDoc.exists ? sellerDoc.get('shopDescription') : null,
            'shopImage': sellerDoc.exists ? sellerDoc.get('shopImage') : null,
            'rating': sellerDoc.exists ? (sellerDoc.get('rating') ?? 0.0) : 0.0,
            'totalReviews':
                sellerDoc.exists ? (sellerDoc.get('totalReviews') ?? 0) : 0,

            // สถิติสินค้า
            'totalProducts': productsQuery.docs.length,
            'activeProducts': productsQuery.docs
                .where((doc) =>
                    (doc.data() as Map<String, dynamic>)['isActive'] == true)
                .length,

            // สถิติคำสั่งซื้อ
            'totalOrders': ordersQuery.docs.length,
            'newOrders': newOrders,
            'pendingOrders': pendingOrders,
            'processingOrders': processingOrders,
            'completedOrders': completedOrders,
            'cancelledOrders': cancelledOrders,
            'todayOrders': todayOrders,

            // สถิติการขาย
            'totalRevenue': totalRevenue,
            'todayRevenue': todayRevenue,
            'todaySales': todayRevenue, // เพื่อความเข้ากันได้

            // สถิติอื่นๆ (จะแสดงเป็น 0 ถ้าไม่มีข้อมูล)
            'todayViews': 0, // ต้องเก็บข้อมูลแยก
            'newFollowers': 0, // ต้องเก็บข้อมูลแยก
            'conversionRate': ordersQuery.docs.isEmpty
                ? 0.0
                : (completedOrders / ordersQuery.docs.length * 100),
          };
        });
      } else {
        setState(() {
          _dashboardData = {};
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _dashboardData = {};
      });
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
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Welcome Card with Real-time Status
              _buildPremiumWelcomeCard(),
              const SizedBox(height: 20),

              // Enhanced Quick Stats
              _buildEnhancedQuickStats(),
              const SizedBox(height: 20),

              // Today Summary
              _buildTodaySummary(),
              const SizedBox(height: 20),

              // Premium Quick Actions
              _buildPremiumQuickActions(),
              const SizedBox(height: 20),

              // Orders Status Dashboard
              _buildOrdersStatusDashboard(),
              const SizedBox(height: 20),

              // Shop Management
              _buildShopManagement(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
            Color(0xFF43A047)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;
          final shopName = _dashboardData['shopName'] as String?;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: user?.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.store,
                                        size: 32, color: Color(0xFF2E7D32)),
                              ),
                            )
                          : const Icon(Icons.store,
                              size: 32, color: Color(0xFF2E7D32)),
                    ),
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shopName ?? 'ยังไม่ได้ตั้งชื่อร้าน',
                          style: TextStyle(
                            color: shopName != null
                                ? Colors.white70
                                : Colors.amber[300],
                            fontSize: 15,
                            fontWeight: shopName != null
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'ผู้ขายยืนยัน',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Real-time Status Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _dashboardData['totalOrders'] != null &&
                                        _dashboardData['totalOrders'] > 0
                                    ? const Color(0xFF4CAF50).withOpacity(0.9)
                                    : Colors.orange.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _dashboardData['totalOrders'] != null &&
                                            _dashboardData['totalOrders'] > 0
                                        ? 'Active'
                                        : 'Setup',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Performance Summary Bar
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildMiniStatItem(
                                  'สินค้า',
                                  '${_dashboardData['totalProducts'] ?? 0}',
                                  Icons.inventory_2,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 20,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              Expanded(
                                child: _buildMiniStatItem(
                                  'คำสั่งซื้อ',
                                  '${_dashboardData['totalOrders'] ?? 0}',
                                  Icons.shopping_cart,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 20,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              Expanded(
                                child: _buildMiniStatItem(
                                  'รายได้',
                                  '฿${(_dashboardData['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                                  Icons.monetization_on,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedQuickStats() {
    return Column(
      children: [
        // Top Row - Main Metrics
        Row(
          children: [
            Expanded(
              child: _buildPremiumStatCard(
                'สินค้าทั้งหมด',
                '${_dashboardData['totalProducts'] ?? 0}',
                '${_dashboardData['activeProducts'] ?? 0} ใช้งาน',
                Icons.inventory_2_outlined,
                const Color(0xFF1976D2),
                const Color(0xFFE3F2FD),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPremiumStatCard(
                'คำสั่งซื้อวันนี้',
                '${_dashboardData['todayOrders'] ?? 0}',
                'คำสั่งใหม่',
                Icons.shopping_cart_outlined,
                const Color(0xFFFF9800),
                const Color(0xFFFFF3E0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom Row - Financial Metrics
        Row(
          children: [
            Expanded(
              child: _buildPremiumStatCard(
                'ยอดขายวันนี้',
                '฿${(_dashboardData['todayRevenue'] ?? 0).toStringAsFixed(0)}',
                'รายได้รวม ฿${(_dashboardData['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                Icons.monetization_on_outlined,
                const Color(0xFF388E3C),
                const Color(0xFFE8F5E8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPremiumStatCard(
                'คะแนนร้าน',
                '${(_dashboardData['rating'] ?? 0.0).toStringAsFixed(1)}',
                '${_dashboardData['totalReviews'] ?? 0} รีวิว',
                Icons.star_outline,
                const Color(0xFFFBC02D),
                const Color(0xFFFFFDE7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumStatCard(String title, String mainValue, String subValue,
      IconData icon, Color iconColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Spacer(),
              if (mainValue != '0' && mainValue != '฿0')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 8),
              const Text(
                'สรุปประจำวัน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              Text(
                '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'การดูสินค้า:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                _dashboardData['todayViews'] == null ||
                        _dashboardData['todayViews'] == 0
                    ? 'ไม่มีข้อมูล'
                    : '${_dashboardData['todayViews']} ครั้ง',
                style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ผู้ติดตามใหม่:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                _dashboardData['newFollowers'] == null ||
                        _dashboardData['newFollowers'] == 0
                    ? 'ไม่มีข้อมูล'
                    : '${_dashboardData['newFollowers']} คน',
                style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'อัตราการแปลง:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                _dashboardData['conversionRate'] == null ||
                        _dashboardData['conversionRate'] == 0
                    ? 'ไม่มีข้อมูล'
                    : '${(_dashboardData['conversionRate'] as double).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 8),
              const Text(
                'การดำเนินการด่วน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pro',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // First Row of Actions
          Row(
            children: [
              Expanded(
                child: _buildPremiumActionCard(
                  'เพิ่มสินค้าใหม่',
                  'สร้างรายการสินค้า',
                  Icons.add_circle_outline,
                  const Color(0xFF4CAF50),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddProductScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionCard(
                  'จัดการสินค้า',
                  '${_dashboardData['totalProducts'] ?? 0} รายการ',
                  Icons.inventory_outlined,
                  const Color(0xFF2196F3),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyProductsScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Second Row of Actions
          Row(
            children: [
              Expanded(
                child: _buildPremiumActionCard(
                  'คำสั่งซื้อ',
                  '${_dashboardData['newOrders'] ?? 0} ใหม่',
                  Icons.shopping_bag_outlined,
                  const Color(0xFFFF9800),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SellerOrdersScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionCard(
                  'การจัดส่ง',
                  'จัดการพัสดุ',
                  Icons.local_shipping_outlined,
                  const Color(0xFF9C27B0),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const EnhancedShippingManagementScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Third Row - Smart Actions with AI Insights
          _buildSmartActionCard(
            'เปลี่ยนทีมร้าน',
            'อัปเดตลุคร้านค้า',
            Icons.palette_outlined,
            const Color(0xFF795548),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ShopCustomizationScreen(
                        sellerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                      )),
            ),
            hasAlert: (_dashboardData['totalProducts'] as int? ?? 0) < 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isPriority = false,
    bool hasAlert = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isPriority ? color.withOpacity(0.15) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isPriority
                    ? color.withOpacity(0.4)
                    : color.withOpacity(0.2),
                width: isPriority ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      if (hasAlert || isPriority)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (isPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ด่วน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.arrow_forward_ios, size: 14, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPriority ? color : color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.7),
                  fontWeight: isPriority ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersStatusDashboard() {
    final totalOrders = _dashboardData['totalOrders'] as int? ?? 0;
    final newOrders = _dashboardData['newOrders'] as int? ?? 0;
    final pendingOrders = _dashboardData['pendingOrders'] as int? ?? 0;
    final processingOrders = _dashboardData['processingOrders'] as int? ?? 0;
    final completedOrders = _dashboardData['completedOrders'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment,
                      color: Color(0xFF2E7D32), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'สถานะคำสั่งซื้อ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (totalOrders == 0)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'ยังไม่มีคำสั่งซื้อ',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildOrderStatusCard(
                    'ใหม่',
                    newOrders,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOrderStatusCard(
                    'รอดำเนินการ',
                    pendingOrders,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildOrderStatusCard(
                    'กำลังดำเนินการ',
                    processingOrders,
                    const Color(0xFF9C27B0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOrderStatusCard(
                    'เสร็จสิ้น',
                    completedOrders,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text('จัดการคำสั่งซื้อ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShopManagement() {
    final shopName = _dashboardData['shopName'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 8),
              const Text(
                'จัดการร้านค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (shopName == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.amber),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'กรุณาตั้งชื่อร้านค้าเพื่อเริ่มต้นการขาย',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.animateTo(5),
                    child: const Text('ตั้งค่า'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ปุ่มแถวแรก
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShopPreviewScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('ดูหน้าร้าน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _tabController.animateTo(5),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('ตั้งค่า'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ปุ่มแถวที่สอง - เปลี่ยนทีม
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopCustomizationScreen(
                    sellerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                ),
              ),
              icon: const Icon(Icons.palette_outlined),
              label: const Text('ธีมร้านค้า (ครบครัน)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF795548),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text('สถิติการขาย - Coming Soon'),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return const ShopSettingsScreen();
  }
}
