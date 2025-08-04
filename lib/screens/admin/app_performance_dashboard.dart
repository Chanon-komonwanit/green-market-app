// lib/screens/admin/app_performance_dashboard.dart
// แดชบอร์ดติดตามประสิทธิภาพและการทำงานของแอพ

import 'package:flutter/material.dart';
import 'package:green_market/utils/app_comprehensive_strengthening.dart';
import 'package:fl_chart/fl_chart.dart';

class AppPerformanceDashboard extends StatefulWidget {
  const AppPerformanceDashboard({super.key});

  @override
  State<AppPerformanceDashboard> createState() =>
      _AppPerformanceDashboardState();
}

class _AppPerformanceDashboardState extends State<AppPerformanceDashboard>
    with TickerProviderStateMixin {
  final AppComprehensiveStrengthening _strengthening =
      AppComprehensiveStrengthening();

  List<SystemHealthInfo> _healthHistory = [];
  Map<String, dynamic>? _latestReport;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      _healthHistory = _strengthening.healthHistory;
      _latestReport = _strengthening.getComprehensiveReport();

      // ถ้าไม่มีข้อมูล ให้ทำการตรวจสอบใหม่
      if (_healthHistory.isEmpty) {
        await _strengthening.performHealthCheck();
        _healthHistory = _strengthening.healthHistory;
        _latestReport = _strengthening.getComprehensiveReport();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'แดชบอร์ดประสิทธิภาพ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF20C997),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'ภาพรวม'),
            Tab(icon: Icon(Icons.speed), text: 'ประสิทธิภาพ'),
            Tab(icon: Icon(Icons.security), text: 'ความปลอดภัย'),
            Tab(icon: Icon(Icons.error_outline), text: 'ข้อผิดพลาด'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPerformanceTab(),
                _buildSecurityTab(),
                _buildErrorsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthTrendChart(),
          const SizedBox(height: 20),
          _buildQuickStatsGrid(),
          const SizedBox(height: 20),
          _buildRecentActivitiesCard(),
        ],
      ),
    );
  }

  Widget _buildHealthTrendChart() {
    if (_healthHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('ไม่มีข้อมูลประวัติสุขภาพระบบ'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แนวโน้มสุขภาพระบบ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _healthHistory.length) {
                            final time =
                                _healthHistory[value.toInt()].timestamp;
                            return Text(
                                '${time.hour}:${time.minute.toString().padLeft(2, '0')}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _healthHistory.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.healthScore,
                        );
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF20C997),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF20C997).withOpacity(0.3),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    if (_latestReport == null) return const SizedBox.shrink();

    final performance =
        _latestReport!['performance'] as Map<String, dynamic>? ?? {};
    final security = _latestReport!['security'] as Map<String, dynamic>? ?? {};
    final errors = _latestReport!['errors'] as Map<String, dynamic>? ?? {};
    final backup = _latestReport!['backup'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'การทำงานช้า',
          (performance['slow_operations'] as List?)?.length ?? 0,
          Icons.speed,
          Colors.blue,
        ),
        _buildStatCard(
          'ภัยคุกคาม 24ชม.',
          security['recent_threats_24h'] ?? 0,
          Icons.security,
          Colors.red,
        ),
        _buildStatCard(
          'ข้อผิดพลาดล่าสุด',
          errors['recent'] ?? 0,
          Icons.error_outline,
          Colors.orange,
        ),
        _buildStatCard(
          'สำรองข้อมูลล้มเหลว',
          backup['failed_backups'] ?? 0,
          Icons.backup,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กิจกรรมล่าสุด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_latestReport?['system_status']?['monitoring_active'] == true)
              _buildActivityItem(
                'ระบบติดตามทำงานปกติ',
                'เมื่อสักครู่',
                Icons.check_circle,
                Colors.green,
              ),
            _buildActivityItem(
              'ตรวจสอบสุขภาพระบบ',
              _formatLastUpdate(),
              Icons.health_and_safety,
              Colors.blue,
            ),
            if (_healthHistory.isNotEmpty &&
                _healthHistory.last.healthScore > 75)
              _buildActivityItem(
                'ระบบทำงานปกติ',
                'ตอนนี้',
                Icons.thumb_up,
                Colors.green,
              )
            else
              _buildActivityItem(
                'ตรวจพบปัญหาในระบบ',
                'ตอนนี้',
                Icons.warning,
                Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return const Center(
      child: Text('แท็บประสิทธิภาพ (กำลังพัฒนา)'),
    );
  }

  Widget _buildSecurityTab() {
    return const Center(
      child: Text('แท็บความปลอดภัย (กำลังพัฒนา)'),
    );
  }

  Widget _buildErrorsTab() {
    return const Center(
      child: Text('แท็บข้อผิดพลาด (กำลังพัฒนา)'),
    );
  }

  String _formatLastUpdate() {
    if (_healthHistory.isEmpty) return 'ไม่ทราบ';

    final lastHealth = _healthHistory.last;
    final now = DateTime.now();
    final diff = now.difference(lastHealth.timestamp);

    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }
}
