// lib/utils/app_comprehensive_strengthening.dart
// ระบบเสริมสร้างความแข็งแรงครอบคลุมสำหรับ Green Market App

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:green_market/utils/enhanced_error_handler.dart';
import 'package:green_market/utils/performance_monitor.dart';
import 'package:green_market/utils/security_hardening.dart';
import 'package:green_market/utils/backup_recovery_system.dart';

/// สถานะของระบบเสริมสร้างความแข็งแรง
enum SystemHealthStatus {
  excellent,
  good,
  warning,
  critical,
}

/// ข้อมูลสถานะระบบ
class SystemHealthInfo {
  final SystemHealthStatus status;
  final double score;
  final Map<String, dynamic> metrics;
  final List<String> issues;
  final List<String> recommendations;
  final DateTime timestamp;

  SystemHealthInfo({
    required this.status,
    required this.score,
    required this.metrics,
    required this.issues,
    required this.recommendations,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'score': score,
      'metrics': metrics,
      'issues': issues,
      'recommendations': recommendations,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// ระบบเสริมสร้างความแข็งแรงครอบคลุม
class AppComprehensiveStrengthening {
  static final AppComprehensiveStrengthening _instance =
      AppComprehensiveStrengthening._internal();
  factory AppComprehensiveStrengthening() => _instance;
  AppComprehensiveStrengthening._internal();

  // Sub-systems
  final EnhancedErrorHandler _errorHandler = EnhancedErrorHandler();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final SecurityHardening _securityHardening = SecurityHardening();
  final BackupRecoverySystem _backupSystem = BackupRecoverySystem();

  // State
  bool _isInitialized = false;
  Timer? _healthCheckTimer;
  SystemHealthInfo? _lastHealthCheck;
  final List<SystemHealthInfo> _healthHistory = [];

  // Configuration
  static const Duration HEALTH_CHECK_INTERVAL = Duration(minutes: 5);
  static const int MAX_HEALTH_HISTORY = 288; // 1 day with 5-minute intervals

  /// เริ่มต้นระบบทั้งหมด
  Future<void> initialize() async {
    if (_isInitialized) {
      _logInfo('System already initialized');
      return;
    }

    _logInfo('Initializing comprehensive strengthening system...');

    try {
      // เริ่มต้นระบบต่างๆ ตามลำดับ
      await _initializeErrorHandling();
      await _initializePerformanceMonitoring();
      await _initializeSecurityHardening();
      await _initializeBackupSystem();

      // เริ่มการตรวจสอบสุขภาพระบบ
      _startHealthMonitoring();

      _isInitialized = true;
      _logInfo('✅ All systems initialized successfully');

      // ทำการตรวจสอบเริ่มต้น
      await performHealthCheck();
    } catch (e) {
      _logError('Failed to initialize comprehensive strengthening: $e');
      rethrow;
    }
  }

  /// เริ่มต้นระบบจัดการข้อผิดพลาด
  Future<void> _initializeErrorHandling() async {
    _errorHandler.initialize();

    // เพิ่ม listener สำหรับข้อผิดพลาดร้ายแรง
    _errorHandler.addErrorListener((error) {
      if (error.severity == ErrorSeverity.critical) {
        _handleCriticalError(error);
      }
    });

    _logInfo('✅ Error handling system initialized');
  }

  /// เริ่มต้นระบบติดตามประสิทธิภาพ
  Future<void> _initializePerformanceMonitoring() async {
    await _performanceMonitor.initialize();

    // ติดตามการเริ่มต้นแอพ
    _performanceMonitor.stopOperation('app_startup');

    _logInfo('✅ Performance monitoring system initialized');
  }

  /// เริ่มต้นระบบรักษาความปลอดภัย
  Future<void> _initializeSecurityHardening() async {
    await _securityHardening.initialize();
    _logInfo('✅ Security hardening system initialized');
  }

  /// เริ่มต้นระบบสำรองข้อมูล
  Future<void> _initializeBackupSystem() async {
    await _backupSystem.initialize();
    _logInfo('✅ Backup recovery system initialized');
  }

  /// เริ่มการติดตามสุขภาพระบบ
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(HEALTH_CHECK_INTERVAL, (_) async {
      try {
        await performHealthCheck();
      } catch (e) {
        _logError('Health check failed: $e');
      }
    });
  }

  /// ทำการตรวจสอบสุขภาพระบบ
  Future<SystemHealthInfo> performHealthCheck() async {
    _logInfo('Performing system health check...');

    final metrics = <String, dynamic>{};
    final issues = <String>[];
    final recommendations = <String>[];

    // ตรวจสอบประสิทธิภาพ
    final performanceReport = _performanceMonitor.getPerformanceReport();
    metrics['performance'] = performanceReport;

    _analyzePerformance(performanceReport, issues, recommendations);

    // ตรวจสอบความปลอดภัย
    final securityReport = _securityHardening.getSecurityReport();
    metrics['security'] = securityReport;

    _analyzeSecurity(securityReport, issues, recommendations);

    // ตรวจสอบข้อผิดพลาด
    final errorCounts = _errorHandler.errorCounts;
    metrics['errors'] = {
      'total_errors': _errorHandler.errorHistory.length,
      'error_counts': errorCounts,
      'recent_errors': _getRecentErrorCount(),
    };

    _analyzeErrors(metrics['errors'], issues, recommendations);

    // ตรวจสอบระบบสำรองข้อมูล
    final backupReport = _backupSystem.getBackupReport();
    metrics['backup'] = backupReport;

    _analyzeBackup(backupReport, issues, recommendations);

    // คำนวณคะแนนสุขภาพ
    final score = _calculateHealthScore(metrics, issues);
    final status = _determineHealthStatus(score);

    final healthInfo = SystemHealthInfo(
      status: status,
      score: score,
      metrics: metrics,
      issues: issues,
      recommendations: recommendations,
      timestamp: DateTime.now(),
    );

    _addHealthInfo(healthInfo);
    _lastHealthCheck = healthInfo;

    _logInfo(
        'Health check completed - Status: ${status.name}, Score: ${score.toStringAsFixed(1)}');

    if (issues.isNotEmpty) {
      _logWarning('Health issues detected: ${issues.length}');
      for (final issue in issues) {
        _logWarning('- $issue');
      }
    }

    return healthInfo;
  }

  /// วิเคราะห์ประสิทธิภาพ
  void _analyzePerformance(Map<String, dynamic> report, List<String> issues,
      List<String> recommendations) {
    final slowOperations = report['slow_operations'] as List? ?? [];
    final framePerformance =
        report['frame_performance'] as Map<String, dynamic>? ?? {};

    if (slowOperations.isNotEmpty) {
      issues.add('มีการทำงานที่ช้า ${slowOperations.length} รายการ');
      recommendations.add('ปรับปรุงประสิทธิภาพของการทำงานที่ช้า');
    }

    final jankyPercentage = double.tryParse(
            framePerformance['janky_percentage']?.toString() ?? '0') ??
        0;
    if (jankyPercentage > 5) {
      issues.add('การเรนเดอร์เฟรมมีปัญหา $jankyPercentage%');
      recommendations.add('ปรับปรุงการเรนเดอร์เพื่อลดการสะดุดของ UI');
    }
  }

  /// วิเคราะห์ความปลอดภัย
  void _analyzeSecurity(Map<String, dynamic> report, List<String> issues,
      List<String> recommendations) {
    final recentThreats = report['recent_threats_24h'] as int? ?? 0;
    final securityMode = report['security_mode_enabled'] as bool? ?? false;
    final blockedIdentifiers = report['blocked_identifiers'] as int? ?? 0;

    if (recentThreats > 10) {
      issues.add(
          'มีภัยคุกคามความปลอดภัย $recentThreats รายการใน 24 ชั่วโมงที่ผ่านมา');
      recommendations.add('ตรวจสอบและเสริมสร้างมาตรการรักษาความปลอดภัย');
    }

    if (securityMode) {
      issues.add('ระบบอยู่ในโหมดรักษาความปลอดภัยสูง');
      recommendations.add('ตรวจสอบสาเหตุและแก้ไขปัญหาความปลอดภัย');
    }

    if (blockedIdentifiers > 5) {
      issues.add('มี IP ที่ถูกบล็อค $blockedIdentifiers รายการ');
    }
  }

  /// วิเคราะห์ข้อผิดพลาด
  void _analyzeErrors(Map<String, dynamic> errorData, List<String> issues,
      List<String> recommendations) {
    final totalErrors = errorData['total_errors'] as int? ?? 0;
    final recentErrors = errorData['recent_errors'] as int? ?? 0;

    if (recentErrors > 10) {
      issues.add('มีข้อผิดพลาด $recentErrors รายการในชั่วโมงที่ผ่านมา');
      recommendations.add('ตรวจสอบและแก้ไขข้อผิดพลาดที่เกิดขึ้นบ่อย');
    }

    if (totalErrors > 100) {
      recommendations.add('ล้างประวัติข้อผิดพลาดเก่าเพื่อปรับปรุงประสิทธิภาพ');
    }
  }

  /// วิเคราะห์ระบบสำรองข้อมูล
  void _analyzeBackup(Map<String, dynamic> report, List<String> issues,
      List<String> recommendations) {
    final failedBackups = report['failed_backups'] as int? ?? 0;
    final latestBackup = report['latest_backup'] as Map<String, dynamic>?;

    if (failedBackups > 0) {
      issues.add('มีการสำรองข้อมูลที่ล้มเหลว $failedBackups รายการ');
      recommendations.add('ตรวจสอบและแก้ไขปัญหาการสำรองข้อมูล');
    }

    if (latestBackup != null) {
      final latestTimestamp =
          DateTime.tryParse(latestBackup['timestamp'] ?? '');
      if (latestTimestamp != null) {
        final daysSinceBackup =
            DateTime.now().difference(latestTimestamp).inDays;
        if (daysSinceBackup > 7) {
          issues.add('ไม่มีการสำรองข้อมูลมาแล้ว $daysSinceBackup วัน');
          recommendations.add('ทำการสำรองข้อมูลให้เป็นปัจจุบัน');
        }
      }
    } else {
      issues.add('ยังไม่เคยมีการสำรองข้อมูล');
      recommendations.add('สร้างการสำรองข้อมูลเพื่อความปลอดภัย');
    }
  }

  /// คำนวณคะแนนสุขภาพ
  double _calculateHealthScore(
      Map<String, dynamic> metrics, List<String> issues) {
    double score = 100.0;

    // ลดคะแนนตามจำนวนปัญหา
    score -= issues.length * 5.0;

    // ลดคะแนนตามประสิทธิภาพ
    final performance = metrics['performance'] as Map<String, dynamic>? ?? {};
    final slowOperations = performance['slow_operations'] as List? ?? [];
    score -= slowOperations.length * 2.0;

    // ลดคะแนนตามความปลอดภัย
    final security = metrics['security'] as Map<String, dynamic>? ?? {};
    final recentThreats = security['recent_threats_24h'] as int? ?? 0;
    score -= recentThreats * 1.0;

    // ลดคะแนนตามข้อผิดพลาด
    final errors = metrics['errors'] as Map<String, dynamic>? ?? {};
    final recentErrors = errors['recent_errors'] as int? ?? 0;
    score -= recentErrors * 0.5;

    return score.clamp(0.0, 100.0);
  }

  /// กำหนดสถานะสุขภาพ
  SystemHealthStatus _determineHealthStatus(double score) {
    if (score >= 90) return SystemHealthStatus.excellent;
    if (score >= 75) return SystemHealthStatus.good;
    if (score >= 50) return SystemHealthStatus.warning;
    return SystemHealthStatus.critical;
  }

  /// นับข้อผิดพลาดล่าสุด
  int _getRecentErrorCount() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _errorHandler.errorHistory
        .where((error) => error.timestamp.isAfter(oneHourAgo))
        .length;
  }

  /// จัดการข้อผิดพลาดร้ายแรง
  void _handleCriticalError(AppError error) {
    _logError('CRITICAL ERROR DETECTED: ${error.message}');

    // อาจทำการสำรองข้อมูลฉุกเฉิน
    _performEmergencyBackup();

    // เริ่มโหมดรักษาความปลอดภัยสูง
    _securityHardening.markUserSuspicious(
      error.context?['user_id'] ?? 'unknown',
      'Critical error occurred',
    );
  }

  /// สำรองข้อมูลฉุกเฉิน
  Future<void> _performEmergencyBackup() async {
    try {
      await _backupSystem.performBackup(
        BackupType.preferences,
        automated: true,
        options: {'emergency': true},
      );
      _logInfo('Emergency backup completed');
    } catch (e) {
      _logError('Emergency backup failed: $e');
    }
  }

  /// เพิ่มข้อมูลสุขภาพ
  void _addHealthInfo(SystemHealthInfo info) {
    _healthHistory.add(info);

    // จำกัดขนาดประวัติ
    while (_healthHistory.length > MAX_HEALTH_HISTORY) {
      _healthHistory.removeAt(0);
    }
  }

  /// ทำการปรับปรุงอัตโนมัติ
  Future<void> performAutoOptimization() async {
    _logInfo('Performing automatic optimization...');

    try {
      // ล้างข้อมูลเก่า
      if (_errorHandler.errorHistory.length > 50) {
        _errorHandler.clearErrorHistory();
      }

      // ทำการสำรองข้อมูลถ้าจำเป็น
      final backupReport = _backupSystem.getBackupReport();
      final latestBackup =
          backupReport['latest_backup'] as Map<String, dynamic>?;

      if (latestBackup == null) {
        await _backupSystem.performBackup(BackupType.preferences,
            automated: true);
      }

      // ล้างข้อมูลความปลอดภัยเก่า
      final securityReport = _securityHardening.getSecurityReport();
      final oldThreats = securityReport['total_threats'] as int? ?? 0;

      if (oldThreats > 100) {
        _securityHardening.clearSecurityData();
      }

      _logInfo('Auto optimization completed');
    } catch (e) {
      _logError('Auto optimization failed: $e');
    }
  }

  /// ได้รับรายงานสถานะทั้งหมด
  Map<String, dynamic> getComprehensiveReport() {
    return {
      'system_health': _lastHealthCheck?.toJson(),
      'health_history_count': _healthHistory.length,
      'performance': _performanceMonitor.getPerformanceReport(),
      'security': _securityHardening.getSecurityReport(),
      'backup': _backupSystem.getBackupReport(),
      'errors': {
        'total': _errorHandler.errorHistory.length,
        'recent': _getRecentErrorCount(),
        'counts': _errorHandler.errorCounts,
      },
      'system_status': {
        'initialized': _isInitialized,
        'monitoring_active': _healthCheckTimer?.isActive ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  /// ได้รับประวัติสุขภาพระบบ
  List<SystemHealthInfo> get healthHistory => List.unmodifiable(_healthHistory);

  /// ได้รับสถานะสุขภาพล่าสุด
  SystemHealthInfo? get latestHealthStatus => _lastHealthCheck;

  /// ตรวจสอบว่าระบบพร้อมใช้งานหรือไม่
  bool get isSystemHealthy {
    final status = _lastHealthCheck?.status;
    return status == SystemHealthStatus.excellent ||
        status == SystemHealthStatus.good;
  }

  /// ปิดระบบทั้งหมด
  void dispose() {
    _healthCheckTimer?.cancel();
    _performanceMonitor.dispose();
    _securityHardening.dispose();
    _backupSystem.dispose();

    _healthHistory.clear();
    _lastHealthCheck = null;
    _isInitialized = false;

    _logInfo('Comprehensive strengthening system disposed');
  }

  // Logging methods
  void _logInfo(String message) {
    if (kDebugMode) {
      print('🟢 [ComprehensiveStrengthening] $message');
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
      print('🟡 [ComprehensiveStrengthening] WARNING: $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      print('🔴 [ComprehensiveStrengthening] ERROR: $message');
    }
  }
}
