// lib/services/app_performance_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Performance metrics data class
class PerformanceMetrics {
  final String sessionId;
  final DateTime timestamp;
  final String screenName;
  final Duration screenLoadTime;
  final int memoryUsageMB;
  final double cpuUsagePercent;
  final int networkRequests;
  final Duration averageNetworkResponseTime;
  final int errorCount;
  final Map<String, dynamic> customMetrics;

  PerformanceMetrics({
    required this.sessionId,
    required this.timestamp,
    required this.screenName,
    required this.screenLoadTime,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.networkRequests,
    required this.averageNetworkResponseTime,
    required this.errorCount,
    this.customMetrics = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'timestamp': Timestamp.fromDate(timestamp),
      'screenName': screenName,
      'screenLoadTimeMs': screenLoadTime.inMilliseconds,
      'memoryUsageMB': memoryUsageMB,
      'cpuUsagePercent': cpuUsagePercent,
      'networkRequests': networkRequests,
      'averageNetworkResponseTimeMs': averageNetworkResponseTime.inMilliseconds,
      'errorCount': errorCount,
      'customMetrics': customMetrics,
    };
  }
}

/// User interaction analytics data
class UserInteractionEvent {
  final String eventType;
  final String screenName;
  final DateTime timestamp;
  final Map<String, dynamic> parameters;

  UserInteractionEvent({
    required this.eventType,
    required this.screenName,
    required this.timestamp,
    this.parameters = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType,
      'screenName': screenName,
      'timestamp': Timestamp.fromDate(timestamp),
      'parameters': parameters,
    };
  }
}

/// Comprehensive app performance and analytics service
class AppPerformanceService {
  static final AppPerformanceService _instance =
      AppPerformanceService._internal();
  factory AppPerformanceService() => _instance;
  AppPerformanceService._internal();

  final Logger _logger = Logger();
  final String _sessionId = _generateSessionId();

  // Performance tracking
  final Map<String, Stopwatch> _screenStopwatches = {};
  final Map<String, DateTime> _screenStartTimes = {};
  final List<PerformanceMetrics> _pendingMetrics = [];
  final List<UserInteractionEvent> _pendingEvents = [];

  // Network monitoring
  int _networkRequestCount = 0;
  final List<Duration> _networkResponseTimes = [];

  // Error tracking
  int _errorCount = 0;
  final List<Map<String, dynamic>> _errorEvents = [];

  // Custom metrics storage
  final List<Map<String, dynamic>> _customMetrics = [];

  // Memory and performance monitoring
  Timer? _performanceTimer;
  bool _isMonitoring = false;

  static const int _batchSize = 10;
  static const Duration _batchInterval = Duration(minutes: 5);

  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _startPerformanceMonitoring();
    _startBatchUpload();

