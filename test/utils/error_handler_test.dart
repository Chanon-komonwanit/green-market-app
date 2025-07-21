import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() {
  group('ErrorHandler', () {
    test('handleFirebaseAuthError returns correct message', () {
      final error = FirebaseAuthException(
          code: 'user-not-found', message: 'User not found');
      expect(ErrorHandler.handleFirebaseAuthError(error),
          contains('ไม่พบผู้ใช้นี้'));
    });

    test('handleFirestoreError returns correct message', () {
      final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Permission denied');
      expect(ErrorHandler.handleFirestoreError(error), contains('ไม่มีสิทธิ์'));
    });

    test('handleStorageError returns correct message', () {
      final error = FirebaseException(
          plugin: 'firebase_storage',
          code: 'object-not-found',
          message: 'Object not found');
      expect(ErrorHandler.handleStorageError(error), contains('ไม่พบไฟล์'));
    });

    test('handleNetworkError returns correct message', () {
      expect(ErrorHandler.handleNetworkError('SocketException'),
          contains('เชื่อมต่อ'));
      expect(ErrorHandler.handleNetworkError('timeout'), contains('หมดเวลา'));
      expect(ErrorHandler.handleNetworkError('ssl'), contains('ความปลอดภัย'));
      expect(ErrorHandler.handleNetworkError('format'), contains('รูปแบบ'));
    });

    test('logError prints error', () {
      // Just ensure no exception thrown
      ErrorHandler.logError('testOp', 'error', stackTrace: StackTrace.current);
    });
  });
}
