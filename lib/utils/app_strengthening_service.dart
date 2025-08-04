// lib/utils/app_strengthening_service.dart
// ระบบเสริมสร้างความแข็งแรงแอพอย่างครอบคลุม

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// ระบบเสริมสร้างความแข็งแรงและความเสถียรของแอพ
class AppStrengtheningService {
  static final AppStrengtheningService _instance =
      AppStrengtheningService._internal();
  factory AppStrengtheningService() => _instance;
  AppStrengtheningService._internal();

  // Performance Monitoring
  final Map<String, DateTime> _performanceMetrics = {};
  final List<String> _errorLogs = [];
  final Map<String, int> _operationCounts = {};

  // Network & Connectivity
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  final List<VoidCallback> _connectionCallbacks = [];

  // Memory & Resource Management
  Timer? _memoryCleanupTimer;
  final Map<String, dynamic> _cachedData = {};
  static const int maxCacheSize = 100;

  // Security Enhancements
  DateTime? _lastSecurityCheck;
  bool _isSecurityModeEnabled = false;

  // Error Recovery
  final Map<String, Function> _retryableOperations = {};
  static const int maxRetryAttempts = 3;

  /// 🚀 เริ่มต้นระบบเสริมสร้างความแข็งแรง
  Future<void> initialize() async {
    try {
      await _initializePerformanceMonitoring();
      await _initializeNetworkMonitoring();
      await _initializeMemoryManagement();
      await _initializeSecurityEnhancements();
      await _initializeErrorRecovery();

      _logInfo('AppStrengtheningService initialized successfully');
    } catch (e) {
      _logError('Failed to initialize AppStrengtheningService: $e');
    }
  }

