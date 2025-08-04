// lib/utils/enhanced_error_handler.dart
// ระบบจัดการข้อผิดพลาดขั้นสูงสำหรับ Green Market App

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// ประเภทของข้อผิดพลาด
enum ErrorType {
  network,
  authentication,
  firestore,
  storage,
  validation,
  permission,
  unknown,
}

/// ระดับความรุนแรงของข้อผิดพลาด
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// โครงสร้างข้อมูลข้อผิดพลาด
class AppError {
  final String id;
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? technicalDetails;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  AppError({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    this.technicalDetails,
    this.stackTrace,
    DateTime? timestamp,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'technicalDetails': technicalDetails,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }
}

/// ระบบจัดการข้อผิดพลาดขั้นสูง
class EnhancedErrorHandler {
  static final EnhancedErrorHandler _instance =
      EnhancedErrorHandler._internal();
  factory EnhancedErrorHandler() => _instance;
  EnhancedErrorHandler._internal();

  final List<AppError> _errorHistory = [];
  final Map<String, int> _errorCounts = {};
  final List<Function(AppError)> _errorListeners = [];

  static const int MAX_ERROR_HISTORY = 100;
  static const int MAX_RETRY_COUNT = 3;

  /// เริ่มต้นระบบจัดการข้อผิดพลาด
  void initialize() {
    // ตั้งค่า Flutter Error Handler
    FlutterError.onError = (FlutterErrorDetails details) {
      handleFlutterError(details);
    };

    // ตั้งค่า Platform Error Handler
    PlatformDispatcher.instance.onError = (error, stack) {
      handlePlatformError(error, stack);
      return true;
    };

    _logInfo('Enhanced Error Handler initialized');
  }

  /// จัดการข้อผิดพลาดจาก Flutter Framework
  void handleFlutterError(FlutterErrorDetails details) {
    final error = AppError(
      id: _generateErrorId(),
      type: _classifyFlutterError(details),
      severity: _assessFlutterErrorSeverity(details),
      message: details.exception.toString(),
      technicalDetails: details.toString(),
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );

    _recordError(error);
  }

  /// จัดการข้อผิดพลาดจาก Platform
  void handlePlatformError(Object error, StackTrace stack) {
    final appError = AppError(
      id: _generateErrorId(),
      type: _classifyPlatformError(error),
      severity: _assessPlatformErrorSeverity(error),
      message: error.toString(),
      stackTrace: stack,
      context: {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      },
    );

    _recordError(appError);
  }

  /// จัดการข้อผิดพลาดจาก Firebase
  AppError handleFirebaseError(dynamic error, {Map<String, dynamic>? context}) {
    ErrorType type = ErrorType.unknown;
    ErrorSeverity severity = ErrorSeverity.medium;
    String userMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';

    if (error is FirebaseAuthException) {
      type = ErrorType.authentication;
      userMessage = _getAuthErrorMessage(error.code);
      severity = _getAuthErrorSeverity(error.code);
    } else if (error is FirebaseException) {
      if (error.plugin == 'firebase_storage') {
        type = ErrorType.storage;
        userMessage = _getStorageErrorMessage(error.code);
        severity = _getStorageErrorSeverity(error.code);
      } else {
        type = ErrorType.firestore;
        userMessage = _getFirestoreErrorMessage(error.code);
        severity = _getFirestoreErrorSeverity(error.code);
      }
    }

    final appError = AppError(
      id: _generateErrorId(),
      type: type,
      severity: severity,
      message: userMessage,
      technicalDetails: error.toString(),
      context: context,
    );

    _recordError(appError);
    return appError;
  }

  /// จัดการข้อผิดพลาดจาก Network
  AppError handleNetworkError(dynamic error, {Map<String, dynamic>? context}) {
    String userMessage =
        'ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    ErrorSeverity severity = ErrorSeverity.high;

    if (error is SocketException) {
      userMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง';
    } else if (error is TimeoutException) {
      userMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
    } else if (error is HttpException) {
      userMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองใหม่อีกครั้ง';
    }

    final appError = AppError(
      id: _generateErrorId(),
      type: ErrorType.network,
      severity: severity,
      message: userMessage,
      technicalDetails: error.toString(),
      context: context,
    );

    _recordError(appError);
    return appError;
  }

