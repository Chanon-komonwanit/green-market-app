// lib/utils/error_handler.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  // Show error dialog
  static void showErrorDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'ปิด',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Handle Firebase Auth errors
  static String handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'ไม่พบผู้ใช้นี้ในระบบ';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'weak-password':
        return 'รหัสผ่านไม่แข็งแรงพอ';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีผู้ใช้นี้ถูกปิดใช้งาน';
      case 'too-many-requests':
        return 'มีการร้องขอเข้าสู่ระบบมากเกินไป กรุณารอสักครู่';
      case 'operation-not-allowed':
        return 'การดำเนินการนี้ไม่ได้รับอนุญาต';
      case 'network-request-failed':
        return 'เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย';
      case 'requires-recent-login':
        return 'กรุณาเข้าสู่ระบบใหม่เพื่อดำเนินการต่อ';
      default:
        return 'เกิดข้อผิดพลาด: ${e.message ?? 'ไม่ทราบสาเหตุ'}';
    }
  }

  // Handle Firestore errors
  static String handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'คุณไม่มีสิทธิ์ในการเข้าถึงข้อมูลนี้';
      case 'not-found':
        return 'ไม่พบข้อมูลที่ร้องขอ';
      case 'already-exists':
        return 'ข้อมูลนี้มีอยู่แล้วในระบบ';
      case 'resource-exhausted':
        return 'ระบบไม่สามารถประมวลผลได้ในขณะนี้ กรุณาลองใหม่ภายหลัง';
      case 'failed-precondition':
        return 'เงื่อนไขไม่เป็นไปตามที่กำหนด';
      case 'aborted':
        return 'การดำเนินการถูกยกเลิก';
      case 'out-of-range':
        return 'ข้อมูลเกินขอบเขตที่กำหนด';
      case 'unimplemented':
        return 'ฟีเจอร์นี้ยังไม่ได้รับการพัฒนา';
      case 'internal':
        return 'เกิดข้อผิดพลาดภายในระบบ';
      case 'unavailable':
        return 'บริการไม่สามารถใช้งานได้ในขณะนี้';
      case 'data-loss':
        return 'เกิดการสูญหายของข้อมูล';
      case 'unauthenticated':
        return 'กรุณาเข้าสู่ระบบเพื่อใช้งาน';
      case 'deadline-exceeded':
        return 'การร้องขอใช้เวลานานเกินไป';
      default:
        return 'เกิดข้อผิดพลาดกับฐานข้อมูล: ${e.message ?? 'ไม่ทราบสาเหตุ'}';
    }
  }

  // Handle Firebase Storage errors
  static String handleStorageError(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return 'ไม่พบไฟล์ที่ต้องการ';
      case 'bucket-not-found':
        return 'ไม่พบที่เก็บไฟล์';
      case 'project-not-found':
        return 'ไม่พบโปรเจกต์';
      case 'quota-exceeded':
        return 'เกินขีดจำกัดการใช้งาน';
      case 'unauthenticated':
        return 'กรุณาเข้าสู่ระบบเพื่ออัปโหลดไฟล์';
      case 'unauthorized':
        return 'คุณไม่มีสิทธิ์ในการอัปโหลดไฟล์นี้';
      case 'retry-limit-exceeded':
        return 'พยายามอัปโหลดมากเกินไป กรุณาลองใหม่ภายหลัง';
      case 'invalid-checksum':
        return 'ไฟล์เสียหาย กรุณาลองใหม่';
      case 'canceled':
        return 'การอัปโหลดถูกยกเลิก';
      case 'invalid-event-name':
        return 'เกิดข้อผิดพลาดในการอัปโหลด';
      default:
        return 'เกิดข้อผิดพลาดในการอัปโหลดไฟล์: ${e.message ?? 'ไม่ทราบสาเหตุ'}';
    }
  }

  // Handle network errors
  static String handleNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') || errorString.contains('connection')) {
      return 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    }

    if (errorString.contains('timeout')) {
      return 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่';
    }

    if (errorString.contains('certificate') || errorString.contains('ssl')) {
      return 'เกิดปัญหาด้านความปลอดภัยในการเชื่อมต่อ';
    }

    if (errorString.contains('format')) {
      return 'รูปแบบข้อมูลไม่ถูกต้อง';
    }

    return 'เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองใหม่';
  }

  // Generic error handler
  static void handleError(BuildContext context, dynamic error,
      {String? customMessage}) {
    String message = customMessage ?? 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ';

    if (error is FirebaseAuthException) {
      message = handleFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      if (error.plugin == 'cloud_firestore') {
        message = handleFirestoreError(error);
      } else if (error.plugin == 'firebase_storage') {
        message = handleStorageError(error);
      }
    } else if (error is Exception) {
      message = handleNetworkError(error);
    }

    showErrorSnackBar(context, message);
  }

  // Log error for debugging
  static void logError(String operation, dynamic error,
      {StackTrace? stackTrace}) {
    print('🔴 Error in $operation: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

  // Validate form and show errors
  static bool validateAndShowErrors(
    BuildContext context,
    Map<String, String?> validationErrors,
  ) {
    final errors =
        validationErrors.values.where((error) => error != null).toList();

    if (errors.isNotEmpty) {
      showErrorDialog(
        context,
        'ข้อมูลไม่ถูกต้อง',
        errors.join('\n'),
      );
      return false;
    }

    return true;
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String content, {
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context,
      {String message = 'กำลังโหลด...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
