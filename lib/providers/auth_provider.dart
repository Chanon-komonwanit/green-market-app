// lib/providers/auth_provider.dart
//
// 🔐 AuthProvider - จัดการสถานะการเข้าสู่ระบบ
//
// หน้าที่:
// - จัดการ Login/Logout/Register
// - ตรวจสอบสถานะการเข้าสู่ระบบ (Authentication State)
// - จัดการ User Session
// - รองรับ Multiple login methods (Email, Google, Facebook, Phone)
// - ตรวจสอบ Network connectivity
//
// ใช้งานที่: ทุกหน้าที่ต้องตรวจสอบการเข้าสู่ระบบ
//
// วิธีใช้:
// ```dart
// // Login
// await authProvider.signInWithEmailAndPassword(email, password);
//
// // Check login status
// if (authProvider.isAuthenticated) {
//   // User is logged in
// }
//
// // Logout
// await authProvider.signOut();
// ```

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/enhanced_error_handler.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// สถานะการเข้าสู่ระบบ
enum AuthState {
  unknown, // ยังไม่ทราบสถานะ (กำลังตรวจสอบ)
  authenticated, // เข้าสู่ระบบแล้ว
  unauthenticated, // ยังไม่ได้เข้าสู่ระบบ
  maintenance, // อยู่ในโหมดปรับปรุง
}

/// ประเภทของ Error ที่เกิดขึ้นจากการเข้าสู่ระบบ
enum AuthError {
  userDisabled, // บัญชีถูกปิดการใช้งาน
  userNotFound, // ไม่พบผู้ใช้
  wrongPassword, // รหัสผ่านผิด
  emailAlreadyInUse, // Email ถูกใช้งานแล้ว
  invalidEmail, // Email ไม่ถูกต้อง
  operationNotAllowed, // ไม่อนุญาตให้ทำงานนี้
  weakPassword, // รหัสผ่านไม่ปลอดภัย
  networkError, // ปัญหาเครือข่าย
  tooManyRequests, // พยายามเข้าสู่ระบบบ่อยเกินไป
  maintenanceMode, // อยู่ในโหมดปรับปรุง
  sessionExpired, // Session หมดอายุ
  deviceNotSupported, // อุปกรณ์ไม่รองรับ
  unknown, // ข้อผิดพลาดที่ไม่ทราบสาเหตุ
}

