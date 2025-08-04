// lib/utils/security_hardening.dart
// ระบบรักษาความปลอดภัยขั้นสูงสำหรับ Green Market App

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ระดับความปลอดภัย
enum SecurityLevel {
  low,
  medium,
  high,
  critical,
}

/// ประเภทการโจมตี
enum ThreatType {
  bruteForce,
  sqlInjection,
  xss,
  csrf,
  ddos,
  unauthorizedAccess,
  dataExfiltration,
  maliciousInput,
}

/// ข้อมูลการคุกคาม
class SecurityThreat {
  final String id;
  final ThreatType type;
  final SecurityLevel severity;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final String? userAgent;
  final String? ipAddress;

  SecurityThreat({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.timestamp,
    this.context,
    this.userAgent,
    this.ipAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'user_agent': userAgent,
      'ip_address': ipAddress,
    };
  }
}

/// ระบบรักษาความปลอดภัยขั้นสูง
class SecurityHardening {
  static final SecurityHardening _instance = SecurityHardening._internal();
  factory SecurityHardening() => _instance;
  SecurityHardening._internal();

  // Security State
  final List<SecurityThreat> _threatHistory = [];
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _blockedIps = {};
  final Map<String, DateTime> _rateLimits = {};
  final Set<String> _suspiciousActivities = {};

  // Configuration
  static const int MAX_FAILED_ATTEMPTS = 5;
  static const Duration LOCKOUT_DURATION = Duration(minutes: 15);
  static const Duration RATE_LIMIT_WINDOW = Duration(minutes: 1);
  static const int MAX_REQUESTS_PER_MINUTE = 60;
  static const int MAX_THREAT_HISTORY = 1000;

  // Security Features
  bool _isSecurityModeEnabled = false;
  String? _deviceFingerprint;
  Timer? _securityTimer;

  /// เริ่มต้นระบบรักษาความปลอดภัย
  Future<void> initialize() async {
    await _generateDeviceFingerprint();
    _startSecurityMonitoring();
    _logInfo('Security Hardening initialized');
  }

  /// สร้าง Device Fingerprint
  Future<void> _generateDeviceFingerprint() async {
    try {
      final deviceData = {
        'platform': defaultTargetPlatform.name,
        'locale': PlatformDispatcher.instance.locale.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final jsonString = jsonEncode(deviceData);
      final bytes = utf8.encode(jsonString);
      final digest = sha256.convert(bytes);
      _deviceFingerprint = digest.toString();

      _logInfo('Device fingerprint generated');
    } catch (e) {
      _logError('Failed to generate device fingerprint: $e');
    }
  }

  /// เริ่มการติดตามความปลอดภัย
  void _startSecurityMonitoring() {
    _securityTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _performSecurityCheck(),
    );
  }

  /// ตรวจสอบความปลอดภัยตามช่วงเวลา
  void _performSecurityCheck() {
    _cleanupExpiredBlocks();
    _cleanupRateLimits();
    _analyzeSecurityPatterns();
    _checkForAnomalies();
  }

  /// ตรวจสอบ Rate Limiting
  bool checkRateLimit(String identifier) {
    final now = DateTime.now();
    final key = 'rate_$identifier';

    final lastRequest = _rateLimits[key];
    if (lastRequest != null) {
      final timeDiff = now.difference(lastRequest);
      if (timeDiff < RATE_LIMIT_WINDOW) {
        _recordThreat(
          ThreatType.ddos,
          SecurityLevel.medium,
          'Rate limit exceeded for $identifier',
          context: {'identifier': identifier, 'time_diff': timeDiff.inSeconds},
        );
        return false;
      }
    }

    _rateLimits[key] = now;
    return true;
  }

  /// ตรวจสอบการเข้าสู่ระบบ
  bool validateLoginAttempt(String identifier) {
    if (_isBlocked(identifier)) {
      _recordThreat(
        ThreatType.bruteForce,
        SecurityLevel.high,
        'Login attempt from blocked identifier: $identifier',
        context: {'identifier': identifier},
      );
      return false;
    }

    return checkRateLimit('login_$identifier');
  }

