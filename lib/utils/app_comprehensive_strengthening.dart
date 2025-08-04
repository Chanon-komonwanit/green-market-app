// lib/utils/app_comprehensive_strengthening.dart
// ระบบเสริมความแข็งแกร่งและติดตามประสิทธิภาพแอพ

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// ข้อมูลสุขภาพระบบ
class SystemHealthInfo {
  final DateTime timestamp;
  final double memoryUsage;
  final double cpuUsage;
  final String networkStatus;
  final int activeConnections;
  final Map<String, dynamic> performanceMetrics;
  final List<String> errors;
  final List<String> warnings;

  SystemHealthInfo({
    required this.timestamp,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.networkStatus,
    required this.activeConnections,
    required this.performanceMetrics,
    required this.errors,
    required this.warnings,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'memoryUsage': memoryUsage,
      'cpuUsage': cpuUsage,
      'networkStatus': networkStatus,
      'activeConnections': activeConnections,
      'performanceMetrics': performanceMetrics,
      'errors': errors,
      'warnings': warnings,
    };
  }

  factory SystemHealthInfo.fromJson(Map<String, dynamic> json) {
    return SystemHealthInfo(
      timestamp: DateTime.parse(json['timestamp']),
      memoryUsage: json['memoryUsage']?.toDouble() ?? 0.0,
      cpuUsage: json['cpuUsage']?.toDouble() ?? 0.0,
      networkStatus: json['networkStatus'] ?? 'unknown',
      activeConnections: json['activeConnections'] ?? 0,
      performanceMetrics: json['performanceMetrics'] ?? {},
      errors: List<String>.from(json['errors'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  /// คำนวณคะแนนสุขภาพระบบ (0-100)
  double get healthScore {
    double score = 100.0;

    // ลดคะแนนตามการใช้หน่วยความจำ
    if (memoryUsage > 80) {
      score -= 20;
    } else if (memoryUsage > 60) {
      score -= 10;
    } else if (memoryUsage > 40) {
      score -= 5;
    }

    // ลดคะแนนตามการใช้ CPU
    if (cpuUsage > 80) {
      score -= 15;
    } else if (cpuUsage > 60) {
      score -= 8;
    } else if (cpuUsage > 40) {
      score -= 3;
    }

    // ลดคะแนนตามสถานะเครือข่าย
    if (networkStatus == 'none') {
      score -= 30;
    } else if (networkStatus == 'mobile') {
      score -= 5;
    }

    // ลดคะแนนตาม errors และ warnings
    score -= (errors.length * 10);
    score -= (warnings.length * 2);

    return score.clamp(0, 100);
  }

  /// ระดับสุขภาพระบบ
  String get healthLevel {
    final score = healthScore;
    if (score >= 90) return 'ดีเยี่ยม';
    if (score >= 75) return 'ดี';
    if (score >= 60) return 'ปานกลาง';
    if (score >= 40) return 'ต้องปรับปรุง';
    return 'วิกฤต';
  }

  /// สีแสดงระดับสุขภาพ
  String get healthColor {
    final score = healthScore;
    if (score >= 90) return '#10B981'; // เขียว
    if (score >= 75) return '#3B82F6'; // น้ำเงิน
    if (score >= 60) return '#F59E0B'; // เหลือง
    if (score >= 40) return '#EF4444'; // แดง
    return '#991B1B'; // แดงเข้ม
  }
}

/// ระบบเสริมความแข็งแกร่งและติดตามประสิทธิภาพแอพ
class AppComprehensiveStrengthening {
  static final AppComprehensiveStrengthening _instance =
      AppComprehensiveStrengthening._internal();

  factory AppComprehensiveStrengthening() => _instance;
  AppComprehensiveStrengthening._internal();

  // ข้อมูลประวัติสุขภาพระบบ
  final List<SystemHealthInfo> _healthHistory = [];

  // ข้อมูลการกำหนดค่า
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _deviceInfo;

  // สถานะการทำงาน
  bool _isInitialized = false;
  bool _isMonitoring = false;

  /// เข้าถึงประวัติสุขภาพระบบ
  List<SystemHealthInfo> get healthHistory => List.from(_healthHistory);

  /// ตรวจสอบว่าระบบเริ่มต้นแล้วหรือไม่
  bool get isInitialized => _isInitialized;

  /// ตรวจสอบว่ากำลังตติดตามหรือไม่
  bool get isMonitoring => _isMonitoring;

  /// เริ่มต้นระบบ
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // โหลดข้อมูลแอพ
      _packageInfo = await PackageInfo.fromPlatform();

      // โหลดข้อมูลอุปกรณ์
      await _loadDeviceInfo();

      // ทำการตรวจสอบสุขภาพเบื้องต้น
      await performHealthCheck();

      _isInitialized = true;
      debugPrint('[AppStrengthening] ระบบเริ่มต้นสำเร็จ');
    } catch (e) {
      debugPrint('[AppStrengthening] เกิดข้อผิดพลาดเริ่มต้น: $e');
    }
  }

  /// โหลดข้อมูลอุปกรณ์
  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      _deviceInfo = {
        'platform': 'web',
        'browser': webInfo.browserName.name,
        'version': webInfo.appVersion,
        'userAgent': webInfo.userAgent,
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceInfo = {
        'platform': 'android',
        'brand': androidInfo.brand,
        'model': androidInfo.model,
        'version': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _deviceInfo = {
        'platform': 'ios',
        'name': iosInfo.name,
        'model': iosInfo.model,
        'version': iosInfo.systemVersion,
        'identifierForVendor': iosInfo.identifierForVendor,
      };
    } else {
      _deviceInfo = {
        'platform': 'unknown',
      };
    }
  }

  /// ตรวจสอบสุขภาพระบบ
  Future<SystemHealthInfo> performHealthCheck() async {
    final errors = <String>[];
    final warnings = <String>[];
    final performanceMetrics = <String, dynamic>{};

    try {
      // ตรวจสอบการเชื่อมต่อเครือข่าย
      final connectivityResults = await Connectivity().checkConnectivity();
      final networkStatus = _getNetworkStatusString(
          connectivityResults.isNotEmpty
              ? connectivityResults.first
              : ConnectivityResult.none);

      // จำลองการใช้หน่วยความจำ (ในแอพจริงอาจใช้ plugin อื่น)
      final memoryUsage = _simulateMemoryUsage();
      final cpuUsage = _simulateCpuUsage();
      final activeConnections = _simulateActiveConnections();

      // ตรวจสอบการทำงานของระบบ
      performanceMetrics['appVersion'] = _packageInfo?.version ?? 'unknown';
      performanceMetrics['buildNumber'] =
          _packageInfo?.buildNumber ?? 'unknown';
      performanceMetrics['platform'] = _deviceInfo?['platform'] ?? 'unknown';

      // ตรวจสอบเงื่อนไขต่างๆ
      if (memoryUsage > 85) {
        errors.add(
            'การใช้หน่วยความจำสูงเกินไป: ${memoryUsage.toStringAsFixed(1)}%');
      } else if (memoryUsage > 70) {
        warnings.add(
            'การใช้หน่วยความจำค่อนข้างสูง: ${memoryUsage.toStringAsFixed(1)}%');
      }

      if (cpuUsage > 80) {
        errors.add('การใช้ CPU สูงเกินไป: ${cpuUsage.toStringAsFixed(1)}%');
      } else if (cpuUsage > 60) {
        warnings.add('การใช้ CPU ค่อนข้างสูง: ${cpuUsage.toStringAsFixed(1)}%');
      }

      if (networkStatus == 'none') {
        errors.add('ไม่มีการเชื่อมต่ออินเทอร์เน็ต');
      }

      // สร้างรายงานสุขภาพ
      final healthInfo = SystemHealthInfo(
        timestamp: DateTime.now(),
        memoryUsage: memoryUsage,
        cpuUsage: cpuUsage,
        networkStatus: networkStatus,
        activeConnections: activeConnections,
        performanceMetrics: performanceMetrics,
        errors: errors,
        warnings: warnings,
      );

      // เก็บประวัติ (เก็บแค่ 100 รายการล่าสุด)
      _healthHistory.add(healthInfo);
      if (_healthHistory.length > 100) {
        _healthHistory.removeAt(0);
      }

      debugPrint(
          '[AppStrengthening] ตรวจสอบสุขภาพระบบเสร็จสิ้น - คะแนน: ${healthInfo.healthScore}');

      return healthInfo;
    } catch (e) {
      debugPrint('[AppStrengthening] เกิดข้อผิดพลาดในการตรวจสอบสุขภาพ: $e');

      // สร้างรายงานฉุกเฉิน
      return SystemHealthInfo(
        timestamp: DateTime.now(),
        memoryUsage: 0,
        cpuUsage: 0,
        networkStatus: 'error',
        activeConnections: 0,
        performanceMetrics: {'error': e.toString()},
        errors: ['เกิดข้อผิดพลาดในการตรวจสอบระบบ: $e'],
        warnings: [],
      );
    }
  }

  /// แปลงสถานะเครือข่าย
  String _getNetworkStatusString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'wifi';
      case ConnectivityResult.mobile:
        return 'mobile';
      case ConnectivityResult.ethernet:
        return 'ethernet';
      case ConnectivityResult.none:
        return 'none';
      default:
        return 'unknown';
    }
  }

