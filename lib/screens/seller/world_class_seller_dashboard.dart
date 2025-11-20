// lib/screens/seller/world_class_seller_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:green_market/screens/seller/promotion_management_screen.dart';
import 'package:green_market/screens/seller/enhanced_shipping_management_screen.dart';
import 'package:green_market/screens/seller/shop_customization_screen.dart';
import 'package:green_market/screens/seller/shop_preview_screen.dart';
import 'package:green_market/screens/seller/professional_product_management.dart';
import 'package:green_market/screens/seller/sophisticated_order_hub.dart';

/// 🌟 World-Class Seller Dashboard like Shopee/Lazada with Green Market concept
/// Enhanced with advanced analytics, business intelligence, and environmental focus
class WorldClassSellerDashboard extends StatefulWidget {
  const WorldClassSellerDashboard({super.key});

  @override
  State<WorldClassSellerDashboard> createState() =>
      _WorldClassSellerDashboardState();
}

class _WorldClassSellerDashboardState extends State<WorldClassSellerDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  String _selectedTimeRange = '7d';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadDashboardData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Load comprehensive dashboard data
      await _loadBasicStats(userId);
      await _loadAdvancedAnalytics(userId);
      await _loadGreenMetrics(userId);
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBasicStats(String userId) async {
    // Basic seller statistics
    final sellerDoc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(userId)
        .get();

    final productsQuery = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: userId)
        .get();

    final ordersQuery = await FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: userId)
        .get();

    // Calculate revenue and order stats
    double totalRevenue = 0;
    double todayRevenue = 0;
    int todayOrders = 0;
    int newOrders = 0;
    int processingOrders = 0;
    int completedOrders = 0;
    int cancelledOrders = 0;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (var doc in ordersQuery.docs) {
      final data = doc.data();
      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final status = data['status'] as String? ?? 'pending';

      totalRevenue += total;

      if (createdAt.isAfter(todayStart)) {
        todayRevenue += total;
        todayOrders++;
      }

      switch (status) {
        case 'pending':
        case 'new':
          newOrders++;
          break;
        case 'processing':
        case 'confirmed':
          processingOrders++;
          break;
        case 'completed':
        case 'delivered':
          completedOrders++;
          break;
        case 'cancelled':
          cancelledOrders++;
          break;
      }
    }

    setState(() {
      _dashboardData = {
        // Shop info
        'shopName':
            sellerDoc.exists ? sellerDoc.get('shopName') : 'ร้านค้าของคุณ',
        'rating': sellerDoc.exists ? (sellerDoc.get('rating') ?? 0.0) : 0.0,
        'totalReviews':
            sellerDoc.exists ? (sellerDoc.get('totalReviews') ?? 0) : 0,

        // Products
        'totalProducts': productsQuery.docs.length,
        'activeProducts': productsQuery.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length,

        // Orders
        'totalOrders': ordersQuery.docs.length,
        'newOrders': newOrders,
        'processingOrders': processingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'todayOrders': todayOrders,

        // Revenue
        'totalRevenue': totalRevenue,
        'todayRevenue': todayRevenue,

        // Performance metrics (simulated for now)
        'todayViews': 245,
        'conversionRate': ordersQuery.docs.isEmpty
            ? 0.0
            : (completedOrders / ordersQuery.docs.length * 100),
        'avgOrderValue': ordersQuery.docs.isEmpty
            ? 0.0
            : totalRevenue / ordersQuery.docs.length,
      };
    });
  }

  Future<void> _loadAdvancedAnalytics(String userId) async {
    // Load advanced analytics data for charts and insights
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));

    // Sales chart data (simulated with realistic patterns)
    final salesData = <FlSpot>[];
    final orderData = <FlSpot>[];

    for (int i = 0; i < 7; i++) {
      final day = last7Days.add(Duration(days: i));
      // Simulate realistic sales data with weekend patterns
      double sales = 1200 + (i * 150) + (day.weekday > 5 ? 300 : 0);
      int orders = 8 + (i * 2) + (day.weekday > 5 ? 5 : 0);

      salesData.add(FlSpot(i.toDouble(), sales));
      orderData.add(FlSpot(i.toDouble(), orders.toDouble()));
    }

    setState(() {
      _analyticsData = {
        'salesChart': salesData,
        'ordersChart': orderData,
        'topCategories': [
          {
            'name': 'อาหารออร์แกนิก',
            'sales': 34.5,
            'color': const Color(0xFF4CAF50)
          },
          {
            'name': 'ผลิตภัณฑ์ธรรมชาติ',
            'sales': 28.2,
            'color': const Color(0xFF8BC34A)
          },
          {
            'name': 'เครื่องใช้รีไซเคิล',
            'sales': 19.8,
            'color': const Color(0xFF009688)
          },
          {'name': 'อื่นๆ', 'sales': 17.5, 'color': const Color(0xFF607D8B)},
        ],
        'performanceScore': 87.5,
        'marketingROI': 234.5,
        'customerSatisfaction': 4.6,
      };
    });
  }

  Future<void> _loadGreenMetrics(String userId) async {
    // Green Market specific metrics
    setState(() {
      _dashboardData.addAll({
        'carbonSaved': 45.2, // kg CO2
        'ecoScore': 92,
        'sustainableProducts': 23,
        'greenCertifications': 5,
        'environmentalImpact': 'สูง',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildWorldClassAppBar(),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardOverview(),
                  _buildAdvancedAnalytics(),
                  _buildProductManagement(),
                  _buildOrderHub(),
                  _buildMarketingCenter(),
                  _buildGreenImpact(),
                  _buildBusinessTools(),
                ],
              ),
            ),
    );
  }

  Widget _buildWorldClassAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1B5E20),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF388E3C),
                Color(0xFF4CAF50),
              ],
            ),
          ),
          child: _buildPremiumHeader(),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2E7D32),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'ภาพรวม'),
              Tab(text: 'วิเคราะห์'),
              Tab(text: 'สินค้า'),
              Tab(text: 'ออเดอร์'),
              Tab(text: 'การตลาด'),
              Tab(text: 'Green Impact'),
              Tab(text: 'เครื่องมือ'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with shop info and performance badge
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.store, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dashboardData['shopName'] ?? 'ร้านค้าของคุณ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' ${(_dashboardData['rating'] ?? 0.0).toStringAsFixed(1)} (${_dashboardData['totalReviews'] ?? 0})',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildPerformanceBadge(),
            ],
          ),

          const SizedBox(height: 20),

          // Revenue metrics row
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  'ยอดขายวันนี้',
                  '฿${(_dashboardData['todayRevenue'] ?? 0).toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeaderMetric(
                  'คำสั่งซื้อใหม่',
                  '${_dashboardData['newOrders'] ?? 0}',
                  Icons.shopping_cart,
                  Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Green metrics row
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  'CO₂ ที่ช่วยลด',
                  '${(_dashboardData['carbonSaved'] ?? 0).toStringAsFixed(1)} kg',
                  Icons.eco,
                  Colors.lightGreenAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeaderMetric(
                  'คะแนน Eco',
                  '${_dashboardData['ecoScore'] ?? 0}/100',
                  Icons.grade,
                  Colors.lightGreenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBadge() {
    final score = _analyticsData['performanceScore'] ?? 0.0;
    String level = 'เริ่มต้น';
    Color color = Colors.grey;

    if (score >= 90) {
      level = 'ระดับเพชร';
      color = const Color(0xFF9C27B0);
    } else if (score >= 80) {
      level = 'ระดับทอง';
      color = const Color(0xFFFFD700);
    } else if (score >= 70) {
      level = 'ระดับเงิน';
      color = const Color(0xFFC0C0C0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(
      String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickStatsGrid(),
          const SizedBox(height: 20),
          _buildRevenueChart(),
          const SizedBox(height: 20),
          _buildQuickActionsGrid(),
          const SizedBox(height: 20),
          _buildRecentOrdersPreview(),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'ยอดขายรวม',
          '฿${(_dashboardData['totalRevenue'] ?? 0).toStringAsFixed(0)}',
          'เพิ่มขึ้น 12.5%',
          Icons.monetization_on,
          const Color(0xFF4CAF50),
          true,
        ),
        _buildStatCard(
          'สินค้าทั้งหมด',
          '${_dashboardData['totalProducts'] ?? 0}',
          '${_dashboardData['activeProducts'] ?? 0} รายการใช้งาน',
          Icons.inventory,
          const Color(0xFF2196F3),
          false,
        ),
        _buildStatCard(
          'อัตราการแปลง',
          '${(_dashboardData['conversionRate'] ?? 0.0).toStringAsFixed(1)}%',
          'เป้าหมาย 15%',
          Icons.trending_up,
          const Color(0xFFFF9800),
          false,
        ),
        _buildStatCard(
          'มูลค่าเฉลี่ย/ออเดอร์',
          '฿${(_dashboardData['avgOrderValue'] ?? 0.0).toStringAsFixed(0)}',
          'เพิ่มขึ้น 8.2%',
          Icons.receipt,
          const Color(0xFF9C27B0),
          true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color color, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (isPositive)
                const Icon(Icons.arrow_upward,
                    color: Color(0xFF4CAF50), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isPositive ? const Color(0xFF4CAF50) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              const Text(
                'แนวโน้มยอดขาย',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              _buildTimeRangeSelector(),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 500,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '฿${value.toInt()}',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
                        return Text(
                          days[value.toInt() % 7],
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _analyticsData['salesChart'] ?? [],
                    isCurved: true,
                    color: const Color(0xFF4CAF50),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF4CAF50),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withOpacity(0.3),
                          const Color(0xFF4CAF50).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeRangeButton('7วัน', '7d'),
          _buildTimeRangeButton('30วัน', '30d'),
          _buildTimeRangeButton('3เดือน', '3m'),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, String value) {
    final isSelected = _selectedTimeRange == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeRange = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การดำเนินการด่วน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
            children: [
              _buildQuickActionCard(
                'เพิ่มสินค้า',
                Icons.add_circle_outline,
                const Color(0xFF4CAF50),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddProductScreen()),
                ),
              ),
              _buildQuickActionCard(
                'จัดการคำสั่งซื้อ',
                Icons.shopping_cart_outlined,
                const Color(0xFFFF9800),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SellerOrdersScreen()),
                ),
              ),
              _buildQuickActionCard(
                'โปรโมชั่น',
                Icons.local_offer_outlined,
                const Color(0xFFE91E63),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PromotionManagementScreen()),
                ),
              ),
              _buildQuickActionCard(
                'การจัดส่ง',
                Icons.local_shipping_outlined,
                const Color(0xFF9C27B0),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const EnhancedShippingManagementScreen()),
                ),
              ),
              _buildQuickActionCard(
                'ตั้งค่าร้าน',
                Icons.store_outlined,
                const Color(0xFF607D8B),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ShopSettingsScreen()),
                ),
              ),
              _buildQuickActionCard(
                'ปรับแต่งร้าน',
                Icons.palette_outlined,
                const Color(0xFF795548),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopCustomizationScreen(
                      sellerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              const Text(
                'คำสั่งซื้อล่าสุด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _tabController.animateTo(3); // Navigate to Orders tab
                },
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sample recent orders (replace with real data)
          _buildOrderPreviewItem(
              'ORD-001', 'สินค้าออร์แกนิก 3 รายการ', '฿450', 'ใหม่'),
          _buildOrderPreviewItem(
              'ORD-002', 'ผลิตภัณฑ์รีไซเคิล', '฿320', 'กำลังดำเนินการ'),
          _buildOrderPreviewItem(
              'ORD-003', 'เครื่องใช้ไผ่', '฿680', 'พร้อมจัดส่ง'),
        ],
      ),
    );
  }

  Widget _buildOrderPreviewItem(
      String orderId, String items, String amount, String status) {
    Color statusColor = Colors.grey;
    switch (status) {
      case 'ใหม่':
        statusColor = const Color(0xFFFF9800);
        break;
      case 'กำลังดำเนินการ':
        statusColor = const Color(0xFF2196F3);
        break;
      case 'พร้อมจัดส่ง':
        statusColor = const Color(0xFF4CAF50);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_long, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  items,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Placeholder methods for other tabs (will be implemented in next steps)
  Widget _buildAdvancedAnalytics() {
    return const Center(child: Text('Advanced Analytics - Coming Next'));
  }

  Widget _buildProductManagement() {
    return const ProfessionalProductManagement();
  }

  Widget _buildOrderHub() {
    return const SophisticatedOrderHub();
  }

  Widget _buildMarketingCenter() {
    return const PromotionManagementScreen();
  }

  Widget _buildGreenImpact() {
    return const Center(child: Text('Green Impact Dashboard - Coming Next'));
  }

  Widget _buildBusinessTools() {
    return const Center(child: Text('Business Tools - Coming Next'));
  }
}