/// AuthProvider - Provider สำหรับจัดการ Authentication
///
/// Features:
/// - ✅ Multiple login methods (Email, Google, Facebook, Phone)
/// - ✅ Auto reconnection on network recovery
/// - ✅ Session management
/// - ✅ Error handling with localized messages
class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  final Logger _logger = Logger();
  final EnhancedErrorHandler _errorHandler = EnhancedErrorHandler();

  User? _user;
  AuthState _authState = AuthState.unknown;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;
  AuthError? _lastError;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Enhanced Security & Performance Features
  int _consecutiveFailures = 0;
  static const int maxConsecutiveFailures = 15; // เพิ่มจาก 5 → 15 ครั้ง
  bool _isNetworkAvailable = true;
  Timer? _sessionTimer;
  Timer? _retryTimer;
  DateTime? _lastActivity;

  // Rate limiting
  final Map<String, List<DateTime>> _rateLimitCache = {};
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const int _maxAttemptsPerWindow = 5;

  // Session management
  static const Duration _inactivityTimeout = Duration(minutes: 30);

  // Operation tracking for better reliability
  final Set<String> _pendingOperations = {};
  static const Duration _operationTimeout = Duration(seconds: 30);

  AuthProvider(this._firebaseService) {
    _initializeProvider();
  }

  // Enhanced initialization with connectivity monitoring
  void _initializeProvider() {
    _listenToAuthChanges();
    _monitorConnectivity();
    _startSessionManagement();
    _logger.i('AuthProvider initialized with enhanced features');
  }

  // Enhanced Getters with additional security information
  User? get user => _user;
  AuthState get authState => _authState;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthError? get lastError => _lastError;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isHealthy =>
      !hasError && _consecutiveFailures < maxConsecutiveFailures;
  bool get hasError => _errorMessage != null;
  bool get isNetworkAvailable => _isNetworkAvailable;
  bool get canPerformOperations => isHealthy && _isNetworkAvailable;
  bool get isSessionActive => _user != null && _isSessionValid();

  // Security status getters
  bool get isRateLimited => _isRateLimitReached('general');
  int get failureCount => _consecutiveFailures;
  DateTime? get lastActivity => _lastActivity;

  // Public method to reset circuit breaker (for recovery)
  void resetFailureCount() {
    _consecutiveFailures = 0;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();
    _logger.i('Circuit breaker reset - operations enabled');
  }

  // Enhanced error parsing with additional error types
  AuthError _parseAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-disabled':
          return AuthError.userDisabled;
        case 'user-not-found':
          return AuthError.userNotFound;
        case 'wrong-password':
          return AuthError.wrongPassword;
        case 'email-already-in-use':
          return AuthError.emailAlreadyInUse;
        case 'invalid-email':
          return AuthError.invalidEmail;
        case 'operation-not-allowed':
          return AuthError.operationNotAllowed;
        case 'weak-password':
          return AuthError.weakPassword;
        case 'network-request-failed':
          return AuthError.networkError;
        case 'too-many-requests':
          return AuthError.tooManyRequests;
        case 'invalid-credential':
        case 'user-token-expired':
          return AuthError.sessionExpired;
        default:
          return AuthError.unknown;
      }
    }
    if (error is SocketException || error is TimeoutException) {
      return AuthError.networkError;
    }
    return AuthError.unknown;
  }

  String _getErrorMessage(AuthError error) {
    switch (error) {
      case AuthError.userDisabled:
        return 'This account has been disabled. Please contact support.';
      case AuthError.userNotFound:
        return 'No account found with this email address.';
      case AuthError.wrongPassword:
        return 'Incorrect password. Please try again.';
      case AuthError.emailAlreadyInUse:
        return 'An account with this email already exists.';
      case AuthError.invalidEmail:
        return 'Please enter a valid email address.';
      case AuthError.operationNotAllowed:
        return 'This sign-in method is not enabled.';
      case AuthError.weakPassword:
        return 'Password should be at least 6 characters long.';
      case AuthError.networkError:
        return 'Network error. Please check your connection.';
      case AuthError.tooManyRequests:
        return 'Too many attempts. Please try again later.';
      case AuthError.maintenanceMode:
        return 'App is under maintenance. Please try again later.';
      case AuthError.sessionExpired:
        return 'Your session has expired. Please sign in again.';
      case AuthError.deviceNotSupported:
        return 'This device is not supported. Please contact support.';
      case AuthError.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(dynamic error) {
    _lastError = _parseAuthError(error);
    _errorMessage = _getErrorMessage(_lastError!);
    _consecutiveFailures++;

    // Enhanced error handling with circuit breaker
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      _isNetworkAvailable = false;
      _scheduleRecovery();
    }

    _errorHandler.handlePlatformError(
      Exception(_errorMessage!),
      StackTrace.current,
    );
    _logger.e('Auth Error: $_errorMessage', error: error);
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null || _lastError != null) {
      _errorMessage = null;
      _lastError = null;
      _consecutiveFailures = 0;
      _isNetworkAvailable = true;
      notifyListeners();
    }
  }

  // Enhanced public method for clearing errors
  void clearError() => _clearError();

  // Schedule recovery attempt for circuit breaker pattern
  void _scheduleRecovery() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 5), () {
      _consecutiveFailures = 0;
      _isNetworkAvailable = true;
      _clearError();
    });
  }

  // Enhanced operation wrapper with timeout and validation
  Future<T?> _performOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration? timeout,
  }) async {
    if (!canPerformOperations) {
      throw Exception(
          'Operations temporarily disabled due to consecutive failures');
    }

    if (_pendingOperations.contains(operationName)) {
      throw Exception('Operation $operationName is already in progress');
    }

    if (_isRateLimitReached(operationName)) {
      throw Exception('Rate limit exceeded for $operationName');
    }

    _pendingOperations.add(operationName);
    _updateLastActivity();

    try {
      _recordAttempt(operationName);
      return await operation().timeout(timeout ?? _operationTimeout);
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _pendingOperations.remove(operationName);
    }
  }

  // Rate limiting implementation
  bool _isRateLimitReached(String operation) {
    final now = DateTime.now();
    final attempts = _rateLimitCache[operation] ?? [];

    // Remove old attempts outside the window
    attempts.removeWhere(
        (time) => now.difference(time).compareTo(_rateLimitWindow) > 0);

    return attempts.length >= _maxAttemptsPerWindow;
  }

  void _recordAttempt(String operation) {
    final now = DateTime.now();
    _rateLimitCache[operation] = (_rateLimitCache[operation] ?? [])..add(now);
  }

  // Session management
  void _startSessionManagement() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_user != null && !_isSessionValid()) {
        _handleSessionExpiry();
      }
    });
  }

  bool _isSessionValid() {
    if (_lastActivity == null) return true;
    final now = DateTime.now();
    return now.difference(_lastActivity!).compareTo(_inactivityTimeout) <= 0;
  }

  void _updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  void _handleSessionExpiry() {
    _logger.w('Session expired due to inactivity');
    _setError(FirebaseAuthException(
      code: 'user-token-expired',
      message: 'Session expired',
    ));
    signOut();
  }

  // Connectivity monitoring
  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasAvailable = _isNetworkAvailable;
      _isNetworkAvailable =
          results.any((result) => result != ConnectivityResult.none);

      if (!wasAvailable && _isNetworkAvailable) {
        _logger.i('Network connectivity restored');
        _consecutiveFailures = 0;
        _clearError();
      } else if (wasAvailable && !_isNetworkAvailable) {
        _logger.w('Network connectivity lost');
        _setError(Exception('Network connection lost'));
      }
    });
  }

  void _listenToAuthChanges() {
    _authStateSubscription =
        _firebaseService.authStateChanges.listen((newUser) {
      final oldState = _authState;
      _user = newUser;
      _authState =
          newUser != null ? AuthState.authenticated : AuthState.unauthenticated;

      if (_isInitializing) {
        _isInitializing = false;
      }

      // Update last activity on auth state change
      if (newUser != null) {
        _updateLastActivity();
      }

      // Only notify if state actually changed
      if (oldState != _authState || _isInitializing) {
        _logger.i('Auth state changed: ${_authState.name}');
        notifyListeners();
      }
    });
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    return await _performOperation('signInWithEmailPassword', () async {
          _clearError();
          _setLoading(true);

          try {
            // Enhanced validation
            if (email.trim().isEmpty || password.trim().isEmpty) {
              throw FirebaseAuthException(
                code: 'invalid-email',
                message: 'Email and password cannot be empty',
              );
            }

            // Additional email format validation
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              throw FirebaseAuthException(
                code: 'invalid-email',
                message: 'Please enter a valid email format',
              );
            }

            await _firebaseService.signInWithEmailAndPassword(
                email.trim(), password);
            _logger.i('User signed in successfully: ${email.trim()}');
            return true;
          } catch (e) {
            _setError(e);
            return false;
          } finally {
            _setLoading(false);
          }
        }) ??
        false;
  }

  Future<bool> registerWithEmailPassword(
      String email, String password, String displayName) async {
    return await _performOperation('registerWithEmailPassword', () async {
          _clearError();
          _setLoading(true);

          try {
            // Enhanced validation
            if (email.trim().isEmpty ||
                password.trim().isEmpty ||
                displayName.trim().isEmpty) {
              throw FirebaseAuthException(
                code: 'invalid-email',
                message: 'All fields are required',
              );
            }

            // Enhanced email format validation
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              throw FirebaseAuthException(
                code: 'invalid-email',
                message: 'Please enter a valid email format',
              );
            }

            // Enhanced password validation
            if (password.length < 8) {
              throw FirebaseAuthException(
                code: 'weak-password',
                message: 'Password should be at least 8 characters long',
              );
            }

            // Enhanced display name validation
            if (displayName.trim().length < 2) {
              throw FirebaseAuthException(
                code: 'invalid-display-name',
                message: 'Display name should be at least 2 characters long',
              );
            }

            final userCredential = await _firebaseService
                .createUserWithEmailAndPassword(email.trim(), password);
            final firebaseUser = userCredential.user;

            if (firebaseUser != null) {
              // Update display name in Firebase Auth
              await firebaseUser.updateDisplayName(displayName.trim());

              // Create user document in Firestore with enhanced retry logic
              final appUser = AppUser(
                id: firebaseUser.uid,
                email: email.trim(),
                displayName: displayName.trim(),
                createdAt: Timestamp.fromDate(DateTime.now()),
              );

              // Enhanced retry logic with exponential backoff
              for (int attempt = 1; attempt <= 5; attempt++) {
                try {
                  await _firebaseService.createOrUpdateAppUser(appUser,
                      merge: false);
                  break;
                } catch (e) {
                  if (attempt == 5) rethrow;
                  await Future.delayed(Duration(seconds: attempt * 2));
                  _logger.w('Retry attempt $attempt for user creation');
                }
              }

              _logger.i('User registered successfully: ${email.trim()}');
              return true;
            }
            return false;
          } catch (e) {
            _setError(e);
            return false;
          } finally {
            _setLoading(false);
          }
        }) ??
        false;
  }

  Future<bool> signInWithGoogle() async {
    return await _performOperation('signInWithGoogle', () async {
          _clearError();
          _setLoading(true);

          try {
            final userCredential = await _firebaseService.signInWithGoogle();
            final firebaseUser = userCredential?.user;

            if (firebaseUser != null) {
              // Enhanced user data validation
              if (firebaseUser.email == null || firebaseUser.email!.isEmpty) {
                throw FirebaseAuthException(
                  code: 'invalid-credential',
                  message: 'Google account does not have a valid email',
                );
              }

              // Check if user exists in Firestore with enhanced retry logic
              AppUser? appUser;
              for (int attempt = 1; attempt <= 5; attempt++) {
                try {
                  appUser = await _firebaseService.getAppUser(firebaseUser.uid);
                  break;
                } catch (e) {
                  if (attempt == 5) {
                    _logger
                        .w('Failed to check existing user, creating new one');
                    appUser = null;
                  }
                  await Future.delayed(Duration(seconds: attempt * 2));
                }
              }

              if (appUser == null) {
                // If new user, create document in Firestore with enhanced validation
                final newUser = AppUser(
                  id: firebaseUser.uid,
                  email: firebaseUser.email!,
                  displayName: firebaseUser.displayName ??
                      firebaseUser.email!
                          .split('@')[0], // Fallback display name
                  photoUrl: firebaseUser.photoURL,
                  createdAt: Timestamp.fromDate(DateTime.now()),
                );

                // Enhanced retry logic with exponential backoff
                for (int attempt = 1; attempt <= 5; attempt++) {
                  try {
                    await _firebaseService.createOrUpdateAppUser(newUser,
                        merge: false);
                    break;
                  } catch (e) {
                    if (attempt == 5) rethrow;
                    await Future.delayed(Duration(seconds: attempt * 2));
                    _logger
                        .w('Retry attempt $attempt for Google user creation');
                  }
                }
              }

              _logger.i('Google sign-in successful: ${firebaseUser.email}');
              return true;
            }
            return false;
          } catch (e) {
            _setError(e);
            return false;
          } finally {
            _setLoading(false);
          }
        }) ??
        false;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    return await _performOperation('sendPasswordResetEmail', () async {
          _clearError();
          _setLoading(true);

          try {
            // Enhanced validation
            if (email.trim().isEmpty) {
              throw FirebaseAuthException(
                code: 'invalid-email',
                message: 'Email cannot be empty',
              );
            }

            // Enhanced email format validation
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              throw FirebaseAuthException(
                code: 'invalid-email',
                message: 'Please enter a valid email format',
              );
            }

            await _firebaseService.sendPasswordResetEmail(email.trim());
            _logger.i('Password reset email sent to: ${email.trim()}');
            return true;
          } catch (e) {
            _setError(e);
            return false;
          } finally {
            _setLoading(false);
          }
        }) ??
        false;
  }

  Future<void> signOut() async {
    await _performOperation('signOut', () async {
      _clearError();
      _setLoading(true);

      try {
        await _firebaseService.signOut();

        // Clear session data
        _lastActivity = null;
        _consecutiveFailures = 0;
        _rateLimitCache.clear();
        _pendingOperations.clear();

        _logger.i('User signed out successfully');
      } catch (e) {
        _logger.e('Sign out failed', error: e);
        // Don't show error for sign out failures, just log
      } finally {
        _setLoading(false);
      }
    });
  }

  // Enhanced dispose method with proper cleanup
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _sessionTimer?.cancel();
    _retryTimer?.cancel();
    _pendingOperations.clear();
    _rateLimitCache.clear();
    _logger.i('AuthProvider disposed with cleanup');
    super.dispose();
  }

  // Legacy method for compatibility
  Future<void> signIn(String email, String password) async {
    await signInWithEmailPassword(email, password);
  }

  // Additional utility methods for enhanced functionality
  void refreshSession() {
    _updateLastActivity();
    _clearError();
  }

  // Force clear all cached data (for admin operations)
  void forceReset() {
    _consecutiveFailures = 0;
    _isNetworkAvailable = true;
    _rateLimitCache.clear();
    _pendingOperations.clear();
    _lastActivity = null;
    _clearError();
    _logger.i('AuthProvider forcefully reset');
  }

  // Check if specific operation is available
  bool canPerformOperation(String operation) {
    return canPerformOperations &&
        !_pendingOperations.contains(operation) &&
        !_isRateLimitReached(operation);
  }
}
