// lib/screens/admin/system_health_screen.dart
// หน้าจอติดตามสุขภาพระบบสำหรับผู้ดูแลระบบ

import 'package:flutter/material.dart';
import 'package:green_market/utils/app_comprehensive_strengthening.dart';
import 'dart:math' as math;

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen>
    with TickerProviderStateMixin {
  final AppComprehensiveStrengthening _strengthening =
      AppComprehensiveStrengthening();

  SystemHealthInfo? _currentHealth;
  Map<String, dynamic>? _comprehensiveReport;
  bool _isLoading = false;
  late AnimationController _refreshAnimation;

  @override
  void initState() {
    super.initState();
    _refreshAnimation = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadSystemHealth();
  }

  @override
  void dispose() {
    _refreshAnimation.dispose();
    super.dispose();
  }

  Future<void> _loadSystemHealth() async {
    setState(() => _isLoading = true);

    try {
      _refreshAnimation.forward();

      final healthInfo = await _strengthening.performHealthCheck();
      final report = _strengthening.getComprehensiveReport();

      setState(() {
        _currentHealth = healthInfo;
        _comprehensiveReport = report;
      });
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
      _refreshAnimation.reset();
    }
  }

  Future<void> _performOptimization() async {
    setState(() => _isLoading = true);

    try {
      await _strengthening.performAutoOptimization();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปรับปรุงระบบเสร็จสิ้น'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadSystemHealth();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการปรับปรุงระบบ: $e'),
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
          'สุขภาพระบบ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF20C997),
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2 * math.pi,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadSystemHealth,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _isLoading ? null : _performOptimization,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _currentHealth == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('กำลังตรวจสอบสุขภาพระบบ...'),
          ],
        ),
      );
    }

    if (_currentHealth == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text('ไม่สามารถโหลดข้อมูลสุขภาพระบบได้'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSystemHealth,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSystemHealth,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthOverviewCard(),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 16),
            _buildIssuesCard(),
            const SizedBox(height: 16),
            _buildRecommendationsCard(),
            const SizedBox(height: 16),
            _buildSystemStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthOverviewCard() {
    final health = _currentHealth!;
    final statusColor = _getStatusColor(health.status);
    final statusIcon = _getStatusIcon(health.status);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  size: 48,
                  color: statusColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สถานะระบบ: ${_getStatusText(health.status)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'คะแนนสุขภาพ: ${health.score.toStringAsFixed(1)}/100',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'อัปเดตล่าสุด: ${_formatDateTime(health.timestamp)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: health.score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final report = _comprehensiveReport;
    if (report == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'ประสิทธิภาพ',
          Icons.speed,
          Colors.blue,
          _getPerformanceText(report['performance']),
        ),
        _buildMetricCard(
          'ความปลอดภัย',
          Icons.security,
          Colors.red,
          _getSecurityText(report['security']),
        ),
        _buildMetricCard(
          'ข้อผิดพลาด',
          Icons.error_outline,
          Colors.orange,
          _getErrorText(report['errors']),
        ),
        _buildMetricCard(
          'การสำรองข้อมูล',
          Icons.backup,
          Colors.green,
          _getBackupText(report['backup']),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, IconData icon, Color color, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesCard() {
    final health = _currentHealth!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'ปัญหาที่พบ (${health.issues.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (health.issues.isEmpty)
              const Text(
                'ไม่พบปัญหาใดๆ',
                style: TextStyle(color: Colors.green),
              )
            else
              ...health.issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(issue)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final health = _currentHealth!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'คำแนะนำ (${health.recommendations.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (health.recommendations.isEmpty)
              const Text(
                'ไม่มีคำแนะนำ',
                style: TextStyle(color: Colors.green),
              )
            else
              ...health.recommendations.map((recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(recommendation)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    final report = _comprehensiveReport;
    if (report == null) return const SizedBox.shrink();

    final systemStatus = report['system_status'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'สถานะระบบ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'ระบบเริ่มต้นแล้ว',
              systemStatus['initialized'] == true,
            ),
            _buildStatusRow(
              'การติดตามทำงาน',
              systemStatus['monitoring_active'] == true,
            ),
            const SizedBox(height: 8),
            Text(
              'อัปเดตล่าสุด: ${_formatDateTime(DateTime.tryParse(systemStatus['timestamp'] ?? '') ?? DateTime.now())}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Color _getStatusColor(SystemHealthStatus status) {
    switch (status) {
      case SystemHealthStatus.excellent:
        return Colors.green;
      case SystemHealthStatus.good:
        return Colors.blue;
      case SystemHealthStatus.warning:
        return Colors.orange;
      case SystemHealthStatus.critical:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(SystemHealthStatus status) {
    switch (status) {
      case SystemHealthStatus.excellent:
        return Icons.check_circle;
      case SystemHealthStatus.good:
        return Icons.thumb_up;
      case SystemHealthStatus.warning:
        return Icons.warning;
      case SystemHealthStatus.critical:
        return Icons.error;
    }
  }

  String _getStatusText(SystemHealthStatus status) {
    switch (status) {
      case SystemHealthStatus.excellent:
        return 'ดีเยี่ยม';
      case SystemHealthStatus.good:
        return 'ดี';
      case SystemHealthStatus.warning:
        return 'ต้องระวัง';
      case SystemHealthStatus.critical:
        return 'วิกฤต';
    }
  }

  String _getPerformanceText(Map<String, dynamic>? performance) {
    if (performance == null) return 'ไม่มีข้อมูล';

    final slowOps = performance['slow_operations'] as List? ?? [];
    return '${slowOps.length} การทำงานช้า';
  }

  String _getSecurityText(Map<String, dynamic>? security) {
    if (security == null) return 'ไม่มีข้อมูล';

    final threats = security['recent_threats_24h'] as int? ?? 0;
    return '$threats ภัยคุกคาม';
  }

  String _getErrorText(Map<String, dynamic>? errors) {
    if (errors == null) return 'ไม่มีข้อมูล';

    final recentErrors = errors['recent'] as int? ?? 0;
    return '$recentErrors ข้อผิดพลาดล่าสุด';
  }

  String _getBackupText(Map<String, dynamic>? backup) {
    if (backup == null) return 'ไม่มีข้อมูล';

    final failedBackups = backup['failed_backups'] as int? ?? 0;
    return failedBackups == 0 ? 'ปกติ' : '$failedBackups ล้มเหลว';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