  /// จัดการข้อผิดพลาดจาก Validation
  AppError handleValidationError(String field, String message,
      {Map<String, dynamic>? context}) {
    final appError = AppError(
      id: _generateErrorId(),
      type: ErrorType.validation,
      severity: ErrorSeverity.low,
      message: message,
      context: {
        'field': field,
        ...?context,
      },
    );

    _recordError(appError);
    return appError;
  }

  /// บันทึกข้อผิดพลาด
  void _recordError(AppError error) {
    // เพิ่มลงประวัติ
    _errorHistory.add(error);
    if (_errorHistory.length > MAX_ERROR_HISTORY) {
      _errorHistory.removeAt(0);
    }

    // นับจำนวนข้อผิดพลาด
    final key = '${error.type.name}_${error.message}';
    _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;

    // แจ้งผู้ฟัง
    for (final listener in _errorListeners) {
      try {
        listener(error);
      } catch (e) {
        _logError('Error in error listener: $e');
      }
    }

    // Log ข้อผิดพลาด
    _logError('${error.type.name.toUpperCase()}: ${error.message}');
    if (error.severity == ErrorSeverity.critical) {
      _logError('CRITICAL ERROR: ${error.technicalDetails}');
    }
  }

  /// ลองซ้ำการทำงานเมื่อเกิดข้อผิดพลาด
  Future<T?> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = MAX_RETRY_COUNT,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        if (attempt == maxRetries) {
          handleNetworkError(error, context: {'attempts': attempt + 1});
          rethrow;
        }

        if (shouldRetry != null && !shouldRetry(error)) {
          handleNetworkError(error, context: {'stopped_retry': true});
          rethrow;
        }