  /// จำลองการใช้หน่วยความจำ
  double _simulateMemoryUsage() {
    // ในการใช้งานจริง อาจใช้ plugin เช่น system_info
    return 45.0 + (DateTime.now().millisecond % 30); // 45-75%
  }

  /// จำลองการใช้ CPU
  double _simulateCpuUsage() {
    return 20.0 + (DateTime.now().millisecond % 40); // 20-60%
  }

  /// จำลองจำนวนการเชื่อมต่อที่ใช้งาน
  int _simulateActiveConnections() {
    return 2 + (DateTime.now().millisecond % 8); // 2-10 connections
  }

  /// ได้รายงานที่ครอบคลุม
  Map<String, dynamic> getComprehensiveReport() {
    if (_healthHistory.isEmpty) {
      return {
        'status': 'no_data',
        'message': 'ยังไม่มีข้อมูลการตรวจสอบ',
        'lastCheck': null,
        'averageScore': 0,
        'trends': {},
      };
    }

    final latest = _healthHistory.last;
    final last24Hours = _healthHistory
        .where((h) => DateTime.now().difference(h.timestamp).inHours <= 24)
        .toList();

    // คำนวณค่าเฉลี่ย
    final avgMemory = last24Hours.isEmpty
        ? 0.0
        : last24Hours.map((h) => h.memoryUsage).reduce((a, b) => a + b) /
            last24Hours.length;
    final avgCpu = last24Hours.isEmpty
        ? 0.0
        : last24Hours.map((h) => h.cpuUsage).reduce((a, b) => a + b) /
            last24Hours.length;
    final avgScore = last24Hours.isEmpty
        ? 0.0
        : last24Hours.map((h) => h.healthScore).reduce((a, b) => a + b) /
            last24Hours.length;

    return {
      'status': 'success',
      'lastCheck': latest.timestamp.toIso8601String(),
      'latestScore': latest.healthScore,
      'averageScore': avgScore,
      'healthLevel': latest.healthLevel,
      'trends': {
        'memoryUsage': {
          'current': latest.memoryUsage,
          'average24h': avgMemory,
          'trend': _calculateTrend('memory'),
        },
        'cpuUsage': {
          'current': latest.cpuUsage,
          'average24h': avgCpu,
          'trend': _calculateTrend('cpu'),
        },
        'networkStatus': latest.networkStatus,
        'activeConnections': latest.activeConnections,
      },
      'issues': {
        'errors': latest.errors.length,
        'warnings': latest.warnings.length,
        'errorList': latest.errors,
        'warningList': latest.warnings,
      },
      'systemInfo': {
        'appVersion': _packageInfo?.version ?? 'unknown',
        'buildNumber': _packageInfo?.buildNumber ?? 'unknown',
        'platform': _deviceInfo?['platform'] ?? 'unknown',
        'deviceModel': _deviceInfo?['model'] ?? 'unknown',
      },
      'dataPoints': _healthHistory.length,
      'monitoringDuration': _healthHistory.isEmpty
          ? 0
          : DateTime.now().difference(_healthHistory.first.timestamp).inHours,
    };
  }

