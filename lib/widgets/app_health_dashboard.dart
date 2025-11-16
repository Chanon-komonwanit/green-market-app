// lib/widgets/app_health_dashboard.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:green_market/services/app_performance_service.dart';

/// Comprehensive app health monitoring dashboard
/// Only visible in debug mode for developers
class AppHealthDashboard extends StatefulWidget {
  const AppHealthDashboard({super.key});

  @override
  State<AppHealthDashboard> createState() => _AppHealthDashboardState();
}

class _AppHealthDashboardState extends State<AppHealthDashboard>
    with TickerProviderStateMixin {
  final AppPerformanceService _performanceService = AppPerformanceService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic> _healthData = {};
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _loadHealthData();
    _animationController.forward();

    // Update health data every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadHealthData();
    });
  }

  void _loadHealthData() {
    setState(() {
      _healthData = _performanceService.getAppHealthStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    final isHealthy = _healthData['isHealthy'] ?? false;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Positioned(
        top: 100,
        right: 16,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: _isExpanded ? 300 : 60,
            maxHeight: _isExpanded ? 400 : 60,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHealthy ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: _isExpanded
              ? _buildExpandedDashboard()
              : _buildCollapsedDashboard(isHealthy),
        ),
      ),
    );
  }

  Widget _buildCollapsedDashboard(bool isHealthy) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isHealthy
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
        child: Icon(
          isHealthy ? Icons.health_and_safety : Icons.warning,
          color: isHealthy ? Colors.green : Colors.red,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildExpandedDashboard() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              const Icon(Icons.monitor_heart, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'App Health',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = false),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),

        // Health metrics
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHealthIndicator(),
                  const SizedBox(height: 12),
                  _buildMetricItem(
                      'Session ID',
                      _healthData['sessionId']?.toString().substring(0, 12) ??
                          'N/A'),
                  _buildMetricItem(
                      'Errors', '${_healthData['errorCount'] ?? 0}',
                      color: (_healthData['errorCount'] ?? 0) > 5
                          ? Colors.red
                          : Colors.green),
                  _buildMetricItem(
                      'Memory', '${_healthData['averageMemoryUsage'] ?? 0} MB',
                      color: (_healthData['averageMemoryUsage'] ?? 0) > 150
                          ? Colors.orange
                          : Colors.green),
                  _buildMetricItem('Response Time',
                      '${_healthData['averageResponseTime'] ?? 0} ms',
                      color: (_healthData['averageResponseTime'] ?? 0) > 2000
                          ? Colors.red
                          : Colors.green),
                  _buildMetricItem('Active Trackers',
                      '${_healthData['activeScreenTrackers'] ?? 0}'),
                  _buildMetricItem('Pending Metrics',
                      '${_healthData['pendingMetrics'] ?? 0}'),
                  _buildMetricItem(
                      'Pending Events', '${_healthData['pendingEvents'] ?? 0}'),
                  const SizedBox(height: 8),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator() {
    final isHealthy = _healthData['isHealthy'] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHealthy
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHealthy ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isHealthy ? 'Healthy' : 'Issues Detected',
            style: TextStyle(
              color: isHealthy ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _exportData,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Text(
                'Export',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _refreshData,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: const Text(
                'Refresh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _exportData() {
    final data = _performanceService.exportPerformanceData();
    // In a real app, you might save this to clipboard or file
    debugPrint('Performance Data Exported: $data');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Performance data exported to console'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshData() {
    _loadHealthData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health data refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