  /// 📊 Performance Monitoring
  Future<void> _initializePerformanceMonitoring() async {
    _logInfo('Initializing Performance Monitoring...');

    // Track app startup time
    startPerformanceTimer('app_startup');

    // Monitor frame rendering
    if (!kIsWeb) {
      WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
        _trackFramePerformance(timeStamp);
      });
    }
  }

  void startPerformanceTimer(String operation) {
    _performanceMetrics[operation] = DateTime.now();
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
  }

  Duration? stopPerformanceTimer(String operation) {
    final startTime = _performanceMetrics[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _performanceMetrics.remove(operation);

      // Log slow operations
      if (duration.inMilliseconds > 1000) {
        _logWarning(
            'Slow operation detected: $operation took ${duration.inMilliseconds}ms');
      }

      return duration;
    }
    return null;
  }

  void _trackFramePerformance(Duration timeStamp) {
    // Monitor for frame drops (simplified)
    final frameTime = timeStamp.inMicroseconds;
    if (frameTime > 16666) {
      // > 16.67ms = dropped frame at 60fps
      _logWarning('Frame drop detected: $frameTimeμs');
    }
  }

  /// 🌐 Network & Connectivity Monitoring
  Future<void> _initializeNetworkMonitoring() async {
    _logInfo('Initializing Network Monitoring...');

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);

        if (wasOnline != _isOnline) {
          _handleConnectionChange(_isOnline);
        }
      },
    );

    // Check initial connectivity
    final results = await Connectivity().checkConnectivity();
    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  void _handleConnectionChange(bool isOnline) {
    _logInfo('Connection status changed: ${isOnline ? 'Online' : 'Offline'}');

    if (isOnline) {
      _syncOfflineData();
    }

    // Notify listeners
    for (final callback in _connectionCallbacks) {
      callback();
    }
  }

  void addConnectionListener(VoidCallback callback) {
    _connectionCallbacks.add(callback);
  }

  void removeConnectionListener(VoidCallback callback) {
    _connectionCallbacks.remove(callback);
  }

  /// 💾 Memory & Resource Management
  Future<void> _initializeMemoryManagement() async {
    _logInfo('Initializing Memory Management...');

    // Periodic cleanup
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performMemoryCleanup(),
    );
  }

  void _performMemoryCleanup() {
    // Clear old cache entries
    if (_cachedData.length > maxCacheSize) {
      final keysToRemove =
          _cachedData.keys.take(_cachedData.length - maxCacheSize);
      for (final key in keysToRemove) {
        _cachedData.remove(key);
      }
      _logInfo('Cache cleanup: Removed ${keysToRemove.length} entries');
    }

    // Clear old performance metrics
    final now = DateTime.now();
    _performanceMetrics.removeWhere((key, startTime) {
      return now.difference(startTime).inHours > 1;
    });

    // Clear old error logs
    if (_errorLogs.length > 100) {
      _errorLogs.removeRange(0, _errorLogs.length - 50);
    }
  }

  T? getCachedData<T>(String key) {
    return _cachedData[key] as T?;
  }

  void setCachedData<T>(String key, T data) {
    _cachedData[key] = data;
  }

  void clearCache() {
    _cachedData.clear();
    _logInfo('Cache cleared');
  }

  /// 🔒 Security Enhancements
  Future<void> _initializeSecurityEnhancements() async {
    _logInfo('Initializing Security Enhancements...');

    await _performSecurityCheck();

    // Schedule periodic security checks
    Timer.periodic(
      const Duration(hours: 1),
      (_) => _performSecurityCheck(),
    );
  }

  Future<void> _performSecurityCheck() async {
    _lastSecurityCheck = DateTime.now();

    try {
      // Check Firebase Auth token validity
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true); // Force token refresh
      }

      // Check for suspicious activity patterns
      await _checkSuspiciousActivity();

      _logInfo('Security check completed successfully');
    } catch (e) {
      _logError('Security check failed: $e');
      _enableSecurityMode();
    }
  }

  Future<void> _checkSuspiciousActivity() async {
    // Check for rapid API calls
    final rapidOperations =
        _operationCounts.entries.where((entry) => entry.value > 100).toList();

    if (rapidOperations.isNotEmpty) {
      _logWarning(
          'Suspicious activity detected: Rapid operations ${rapidOperations.map((e) => '${e.key}:${e.value}').join(', ')}');
    }
  }

  void _enableSecurityMode() {
    _isSecurityModeEnabled = true;
    _logWarning('Security mode enabled due to potential threats');
  }

  bool get isSecurityModeEnabled => _isSecurityModeEnabled;

  /// 🔄 Error Recovery & Resilience
  Future<void> _initializeErrorRecovery() async {
    _logInfo('Initializing Error Recovery...');

    // Set up global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handle platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    _logError('Flutter Error: ${details.exception}');
    _logError('Stack: ${details.stack}');

    // Attempt recovery if possible
    _attemptErrorRecovery('flutter_error', details.exception);
  }

  bool _handlePlatformError(Object error, StackTrace stack) {
    _logError('Platform Error: $error');
    _logError('Stack: $stack');

    // Attempt recovery
    _attemptErrorRecovery('platform_error', error);
    return true;
  }

  void registerRetryableOperation(String key, Function operation) {
    _retryableOperations[key] = operation;
  }

  Future<T?> executeWithRetry<T>(
    String operationKey,
    Future<T> Function() operation, {
    int maxRetries = maxRetryAttempts,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        startPerformanceTimer(operationKey);
        final result = await operation();
        stopPerformanceTimer(operationKey);
        return result;
      } catch (e) {
        _logError(
            'Operation $operationKey failed (attempt ${attempt + 1}): $e');

        if (attempt == maxRetries) {
          _logError(
              'Operation $operationKey failed after $maxRetries attempts');
          rethrow;
        }

        // Wait before retry
        await Future.delayed(delay * (attempt + 1));
      }
    }
    return null;
  }

  void _attemptErrorRecovery(String errorType, Object error) {
    _logInfo('Attempting error recovery for: $errorType');

    // Add recovery logic based on error type
    switch (errorType) {
      case 'network_error':
        _handleNetworkErrorRecovery();
        break;
      case 'auth_error':
        _handleAuthErrorRecovery();
        break;
      case 'storage_error':
        _handleStorageErrorRecovery();
        break;
      default:
        _handleGenericErrorRecovery();
    }
  }

  void _handleNetworkErrorRecovery() {
    _logInfo('Recovering from network error...');
    // Implement network recovery logic
  }

  void _handleAuthErrorRecovery() {
    _logInfo('Recovering from auth error...');
    // Implement auth recovery logic
  }

  void _handleStorageErrorRecovery() {
    _logInfo('Recovering from storage error...');
    // Implement storage recovery logic
  }

  void _handleGenericErrorRecovery() {
    _logInfo('Performing generic error recovery...');
    // Clear cache, reset states, etc.
    clearCache();
  }

  /// 📱 Device & System Information
  Future<Map<String, dynamic>> getSystemInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    Map<String, dynamic> info = {
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'package_name': packageInfo.packageName,
    };

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      info.addAll({
        'platform': 'Android',
        'device': androidInfo.model,
        'os_version': androidInfo.version.release,
        'sdk_version': androidInfo.version.sdkInt,
      });
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      info.addAll({
        'platform': 'iOS',
        'device': iosInfo.model,
        'os_version': iosInfo.systemVersion,
      });
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      info.addAll({
        'platform': 'Windows',
        'device': windowsInfo.computerName,
        'os_version': windowsInfo.displayVersion,
      });
    }

    return info;
  }

  /// 📈 Analytics & Reporting
  Map<String, dynamic> getPerformanceReport() {
    return {
      'total_operations': _operationCounts.length,
      'operation_counts': Map.from(_operationCounts),
      'active_timers': _performanceMetrics.length,
      'error_count': _errorLogs.length,
      'cache_size': _cachedData.length,
      'is_online': _isOnline,
      'security_mode': _isSecurityModeEnabled,
      'last_security_check': _lastSecurityCheck?.toIso8601String(),
    };
  }

  List<String> getErrorLogs() => List.unmodifiable(_errorLogs);

  /// 🧹 Cleanup & Disposal
  void dispose() {
    _connectivitySubscription?.cancel();
    _memoryCleanupTimer?.cancel();
    _connectionCallbacks.clear();
    _cachedData.clear();
    _performanceMetrics.clear();
    _operationCounts.clear();
    _retryableOperations.clear();
    _logInfo('AppStrengtheningService disposed');
  }

  /// 📝 Offline Data Sync
  Future<void> _syncOfflineData() async {
    _logInfo('Syncing offline data...');
    // Implement offline data synchronization
  }

  /// 🔧 Utility Methods
  void _logInfo(String message) {
    if (kDebugMode) {
      print('🟢 [AppStrengthening] $message');
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
      print('🟡 [AppStrengthening] WARNING: $message');
    }
    _errorLogs.add('WARNING: $message [${DateTime.now()}]');
  }

  void _logError(String message) {
    if (kDebugMode) {
      print('🔴 [AppStrengthening] ERROR: $message');
    }
    _errorLogs.add('ERROR: $message [${DateTime.now()}]');
  }
}

/// 🎛️ App Strengthening Widget
class AppStrengtheningWidget extends StatefulWidget {
  final Widget child;

  const AppStrengtheningWidget({
    super.key,
    required this.child,
  });

  @override
  State<AppStrengtheningWidget> createState() => _AppStrengtheningWidgetState();
}

class _AppStrengtheningWidgetState extends State<AppStrengtheningWidget> {
  final _strengthening = AppStrengtheningService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeStrengthening();
  }

  Future<void> _initializeStrengthening() async {
    try {
      await _strengthening.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      print('Failed to initialize app strengthening: $e');
      setState(() => _isInitialized = true); // Continue even if init fails
    }
  }

  @override
  void dispose() {
    _strengthening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return widget.child;
  }
}
