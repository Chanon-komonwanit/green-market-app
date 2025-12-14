// lib/widgets/ai_status_widget.dart
// 🤖 AI System Status Widget for Dashboard
// แสดงสถานะการทำงานของระบบ AI แบบ Real-time

import 'package:flutter/material.dart';
import '../services/ai_eco_analysis_service.dart';
import '../models/ai_settings.dart';

class AIStatusWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const AIStatusWidget({
    super.key,
    this.onTap,
  });

  @override
  State<AIStatusWidget> createState() => _AIStatusWidgetState();
}

class _AIStatusWidgetState extends State<AIStatusWidget> {
  final _aiService = AIEcoAnalysisService();
  AISettings? _settings;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final settings = await _aiService.getAISettings();
      final stats = await _aiService.getTodayUsageStats();

      if (mounted) {
        setState(() {
          _settings = settings;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor() {
    if (_settings == null) return Colors.grey;
    if (!_settings!.aiEnabled) return Colors.orange;
    if (_stats != null && _stats!['usagePercentage'] > 90) return Colors.red;
    return Colors.green;
  }

  String _getStatusText() {
    if (_settings == null) return 'กำลังโหลด...';
    if (!_settings!.aiEnabled) return 'AI ปิดใช้งาน';
    if (_stats != null && _stats!['usagePercentage'] > 90) {
      return 'ใกล้เกิน Limit';
    }
    return 'AI พร้อมใช้งาน';
  }

  IconData _getStatusIcon() {
    if (_settings == null) return Icons.hourglass_empty;
    if (!_settings!.aiEnabled) return Icons.power_off;
    if (_stats != null && _stats!['usagePercentage'] > 90) {
      return Icons.warning;
    }
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('กำลังโหลดสถานะ AI...'),
            ],
          ),
        ),
      );
    }

    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();

    return Card(
      elevation: 3,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI System',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 13,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ],
              ),

              if (_settings != null &&
                  _settings!.aiEnabled &&
                  _stats != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Usage Progress
                Row(
                  children: [
                    const Icon(
                      Icons.analytics,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'การใช้งานวันนี้',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor:
                          (_stats!['usagePercentage'] / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _stats!['usagePercentage'] > 80
                              ? Colors.red
                              : _stats!['usagePercentage'] > 50
                                  ? Colors.orange
                                  : Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_stats!['currentUsage']} / ${_stats!['dailyLimit']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_stats!['usagePercentage'].toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _stats!['usagePercentage'] > 80
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],

              if (_settings != null && !_settings!.aiEnabled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI ปิดใช้งาน - ใช้ Fallback Analysis',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact version สำหรับ Header/AppBar
class AIStatusIndicator extends StatefulWidget {
  final VoidCallback? onTap;

  const AIStatusIndicator({
    super.key,
    this.onTap,
  });

  @override
  State<AIStatusIndicator> createState() => _AIStatusIndicatorState();
}

class _AIStatusIndicatorState extends State<AIStatusIndicator> {
  final _aiService = AIEcoAnalysisService();
  AISettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final settings = await _aiService.getAISettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final isEnabled = _settings?.aiEnabled ?? false;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled ? Colors.green : Colors.orange,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              size: 16,
              color: isEnabled ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              'AI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isEnabled ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