  /// คำนวณแนวโน้ม
  String _calculateTrend(String metric) {
    if (_healthHistory.length < 5) return 'insufficient_data';

    final recent = _healthHistory.takeLast(5).toList();
    final values = recent.map((h) {
      switch (metric) {
        case 'memory':
          return h.memoryUsage;
        case 'cpu':
          return h.cpuUsage;
        default:
          return h.healthScore;
      }
    }).toList();

    // คำนวณแนวโน้มอย่างง่าย
    final first = values.first;
    final last = values.last;
    final difference = last - first;

    if (difference > 5) return 'increasing';
    if (difference < -5) return 'decreasing';
    return 'stable';
  }

  /// เริ่มการตติดตามอัตโนมัติ
  void startMonitoring({Duration interval = const Duration(minutes: 5)}) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    debugPrint('[AppStrengthening] เริ่มการติดตามอัตโนมัติ');

    // ใช้ Timer.periodic สำหรับการตรวจสอบเป็นระยะ
    // Timer.periodic(interval, (timer) async {
    //   if (!_isMonitoring) {
    //     timer.cancel();
    //     return;
    //   }
    //   await performHealthCheck();
    // });
  }

  /// หยุดการติดตาม
  void stopMonitoring() {
    _isMonitoring = false;
    debugPrint('[AppStrengthening] หยุดการติดตาม');
  }

  /// ล้างข้อมูลประวัติ
  void clearHistory() {
    _healthHistory.clear();
    debugPrint('[AppStrengthening] ล้างข้อมูลประวัติเรียบร้อย');
  }

  /// ส่งออกข้อมูลเป็น JSON
  String exportData() {
    final data = {
      'exportTime': DateTime.now().toIso8601String(),
      'appInfo': {
        'version': _packageInfo?.version,
        'buildNumber': _packageInfo?.buildNumber,
      },
      'deviceInfo': _deviceInfo,
      'healthHistory': _healthHistory.map((h) => h.toJson()).toList(),
      'comprehensiveReport': getComprehensiveReport(),
    };

    return jsonEncode(data);
  }

  /// นำเข้าข้อมูลจาก JSON
  void importData(String jsonData) {
    try {
      final data = jsonDecode(jsonData);

      if (data['healthHistory'] != null) {
        _healthHistory.clear();
        for (final item in data['healthHistory']) {
          _healthHistory.add(SystemHealthInfo.fromJson(item));
        }
      }

      debugPrint(
          '[AppStrengthening] นำเข้าข้อมูล ${_healthHistory.length} รายการ');
    } catch (e) {
      debugPrint('[AppStrengthening] เกิดข้อผิดพลาดในการนำเข้าข้อมูล: $e');
    }
  }
}

/// Extension สำหรับ List
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}
