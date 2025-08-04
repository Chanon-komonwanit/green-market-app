// lib/widgets/system_health_indicator.dart
// วิดเจ็ตแสดงสถานะสุขภาพระบบแบบ real-time

import 'package:flutter/material.dart';
import 'package:green_market/utils/app_comprehensive_strengthening.dart';
import 'package:green_market/screens/admin/system_health_screen.dart';
import 'dart:async';

class SystemHealthIndicator extends StatefulWidget {
  const SystemHealthIndicator({super.key});

  @override
  State<SystemHealthIndicator> createState() => _SystemHealthIndicatorState();
}

class _SystemHealthIndicatorState extends State<SystemHealthIndicator>
    with TickerProviderStateMixin {
  final AppComprehensiveStrengthening _strengthening =
      AppComprehensiveStrengthening();

  SystemHealthInfo? _currentHealth;
  Timer? _updateTimer;
  late AnimationController _pulseController;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _startMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startMonitoring() {
    _updateStatus();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateStatus();
    });
  }

  void _updateStatus() {
    final latestHealth = _strengthening.latestHealthStatus;
    if (mounted && latestHealth != _currentHealth) {
      setState(() {
        _currentHealth = latestHealth;
      });
    }
  }

  void _navigateToHealthScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SystemHealthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentHealth == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 16,
      child: GestureDetector(
        onTap: _navigateToHealthScreen,
        onLongPress: () {
          setState(() {
            _isVisible = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ซ่อนตัวบ่งชี้สุขภาพระบบแล้ว'),
              action: SnackBarAction(
                label: 'แสดง',
                onPressed: () {
                  setState(() {
                    _isVisible = true;
                  });
                },
              ),
            ),
          );
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor().withOpacity(0.3),
                    blurRadius: 4 + (_pulseController.value * 2),
                    spreadRadius: _pulseController.value,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_currentHealth == null) return Colors.grey;

    switch (_currentHealth!.status) {
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

  IconData _getStatusIcon() {
    if (_currentHealth == null) return Icons.help_outline;

    switch (_currentHealth!.status) {
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

  String _getStatusText() {
    if (_currentHealth == null) return 'N/A';

    final score = _currentHealth!.score.toStringAsFixed(0);
    return '$score%';
  }
}

/// วิดเจ็ตแสดงสถานะสุขภาพแบบง่าย
class SimpleHealthIndicator extends StatelessWidget {
  final SystemHealthInfo? healthInfo;
  final VoidCallback? onTap;

  const SimpleHealthIndicator({
    super.key,
    this.healthInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (healthInfo == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.help_outline,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(healthInfo!.status),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(healthInfo!.status),
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '${healthInfo!.score.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
}

/// วิดเจ็ตแสดงสถานะข้อมูลแบบละเอียด
class DetailedHealthWidget extends StatelessWidget {
  final SystemHealthInfo healthInfo;
  final VoidCallback? onRefresh;

  const DetailedHealthWidget({
    super.key,
    required this.healthInfo,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(healthInfo.status),
                      color: _getStatusColor(healthInfo.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'สุขภาพระบบ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'คะแนน: ${healthInfo.score.toStringAsFixed(1)}/100',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'สถานะ: ${_getStatusText(healthInfo.status)}',
              style: TextStyle(
                fontSize: 14,
                color: _getStatusColor(healthInfo.status),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: healthInfo.score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(healthInfo.status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'อัปเดต: ${_formatDateTime(healthInfo.timestamp)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (healthInfo.issues.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'ปัญหาที่พบ: ${healthInfo.issues.length} รายการ',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