    _logger.i('AppPerformanceService initialized with session: $_sessionId');
  }

  /// Start monitoring screen performance
  void startScreenTracking(String screenName) {
    final stopwatch = Stopwatch()..start();
    _screenStopwatches[screenName] = stopwatch;
    _screenStartTimes[screenName] = DateTime.now();

    _logger.d('Started tracking screen: $screenName');
  }

  /// Stop monitoring screen and record metrics
  void stopScreenTracking(String screenName) {
    final stopwatch = _screenStopwatches[screenName];
    final startTime = _screenStartTimes[screenName];

    if (stopwatch != null && startTime != null) {
      stopwatch.stop();

      final metrics = PerformanceMetrics(
        sessionId: _sessionId,
        timestamp: DateTime.now(),
        screenName: screenName,
        screenLoadTime: stopwatch.elapsed,
        memoryUsageMB: _getCurrentMemoryUsage(),
        cpuUsagePercent: _getCurrentCpuUsage(),
        networkRequests: _networkRequestCount,
        averageNetworkResponseTime: _getAverageNetworkResponseTime(),
        errorCount: _errorCount,
        customMetrics: _getCustomMetrics(screenName),
      );

      _pendingMetrics.add(metrics);
      _screenStopwatches.remove(screenName);
      _screenStartTimes.remove(screenName);

      _logger.d(
          'Screen tracking completed: $screenName, Load time: ${stopwatch.elapsed.inMilliseconds}ms');
    }
  }

  /// Track user interaction events
  void trackUserInteraction(String eventType, String screenName,
      {Map<String, dynamic>? parameters}) {
    final event = UserInteractionEvent(
      eventType: eventType,
      screenName: screenName,
      timestamp: DateTime.now(),
      parameters: parameters ?? {},
    );

    _pendingEvents.add(event);
    _logger.d('User interaction tracked: $eventType on $screenName');
  }

  /// Track network request performance
  void trackNetworkRequest(Duration responseTime) {
    _networkRequestCount++;
    _networkResponseTimes.add(responseTime);

    // Keep only last 100 response times for average calculation
    if (_networkResponseTimes.length > 100) {
      _networkResponseTimes.removeAt(0);
    }
  }

  /// Track application errors
  void trackError(String errorType, String errorMessage,
      {String? screenName, Map<String, dynamic>? context}) {
    _errorCount++;

    final errorEvent = {
      'sessionId': _sessionId,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'errorType': errorType,
      'errorMessage': errorMessage,
      'screenName': screenName,
      'context': context ?? {},
    };

    _errorEvents.add(errorEvent);
    _logger.e('Error tracked: $errorType - $errorMessage');
  }

  /// Track custom business metrics
  void trackCustomMetric(String metricName, dynamic value,
      {Map<String, dynamic>? tags}) {
    final metric = {
      'sessionId': _sessionId,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'metricName': metricName,
      'value': value,
      'tags': tags ?? {},
    };

    // Store the metric for later upload
    _customMetrics.add(metric);

    _logger.d('Custom metric tracked: $metricName = $value');
  }

  /// Get current app health status
  Map<String, dynamic> getAppHealthStatus() {
    return {
      'sessionId': _sessionId,
      'isHealthy': _errorCount < 10 && _getAverageMemoryUsage() < 200,
      'errorCount': _errorCount,
      'averageMemoryUsage': _getAverageMemoryUsage(),
      'averageResponseTime': _getAverageNetworkResponseTime().inMilliseconds,
      'activeScreenTrackers': _screenStopwatches.length,
      'pendingMetrics': _pendingMetrics.length,
      'pendingEvents': _pendingEvents.length,
    };
  }

  /// Export all performance data for analysis
  Map<String, dynamic> exportPerformanceData() {
    return {
      'sessionId': _sessionId,
      'metrics': _pendingMetrics.map((m) => m.toJson()).toList(),
      'userEvents': _pendingEvents.map((e) => e.toJson()).toList(),
      'errors': _errorEvents,
      'networkStats': {
        'totalRequests': _networkRequestCount,
        'averageResponseTime': _getAverageNetworkResponseTime().inMilliseconds,
      },
      'appHealth': getAppHealthStatus(),
    };
  }

  // === PRIVATE HELPER METHODS ===

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _collectSystemMetrics();
    });
  }

  void _startBatchUpload() {
    Timer.periodic(_batchInterval, (_) {
      _uploadPendingData();
    });
  }

  void _collectSystemMetrics() {
    // Collect system-wide performance metrics
    final currentMetrics = PerformanceMetrics(
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      screenName: 'system',
      screenLoadTime: Duration.zero,
      memoryUsageMB: _getCurrentMemoryUsage(),
      cpuUsagePercent: _getCurrentCpuUsage(),
      networkRequests: _networkRequestCount,
      averageNetworkResponseTime: _getAverageNetworkResponseTime(),
      errorCount: _errorCount,
      customMetrics: {'collectTime': DateTime.now().millisecondsSinceEpoch},
    );

    _pendingMetrics.add(currentMetrics);
  }

  Future<void> _uploadPendingData() async {
    if (_pendingMetrics.isEmpty &&
        _pendingEvents.isEmpty &&
        _errorEvents.isEmpty) {
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Upload performance metrics
      for (final metric in _pendingMetrics.take(_batchSize)) {
        final ref = firestore.collection('performance_metrics').doc();
        batch.set(ref, metric.toJson());
      }

      // Upload user events
      for (final event in _pendingEvents.take(_batchSize)) {
        final ref = firestore.collection('user_events').doc();
        batch.set(ref, event.toJson());
      }

      // Upload error events
      for (final error in _errorEvents.take(_batchSize)) {
        final ref = firestore.collection('error_events').doc();
        batch.set(ref, error);
      }

      await batch.commit();

      // Remove uploaded data
      _pendingMetrics.removeRange(0, min(_pendingMetrics.length, _batchSize));
      _pendingEvents.removeRange(0, min(_pendingEvents.length, _batchSize));
      _errorEvents.removeRange(0, min(_errorEvents.length, _batchSize));

      _logger.d('Performance data uploaded successfully');
    } catch (e) {
      _logger.e('Failed to upload performance data: $e');
    }
  }

  int _getCurrentMemoryUsage() {
    // Simulate memory usage tracking
    // In a real implementation, you might use platform channels to get actual memory usage
    return 50 + Random().nextInt(100);
  }

  double _getCurrentCpuUsage() {
    // Simulate CPU usage tracking
    return Random().nextDouble() * 100;
  }

  Duration _getAverageNetworkResponseTime() {
    if (_networkResponseTimes.isEmpty) {
      return Duration.zero;
    }

    final totalMs = _networkResponseTimes
        .map((duration) => duration.inMilliseconds)
        .reduce((a, b) => a + b);

    return Duration(
        milliseconds: (totalMs / _networkResponseTimes.length).round());
  }

  int _getAverageMemoryUsage() {
    return _getCurrentMemoryUsage(); // Simplified for demo
  }

  Map<String, dynamic> _getCustomMetrics(String screenName) {
    return {
      'screenName': screenName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'deviceInfo': _getDeviceInfo(),
    };
  }

  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': defaultTargetPlatform.name,
      'isDebug': kDebugMode,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Cleanup resources
  void dispose() {
    _performanceTimer?.cancel();
    _screenStopwatches.clear();
    _screenStartTimes.clear();
    _isMonitoring = false;
    _logger.i('AppPerformanceService disposed');
  }
}

/// Mixin for easy performance tracking in screens
mixin PerformanceTrackingMixin {
  final AppPerformanceService _performanceService = AppPerformanceService();

  void startScreenTracking(String screenName) {
    _performanceService.startScreenTracking(screenName);
  }

  void stopScreenTracking(String screenName) {
    _performanceService.stopScreenTracking(screenName);
  }

  void trackUserInteraction(String eventType, String screenName,
      {Map<String, dynamic>? parameters}) {
    _performanceService.trackUserInteraction(eventType, screenName,
        parameters: parameters);
  }

  void trackError(String errorType, String errorMessage,
      {String? screenName, Map<String, dynamic>? context}) {
    _performanceService.trackError(errorType, errorMessage,
        screenName: screenName, context: context);
  }
}
