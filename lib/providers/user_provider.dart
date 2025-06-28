// user_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'
    as auth; // ใช้ as auth เพื่อความชัดเจน
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
    try {
      // เรียกใช้ service เพื่อดึงข้อมูลจาก collection 'users'
      _currentUser = await _firebaseService.getAppUser(uid);
    } catch (e) {
      _firebaseService.logger.e('Failed to load user data', error: e);
      _currentUser = null; // หากพลาด ให้เคลียร์ข้อมูล
    } finally {
      _isLoading = false;
      notifyListeners(); // แจ้ง UI ว่าโหลดเสร็จแล้ว (ไม่ว่าจะสำเร็จหรือไม่)
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

  /// อัปเดตข้อมูลโปรไฟล์ (ชื่อ, เบอร์โทร)
  Future<void> updateUserProfile(String displayName, String phoneNumber) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _currentUser!.id;
      await _firebaseService.updateUserProfile(
          userId, displayName, phoneNumber);
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
