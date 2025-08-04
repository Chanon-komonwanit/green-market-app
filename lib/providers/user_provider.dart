// user_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'
    as auth; // ใช้ as auth เพื่อความชัดเจน
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/enhanced_error_handler.dart';
import 'package:image_picker/image_picker.dart';

/// UserProvider ทำหน้าที่จัดการข้อมูลและสถานะของผู้ใช้ที่ล็อกอินเข้ามา
/// เป็นหัวใจสำคัญในการระบุว่าผู้ใช้เป็นใคร (ผู้ซื้อ, ผู้ขาย, หรือแอดมิน)
/// พร้อมด้วยระบบการจัดการข้อผิดพลาดและการป้องกันความปลอดภัยขั้นสูง
class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final EnhancedErrorHandler _errorHandler = EnhancedErrorHandler();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<auth.User?>? _authSubscription;

  // Enhanced Security & Performance Features
  int _consecutiveFailures = 0;
  static const int maxConsecutiveFailures = 3;
  bool _isNetworkAvailable = true;
  Timer? _retryTimer;

  // Operation tracking for better reliability
  final Set<String> _pendingOperations = {};
  static const Duration _operationTimeout = Duration(seconds: 30);

  /// Constructor: เมื่อ Provider ถูกสร้างขึ้น จะเริ่มฟังการเปลี่ยนแปลงสถานะการล็อกอินทันที
  UserProvider({required FirebaseService firebaseService})
      : _firebaseService = firebaseService {
    _listenToAuthChanges();
  }

  // --- Enhanced Getters สำหรับให้ UI ส่วนต่างๆ นำไปใช้ ---
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSeller => _currentUser?.isSeller ?? false;
  bool get isHealthy =>
      !hasError && _consecutiveFailures < maxConsecutiveFailures;
  bool get canPerformOperations => isHealthy && _isNetworkAvailable;

  // เพิ่ม enhanced getters สำหรับตรวจสอบสถานะการสมัครเป็นผู้ขาย
  bool get hasAppliedToBecomeSeller =>
      _currentUser?.sellerApplicationStatus != null;
  bool get isSellerApplicationPending =>
      _currentUser?.sellerApplicationStatus == 'pending';
  bool get isSellerApplicationApproved =>
      _currentUser?.sellerApplicationStatus == 'approved';
  bool get isSellerApplicationRejected =>
      _currentUser?.sellerApplicationStatus == 'rejected';
  bool get canApplyToBecomeSeller =>
      !isAdmin && !isSeller && !hasAppliedToBecomeSeller;

  /// Enhanced error handling with retry logic and security measures
  void _setError(String? error) {
    if (error != null) {
      _consecutiveFailures++;

      // Use the appropriate error handler method
      _errorHandler.handlePlatformError(
        Exception(error),
        StackTrace.current,
      );

      // Implement circuit breaker pattern
      if (_consecutiveFailures >= maxConsecutiveFailures) {
        _isNetworkAvailable = false;
        _scheduleRecovery();
      }
    } else {
      _consecutiveFailures = 0;
      _isNetworkAvailable = true;
    }

    _error = error;
    notifyListeners();
  }

  /// Enhanced loading state management
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Schedule recovery attempt for circuit breaker pattern
  void _scheduleRecovery() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 5), () {
      _consecutiveFailures = 0;
      _isNetworkAvailable = true;
      _setError(null);
    });
  }

  /// Enhanced operation wrapper with timeout and validation
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

    _pendingOperations.add(operationName);
    try {
      return await operation().timeout(timeout ?? _operationTimeout);
    } catch (e) {
      _setError('$operationName failed: $e');
      return null;
    } finally {
      _pendingOperations.remove(operationName);
    }
  }

  /// Clear error message with enhanced logic
  void clearError() {
    _setError(null);
    if (!_isNetworkAvailable && _consecutiveFailures < maxConsecutiveFailures) {
      _isNetworkAvailable = true;
    }
  }

  /// [หัวใจหลัก] เมธอดนี้จะคอย "ฟัง" ว่ามีการล็อกอินหรือล็อกเอาท์เกิดขึ้นหรือไม่
  void _listenToAuthChanges() {
    // ยกเลิกการฟังเก่า (ถ้ามี) เพื่อป้องกันการทำงานซ้ำซ้อน
    _authSubscription?.cancel();
    _authSubscription =
        _firebaseService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        // หากมีผู้ใช้ล็อกอินเข้ามา, ให้ไปดึงข้อมูลจาก Firestore ทันที
        loadUserData(firebaseUser.uid);
      } else {
        // หากผู้ใช้ล็อกเอาท์, ให้ล้างข้อมูลผู้ใช้ออกจากระบบ
        clearUserData();
      }
    });
  }

  /// Enhanced โหลดข้อมูลโปรไฟล์ของผู้ใช้ (AppUser) จาก Firestore โดยใช้ uid
  /// ซึ่งข้อมูลนี้จะมี field สำคัญเช่น isAdmin, isSeller อยู่ด้วย
  /// พร้อมระบบความแข็งแกร่งและการจัดการข้อผิดพลาดขั้นสูง
  Future<void> loadUserData(String uid) async {
    if (uid.trim().isEmpty) {
      _setError('Invalid user ID');
      return;
    }

    await _performOperation('loadUserData', () async {
      _setLoading(true);
      _setError(null);

      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          _firebaseService.logger.i(
              "[LOADING] Loading user data for: $uid (attempt ${retryCount + 1})");

          // เรียกใช้ service เพื่อดึงข้อมูลจาก collection 'users'
          _currentUser = await _firebaseService.getAppUser(uid);

          if (_currentUser != null) {
            _firebaseService.logger.i(
                "[SUCCESS] User data loaded successfully: ${_currentUser!.email}");

            // ตรวจสอบและให้รางวัลการเข้าสู่ระบบประจำวัน
            _firebaseService.checkDailyLoginReward(uid);

            break; // สำเร็จ, ออกจาก retry loop
          } else {
            _firebaseService.logger
                .w("[WARNING] User data is null for UID: $uid");

            // ถ้าไม่มีข้อมูลใน Firestore, สร้างใหม่
            await _createMissingUserData(uid);
            retryCount++; // เพิ่ม retry count
          }
        } catch (e) {
          retryCount++;
          _firebaseService.logger
              .e('Failed to load user data (attempt $retryCount)', error: e);

          if (retryCount < maxRetries) {
            // รอก่อน retry (exponential backoff)
            await Future.delayed(Duration(seconds: retryCount * 2));
          } else {
            _firebaseService.logger
                .e('All retry attempts failed for user: $uid');
            _currentUser = null; // หากพลาดหลังจากครบ retry
            _setError('Failed to load user data after $maxRetries attempts');
          }
        }
      }
    });

    _setLoading(false);
  }

  /// สร้างข้อมูลผู้ใช้ใหม่ใน Firestore หากไม่มี
  Future<void> _createMissingUserData(String uid) async {
    try {
      final firebaseUser = _firebaseService.getCurrentUser();
      if (firebaseUser != null && firebaseUser.uid == uid) {
        _firebaseService.logger
            .i("[CREATE] Creating missing user data for: $uid");

        final newUser = AppUser(
          id: uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          createdAt: Timestamp.fromDate(DateTime.now()),
        );

        await _firebaseService.createOrUpdateAppUser(newUser, merge: false);
        _firebaseService.logger
            .i("[SUCCESS] Created missing user data for: $uid");
      }
    } catch (e) {
      _firebaseService.logger.e('Failed to create missing user data', error: e);
    }
  }

  /// ล้างข้อมูลผู้ใช้ทั้งหมดเมื่อมีการล็อกเอาท์
  void clearUserData() {
    _currentUser = null;
    notifyListeners();
  }

  /// Enhanced อัปเดตรูปโปรไฟล์พร้อมการตรวจสอบและการจัดการข้อผิดพลาดขั้นสูง
  Future<void> updateUserProfilePicture(XFile imageFile) async {
    if (_currentUser == null) {
      _setError('User not logged in');
      return;
    }

    // Input validation
    if (!await File(imageFile.path).exists()) {
      _setError('Selected image file does not exist');
      return;
    }

    // Check file size (max 5MB)
    final fileSize = await File(imageFile.path).length();
    if (fileSize > 5 * 1024 * 1024) {
      _setError('Image file too large. Maximum size is 5MB');
      return;
    }

    await _performOperation('updateUserProfilePicture', () async {
      _setLoading(true);
      _setError(null);

      final userId = _currentUser!.id;
      // ใช้ uploadImageFile แทน uploadImage
      final imageUrl = await _firebaseService.uploadImageFile(
        File(imageFile.path),
        'user_profiles/${userId}_profile.jpg',
      );

      await _firebaseService.updateUserProfilePicture(userId, imageUrl);
      await loadUserData(userId); // โหลดข้อมูลใหม่เพื่อให้ UI อัปเดต
    });

    _setLoading(false);
  }

  /// Enhanced อัปเดตข้อมูลโปรไฟล์ (ชื่อ, เบอร์โทร และข้อมูลเพิ่มเติม)
  /// พร้อมการตรวจสอบข้อมูลและการจัดการข้อผิดพลาดขั้นสูง
  Future<void> updateUserProfile({
    required String displayName,
    required String phoneNumber,
    String? photoUrl,
    String? bio,
    String? address,
    String? shopName,
    String? shopDescription,
    String? motto,
    String? website, // เพิ่ม field ใหม่
    String? facebook, // เพิ่ม field ใหม่
    String? instagram, // เพิ่ม field ใหม่
    String? lineId, // เพิ่ม field ใหม่
    String? gender, // เพิ่ม field ใหม่
  }) async {
    if (_currentUser == null) {
      _setError('User not logged in');
      return;
    }

    // Enhanced input validation
    if (displayName.trim().isEmpty) {
      _setError('Display name cannot be empty');
      return;
    }

    if (displayName.length > 50) {
      _setError('Display name must be less than 50 characters');
      return;
    }

    if (phoneNumber.trim().isEmpty) {
      _setError('Phone number cannot be empty');
      return;
    }

    // Basic phone number validation
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(phoneNumber.replaceAll(RegExp(r'[\s-()]'), ''))) {
      _setError('Invalid phone number format');
      return;
    }

    await _performOperation('updateUserProfile', () async {
      _setLoading(true);
      _setError(null);

      final userId = _currentUser!.id;
      await _firebaseService.updateUserProfile(
        userId,
        displayName,
        phoneNumber,
        photoUrl: photoUrl,
        bio: bio,
        address: address,
        shopName: shopName,
        shopDescription: shopDescription,
        motto: motto,
        website: website, // เพิ่ม field ใหม่
        facebook: facebook, // เพิ่ม field ใหม่
        instagram: instagram, // เพิ่ม field ใหม่
        lineId: lineId, // เพิ่ม field ใหม่
        gender: gender, // เพิ่ม field ใหม่
      );
      await loadUserData(userId); // โหลดข้อมูลใหม่เพื่อให้ UI อัปเดต
    });

    _setLoading(false);
  }

  // --- Enhanced Investment Methods with comprehensive error handling ---
  // เมธอดด้านล่างเป็นตัวอย่างการทำงานร่วมกับข้อมูลผู้ใช้ปัจจุบัน

  Future<void> investInProject(
      String projectId, String projectTitle, double amount) async {
    if (_currentUser == null) {
      _setError('User not logged in');
      return;
    }

    // Enhanced input validation
    if (projectId.trim().isEmpty) {
      _setError('Project ID cannot be empty');
      return;
    }

    if (amount <= 0) {
      _setError('Investment amount must be greater than 0');
      return;
    }

    await _performOperation('investInProject', () async {
      _setLoading(true);
      _setError(null);

      await _firebaseService.investInProject(
        projectId,
        _currentUser!.id,
        amount,
      );
    });

    _setLoading(false);
  }

  Future<void> buyMoreInvestment(String investmentId, double amount) async {
    if (_currentUser == null) {
      _setError('User not logged in');
      return;
    }

    // Enhanced input validation
    if (investmentId.trim().isEmpty) {
      _setError('Investment ID cannot be empty');
      return;
    }

    if (amount <= 0) {
      _setError('Investment amount must be greater than 0');
      return;
    }

    await _performOperation('buyMoreInvestment', () async {
      _setLoading(true);
      _setError(null);

      await _firebaseService.buyMoreInvestment(
        investmentId,
        amount,
      );
      await loadUserData(_currentUser!.id);
    });

    _setLoading(false);
  }

  Future<void> sellInvestment(String investmentId, double amount) async {
    if (_currentUser == null) {
      _setError('User not logged in');
      return;
    }

    // Enhanced input validation
    if (investmentId.trim().isEmpty) {
      _setError('Investment ID cannot be empty');
      return;
    }

    await _performOperation('sellInvestment', () async {
      _setLoading(true);
      _setError(null);

      await _firebaseService.sellInvestment(investmentId);
      await loadUserData(_currentUser!.id);
    });

    _setLoading(false);
  }

  /// Additional utility methods for enhanced user management

  /// Check if user profile is complete
  bool get isProfileComplete {
    if (_currentUser == null) return false;

    return _currentUser!.displayName != null &&
        _currentUser!.displayName!.isNotEmpty &&
        _currentUser!.phoneNumber != null &&
        _currentUser!.phoneNumber!.isNotEmpty;
  }

  /// Get user's full name or fallback to email
  String get userDisplayName {
    if (_currentUser?.displayName != null &&
        _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }
    return _currentUser?.email ?? 'Unknown User';
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return isAdmin;
      case 'seller':
        return isSeller;
      case 'user':
        return isLoggedIn && !isAdmin && !isSeller;
      default:
        return false;
    }
  }

  /// Refresh user data with cache management
  Future<void> refreshUserData() async {
    if (_currentUser != null) {
      await loadUserData(_currentUser!.id);
    }
  }

  /// สำคัญมาก: Enhanced dispose method
  /// ต้องยกเลิกการ `listen` (unsubscribe) เมื่อ Provider ถูกทำลาย
  /// เพื่อป้องกัน Memory Leak และทำความสะอาดทรัพยากร
  @override
  void dispose() {
    _authSubscription?.cancel();
    _retryTimer?.cancel();
    _pendingOperations.clear();
    super.dispose();
  }
}