  /// บันทึกการเข้าสู่ระบบที่ล้มเหลว
  void recordFailedLoginAttempt(String identifier) {
    _failedAttempts[identifier] = (_failedAttempts[identifier] ?? 0) + 1;

    final attempts = _failedAttempts[identifier]!;
    if (attempts >= MAX_FAILED_ATTEMPTS) {
      _blockIdentifier(identifier);
      _recordThreat(
        ThreatType.bruteForce,
        SecurityLevel.high,
        'Multiple failed login attempts: $attempts',
        context: {'identifier': identifier, 'attempts': attempts},
      );
    } else if (attempts >= MAX_FAILED_ATTEMPTS ~/ 2) {
      _recordThreat(
        ThreatType.bruteForce,
        SecurityLevel.medium,
        'Suspicious login attempts: $attempts',
        context: {'identifier': identifier, 'attempts': attempts},
      );
    }
  }

  /// ล้างการนับความล้มเหลวเมื่อล็อกอินสำเร็จ
  void clearFailedAttempts(String identifier) {
    _failedAttempts.remove(identifier);
  }

  /// ตรวจสอบการป้อนข้อมูล
  bool validateInput(String input, {String? fieldName}) {
    // ตรวจสอบ XSS
    if (_containsXSSPatterns(input)) {
      _recordThreat(
        ThreatType.xss,
        SecurityLevel.high,
        'XSS attempt detected in input',
        context: {'field': fieldName, 'input_length': input.length},
      );
      return false;
    }

    // ตรวจสอบ SQL Injection
    if (_containsSQLInjectionPatterns(input)) {
      _recordThreat(
        ThreatType.sqlInjection,
        SecurityLevel.high,
        'SQL injection attempt detected',
        context: {'field': fieldName, 'input_length': input.length},
      );
      return false;
    }

    // ตรวจสอบข้อมูลที่เป็นอันตราย
    if (_containsMaliciousPatterns(input)) {
      _recordThreat(
        ThreatType.maliciousInput,
        SecurityLevel.medium,
        'Malicious input pattern detected',
        context: {'field': fieldName, 'input_length': input.length},
      );
      return false;
    }

    return true;
  }

  /// ตรวจสอบ patterns ของ XSS
  bool _containsXSSPatterns(String input) {
    final xssPatterns = [
      r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
      r'javascript:',
      r'on\w+\s*=',
      r'<iframe\b',
      r'<object\b',
      r'<embed\b',
      r'<link\b',
      r'<meta\b',
    ];

    final lowerInput = input.toLowerCase();
    return xssPatterns.any((pattern) =>
        RegExp(pattern, caseSensitive: false).hasMatch(lowerInput));
  }

  /// ตรวจสอบ patterns ของ SQL Injection
  bool _containsSQLInjectionPatterns(String input) {
    final sqlPatterns = [
      r"('\s*(or|and)\s*'.*?')|('\s*(or|and)\s*\d+\s*=\s*\d+)",
      r'union\s+select',
      r'drop\s+table',
      r'delete\s+from',
      r'insert\s+into',
      r'update\s+\w+\s+set',
      r'exec\s*\(',
      r'execute\s*\(',
      r'--\s*$',
      r'/\*.*?\*/',
    ];

    final lowerInput = input.toLowerCase();
    return sqlPatterns.any((pattern) =>
        RegExp(pattern, caseSensitive: false).hasMatch(lowerInput));
  }

  /// ตรวจสอบ patterns ที่เป็นอันตราย
  bool _containsMaliciousPatterns(String input) {
    final maliciousPatterns = [
      r'\.\./',
      r'%2e%2e%2f',
      r'\\.\\.\\',
      r'cmd\.exe',
      r'/etc/passwd',
      r'\/bin\/sh',
      r'powershell',
    ];

    final lowerInput = input.toLowerCase();
    return maliciousPatterns.any((pattern) =>
        RegExp(pattern, caseSensitive: false).hasMatch(lowerInput));
  }

