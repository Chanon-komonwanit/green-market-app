// user_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'
    as auth; // ใช้ as auth เพื่อความชัดเจน
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';

/// UserProvider ทำหน้าที่จัดการข้อมูลและสถานะของผู้ใช้ที่ล็อกอินเข้ามา
/// เป็นหัวใจสำคัญในการระบุว่าผู้ใช้เป็นใคร (ผู้ซื้อ, ผู้ขาย, หรือแอดมิน)
class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  AppUser? _currentUser;
  bool _isLoading = false;
  StreamSubscription<auth.User?>? _authSubscription;

  /// Constructor: เมื่อ Provider ถูกสร้างขึ้น จะเริ่มฟังการเปลี่ยนแปลงสถานะการล็อกอินทันที
  UserProvider({required FirebaseService firebaseService})
      : _firebaseService = firebaseService {
    _listenToAuthChanges();
  }

  // --- Getters สำหรับให้ UI ส่วนต่างๆ นำไปใช้ ---
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSeller => _currentUser?.isSeller ?? false;

  // เพิ่ม getters สำหรับตรวจสอบสถานะการสมัครเป็นผู้ขาย
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

  /// โหลดข้อมูลโปรไฟล์ของผู้ใช้ (AppUser) จาก Firestore โดยใช้ uid
  /// ซึ่งข้อมูลนี้จะมี field สำคัญเช่น isAdmin, isSeller อยู่ด้วย
  Future<void> loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners(); // แจ้ง UI ว่ากำลังโหลด

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
          _firebaseService.logger.e('All retry attempts failed for user: $uid');
          _currentUser = null; // หากพลาดหลังจากครบ retry
        }
      }
    }

    _isLoading = false;
    notifyListeners(); // แจ้ง UI ว่าโหลดเสร็จแล้ว (ไม่ว่าจะสำเร็จหรือไม่)
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

  /// อัปเดตรูปโปรไฟล์
  Future<void> updateUserProfilePicture(XFile imageFile) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _currentUser!.id;
      // ใช้ uploadImageFile แทน uploadImage
      final imageUrl = await _firebaseService.uploadImageFile(
        File(imageFile.path),
        'user_profiles/${userId}_profile.jpg',
      );

      await _firebaseService.updateUserProfilePicture(userId, imageUrl);
      await loadUserData(userId); // โหลดข้อมูลใหม่เพื่อให้ UI อัปเดต
    } catch (e) {
      _firebaseService.logger.e('Failed to update profile picture', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// อัปเดตข้อมูลโปรไฟล์ (ชื่อ, เบอร์โทร และข้อมูลเพิ่มเติม)
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
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
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
    } catch (e) {
      _firebaseService.logger.e('Failed to update user profile', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Investment Methods ---
  // เมธอดด้านล่างเป็นตัวอย่างการทำงานร่วมกับข้อมูลผู้ใช้ปัจจุบัน

  Future<void> investInProject(
      String projectId, String projectTitle, double amount) async {
    if (_currentUser == null) {
      throw Exception('User not logged in.');
    }
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.investInProject(
        projectId,
        _currentUser!.id,
        amount,
      );
    } catch (e) {
      _firebaseService.logger.e('Failed to invest in project', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buyMoreInvestment(String investmentId, double amount) async {
    if (_currentUser == null) {
      throw Exception('User not logged in.');
    }
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.buyMoreInvestment(
        investmentId,
        amount,
      );
      await loadUserData(_currentUser!.id);
    } catch (e) {
      _firebaseService.logger.e('Failed to buy more investment', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sellInvestment(String investmentId, double amount) async {
    if (_currentUser == null) {
      throw Exception('User not logged in.');
    }
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.sellInvestment(investmentId);
      await loadUserData(_currentUser!.id);
    } catch (e) {
      _firebaseService.logger.e('Failed to sell investment', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// สำคัญมาก: ต้องยกเลิกการ `listen` (unsubscribe) เมื่อ Provider ถูกทำลาย
  /// เพื่อป้องกัน Memory Leak
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
