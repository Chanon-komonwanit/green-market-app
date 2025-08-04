// lib/utils/performance_monitor.dart
// ระบบติดตามและปรับปรุงประสิทธิภาพสำหรับ Green Market App
// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// ข้อมูลประสิทธิภาพ
class PerformanceMetrics {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetrics({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operationName,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// ข้อมูลการใช้หน่วยความจำ
class MemoryInfo {
  final int used;
  final int total;
  final int external;
  final DateTime timestamp;

  MemoryInfo({
    required this.used,
    required this.total,
    required this.external,
    required this.timestamp,
  });

  double get usagePercentage => (used / total) * 100;

  Map<String, dynamic> toJson() {
    return {
      'used_mb': (used / 1024 / 1024).toStringAsFixed(2),
      'total_mb': (total / 1024 / 1024).toStringAsFixed(2),
      'external_mb': (external / 1024 / 1024).toStringAsFixed(2),
      'usage_percentage': usagePercentage.toStringAsFixed(2),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// ข้อมูลการเรนเดอร์เฟรม
class FrameInfo {
  final Duration buildTime;
  final Duration layoutTime;
  final Duration paintTime;
  final DateTime timestamp;
  final bool isJanky;

  FrameInfo({
    required this.buildTime,
    required this.layoutTime,
    required this.paintTime,
    required this.timestamp,
    required this.isJanky,
  });

  Duration get totalTime => buildTime + layoutTime + paintTime;

  Map<String, dynamic> toJson() {
    return {
      'build_ms': buildTime.inMicroseconds / 1000,
      'layout_ms': layoutTime.inMicroseconds / 1000,
      'paint_ms': paintTime.inMicroseconds / 1000,
      'total_ms': totalTime.inMicroseconds / 1000,
      'is_janky': isJanky,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// ระบบติดตามประสิทธิภาพ
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Collections สำหรับเก็บข้อมูล
  final Queue<PerformanceMetrics> _performanceHistory = Queue();
  final Queue<MemoryInfo> _memoryHistory = Queue();
  final Queue<FrameInfo> _frameHistory = Queue();
  final Map<String, DateTime> _activeOperations = {};
  final Map<String, List<Duration>> _operationStats = {};

  // Timers และ Streams
  Timer? _memoryMonitorTimer;
  Timer? _cleanupTimer;
  StreamController<PerformanceMetrics>? _metricsController;
  StreamController<MemoryInfo>? _memoryController;

  // Settings
  static const int MAX_HISTORY_SIZE = 1000;
  static const Duration MEMORY_CHECK_INTERVAL = Duration(seconds: 10);
  static const Duration CLEANUP_INTERVAL = Duration(minutes: 5);
  static const Duration JANKY_FRAME_THRESHOLD =
      Duration(milliseconds: 16); // 60fps

  bool _isInitialized = false;
  bool _isMonitoring = false;

  /// เริ่มต้นระบบติดตามประสิทธิภาพ
  Future<void> initialize() async {
    if (_isInitialized) return;

    _metricsController = StreamController<PerformanceMetrics>.broadcast();
    _memoryController = StreamController<MemoryInfo>.broadcast();

    // เริ่มติดตามหน่วยความจำ
    _startMemoryMonitoring();

    // เริ่มทำความสะอาดข้อมูลเก่า
    _startCleanupTimer();

    // ติดตามการเรนเดอร์เฟรม
    _startFrameMonitoring();

    _isInitialized = true;
    _isMonitoring = true;

    _logInfo('Performance Monitor initialized');
  }

  /// เริ่มต้นการติดตามการทำงาน
  void startOperation(String operationName, {Map<String, dynamic>? metadata}) {
    if (!_isMonitoring) return;

    _activeOperations[operationName] = DateTime.now();
    _logDebug('Started operation: $operationName');
  }

  /// จบการติดตามการทำงาน
  Duration? stopOperation(String operationName,
      {Map<String, dynamic>? metadata}) {
    if (!_isMonitoring) return null;

    final startTime = _activeOperations.remove(operationName);
    if (startTime == null) {
      _logWarning(
          'Attempted to stop operation that was not started: $operationName');
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    final metrics = PerformanceMetrics(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _addPerformanceMetrics(metrics);
    _updateOperationStats(operationName, duration);

    _logDebug(
        'Completed operation: $operationName in ${duration.inMilliseconds}ms');
    return duration;
  }

  /// ติดตามการทำงานแบบ async
  Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    startOperation(operationName, metadata: metadata);
    try {
      final result = await operation();
      stopOperation(operationName, metadata: metadata);
      return result;
    } catch (e) {
      stopOperation(operationName,
          metadata: {'error': e.toString(), ...?metadata});
      rethrow;
    }
  }

  /// ติดตามการทำงานแบบ sync
  T measure<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    startOperation(operationName, metadata: metadata);
    try {
      final result = operation();
      stopOperation(operationName, metadata: metadata);
      return result;
    } catch (e) {
      stopOperation(operationName,
          metadata: {'error': e.toString(), ...?metadata});
      rethrow;
    }
  }

  /// เริ่มติดตามหน่วยความจำ
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(MEMORY_CHECK_INTERVAL, (_) {
      _collectMemoryInfo();
    });
  }

  /// เก็บข้อมูลการใช้หน่วยความจำ
  void _collectMemoryInfo() {
    if (!kIsWeb) {
      // สำหรับ mobile platforms - ใช้ค่าประมาณ
      final estimatedUsed =
          DateTime.now().millisecondsSinceEpoch % 100000000; // Mock value
      final memoryInfo = MemoryInfo(
        used: estimatedUsed,
        total: estimatedUsed * 2,
        external: 0,
        timestamp: DateTime.now(),
      );

      _addMemoryInfo(memoryInfo);

      // เตือนเมื่อใช้หน่วยความจำมาก (เป็นการจำลอง)
      if (memoryInfo.usagePercentage > 80) {
        _logWarning(
            'High memory usage: ${memoryInfo.usagePercentage.toStringAsFixed(1)}%');
      }
    }
  }

  /// เริ่มติดตามการเรนเดอร์เฟรม
  void _startFrameMonitoring() {
    if (!kIsWeb) {
      SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
        _trackFrame(timeStamp);
      });
    }
  }

  /// ติดตามประสิทธิภาพการเรนเดอร์แต่ละเฟรม
  void _trackFrame(Duration timeStamp) {
    final frameTime = timeStamp;
    final isJanky = frameTime > JANKY_FRAME_THRESHOLD;

    final frameInfo = FrameInfo(
      buildTime: Duration(microseconds: frameTime.inMicroseconds ~/ 3),
      layoutTime: Duration(microseconds: frameTime.inMicroseconds ~/ 3),
      paintTime: Duration(microseconds: frameTime.inMicroseconds ~/ 3),
      timestamp: DateTime.now(),
      isJanky: isJanky,
    );

    _addFrameInfo(frameInfo);

    if (isJanky) {
      _logWarning('Janky frame detected: ${frameTime.inMicroseconds / 1000}ms');
    }
  }

  /// เพิ่มข้อมูลประสิทธิภาพ
  void _addPerformanceMetrics(PerformanceMetrics metrics) {
    _performanceHistory.add(metrics);
    _metricsController?.add(metrics);

    // จำกัดขนาดของประวัติ
    while (_performanceHistory.length > MAX_HISTORY_SIZE) {
      _performanceHistory.removeFirst();
    }
  }

  /// เพิ่มข้อมูลหน่วยความจำ
  void _addMemoryInfo(MemoryInfo info) {
    _memoryHistory.add(info);
    _memoryController?.add(info);

    while (_memoryHistory.length > MAX_HISTORY_SIZE) {
      _memoryHistory.removeFirst();
    }
  }

  /// เพิ่มข้อมูลเฟรม
  void _addFrameInfo(FrameInfo info) {
    _frameHistory.add(info);

    while (_frameHistory.length > MAX_HISTORY_SIZE) {
      _frameHistory.removeFirst();
    }
  }

  /// อัปเดตสถิติการทำงาน
  void _updateOperationStats(String operationName, Duration duration) {
    _operationStats.putIfAbsent(operationName, () => []);
    _operationStats[operationName]!.add(duration);

    // เก็บเฉพาะ 100 รายการล่าสุด
    final stats = _operationStats[operationName]!;
    if (stats.length > 100) {
      stats.removeRange(0, stats.length - 100);
    }
  }

  /// เริ่มทำความสะอาดข้อมูลเก่า
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(CLEANUP_INTERVAL, (_) {
      _performCleanup();
    });
  }

  /// ทำความสะอาดข้อมูลเก่า
  void _performCleanup() {
    final now = DateTime.now();

    // ล้างข้อมูลเก่าเกิน 1 ชั่วโมง
    _performanceHistory.removeWhere((metrics) {
      return now.difference(metrics.timestamp).inHours > 1;
    });

    _memoryHistory.removeWhere((info) {
      return now.difference(info.timestamp).inHours > 1;
    });

    _frameHistory.removeWhere((info) {
      return now.difference(info.timestamp).inHours > 1;
    });

    // ล้าง operations ที่ค้างอยู่เกิน 10 นาที
    _activeOperations.removeWhere((operation, startTime) {
      if (now.difference(startTime).inMinutes > 10) {
        _logWarning('Removing stale operation: $operation');
        return true;
      }
      return false;
    });

    _logDebug('Performance cleanup completed');
  }

  /// ได้รับรายงานประสิทธิภาพ
  Map<String, dynamic> getPerformanceReport() {
    final slowOperations = _operationStats.entries
        .where((entry) => _getAverageTime(entry.value).inMilliseconds > 1000)
        .map((entry) => {
              'operation': entry.key,
              'average_ms': _getAverageTime(entry.value).inMilliseconds,
              'count': entry.value.length,
            })
        .toList();

    final jankyFrames = _frameHistory.where((frame) => frame.isJanky).length;
    final totalFrames = _frameHistory.length;

    return {
      'total_operations': _performanceHistory.length,
      'slow_operations': slowOperations,
      'memory_usage':
          _memoryHistory.isNotEmpty ? _memoryHistory.last.toJson() : null,
      'frame_performance': {
        'total_frames': totalFrames,
        'janky_frames': jankyFrames,
        'janky_percentage': totalFrames > 0
            ? (jankyFrames / totalFrames * 100).toStringAsFixed(2)
            : '0',
      },
      'active_operations': _activeOperations.keys.toList(),
    };
  }

  /// คำนวณเวลาเฉลี่ย
  Duration _getAverageTime(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;

    final totalMicroseconds =
        durations.map((d) => d.inMicroseconds).reduce((a, b) => a + b);

    return Duration(microseconds: totalMicroseconds ~/ durations.length);
  }

  /// Stream สำหรับรับข้อมูลประสิทธิภาพ
  Stream<PerformanceMetrics>? get metricsStream => _metricsController?.stream;

  /// Stream สำหรับรับข้อมูลหน่วยความจำ
  Stream<MemoryInfo>? get memoryStream => _memoryController?.stream;

  /// รายงานข้อมูลปัจจุบัน
  Map<String, dynamic> getCurrentStats() {
    return {
      'operations_in_progress': _activeOperations.length,
      'performance_history_size': _performanceHistory.length,
      'memory_history_size': _memoryHistory.length,
      'frame_history_size': _frameHistory.length,
      'is_monitoring': _isMonitoring,
    };
  }

  /// หยุดการติดตาม
  void pauseMonitoring() {
    _isMonitoring = false;
    _logInfo('Performance monitoring paused');
  }

  /// เริ่มการติดตามใหม่
  void resumeMonitoring() {
    _isMonitoring = true;
    _logInfo('Performance monitoring resumed');
  }

  /// ปิดระบบติดตาม
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _cleanupTimer?.cancel();
    _metricsController?.close();
    _memoryController?.close();

    _performanceHistory.clear();
    _memoryHistory.clear();
    _frameHistory.clear();
    _activeOperations.clear();
    _operationStats.clear();

    _isInitialized = false;
    _isMonitoring = false;

    _logInfo('Performance Monitor disposed');
  }

  // Logging methods
  void _logDebug(String message) {
    if (kDebugMode) {
      print('🔍 [PerformanceMonitor] $message');
    }
  }

  void _logInfo(String message) {
    if (kDebugMode) {
      print('🟢 [PerformanceMonitor] $message');
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
      print('🟡 [PerformanceMonitor] WARNING: $message');
    }
  }
}

/// Widget สำหรับแสดงข้อมูลประสิทธิภาพ
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = kDebugMode,
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final _monitor = PerformanceMonitor();
  StreamSubscription<MemoryInfo>? _memorySubscription;
  MemoryInfo? _currentMemoryInfo;

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay) {
      _monitor.initialize();
      _memorySubscription = _monitor.memoryStream?.listen((info) {
        setState(() {
          _currentMemoryInfo = info;
        });
      });
    }
  }

  @override
  void dispose() {
    _memorySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && _currentMemoryInfo != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Memory: ${_currentMemoryInfo!.usagePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Used: ${(_currentMemoryInfo!.used / 1024 / 1024).toStringAsFixed(1)}MB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
