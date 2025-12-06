// lib/screens/seller/seller_dashboard_screen.dart
// 🌟 World-Class Seller Dashboard - Shopee/TikTok Shop Standard
// Redesigned for Green Market with modern UI/UX and comprehensive features

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:green_market/screens/seller/seller_notifications_screen.dart';
import 'package:green_market/screens/seller/promotion_management_screen.dart';
import 'package:green_market/screens/seller/enhanced_shipping_management_screen.dart';
import 'package:green_market/screens/seller/wallet_screen.dart';
import 'package:green_market/screens/seller/coupon_management_screen.dart';
import 'package:green_market/screens/seller/shop_analytics_screen.dart';
import 'package:green_market/screens/seller/complete_shop_theme_system.dart';
import 'package:green_market/screens/seller/advanced_promotions_screen.dart';
import 'package:green_market/screens/seller/customer_management_screen.dart';
import 'package:green_market/screens/seller/seller_notifications_center.dart';
import 'package:green_market/screens/seller/review_management_screen.dart';
import 'package:green_market/screens/seller/advanced_stock_management_screen.dart';
import 'package:green_market/screens/seller/preview_my_shop_screen.dart';
import 'package:green_market/screens/seller/auto_reply_settings_screen.dart';
import 'package:green_market/screens/seller/return_refund_management_screen.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/widgets/quick_stock_update_widget.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, List<double>> _chartData = {};
  bool _isLoading = true;
  String _selectedPeriod = '7d'; // 7d, 30d, 90d

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Parallel data loading
      final results = await Future.wait([
        _loadSellerStats(user.uid),
        _loadRecentOrders(user.uid),
        _loadTopProducts(user.uid),
        _loadChartData(user.uid),
      ]);

      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _recentOrders = results[1] as List<Map<String, dynamic>>;
        _topProducts = results[2] as List<Map<String, dynamic>>;
        _chartData = results[3] as Map<String, List<double>>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadSellerStats(String sellerId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfPeriod = _getStartOfPeriod(now, _selectedPeriod);

    // Load products
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .get();

    // Load orders for period
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPeriod))
        .get();

    // Calculate statistics
    int totalProducts = productsSnapshot.docs.length;
    int activeProducts = productsSnapshot.docs
        .where((doc) => (doc.data()['isActive'] ?? false))
        .length;
    int lowStockProducts = productsSnapshot.docs
        .where((doc) => ((doc.data()['stock'] ?? 0) as num) < 10)
        .length;

    double totalRevenue = 0;
    double todayRevenue = 0;
    int totalOrders = ordersSnapshot.docs.length;
    int todayOrders = 0;
    int pendingOrders = 0;
    int processingOrders = 0;
    int completedOrders = 0;
    int totalViews = 0;

    for (var order in ordersSnapshot.docs) {
      final data = order.data();
      final status = data['status'] as String? ?? '';
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      if (status == 'completed') {
        totalRevenue += total;
      }

      if (createdAt != null && createdAt.isAfter(startOfDay)) {
        todayOrders++;
        if (status == 'completed') {
          todayRevenue += total;
        }
      }

      // Count by status
      switch (status) {
        case 'pending':
          pendingOrders++;
          break;
        case 'processing':
        case 'confirmed':
          processingOrders++;
          break;
        case 'completed':
          completedOrders++;
          break;
      }
    }

    // Calculate views from products
    for (var product in productsSnapshot.docs) {
      totalViews += ((product.data()['views'] ?? 0) as num).toInt();
    }

    // Calculate conversion rate
    double conversionRate =
        totalViews > 0 ? (completedOrders / totalViews * 100) : 0;

    return {
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
      'totalOrders': totalOrders,
      'todayOrders': todayOrders,
      'pendingOrders': pendingOrders,
      'processingOrders': processingOrders,
      'completedOrders': completedOrders,
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'lowStockProducts': lowStockProducts,
      'totalViews': totalViews,
      'conversionRate': conversionRate,
    };
  }

  Future<List<Map<String, dynamic>>> _loadRecentOrders(String sellerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'customerName': data['fullName'] ?? 'ไม่ระบุชื่อ',
        'total': (data['total'] as num?)?.toDouble() ?? 0,
        'status': data['status'] ?? 'pending',
        'createdAt':
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'items': (data['items'] as List?)?.length ?? 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadTopProducts(String sellerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .where('isActive', isEqualTo: true)
        .orderBy('sold', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'ไม่มีชื่อ',
        'image': data['images'] != null && (data['images'] as List).isNotEmpty
            ? data['images'][0]
            : null,
        'price': (data['price'] as num?)?.toDouble() ?? 0,
        'sold': (data['sold'] as num?)?.toInt() ?? 0,
        'stock': (data['stock'] as num?)?.toInt() ?? 0,
        'views': (data['views'] as num?)?.toInt() ?? 0,
      };
    }).toList();
  }

  Future<Map<String, List<double>>> _loadChartData(String sellerId) async {
    final now = DateTime.now();
    final startOfPeriod = _getStartOfPeriod(now, _selectedPeriod);
    final days = _getDaysInPeriod(_selectedPeriod);

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPeriod))
        .get();

    // Initialize daily data
    List<double> dailyRevenue = List.filled(days, 0);
    List<double> dailyOrders = List.filled(days, 0);

    for (var order in snapshot.docs) {
      final data = order.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final status = data['status'] as String? ?? '';
      final total = (data['total'] as num?)?.toDouble() ?? 0;

      if (createdAt != null && status == 'completed') {
        final dayIndex = now.difference(createdAt).inDays;
        if (dayIndex >= 0 && dayIndex < days) {
          final index = days - 1 - dayIndex; // Reverse for chronological order
          dailyRevenue[index] += total;
          dailyOrders[index] += 1;
        }
      }
    }

    return {
      'revenue': dailyRevenue,
      'orders': dailyOrders,
    };
  }

  DateTime _getStartOfPeriod(DateTime now, String period) {
    switch (period) {
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  int _getDaysInPeriod(String period) {
    switch (period) {
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      default:
        return 7;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildDashboardContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'ศูนย์ผู้ขาย',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Notifications
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SellerNotificationCenter(),
                  ),
                );
              },
            ),
            if ((_stats['pendingOrders'] ?? 0) > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${_stats['pendingOrders']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ShopSettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          SizedBox(height: 16),
          Text(
            'กำลังโหลดข้อมูล...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Cards
              _buildQuickStatsGrid(),
              const SizedBox(height: 20),

              // Quick Stock Update Widget
              const QuickStockUpdateWidget(),
              const SizedBox(height: 20),

              // Quick Action Buttons
              _buildQuickActions(),
              const SizedBox(height: 20),

              // Revenue Chart
              _buildRevenueChart(),
              const SizedBox(height: 20),

              // Recent Orders
              _buildRecentOrders(),
              const SizedBox(height: 20),

              // Top Products
              _buildTopProducts(),
              const SizedBox(height: 20),

              // Performance Insights
              _buildPerformanceInsights(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'ยอดขายวันนี้',
          value:
              '฿${NumberFormat('#,##0.00').format(_stats['todayRevenue'] ?? 0)}',
          icon: Icons.trending_up,
          color: const Color(0xFF4CAF50),
          subtitle: '${_stats['todayOrders'] ?? 0} คำสั่งซื้อ',
        ),
        _buildStatCard(
          title: 'รอดำเนินการ',
          value: '${_stats['pendingOrders'] ?? 0}',
          icon: Icons.pending_actions,
          color: const Color(0xFFFF9800),
          subtitle: 'คำสั่งซื้อใหม่',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
            );
          },
        ),
        _buildStatCard(
          title: 'ยอดขายรวม',
          value:
              '฿${NumberFormat('#,##0').format(_stats['totalRevenue'] ?? 0)}',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF2196F3),
          subtitle: 'ทั้งหมด ${_stats['completedOrders'] ?? 0} คำสั่ง',
        ),
        _buildStatCard(
          title: 'สินค้าทั้งหมด',
          value: '${_stats['totalProducts'] ?? 0}',
          icon: Icons.inventory_2,
          color: const Color(0xFF9C27B0),
          subtitle: 'ใช้งาน ${_stats['activeProducts'] ?? 0}',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProductsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final user = FirebaseAuth.instance.currentUser;
    final sellerId = user?.uid ?? '';

    final actions = [
      {
        'title': 'ดูหน้าร้าน',
        'icon': Icons.storefront,
        'color': const Color(0xFFE91E63),
        'onTap': () {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PreviewMyShopScreen(
                sellerId: sellerId,
                sellerName: userProvider.currentUser?.displayName ?? 'ร้านค้า',
              ),
            ),
          );
        },
      },
      {
        'title': 'เพิ่มสินค้า',
        'icon': Icons.add_circle_outline,
        'color': const Color(0xFF4CAF50),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            ),
      },
      {
        'title': 'คำสั่งซื้อ',
        'icon': Icons.receipt_long_outlined,
        'color': const Color(0xFF2196F3),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
            ),
      },
      {
        'title': 'สินค้าของฉัน',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFF9C27B0),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProductsScreen()),
            ),
      },
      {
        'title': 'สถิติร้านค้า',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF00BCD4),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopAnalyticsScreen()),
            ),
      },
      {
        'title': 'โปรโมชั่น',
        'icon': Icons.local_offer_outlined,
        'color': const Color(0xFFFF5722),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdvancedPromotionsScreen()),
            ),
      },
      {
        'title': 'กระเป๋าเงิน',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFFFFB300),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
      },
      {
        'title': 'การจัดส่ง',
        'icon': Icons.local_shipping_outlined,
        'color': const Color(0xFF5E35B1),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EnhancedShippingManagementScreen()),
            ),
      },
      {
        'title': 'ตั้งค่าร้าน',
        'icon': Icons.settings_outlined,
        'color': const Color(0xFF607D8B),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompleteShopThemeSystem(sellerId: sellerId),
              ),
            ),
      },
      {
        'title': 'Auto Reply',
        'icon': Icons.chat_bubble_outline,
        'color': const Color(0xFF00897B),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AutoReplySettingsScreen(),
              ),
            ),
      },
      {
        'title': 'คืนสินค้า/เงิน',
        'icon': Icons.assignment_return_outlined,
        'color': const Color(0xFFD32F2F),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReturnRefundManagementScreen(),
              ),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เมนูหลัก',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: actions.map((action) {
            return _buildActionCard(
              title: action['title'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              onTap: action['onTap'] as VoidCallback,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดขาย',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['7d', '30d', '90d'].map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedPeriod = period);
              _loadDashboardData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                period.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_chartData.isEmpty || _chartData['revenue']!.isEmpty) {
      return Center(
        child: Text(
          'ไม่มีข้อมูลในช่วงเวลานี้',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    final revenueData = _chartData['revenue']!;
    final maxRevenue = revenueData.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 1000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '฿${NumberFormat.compact().format(value)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getDaysInPeriod(_selectedPeriod) / 7,
              getTitlesWidget: (value, meta) {
                final days = _getDaysInPeriod(_selectedPeriod);
                final now = DateTime.now();
                final date =
                    now.subtract(Duration(days: days - value.toInt() - 1));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d/M').format(date),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (revenueData.length - 1).toDouble(),
        minY: 0,
        maxY: maxRevenue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: revenueData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            color: const Color(0xFF4CAF50),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF4CAF50),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4CAF50).withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '฿${NumberFormat('#,##0').format(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SellerOrdersScreen()),
                  );
                },
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentOrders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'ยังไม่มีคำสั่งซื้อ',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentOrders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                return _buildOrderItem(order);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final statusInfo = _getOrderStatusInfo(order['status']);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: statusInfo['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          statusInfo['icon'],
          color: statusInfo['color'],
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              order['customerName'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusInfo['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusInfo['text'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusInfo['color'],
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${order['items']} รายการ • ฿${NumberFormat('#,##0.00').format(order['total'])}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDateTime(order['createdAt']),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to order detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SellerOrdersScreen(),
          ),
        );
      },
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'สินค้าขายดี',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyProductsScreen()),
                  );
                },
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_topProducts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'ยังไม่มีสินค้า',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topProducts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = _topProducts[index];
                return _buildProductItem(product, index + 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product, int rank) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
              image: product['image'] != null
                  ? DecorationImage(
                      image: NetworkImage(product['image']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product['image'] == null
                ? const Icon(Icons.image, color: Colors.grey)
                : null,
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: rank <= 3 ? const Color(0xFFFFD700) : Colors.grey[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        product['name'],
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '฿${NumberFormat('#,##0.00').format(product['price'])}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'ขายแล้ว ${product['sold']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                ' • คงเหลือ ${product['stock']}',
                style: TextStyle(
                  fontSize: 12,
                  color: product['stock'] < 10 ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights() {
    final conversionRate = _stats['conversionRate'] ?? 0.0;
    final lowStockProducts = _stats['lowStockProducts'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลเชิงลึก',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Conversion Rate
          _buildInsightItem(
            icon: Icons.insights,
            title: 'อัตราการแปลง',
            value: '${conversionRate.toStringAsFixed(2)}%',
            subtitle: 'จากผู้เข้าชมเป็นลูกค้า',
            color: conversionRate >= 5 ? Colors.green : Colors.orange,
          ),

          const SizedBox(height: 12),

          // Low Stock Warning
          if (lowStockProducts > 0)
            _buildInsightItem(
              icon: Icons.warning_amber_rounded,
              title: 'สินค้าใกล้หมด',
              value: '$lowStockProducts รายการ',
              subtitle: 'ควรเติมสต๊อกโดยเร็ว',
              color: Colors.red,
            ),

          const SizedBox(height: 12),

          // Total Views
          _buildInsightItem(
            icon: Icons.visibility_outlined,
            title: 'การเข้าชมสินค้า',
            value: NumberFormat('#,##0').format(_stats['totalViews'] ?? 0),
            subtitle: 'ผู้เข้าชมทั้งหมด',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getOrderStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'text': 'รอดำเนินการ',
          'icon': Icons.pending_actions,
          'color': const Color(0xFFFF9800),
        };
      case 'confirmed':
      case 'processing':
        return {
          'text': 'กำลังดำเนินการ',
          'icon': Icons.autorenew,
          'color': const Color(0xFF2196F3),
        };
      case 'shipping':
        return {
          'text': 'กำลังจัดส่ง',
          'icon': Icons.local_shipping,
          'color': const Color(0xFF9C27B0),
        };
      case 'completed':
        return {
          'text': 'เสร็จสิ้น',
          'icon': Icons.check_circle,
          'color': const Color(0xFF4CAF50),
        };
      case 'cancelled':
        return {
          'text': 'ยกเลิก',
          'icon': Icons.cancel,
          'color': const Color(0xFFF44336),
        };
      default:
        return {
          'text': 'ไม่ทราบสถานะ',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('d MMM yyyy', 'th').format(dateTime);
    }
  }
}
