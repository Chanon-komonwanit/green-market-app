import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/utils/enhanced_error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';

void main() {
  group('EnhancedErrorHandler', () {
    final errorHandler = EnhancedErrorHandler();

    test('handleFirebaseError with auth error', () {
      final error = FirebaseAuthException(
          code: 'user-not-found', message: 'User not found');
      final appError = errorHandler.handleFirebaseError(error);
      expect(appError.type, ErrorType.authentication);
    });

    test('handleFirebaseError with firestore error', () {
      final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Permission denied');
      final appError = errorHandler.handleFirebaseError(error);
      expect(appError.type, ErrorType.firestore);
    });

    test('handleFirebaseError with storage error', () {
      final error = FirebaseException(
          plugin: 'firebase_storage',
          code: 'object-not-found',
          message: 'Object not found');
      final appError = errorHandler.handleFirebaseError(error);
      expect(appError.type, ErrorType.storage);
      expect(appError.message, contains('ไฟล์'));
    });

    test('handleNetworkError returns correct AppError', () {
      final socketError = SocketException('Connection failed');
      final appError = errorHandler.handleNetworkError(socketError);
      expect(appError.type, ErrorType.network);
      expect(appError.message, contains('เชื่อมต่อ'));
    });

    test('addErrorListener works correctly', () {
      bool listenerCalled = false;
      errorHandler.addErrorListener((error) {
        listenerCalled = true;
      });

      // สร้าง error ผ่าน handleFirebaseError เพื่อทริกเกอร์ listener
      final testError = FirebaseAuthException(
        code: 'test-error',
        message: 'Test message',
      );

      errorHandler.handleFirebaseError(testError);
      expect(listenerCalled, isTrue);
    });
  });
}
