// lib/utils/debug_config.dart
// Debug configuration for production-ready logging

import 'package:flutter/foundation.dart';

class DebugConfig {
  // Production Configuration
  static const bool enableVerboseLogging = kDebugMode;
  static const bool enableAnalyticsDebug = kDebugMode;
  static const bool enableFirebaseDebug = kDebugMode;
  static const bool enableUIDebug = kDebugMode;

  // Log Levels
  static const String logLevelInfo = 'INFO';
  static const String logLevelWarning = 'WARNING';
  static const String logLevelError = 'ERROR';
  static const String logLevelDebug = 'DEBUG';

  // Feature Flags
  static const bool enableCrashlytics = !kDebugMode;
  static const bool enablePerformanceMonitoring = !kDebugMode;
  static const bool enableAnalytics = !kDebugMode;

  // Smart Product Analytics Config
  static const bool enableAIVerboseLogging = false; // Turn off for production
  static const bool enableProductAnalyticsDebug = false;
  static const bool enableEcoScoreDebug = false;

  // Network Config
  static const int networkTimeoutSeconds = 30;
  static const int retryAttempts = 3;
  static const bool enableNetworkLogging = kDebugMode;
}

class ProductionLogger {
  static void d(String message) {
    if (DebugConfig.enableVerboseLogging) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void i(String message) {
    if (DebugConfig.enableVerboseLogging) {
      debugPrint('[INFO] $message');
    }
  }

  static void w(String message) {
    if (DebugConfig.enableVerboseLogging) {
      debugPrint('[WARNING] $message');
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null && DebugConfig.enableVerboseLogging) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static void ai(String message) {
    if (DebugConfig.enableAIVerboseLogging) {
      debugPrint('[AI] $message');
    }
  }
}
