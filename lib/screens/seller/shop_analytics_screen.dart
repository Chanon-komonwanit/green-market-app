import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// ระบบสถิติร้านค้าขั้นสูง - Advanced Shop Analytics
/// รวมสถิติการขาย, การเข้าชม, สินค้ายอดนิยม, แหล่งที่มา (marketplace/search/shop)
class ShopAnalyticsScreen extends StatefulWidget {
  const ShopAnalyticsScreen({super.key});

  @override
  State<ShopAnalyticsScreen> createState() => _ShopAnalyticsScreenState();
}

class _ShopAnalyticsScreenState extends State<ShopAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _sellerId;

  bool _isLoading = true;
  String _selectedPeriod = '7days'; // 7days, 30days, 3months, 12months

  // Analytics Data
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _recentOrders = [];
  Map<String, int> _viewsBySource = {};
  List<Map<String, dynamic>> _salesChart = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (_sellerId != null) {
      _loadAnalytics();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case '7days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '30days':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '3months':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case '12months':
          startDate = now.subtract(const Duration(days: 365));
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      // โหลดข้อมูลการขาย
      await _loadSalesData(startDate);

      // โหลดข้อมูลสินค้ายอดนิยม
      await _loadTopProducts(startDate);

      // โหลดข้อมูลการเข้าชม
      await _loadViewAnalytics(startDate);

      // โหลดคำสั่งซื้อล่าสุด
      await _loadRecentOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSalesData(DateTime startDate) async {
    if (_sellerId == null) return;
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: _sellerId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('status', whereIn: ['completed', 'delivered']).get();

    double totalRevenue = 0;
    int totalOrders = ordersSnapshot.docs.length;
    int totalItems = 0;
    Map<String, double> dailySales = {};

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final amount = (data['totalAmount'] ?? 0.0).toDouble();
      final itemCount = (data['items'] as List?)?.length ?? 0;
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);

      totalRevenue += amount;
      totalItems += itemCount;
      dailySales[dateKey] = (dailySales[dateKey] ?? 0) + amount;
    }

    // สร้างข้อมูลกราฟ
    _salesChart = dailySales.entries
        .map((e) => {'date': e.key, 'amount': e.value})
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    _analyticsData = {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'totalItems': totalItems,
      'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
    };
  }

  Future<void> _loadTopProducts(DateTime startDate) async {
    // ดึงข้อมูลสินค้าที่ขายดี
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: _sellerId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('status', whereIn: ['completed', 'delivered']).get();

    Map<String, Map<String, dynamic>> productStats = {};

    for (var doc in ordersSnapshot.docs) {
      final items = doc.data()['items'] as List? ?? [];
      for (var item in items) {
        final productId = item['productId'] as String;
        final quantity = (item['quantity'] ?? 0) as int;
        final revenue = ((item['price'] ?? 0) * quantity).toDouble();

        if (productStats.containsKey(productId)) {
          productStats[productId]!['sold'] += quantity;
          productStats[productId]!['revenue'] += revenue;
        } else {
          productStats[productId] = {
            'productId': productId,
            'name': item['name'] ?? 'สินค้า',
            'imageUrl': item['imageUrl'],
            'price': item['price'] ?? 0,
            'sold': quantity,
            'revenue': revenue,
          };
        }
      }
    }

    _topProducts = productStats.values.toList()
      ..sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int));

    // เอาแค่ 10 อันดับแรก
    if (_topProducts.length > 10) {
      _topProducts = _topProducts.sublist(0, 10);
    }
  }

  Future<void> _loadViewAnalytics(DateTime startDate) async {
    // ดึงข้อมูลการเข้าชมจากระบบ view tracking
    final viewsSnapshot = await _firestore
        .collection('product_views')
        .where('sellerId', isEqualTo: _sellerId)
        .where('viewedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    _viewsBySource = {};
    int totalViews = viewsSnapshot.docs.length;

    for (var doc in viewsSnapshot.docs) {
      final source = doc.data()['source'] as String? ?? 'unknown';
      _viewsBySource[source] = (_viewsBySource[source] ?? 0) + 1;
    }

    _analyticsData['totalViews'] = totalViews;
  }

  Future<void> _loadRecentOrders() async {
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: _sellerId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    _recentOrders = ordersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สถิติร้านค้า'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7days', child: Text('7 วันล่าสุด')),
              const PopupMenuItem(value: '30days', child: Text('30 วันล่าสุด')),
              const PopupMenuItem(
                  value: '3months', child: Text('3 เดือนล่าสุด')),
              const PopupMenuItem(
                  value: '12months', child: Text('12 เดือนล่าสุด')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'ภาพรวม', icon: Icon(Icons.dashboard_outlined, size: 20)),
            Tab(text: 'การขาย', icon: Icon(Icons.trending_up, size: 20)),
            Tab(
                text: 'การเข้าชม',
                icon: Icon(Icons.visibility_outlined, size: 20)),
            Tab(
                text: 'สินค้ายอดนิยม',
                icon: Icon(Icons.star_outlined, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSalesTab(),
                _buildViewsTab(),
                _buildTopProductsTab(),
              ],
            ),
    );
  }

  // ==================== TAB 1: OVERVIEW ====================
  Widget _buildOverviewTab() {
    final revenue = _analyticsData['totalRevenue'] ?? 0.0;
    final orders = _analyticsData['totalOrders'] ?? 0;
    final items = _analyticsData['totalItems'] ?? 0;
    final avgOrder = _analyticsData['averageOrderValue'] ?? 0.0;
    final views = _analyticsData['totalViews'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'แสดงข้อมูล: ${_getPeriodLabel()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'ยอดขาย',
                  '฿${_formatNumber(revenue)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'คำสั่งซื้อ',
                  _formatNumber(orders.toDouble()),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'สินค้าที่ขาย',
                  _formatNumber(items.toDouble()),
                  Icons.inventory_2_outlined,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'ยอดเฉลี่ย',
                  '฿${_formatNumber(avgOrder)}',
                  Icons.calculate,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'การเข้าชมสินค้า',
            _formatNumber(views.toDouble()),
            Icons.visibility,
            Colors.teal,
          ),

          const SizedBox(height: 24),

          // Sales Chart
          const Text(
            '📊 กราฟยอดขาย',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSalesChart(),

          const SizedBox(height: 24),

          // Recent Orders
          const Text(
            '📦 คำสั่งซื้อล่าสุด',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._recentOrders.take(5).map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
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
              Icon(icon, color: Colors.white, size: 30),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: SALES ====================
  Widget _buildSalesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '📈 รายละเอียดการขาย',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildSalesChart(),
        const SizedBox(height: 24),
        const Text(
          'คำสั่งซื้อทั้งหมด',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._recentOrders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _buildSalesChart() {
    if (_salesChart.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('ไม่มีข้อมูลการขายในช่วงเวลานี้'),
        ),
      );
    }

    // ปรับข้อมูลให้เหมาะกับการแสดงผล
    final spots = <FlSpot>[];
    for (int i = 0; i < _salesChart.length; i++) {
      spots.add(FlSpot(
        i.toDouble(),
        (_salesChart[i]['amount'] as double),
      ));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '฿${_formatNumber(value)}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _salesChart.length) {
                    final date = DateTime.parse(_salesChart[index]['date']);
                    return Text(
                      DateFormat('d/M').format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final createdAt = (order['createdAt'] as Timestamp).toDate();
    final amount = (order['totalAmount'] ?? 0.0).toDouble();
    final status = order['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shopping_bag,
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          'คำสั่งซื้อ #${order['id'].toString().substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('d MMM yyyy HH:mm', 'th').format(createdAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '฿${_formatNumber(amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 3: VIEWS ====================
  Widget _buildViewsTab() {
    final totalViews = _analyticsData['totalViews'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '👁️ สถิติการเข้าชม',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'ดูว่าลูกค้าเจอสินค้าคุณจากไหน',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Total Views Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.teal.shade300],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.visibility, color: Colors.white, size: 50),
              const SizedBox(height: 12),
              Text(
                _formatNumber(totalViews.toDouble()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'ครั้งทั้งหมด',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Views by Source
        const Text(
          '📍 แหล่งที่มา',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (_viewsBySource.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('ยังไม่มีข้อมูลการเข้าชม'),
            ),
          )
        else
          ..._viewsBySource.entries.map((entry) {
            final source = entry.key;
            final count = entry.value;
            final percentage = totalViews > 0
                ? (count / totalViews * 100).toStringAsFixed(1)
                : '0';

            return _buildSourceCard(source, count, percentage);
          }),
      ],
    );
  }

  Widget _buildSourceCard(String source, int count, String percentage) {
    final sourceData = _getSourceInfo(source);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sourceData['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sourceData['icon'],
                color: sourceData['color'],
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sourceData['label'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sourceData['description'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(count.toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: sourceData['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getSourceInfo(String source) {
    switch (source) {
      case 'marketplace':
        return {
          'label': 'ตลาดกลาง',
          'description': 'ผู้ซื้อเห็นในหน้าตลาด',
          'icon': Icons.store,
          'color': Colors.blue,
        };
      case 'search':
        return {
          'label': 'การค้นหา',
          'description': 'ผู้ซื้อค้นหาและเจอสินค้า',
          'icon': Icons.search,
          'color': Colors.orange,
        };
      case 'shop':
        return {
          'label': 'หน้าร้าน',
          'description': 'เข้าชมจากหน้าร้านโดยตรง',
          'icon': Icons.storefront,
          'color': Colors.green,
        };
      case 'profile':
        return {
          'label': 'โปรไฟล์',
          'description': 'เข้าชมจากโปรไฟล์ผู้ขาย',
          'icon': Icons.person,
          'color': Colors.purple,
        };
      case 'direct':
        return {
          'label': 'ลิงก์ตรง',
          'description': 'เข้าจากลิงก์โดยตรง',
          'icon': Icons.link,
          'color': Colors.teal,
        };
      default:
        return {
          'label': 'อื่นๆ',
          'description': 'แหล่งที่มาอื่นๆ',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }

  // ==================== TAB 4: TOP PRODUCTS ====================
  Widget _buildTopProductsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '⭐ สินค้ายอดนิยม',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'สินค้าที่ขายดีที่สุดในช่วงเวลานี้',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (_topProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('ยังไม่มีข้อมูลสินค้าที่ขาย'),
            ),
          )
        else
          ..._topProducts.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final product = entry.value;
            return _buildTopProductCard(rank, product);
          }),
      ],
    );
  }

  Widget _buildTopProductCard(int rank, Map<String, dynamic> product) {
    final sold = product['sold'] ?? 0;
    final revenue = (product['revenue'] ?? 0.0).toDouble();
    final name = product['name'] ?? 'สินค้า';
    final imageUrl = product['imageUrl'];
    final price = (product['price'] ?? 0.0).toDouble();

    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey;
    } else if (rank == 3) {
      rankColor = Colors.brown;
    } else {
      rankColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image);
                        },
                      ),
                    )
                  : const Icon(Icons.shopping_bag),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '฿${_formatNumber(price)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.sell, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'ขายแล้ว $sold ชิ้น',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Revenue
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '฿${_formatNumber(revenue)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'รายได้',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case '7days':
        return '7 วันล่าสุด';
      case '30days':
        return '30 วันล่าสุด';
      case '3months':
        return '3 เดือนล่าสุด';
      case '12months':
        return '12 เดือนล่าสุด';
      default:
        return '7 วันล่าสุด';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'processing':
      case 'confirmed':
        return Colors.blue;
      case 'shipping':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    String label;
    switch (status) {
      case 'completed':
        label = 'สำเร็จ';
        break;
      case 'delivered':
        label = 'ส่งแล้ว';
        break;
      case 'processing':
        label = 'กำลังดำเนินการ';
        break;
      case 'confirmed':
        label = 'ยืนยันแล้ว';
        break;
      case 'shipping':
        label = 'กำลังจัดส่ง';
        break;
      case 'cancelled':
        label = 'ยกเลิก';
        break;
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