  /// ตรวจสอบสิทธิ์การเข้าถึง
  bool validateAccess(String userId, String resource, String action) {
    // ตรวจสอบว่าผู้ใช้มีสิทธิ์หรือไม่
    if (_isUserSuspicious(userId)) {
      _recordThreat(
        ThreatType.unauthorizedAccess,
        SecurityLevel.high,
        'Access attempt by suspicious user',
        context: {
          'user_id': userId,
          'resource': resource,
          'action': action,
        },
      );
      return false;
    }

    return true;
  }

  /// ตรวจสอบข้อมูลที่ละเอียดอ่อน
  bool validateSensitiveDataAccess(String userId, String dataType) {
    if (!checkRateLimit('sensitive_$userId')) {
      _recordThreat(
        ThreatType.dataExfiltration,
        SecurityLevel.critical,
        'Rapid sensitive data access attempt',
        context: {
          'user_id': userId,
          'data_type': dataType,
        },
      );
      return false;
    }

    return true;
  }

  /// เข้ารหัสข้อมูลละเอียดอ่อน
  String encryptSensitiveData(String data) {
    // ใช้การเข้ารหัสแบบง่าย (ในการใช้งานจริงควรใช้ AES หรือวิธีที่แข็งแกร่งกว่า)
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// ถอดรหัสข้อมูลละเอียดอ่อน
  bool verifyEncryptedData(String originalData, String encryptedData) {
    final encrypted = encryptSensitiveData(originalData);
    return encrypted == encryptedData;
  }

  /// สร้าง Token แบบปลอดภัย
  String generateSecureToken([int length = 32]) {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// บล็อค identifier
  void _blockIdentifier(String identifier) {
    _blockedIps[identifier] = DateTime.now().add(LOCKOUT_DURATION);
    _logWarning('Blocked identifier: $identifier');
  }

  /// ตรวจสอบว่าถูกบล็อคหรือไม่
  bool _isBlocked(String identifier) {
    final blockedUntil = _blockedIps[identifier];
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) {
      return true;
    }
    return false;
  }

  /// ตรวจสอบว่าผู้ใช้น่าสงสัยหรือไม่
  bool _isUserSuspicious(String userId) {
    return _suspiciousActivities.contains(userId);
  }

  /// ทำเครื่องหมายผู้ใช้ว่าน่าสงสัย
  void markUserSuspicious(String userId, String reason) {
    _suspiciousActivities.add(userId);
    _recordThreat(
      ThreatType.unauthorizedAccess,
      SecurityLevel.medium,
      'User marked as suspicious: $reason',
      context: {'user_id': userId, 'reason': reason},
    );
  }

  /// ล้างผู้ใช้ที่น่าสงสัย
  void clearSuspiciousUser(String userId) {
    _suspiciousActivities.remove(userId);
    _logInfo('Cleared suspicious status for user: $userId');
  }

  /// บันทึกการคุกคาม
  void _recordThreat(
    ThreatType type,
    SecurityLevel severity,
    String description, {
    Map<String, dynamic>? context,
  }) {
    final threat = SecurityThreat(
      id: _generateThreatId(),
      type: type,
      severity: severity,
      description: description,
      timestamp: DateTime.now(),
      context: context,
    );

    _threatHistory.add(threat);

    // จำกัดขนาดประวัติ
    while (_threatHistory.length > MAX_THREAT_HISTORY) {
      _threatHistory.removeAt(0);
    }

    // แจ้งเตือนภัยคุกคามร้ายแรง
    if (severity == SecurityLevel.critical || severity == SecurityLevel.high) {
      _handleCriticalThreat(threat);
    }

    _logWarning('Security threat detected: ${threat.description}');
  }

  /// จัดการภัยคุกคามร้ายแรง
  void _handleCriticalThreat(SecurityThreat threat) {
    _isSecurityModeEnabled = true;

    // ส่งการแจ้งเตือนไปยังระบบ monitoring
    _logError('CRITICAL SECURITY THREAT: ${threat.description}');

    // อาจส่งการแจ้งเตือนไปยัง admin หรือระบบภายนอก
  }

  /// ล้างข้อมูลที่หมดอายุ
  void _cleanupExpiredBlocks() {
    final now = DateTime.now();
    _blockedIps.removeWhere((key, blockedUntil) => now.isAfter(blockedUntil));
  }

  void _cleanupRateLimits() {
    final now = DateTime.now();
    _rateLimits.removeWhere((key, lastRequest) {
      return now.difference(lastRequest) > RATE_LIMIT_WINDOW;
    });
  }

  /// วิเคราะห์รูปแบบความปลอดภัย
  void _analyzeSecurityPatterns() {
    // วิเคราะห์รูปแบบการโจมตีที่เกิดขึ้นบ่อย
    final recentThreats = _threatHistory
        .where(
            (threat) => DateTime.now().difference(threat.timestamp).inHours < 1)
        .toList();

    if (recentThreats.length > 10) {
      _recordThreat(
        ThreatType.ddos,
        SecurityLevel.high,
        'High number of security threats in the last hour: ${recentThreats.length}',
      );
    }
  }

  /// ตรวจสอบความผิดปกติ
  void _checkForAnomalies() {
    // ตรวจสอบความผิดปกติในการใช้งาน
    if (_failedAttempts.length > 50) {
      _recordThreat(
        ThreatType.bruteForce,
        SecurityLevel.medium,
        'High number of failed attempts across different identifiers',
      );
    }
  }

  /// สร้าง ID ของภัยคุกคาม
  String _generateThreatId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// ได้รับรายงานความปลอดภัย
  Map<String, dynamic> getSecurityReport() {
    final now = DateTime.now();
    final recentThreats = _threatHistory
        .where((threat) => now.difference(threat.timestamp).inHours < 24)
        .toList();

    final threatsByType = <String, int>{};
    for (final threat in recentThreats) {
      threatsByType[threat.type.name] =
          (threatsByType[threat.type.name] ?? 0) + 1;
    }

    return {
      'security_mode_enabled': _isSecurityModeEnabled,
      'device_fingerprint': _deviceFingerprint,
      'total_threats': _threatHistory.length,
      'recent_threats_24h': recentThreats.length,
      'threats_by_type': threatsByType,
      'blocked_identifiers': _blockedIps.length,
      'suspicious_users': _suspiciousActivities.length,
      'failed_attempts': _failedAttempts.length,
      'rate_limits_active': _rateLimits.length,
    };
  }

  /// ได้รับประวัติภัยคุกคาม
  List<SecurityThreat> getThreatHistory({int? limit}) {
    final threats = List<SecurityThreat>.from(_threatHistory);
    threats.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && threats.length > limit) {
      return threats.take(limit).toList();
    }

    return threats;
  }

  /// ล้างข้อมูลความปลอดภัย
  void clearSecurityData() {
    _threatHistory.clear();
    _failedAttempts.clear();
    _blockedIps.clear();
    _rateLimits.clear();
    _suspiciousActivities.clear();
    _isSecurityModeEnabled = false;

    _logInfo('Security data cleared');
  }

  /// ปิดระบบรักษาความปลอดภัย
  void dispose() {
    _securityTimer?.cancel();
    clearSecurityData();
    _logInfo('Security Hardening disposed');
  }

  // Logging methods
  void _logInfo(String message) {
    if (kDebugMode) {
      print('🟢 [SecurityHardening] $message');
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
      print('🟡 [SecurityHardening] WARNING: $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      print('🔴 [SecurityHardening] ERROR: $message');
    }
  }

  // Getters
  bool get isSecurityModeEnabled => _isSecurityModeEnabled;
  String? get deviceFingerprint => _deviceFingerprint;
  int get activeThreatCount => _threatHistory
      .where((t) => DateTime.now().difference(t.timestamp).inHours < 1)
      .length;
}