        _logInfo('Retrying operation, attempt ${attempt + 1}/$maxRetries');
        await Future.delayed(delay * (attempt + 1));
      }
    }
    return null;
  }

  /// แสดงข้อผิดพลาดให้ผู้ใช้
  void showErrorToUser(BuildContext context, AppError error) {
    if (error.severity == ErrorSeverity.low) {
      _showSnackBar(context, error.message, Colors.orange);
    } else if (error.severity == ErrorSeverity.medium) {
      _showSnackBar(context, error.message, Colors.red);
    } else {
      _showDialog(context, error);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'ตกลง',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เกิดข้อผิดพลาด'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            if (kDebugMode && error.technicalDetails != null) ...[
              const SizedBox(height: 16),
              const Text('รายละเอียดทางเทคนิค:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                error.technicalDetails!,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
          if (error.severity == ErrorSeverity.critical)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reportCriticalError(error);
              },
              child: const Text('รายงานปัญหา'),
            ),
        ],
      ),
    );
  }

  /// รายงานข้อผิดพลาดร้ายแรง
  void _reportCriticalError(AppError error) {
    // ส่งรายงานไปยังระบบ monitoring (เช่น Firebase Crashlytics)
    _logError('Reporting critical error: ${error.id}');
  }

  /// เพิ่มผู้ฟังข้อผิดพลาด
  void addErrorListener(Function(AppError) listener) {
    _errorListeners.add(listener);
  }

  /// ลบผู้ฟังข้อผิดพลาด
  void removeErrorListener(Function(AppError) listener) {
    _errorListeners.remove(listener);
  }

  /// ได้รับประวัติข้อผิดพลาด
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  /// ได้รับสถิติข้อผิดพลาด
  Map<String, int> get errorCounts => Map.unmodifiable(_errorCounts);

  /// ล้างประวัติข้อผิดพลาด
  void clearErrorHistory() {
    _errorHistory.clear();
    _errorCounts.clear();
    _logInfo('Error history cleared');
  }

  // Helper Methods

  String _generateErrorId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_errorHistory.length}';
  }

  ErrorType _classifyFlutterError(FlutterErrorDetails details) {
    final message = details.exception.toString().toLowerCase();
    if (message.contains('network') || message.contains('socket')) {
      return ErrorType.network;
    }
    if (message.contains('permission')) {
      return ErrorType.permission;
    }
    return ErrorType.unknown;
  }

  ErrorSeverity _assessFlutterErrorSeverity(FlutterErrorDetails details) {
    if (details.library?.contains('rendering') == true) {
      return ErrorSeverity.medium;
    }
    return ErrorSeverity.low;
  }

  ErrorType _classifyPlatformError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socket') || message.contains('network')) {
      return ErrorType.network;
    }
    if (message.contains('permission')) {
      return ErrorType.permission;
    }
    return ErrorType.unknown;
  }

  ErrorSeverity _assessPlatformErrorSeverity(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('fatal') || message.contains('critical')) {
      return ErrorSeverity.critical;
    }
    return ErrorSeverity.medium;
  }

  // Firebase Auth Error Messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'ไม่พบผู้ใช้นี้ในระบบ';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'weak-password':
        return 'รหัสผ่านไม่ปลอดภัย กรุณาใช้รหัสผ่านที่แข็งแกร่งกว่า';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'too-many-requests':
        return 'มีการเข้าถึงมากเกินไป กรุณาลองใหม่ในภายหลัง';
      case 'network-request-failed':
        return 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
      default:
        return 'เกิดข้อผิดพลาดในการยืนยันตัวตน';
    }
  }

  ErrorSeverity _getAuthErrorSeverity(String code) {
    switch (code) {
      case 'too-many-requests':
      case 'network-request-failed':
        return ErrorSeverity.high;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
        return ErrorSeverity.medium;
      default:
        return ErrorSeverity.low;
    }
  }

  // Firestore Error Messages
  String _getFirestoreErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์เข้าถึงข้อมูลนี้';
      case 'unavailable':
        return 'เซิร์ฟเวอร์ไม่พร้อมใช้งาน กรุณาลองใหม่อีกครั้ง';
      case 'deadline-exceeded':
        return 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      case 'resource-exhausted':
        return 'เซิร์ฟเวอร์ทำงานหนัก กรุณาลองใหม่ในภายหลัง';
      default:
        return 'เกิดข้อผิดพลาดในการเข้าถึงข้อมูล';
    }
  }

  ErrorSeverity _getFirestoreErrorSeverity(String code) {
    switch (code) {
      case 'permission-denied':
        return ErrorSeverity.high;
      case 'unavailable':
      case 'deadline-exceeded':
        return ErrorSeverity.medium;
      default:
        return ErrorSeverity.low;
    }
  }

  // Storage Error Messages
  String _getStorageErrorMessage(String code) {
    switch (code) {
      case 'storage/object-not-found':
        return 'ไม่พบไฟล์ที่ต้องการ';
      case 'storage/unauthorized':
        return 'ไม่มีสิทธิ์เข้าถึงไฟล์นี้';
      case 'storage/quota-exceeded':
        return 'พื้นที่จัดเก็บเต็ม';
      case 'storage/invalid-format':
        return 'รูปแบบไฟล์ไม่ถูกต้อง';
      default:
        return 'เกิดข้อผิดพลาดในการจัดการไฟล์';
    }
  }

  ErrorSeverity _getStorageErrorSeverity(String code) {
    switch (code) {
      case 'storage/quota-exceeded':
        return ErrorSeverity.high;
      case 'storage/unauthorized':
        return ErrorSeverity.medium;
      default:
        return ErrorSeverity.low;
    }
  }

  void _logInfo(String message) {
    if (kDebugMode) {
      print('🟢 [ErrorHandler] $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      print('🔴 [ErrorHandler] $message');
    }
  }
}
