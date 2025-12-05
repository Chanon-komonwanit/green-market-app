import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Enhanced Authentication Service with comprehensive security features
/// Provides secure user authentication, session management, and account operations
class AuthService {
  static const String _tag = 'AuthService';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Security configuration
  static const int _maxLoginAttempts = 10; // เพิ่มจาก 5 เป็น 10 ครั้ง
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const Duration _sessionTimeout = Duration(hours: 8);

  // Cache for user data
  final Map<String, Map<String, dynamic>> _userCache = {};
  Timer? _sessionTimer;

  // Login attempt tracking
  final Map<String, List<DateTime>> _loginAttempts = {};

  // Enhanced authentication state stream with user data
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Enhanced user stream with Firestore data
  Stream<Map<String, dynamic>?> get enhancedUserStream =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        return await _getUserData(user.uid);
      });

  // Get current user with enhanced data
  User? get currentUser => _auth.currentUser;

  // Get current user ID safely
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Get cached user data
  Map<String, dynamic>? getCachedUserData(String uid) => _userCache[uid];

  // Security: Check if account is locked due to failed attempts
  bool _isAccountLocked(String email) {
    if (!_loginAttempts.containsKey(email)) return false;

    final attempts = _loginAttempts[email]!;
    final recentAttempts = attempts
        .where(
            (attempt) => DateTime.now().difference(attempt) < _lockoutDuration)
        .toList();

    _loginAttempts[email] = recentAttempts;
    return recentAttempts.length >= _maxLoginAttempts;
  }

  // Security: Record failed login attempt
  void _recordFailedAttempt(String email) {
    _loginAttempts.putIfAbsent(email, () => []).add(DateTime.now());
  }

  // Security: Clear failed attempts on successful login
  void _clearFailedAttempts(String email) {
    _loginAttempts.remove(email);
  }

  // Public method to manually clear account lockout (for admin/debug)
  void clearAccountLockout(String email) {
    _loginAttempts.remove(email.trim().toLowerCase());
    debugPrint('$_tag: Cleared lockout for $email');
  }

  // Validation: Email format validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  // Validation: Password strength validation
  Map<String, bool> validatePasswordStrength(String password) {
    return {
      'minLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChar': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  // Get password strength score (0-5)
  int getPasswordStrengthScore(String password) {
    final validation = validatePasswordStrength(password);
    return validation.values.where((v) => v).length;
  }

  // Helper: Show error message to user
  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper: Show success message to user
  void _showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper: Get user-friendly error message (Thai + detailed)
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return '❌ ไม่พบบัญชีผู้ใช้นี้ในระบบ\nกรุณาตรวจสอบอีเมลหรือสมัครสมาชิกใหม่';
      case 'wrong-password':
        return '❌ รหัสผ่านไม่ถูกต้อง\nกรุณาลองใหม่หรือกด "ลืมรหัสผ่าน"';
      case 'invalid-email':
        return '❌ รูปแบบอีเมลไม่ถูกต้อง\nตัวอย่าง: example@email.com';
      case 'invalid-credential':
        return '❌ อีเมลหรือรหัสผ่านไม่ถูกต้อง\nกรุณาตรวจสอบข้อมูลอีกครั้ง';
      case 'user-disabled':
        return '❌ บัญชีผู้ใช้ถูกปิดใช้งาน\nกรุณาติดต่อผู้ดูแลระบบ';
      case 'too-many-requests':
        return '⏱️ พยายามเข้าสู่ระบบบ่อยเกินไป\nกรุณารอสักครู่แล้วลองใหม่อีกครั้ง';
      case 'operation-not-allowed':
        return '❌ การดำเนินการนี้ไม่ได้รับอนุญาต\nกรุณาติดต่อผู้ดูแลระบบ';
      case 'weak-password':
        return '❌ รหัสผ่านไม่ปลอดภัย\nต้องมีอย่างน้อย 8 ตัวอักษร และมีตัวพิมพ์ใหญ่หรือตัวเลข';
      case 'email-already-in-use':
        return '❌ อีเมลนี้ถูกใช้งานแล้ว\nกรุณาเข้าสู่ระบบหรือใช้อีเมลอื่น';
      case 'requires-recent-login':
        return '⚠️ เซสชันหมดอายุ\nกรุณาเข้าสู่ระบบใหม่เพื่อดำเนินการต่อ';
      case 'network-request-failed':
        return '📡 ไม่สามารถเชื่อมต่ออินเทอร์เน็ต\nกรุณาตรวจสอบการเชื่อมต่อของคุณ';
      case 'permission-denied':
        return '❌ ไม่มีสิทธิ์เข้าถึงข้อมูล\nกรุณาติดต่อผู้ดูแลระบบ';
      case 'account-exists-with-different-credential':
        return '⚠️ อีเมลนี้ถูกใช้กับวิธีเข้าสู่ระบบอื่นแล้ว\nลองใช้ Google หรือ Facebook Login';
      case 'invalid-verification-code':
        return '❌ รหัสยืนยันไม่ถูกต้องหรือหมดอายุ\nกรุณาขอรหัสใหม่';
      case 'invalid-verification-id':
        return '❌ รหัสยืนยันไม่ถูกต้อง\nกรุณาลองใหม่อีกครั้ง';
      default:
        return '❌ เกิดข้อผิดพลาด: $errorCode\nกรุณาลองใหม่อีกครั้งหรือติดต่อผู้ดูแลระบบ';
    }
  }

  // Helper: Log errors for debugging and monitoring
  void _logError(String operation, String errorCode, String? message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry =
        '[$_tag] [$timestamp] Error in $operation: $errorCode - $message';

    print(logEntry);

    // Enhanced: Production-ready logging with severity levels
    // In production, you would send this to Firebase Crashlytics, Sentry, or similar service
    try {
      // Example Firebase Crashlytics integration (when implemented):
      // FirebaseCrashlytics.instance.recordError(
      //   Exception('Auth Error: $errorCode'),
      //   StackTrace.current,
      //   information: [
      //     DiagnosticsProperty('operation', operation),
      //     DiagnosticsProperty('errorCode', errorCode),
      //     DiagnosticsProperty('message', message),
      //   ],
      // );

      // For now, store in local log for debugging
      _storeLocalLog(logEntry, 'error');
    } catch (e) {
      print('[$_tag] Failed to log error: $e');
    }
  }

  // Store logs locally for debugging (can be uploaded to server later)
  void _storeLocalLog(String message, String level) {
    // TODO: Implement local log storage (SharedPreferences or local file)
    // This would be useful for offline debugging and batch upload to monitoring service
  }

  // Helper: Get user data from Firestore with caching
  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      // Check cache first
      if (_userCache.containsKey(uid)) {
        return _userCache[uid];
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userCache[uid] = data; // Cache the data
        return data;
      }
      return null;
    } catch (e) {
      _logError('_getUserData', 'firestore_error', e.toString());
      return null;
    }
  }

  // Helper: Cache user data
  Future<void> _cacheUserData(String uid) async {
    await _getUserData(uid); // This will cache the data
  }

  // Helper: Update user login information
  Future<void> _updateUserLoginInfo(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastLoginIp': Platform.isAndroid || Platform.isIOS ? 'mobile' : 'web',
        'loginCount': FieldValue.increment(1),
      });
    } catch (e) {
      _logError('_updateUserLoginInfo', 'firestore_error', e.toString());
    }
  }

  // Helper: Start session timer for automatic logout
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () async {
      await signOut();
      print('[$_tag] Session timeout - User automatically signed out');
    });
  }

  // Helper: Stop session timer
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // Enhanced sign in with comprehensive validation and security
  Future<UserCredential?> signInWithEmailPassword(
      String email, String password, BuildContext context) async {
    try {
      // Input validation
      if (email.trim().isEmpty || password.isEmpty) {
        _showError(
            context, '⚠️ กรุณากรอกข้อมูล\nกรุณากรอกอีเมลและรหัสผ่านให้ครบถ้วน');
        return null;
      }

      if (!_isValidEmail(email.trim())) {
        _showError(
            context, '❌ รูปแบบอีเมลไม่ถูกต้อง\nตัวอย่าง: yourname@email.com');
        return null;
      }

      // Security: Check for account lockout
      if (_isAccountLocked(email.trim().toLowerCase())) {
        _showError(context,
            '🔒 บัญชีถูกล็อคชั่วคราว\nเนื่องจากพยายามเข้าสู่ระบบผิดหลายครั้ง\nกรุณารอ 15 นาที แล้วลองใหม่อีกครั้ง');
        return null;
      }

      debugPrint('$_tag: Attempting login for: ${email.trim().toLowerCase()}');

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      debugPrint('$_tag: Login successful for: ${email.trim().toLowerCase()}');

      // Success: Clear failed attempts and update user data
      _clearFailedAttempts(email.trim().toLowerCase());
      await _updateUserLoginInfo(userCredential.user!);
      await _cacheUserData(userCredential.user!.uid);
      _startSessionTimer();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _recordFailedAttempt(email.trim().toLowerCase());
      String errorMessage = _getAuthErrorMessage(e.code);
      _showError(context, errorMessage);
      _logError('signInWithEmailPassword', e.code, e.message);
      return null;
    } catch (e) {
      _showError(
          context, "❌ เกิดข้อผิดพลาดที่ไม่คาดคิด\n$e\nกรุณาลองใหม่อีกครั้ง");
      _logError('signInWithEmailPassword', 'unexpected', e.toString());
      return null;
    }
  }

  // Enhanced sign up with comprehensive validation and security
  Future<UserCredential?> signUpWithEmailPassword(
      String email, String password, BuildContext context) async {
    try {
      // Input validation
      if (email.trim().isEmpty || password.isEmpty) {
        _showError(context,
            '⚠️ กรุณากรอกข้อมโลให้ครบถ้วน\nต้องกรอกทั้งอีเมลและรหัสผ่าน');
        return null;
      }

      if (!_isValidEmail(email.trim())) {
        _showError(context,
            '❌ รูปแบบอีเมลไม่ถูกต้อง\nตัวอย่างที่ถูกต้อง: yourname@email.com');
        return null;
      }

      // Password strength validation (relaxed for easier signup)
      final passwordScore = getPasswordStrengthScore(password);
      if (passwordScore < 2) {
        _showError(context,
            '🔑 รหัสผ่านไม่ปลอดภัยพอ\nความต้องการ:\n• มีอย่างน้อย 8 ตัวอักษร\n• มีตัวพิมพ์ใหญ่ (A-Z) หรือตัวเลข (0-9)\nตัวอย่าง: Pass1234, MyPass99');
        return null;
      }
      debugPrint('$_tag: Password strength score: $passwordScore/5');

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Create comprehensive user document in Firestore
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userData = {
          'uid': user.uid,
          'email': email.trim().toLowerCase(),
          'displayName': user.displayName ?? '',
          'profileImageUrl': user.photoURL ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'role': 'buyer',
          'isActive': true,
          'isEmailVerified': false,
          'isSeller': false,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'signInMethod': 'email',
          'loginCount': 1,
          'accountStatus': 'active',
          'preferences': {
            'language': 'th',
            'notifications': true,
            'newsletter': false,
          },
          'security': {
            'twoFactorEnabled': false,
            'lastPasswordChange': FieldValue.serverTimestamp(),
          },
          'ecoCoins': 100, // Welcome bonus
          'metadata': {
            'platform': Platform.isAndroid || Platform.isIOS ? 'mobile' : 'web',
            'version': '1.0.0',
          }
        };

        await _firestore.collection('users').doc(user.uid).set(userData);
        _userCache[user.uid] = userData; // Cache user data

        // Send email verification
        await user.sendEmailVerification();
        _showSuccess(context,
            'บัญชีถูกสร้างเรียบร้อย กรุณาตรวจสอบอีเมลเพื่อยืนยันบัญชี');

        _startSessionTimer();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getAuthErrorMessage(e.code);
      _showError(context, errorMessage);
      _logError('signUpWithEmailPassword', e.code, e.message);
      return null;
    } catch (e) {
      _showError(context, "เกิดข้อผิดพลาดที่ไม่คาดคิด");
      _logError('signUpWithEmailPassword', 'unexpected', e.toString());
      return null;
    }
  }

  // Enhanced sign out with cleanup
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update last logout time
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogoutAt': FieldValue.serverTimestamp(),
        });
      }

      // Cleanup
      _stopSessionTimer();
      _userCache.clear();
      _loginAttempts.clear();

      // Sign out from Firebase Auth
      await _auth.signOut();

      // Sign out from Google if applicable
      await _googleSignIn.signOut();

      print('[$_tag] User signed out successfully');
    } catch (e) {
      _logError('signOut', 'signout_error', e.toString());
    }
  }

  // Enhanced password reset with validation
  Future<bool> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email.trim())) {
        return false;
      }

      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      print('[$_tag] Password reset email sent to $email');
      return true;
    } catch (e) {
      _logError('resetPassword', 'reset_error', e.toString());
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      _logError('sendEmailVerification', 'verification_error', e.toString());
      return false;
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload user to get updated verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      _logError('reloadUser', 'reload_error', e.toString());
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);

        // Update Firestore document
        final updates = <String, dynamic>{};
        if (displayName != null) updates['displayName'] = displayName;
        if (photoURL != null) updates['profileImageUrl'] = photoURL;

        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update(updates);
          // Update cache
          if (_userCache.containsKey(user.uid)) {
            _userCache[user.uid]!.addAll(updates);
          }
        }

        return true;
      }
      return false;
    } catch (e) {
      _logError('updateProfile', 'profile_error', e.toString());
      return false;
    }
  }

  // Change password (requires recent authentication)
  Future<bool> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);

        // Update security metadata
        await _firestore.collection('users').doc(user.uid).update({
          'security.lastPasswordChange': FieldValue.serverTimestamp(),
        });

        return true;
      }
      return false;
    } catch (e) {
      _logError('changePassword', 'password_error', e.toString());
      return false;
    }
  }

  // Google Sign-In

  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        print('Google Sign-In successful: ${user.email}');
        // Check if this is a new user and create profile if needed
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          // Create new user profile
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email ?? '',
            'displayName': user.displayName ?? '',
            'profileImageUrl': user.photoURL ?? '',
            'role': 'buyer',
            'isActive': true,
            'isSeller': false,
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'signInMethod': 'google',
          });
          print('New Google user profile created');
        } else {
          // Update last login time
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return user;
    } catch (e) {
      print('Error with Google Sign-In: $e');
      return null;
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<bool> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        print('Re-authentication successful');
        return true;
      }
      return false;
    } catch (e) {
      print('Error with re-authentication: $e');
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Delete the authentication account
        await user.delete();
        print('User account deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  // Apple Sign-In (placeholder for future implementation)
  Future<User?> signInWithApple() async {
    // TODO: [ภาษาไทย] พัฒนา Apple Sign-In เมื่อพร้อมใช้งาน (ต้องใช้ apple_sign_in package และตั้งค่า iOS)
    throw UnimplementedError('Apple Sign-In not yet implemented');
  }
}
