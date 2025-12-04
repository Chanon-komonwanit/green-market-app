// lib/services/firebase_service.dart
//
// 🔥 FirebaseService - SERVICE หลักที่สำคัญที่สุด
//
// หน้าที่:
// - จัดการทุก CRUD operations กับ Firestore
// - Query ข้อมูลจาก Collections ต่างๆ
// - จัดการ Real-time listeners
// - Upload/Download files จาก Firebase Storage
// - จัดการ Authentication operations
//
// Collections ที่จัดการ:
// - users, products, orders, categories, sellers, reviews
// - coupons, promotions, flashSales, ecoCoins
// - investments, activities, stories, chats, notifications
//
// ใช้โดย: เกือบทุก Provider และ Service ในแอป
//
// วิธีใช้:
// ```dart
// final service = FirebaseService();
// final data = await service.getCollection('users');
// await service.addDocument('products', productData);
// ```

import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List, kDebugMode;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:green_market/models/activity_report.dart';
import 'package:green_market/models/activity_review.dart';
import 'package:green_market/models/activity_summary.dart';
import 'package:green_market/models/app_notification.dart';
import 'package:green_market/models/app_settings.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/models/cart_item.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/models/chat_model.dart';
import 'package:green_market/models/eco_reward.dart';
import 'package:green_market/models/reward_redemption.dart' as redemption_model;
import 'package:green_market/models/homepage_settings.dart';
import 'package:green_market/models/investment_project.dart';
import 'package:green_market/models/investment_summary.dart';
import 'package:green_market/models/news_article_model.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/models/order_item.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/project_question.dart';
import 'package:green_market/models/project_update.dart';
import 'package:green_market/models/unified_promotion.dart';
import 'package:green_market/models/review.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/models/static_page.dart';
import 'package:green_market/models/sustainable_activity.dart';
import 'package:green_market/models/theme_settings.dart';
import 'package:green_market/models/user_investment.dart';
import 'package:green_market/utils/constants.dart';
import 'package:logger/logger.dart';

// 📊 Helper class สำหรับเก็บผลค้นหา AI
class ProductSearchResult {
  final Product product;
  final double score;

  ProductSearchResult(this.product, this.score);
}

/// FirebaseService - Service หลักสำหรับจัดการ Firestore, Storage, และ Auth
///
/// Features:
/// - ✅ CRUD operations (Create, Read, Update, Delete)
/// - ✅ Real-time data listeners
/// - ✅ File upload/download
/// - ✅ Query builder
/// - ✅ Retry mechanism with exponential backoff
/// - ✅ Error handling
class FirebaseService {
  // === ENHANCED ERROR HANDLING AND RETRY SYSTEM ===

  static const int _maxRetryAttempts = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Enhanced retry mechanism with exponential backoff
  static Future<T> _withRetryStatic<T>(
    String operationName,
    Future<T> Function() operation, {
    int? maxAttempts,
  }) async {
    final attempts = maxAttempts ?? _maxRetryAttempts;
    final logger = Logger();
    Exception? lastException;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await operation().timeout(_requestTimeout);
      } on FirebaseException catch (e) {
        lastException = e;

        // Don't retry for certain error codes
        if (_shouldNotRetry(e.code)) {
          rethrow;
        }

        if (attempt == attempts) {
          logger.e(
              'Operation $operationName failed after $attempts attempts: ${e.message}');
          break;
        }

        final delay =
            _baseRetryDelay * (1 << (attempt - 1)); // Exponential backoff
        logger.w(
            'Retry $attempt/$attempts for $operationName after ${delay.inSeconds}s: ${e.message}');
        await Future.delayed(delay);
      } on TimeoutException catch (e) {
        lastException = Exception('Operation timeout: ${e.message}');

        if (attempt == attempts) {
          logger
              .e('Operation $operationName timed out after $attempts attempts');
          break;
        }

        final delay = _baseRetryDelay * (1 << (attempt - 1));
        logger.w('Retry $attempt/$attempts for $operationName after timeout');
        await Future.delayed(delay);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempt == attempts) {
          logger.e('Operation $operationName failed with unexpected error: $e');
          break;
        }

        final delay = _baseRetryDelay * (1 << (attempt - 1));
        logger.w('Retry $attempt/$attempts for $operationName after error: $e');
        await Future.delayed(delay);
      }
    }

    throw lastException ??
        Exception('Operation $operationName failed after $attempts attempts');
  }

  /// Check if a Firebase error should not be retried
  static bool _shouldNotRetry(String? errorCode) {
    const nonRetryableErrors = {
      'permission-denied',
      'not-found',
      'invalid-argument',
      'failed-precondition',
      'already-exists',
    };
    return errorCode != null && nonRetryableErrors.contains(errorCode);
  }

  /// Enhanced error reporting with context
  static Future<void> _reportErrorStatic(
    String operation,
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    try {
      final logger = Logger();
      logger.e('Error in $operation: $error',
          error: error, stackTrace: stackTrace);

      await FirebaseFirestore.instance.collection('error_reports').add({
        'operation': operation,
        'error': error.toString(),
        'stackTrace': stackTrace?.toString(),
        'context': context ?? {},
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
        'severity': _getErrorSeverity(error),
      });
    } catch (e) {
      final logger = Logger();
      logger.w('Failed to report error: $e');
    }
  }

  /// Determine error severity
  static String _getErrorSeverity(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return 'high';
        case 'not-found':
        case 'already-exists':
          return 'medium';
        default:
          return 'low';
      }
    }
    return 'medium';
  }

  // ...existing code...

  // --- Enhanced static methods with retry mechanisms ---
  static Future<List<Product>> getProducts({int limit = 10}) async {
    return await _withRetryStatic('getProducts', () async {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final products = <Product>[];
      for (final doc in snapshot.docs) {
        try {
          final product = Product.fromMap({...doc.data(), 'id': doc.id});
          if (product.isValid && product.canBePurchased) {
            products.add(product);
          }
        } catch (e) {
          // Skip invalid products but log the error
          await _reportErrorStatic('getProducts_parsing', e, StackTrace.current,
              context: {'productId': doc.id});
        }
      }
      return products;
    });
  }

  static Future<List<app_order.Order>> getUserOrders(String userId,
      {int limit = 5}) async {
    return await _withRetryStatic('getUserOrders', () async {
      if (userId.trim().isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final orders = <app_order.Order>[];
      for (final doc in snapshot.docs) {
        try {
          final order = app_order.Order.fromMap({...doc.data(), 'id': doc.id});
          orders.add(order);
        } catch (e) {
          // Skip invalid orders but log the error
          await _reportErrorStatic(
              'getUserOrders_parsing', e, StackTrace.current,
              context: {'orderId': doc.id, 'userId': userId});
        }
      }
      return orders;
    });
  }

  /// Get promotions by seller id
  Future<List<UnifiedPromotion>> getPromotionsBySeller(String sellerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('startDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => UnifiedPromotion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.e('Error getting promotions by seller: $e');
      await _reportError('getPromotionsBySeller', e, StackTrace.current);
      return [];
    }
  }

  /// Get product categories by seller id (return category names)
  Future<List<String>> getProductCategoriesBySeller(String sellerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      final cats = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null &&
            data['category'].toString().isNotEmpty) {
          cats.add(data['category']);
        }
      }
      return cats.toList();
    } catch (e) {
      logger.e('Error getting product categories by seller: $e');
      await _reportError('getProductCategoriesBySeller', e, StackTrace.current);
      return [];
    }
  }

  /// Get seller by id (for shop page)
  Future<Seller?> getSellerById(String sellerId) async {
    // Reuse the main method to avoid code duplication
    return getSellerFullDetails(sellerId);
  }

  /// Update shop template (theme) for a seller
  Future<void> updateShopTemplate(String sellerId, String templateName) async {
    try {
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .update(
        {'shopTemplate': templateName},
      );

      // Log audit trail for security and compliance
      await _logAuditEvent('shop_template_updated', {
        'sellerId': sellerId,
        'templateName': templateName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error updating shop template: $e');
      await _reportError('updateShopTemplate', e, StackTrace.current);
      rethrow; // Re-throw to let caller handle UI feedback
    }
  }

  /// Enhanced error reporting with Crashlytics และ Audit Log
  /// ระบบแจ้งเตือนข้อผิดพลาดและบันทึกการตรวจสอบความปลอดภัย
  Future<void> _logAuditEvent(
      String eventType, Map<String, dynamic> data) async {
    try {
      // Check if we have proper authentication before attempting audit log
      if (_auth.currentUser == null) {
        logger.d('Skipping audit log - no authenticated user');
        return;
      }

      await _firestore.collection('audit_logs').add({
        'eventType': eventType,
        'userId': _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
        'appVersion':
            await _getAppVersion(), // Enhanced: Get actual app version
        'platform': 'flutter',
      });

      logger.d('Audit event logged: $eventType');
    } catch (e) {
      logger.w('Failed to log audit event: $e');
      // Silently fail for audit logging to not disrupt user experience
      // In production, you might want to use local storage as fallback
    }
  }

  /// Report critical errors to monitoring system
  Future<void> _reportError(
      String operation, dynamic error, StackTrace? stackTrace) async {
    try {
      logger.e('Critical error in $operation: $error',
          error: error, stackTrace: stackTrace);

      // Enhanced error reporting with structured data
      await _firestore.collection('error_reports').add({
        'operation': operation,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
        'userId': _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'critical',
        'appVersion': await _getAppVersion(),
        'deviceInfo': await _getDeviceInfo(),
      });

      // Enhanced: Firebase Crashlytics integration ready
      // To enable: add firebase_crashlytics package and uncomment
      // FirebaseCrashlytics.instance.recordError(error, stackTrace,
      //   information: ['Operation: $operation']);
    } catch (e) {
      logger.w('Failed to report error: $e');
    }
  }

  /// Get new products for a specific seller (สินค้าใหม่)
  Future<List<Product>> getNewProductsBySeller(String sellerId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  /// Get best seller products for a specific seller (สินค้าขายดี)
  Future<List<Product>> getBestSellerProductsBySeller(String sellerId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('soldCount', descending: true)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  /// Get approved products for a specific seller (for seller shop page)
  Future<List<Product>> getApprovedProductsBySeller(String sellerId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .where('isApproved', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  /// Stream community chats for a user (for chat list)
  Stream<List<Map<String, dynamic>>> streamCommunityChats(String userId) {
    return _firestore
        .collection('community_chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  /// Get community notifications for a user (for notifications screen)
  Stream<List<Map<String, dynamic>>> getCommunityNotifications(String userId) {
    return _firestore
        .collection('community_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  // (Merged with the first definition, avoid duplicate)
  // Use the first getUserById definition only. If you need to extend, add logic to the first one.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // จำนวนบรรทัดของ method stack trace
      errorMethodCount: 8, // จำนวนบรรทัดของ error stack trace
      lineLength: 120, // ความยาวของบรรทัด
      colors: true, // ใช้สีใน console
      printEmojis: false, // ปิดการใช้ emoji
      printTime: false, // ไม่แสดงเวลา
    ),
  );

  // Getters
  FirebaseFirestore get firestore => _firestore;

  FirebaseService() {
    _initializeAuth();
  }

  /// Initialize authentication with persistence
  Future<void> _initializeAuth() async {
    try {
      // Set auth persistence to keep user logged in
      await _auth.setPersistence(Persistence.LOCAL);
      logger.i("Auth persistence set to LOCAL");
    } catch (e) {
      logger.e("Failed to set auth persistence: $e");
    }
  }

  // Lazy initialization of GoogleSignIn with error handling
  GoogleSignIn? _getGoogleSignIn() {
    try {
      return GoogleSignIn.instance;
    } catch (e) {
      logger.w('Google Sign-In not available: $e');
      return null;
    }
  }

  String generateNewDocId(String collectionPath) {
    return _firestore.collection(collectionPath).doc().id;
  }

  // --- Authentication Methods ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log successful login for audit
      await _logAuditEvent('user_login', {
        'email': email,
        'method': 'email_password',
        'success': true,
      });

      return result;
    } catch (e, stackTrace) {
      logger.e("Sign-in Error: $e");
      await _reportError('signInWithEmailAndPassword', e, stackTrace);
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log successful registration for audit
      await _logAuditEvent('user_registration', {
        'email': email,
        'method': 'email_password',
        'success': true,
      });

      return result;
    } catch (e, stackTrace) {
      logger.e("User Creation Error: $e");
      await _reportError('createUserWithEmailAndPassword', e, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final googleSignIn = _getGoogleSignIn();
      await googleSignIn?.signOut();
      await _auth.signOut();
      logger.i("User signed out.");
    } catch (e) {
      logger.e("Sign-out Error: $e");
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logger.i("Password reset email sent to ");
    } catch (e) {
      logger.e("Password Reset Error: ");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleSignIn = _getGoogleSignIn();
    if (googleSignIn == null) {
      logger.w("Google Sign-In not available");
      return null;
    }

    try {
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      logger.i("Google sign-in successful, signing in with credential.");
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      logger.e("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // --- User Management ---
  Future<void> createOrUpdateAppUser(AppUser user, {bool merge = true}) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: merge));
      logger.i("User data for ${user.id} created/updated.");
    } catch (e) {
      logger.e("Error creating/updating user ${user.id}: ");
      rethrow;
    }
  }

  Stream<AppUser?> streamAppUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      return doc.exists ? AppUser.fromMap(doc.data()!, doc.id) : null;
    });
  }

  Future<AppUser?> getAppUser(String uid) async {
    try {
      logger.i("[FETCH] Fetching user data from Firestore for UID: $uid");
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final userData = doc.data()!;
        logger.i("[SUCCESS] User document found: ${userData['email']}");
        return AppUser.fromMap(userData, doc.id);
      } else {
        logger.w("[WARNING] User document not found for UID: $uid");
        return null;
      }
    } catch (e) {
      logger.e("[ERROR] Error getting user $uid: $e");

      // ถ้าเป็น network error, ลอง retry
      if (e.toString().contains('network') ||
          e.toString().contains('unavailable') ||
          e.toString().contains('timeout')) {
        logger.w("[RETRY] Network error detected, retrying...");
        await Future.delayed(Duration(seconds: 2));

        try {
          final doc = await _firestore.collection('users').doc(uid).get();
          if (doc.exists) {
            return AppUser.fromMap(doc.data()!, doc.id);
          }
        } catch (retryError) {
          logger.e("[ERROR] Retry failed: $retryError");
        }
      }

      return null;
    }
  }

  // Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    // Reuse getAppUser method to avoid code duplication
    return getAppUser(userId);
  }

  Future<String?> getUserDisplayName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['displayName'] as String?;
      }
      return null;
    } catch (e) {
      logger.e("Error getting user display name for : ");
      return null;
    }
  }

  Stream<List<AppUser>> getAllUsers() {
    return _firestore.collection('users').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateUserProfilePicture(String userId, String imageUrl) async {
    await _firestore.collection('users').doc(userId).update({
      'photoUrl': imageUrl,
    });
  }

  Future<void> updateUserProfile(
    String userId,
    String displayName,
    String phoneNumber, {
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
    final updateData = {'displayName': displayName, 'phoneNumber': phoneNumber};

    if (photoUrl != null) updateData['photoUrl'] = photoUrl;
    if (bio != null) updateData['bio'] = bio;
    if (address != null) updateData['address'] = address;
    if (shopName != null) updateData['shopName'] = shopName;
    if (shopDescription != null) {
      updateData['shopDescription'] = shopDescription;
    }
    if (motto != null) updateData['motto'] = motto;
    if (website != null) {
      updateData['website'] = website; // เพิ่ม field ใหม่
    }
    if (facebook != null) {
      updateData['facebook'] = facebook; // เพิ่ม field ใหม่
    }
    if (instagram != null) {
      updateData['instagram'] = instagram; // เพิ่ม field ใหม่
    }
    if (lineId != null) updateData['lineId'] = lineId; // เพิ่ม field ใหม่
    if (gender != null) updateData['gender'] = gender; // เพิ่ม field ใหม่

    await _firestore.collection('users').doc(userId).update(updateData);
  }

  Future<void> updateUserSuspensionStatus(
    String userId,
    bool isSuspended,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSuspended': isSuspended,
      });
      logger.i("User  suspension status updated to ");
    } catch (e) {
      logger.e("Error updating user suspension status for : ");
      rethrow;
    }
  }

  Future<void> updateUserRolesAndStatus({
    required String userId,
    bool? isAdmin,
    bool? isSeller,
    String? sellerStatus,
    bool? isSuspended,
    String? rejectionReason,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (isAdmin != null) updates['isAdmin'] = isAdmin;
      if (isSeller != null) updates['isSeller'] = isSeller;
      if (sellerStatus != null) updates['sellerStatus'] = sellerStatus;
      if (isSuspended != null) updates['isSuspended'] = isSuspended;
      if (rejectionReason != null) updates['rejectionReason'] = rejectionReason;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
        logger.i("User $userId roles and status updated: $updates");
      }
    } catch (e) {
      logger.e("Error updating user roles and status for $userId: $e");
      rethrow;
    }
  }

  Future<void> submitSellerApplication({
    required String userId,
    required String shopName,
    required String contactEmail,
    required String phoneNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'sellerApplication': {
          'shopName': shopName,
          'contactEmail': contactEmail,
          'phoneNumber': phoneNumber,
          'status': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
        },
        'sellerStatus': 'pending',
      });
      logger.i("Seller application submitted for user $userId");
    } catch (e) {
      logger.e("Error submitting seller application for $userId: $e");
      rethrow;
    }
  }

  Future<void> approveSellerApplication(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final sellerRef = _firestore.collection('sellers').doc(userId);

    final userData = await userRef.get();
    final shopName =
        userData.data()?['sellerApplication']?['shopName'] ?? 'Unknown Shop';

    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, {
        'isSeller': true,
        'sellerStatus': 'approved',
        'sellerApplication.status': 'approved',
      });
      transaction.set(
        sellerRef,
        Seller(
          id: userId,
          shopName: shopName,
          contactEmail: userData.data()?['email'] ?? '',
          phoneNumber: userData.data()?['phoneNumber'] ?? '',
          status: 'active',
          rating: 0.0,
          totalRatings: 0,
          createdAt: Timestamp.now(),
        ).toMap(),
      );
    });
  }

  Future<void> rejectSellerApplication(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'sellerStatus': 'rejected',
      'sellerApplication.status': 'rejected',
      'sellerApplication.rejectionReason': reason,
    });
  }

  Stream<List<AppUser>> getPendingSellerApplicationsStream() {
    return _firestore
        .collection('users')
        .where('sellerStatus', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<int> getPendingSellerApplicationsCountStream() {
    return _firestore
        .collection('users')
        .where('sellerStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // --- Seller Management ---
  Future<Seller?> getSellerFullDetails(String sellerId) async {
    final doc = await _firestore.collection('sellers').doc(sellerId).get();
    return doc.exists ? Seller.fromMap(doc.data()!) : null;
  }

  Future<Seller?> getShopDetails(String sellerId) async {
    return getSellerFullDetails(sellerId);
  }

  Stream<List<Seller>> getAllSellers() {
    return _firestore.collection('sellers').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Seller.fromMap(doc.data())).toList(),
        );
  }

  Future<void> updateSellerStatus(String sellerId, String status) async {
    await _firestore.collection('sellers').doc(sellerId).update({
      'status': status,
    });
  }

  Future<void> updateSellerProfile(Seller seller) async {
    await _firestore
        .collection('sellers')
        .doc(seller.id)
        .update(seller.toMap());
  }

  Future<void> updateShopDetails(Seller seller) async {
    return updateSellerProfile(seller);
  }

  Future<int> getTotalApprovedSellersCount() async {
    final snapshot = await _firestore
        .collection('sellers')
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.length;
  }

  // --- Product Management ---
  Future<void> addProduct(Product product) async {
    final docId =
        product.id.isEmpty ? generateNewDocId('products') : product.id;
    await _firestore
        .collection('products')
        .doc(docId)
        .set(product.copyWith(id: docId, createdAt: Timestamp.now()).toMap());
    logger.i("Product ${product.name} added with ID: $docId");
  }

  /// Submit product request for admin approval
  Future<void> submitProductRequest(Product product) async {
    try {
      logger.i("Attempting to submit product request for: ${product.name}");
      logger.i("Current user: ${_auth.currentUser?.uid}");
      logger.i("Product seller ID: ${product.sellerId}");

      final requestData = {
        'productData': product.toMap(),
        'sellerId': product.sellerId,
        'requestType': 'add_product',
        'status': 'pending', // pending, approved, rejected
        'submittedAt': FieldValue.serverTimestamp(),
        'submittedBy': product.sellerId,
        'adminNotes': null,
        'processedAt': null,
        'processedBy': null,
      };

      logger.i("Request data prepared, submitting to Firestore...");
      await _firestore.collection('product_requests').add(requestData);
      logger.i("Product request submitted successfully for: ${product.name}");
    } catch (e) {
      logger.e("Error submitting product request: $e");
      logger.e("Stack trace: ${StackTrace.current}");
      rethrow;
    }
  }

  /// Approve product request and create the actual product
  Future<void> approveProductRequest(
    String requestId, {
    int? ecoScore,
    String? categoryId,
    String? categoryName,
  }) async {
    try {
      final requestDoc =
          await _firestore.collection('product_requests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Product request not found');
      }

      final requestData = requestDoc.data()!;
      final productData = requestData['productData'] as Map<String, dynamic>;

      // Create product from request data
      final product = Product.fromMap(productData);
      final approvedProduct = product.copyWith(
        status: 'approved',
        approvedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
        // Override with admin-specified values if provided
        ecoScore: ecoScore ?? product.ecoScore,
        categoryId: categoryId ?? product.categoryId,
        categoryName: categoryName ?? product.categoryName,
      );

      // Use transaction to ensure atomicity
      String createdProductId = '';
      await _firestore.runTransaction((transaction) async {
        // Add product to products collection
        final productDocId = generateNewDocId('products');
        createdProductId = productDocId;
        final productData = approvedProduct.copyWith(id: productDocId).toMap();
        // Add isApproved flag to the data that will be saved to Firestore
        productData['isApproved'] = true;

        // Use logger instead of print for better debugging control
        logger.d(
            '[DEBUG] approveProductRequest: Creating product with ID: $productDocId');
        logger.d(
            '[DEBUG] approveProductRequest: Product name: ${productData['name']}');
        logger.d(
            '[DEBUG] approveProductRequest: isApproved: ${productData['isApproved']}');

        transaction.set(
          _firestore.collection('products').doc(productDocId),
          productData,
        );

        // Update request status
        transaction.update(
          _firestore.collection('product_requests').doc(requestId),
          {
            'status': 'approved',
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': _auth.currentUser?.uid,
            'productId': productDocId, // Reference to created product
          },
        );
      });

      logger.i("Product request approved and product created: ${product.name}");
      logger.i("Product ID: $createdProductId");
      logger.i("Product will be visible with isApproved: true");
    } catch (e) {
      logger.e("Error approving product request: $e");
      rethrow;
    }
  }

  /// Reject product request
  Future<void> rejectProductRequest(String requestId, String reason) async {
    try {
      await _firestore.collection('product_requests').doc(requestId).update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': _auth.currentUser?.uid,
        'adminNotes': reason,
      });

      logger.i("Product request rejected: $requestId");
    } catch (e) {
      logger.e("Error rejecting product request: $e");
      rethrow;
    }
  }

  /// Get product requests for admin review
  Stream<List<Map<String, dynamic>>> getProductRequests({String? status}) {
    logger.i("Getting product requests with status: ${status ?? 'all'}");

    Query query = _firestore.collection('product_requests');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
      logger.i("Filtering by status: $status");
    }

    return query.orderBy('submittedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      logger.i(
        "Product requests snapshot received: ${snapshot.docs.length} documents",
      );
      final results = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        data['id'] = doc.id;
        logger.i(
          "Product request: ${data['id']} - Status: ${data['status']} - Product: ${data['productData']?['name'] ?? 'Unknown'}",
        );
        return data;
      }).toList();
      logger.i("Returning ${results.length} product requests");
      return results;
    });
  }

  /// Get product requests by seller
  Stream<List<Map<String, dynamic>>> getProductRequestsBySeller(
    String sellerId,
  ) {
    return _firestore
        .collection('product_requests')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  Future<void> updateProduct(Product product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toMap());
    logger.i("Product ${product.name} updated with ID: ${product.id}");
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    logger.i("Product $productId deleted.");
  }

  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList(),
        );
  }

  Stream<List<Product>> getApprovedProducts() {
    logger.d('[DEBUG] getApprovedProducts: Starting query...');
    return _firestore.collection('products').snapshots().map(
      (snapshot) {
        logger.d(
            '[DEBUG] getApprovedProducts: Received ${snapshot.docs.length} total documents');

        // Filter approved products in code to handle both conditions
        final approvedProducts = <Product>[];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final bool isApprovedField = data['isApproved'] as bool? ?? false;
          final String status = data['status'] as String? ?? '';
          final bool isApprovedByStatus = status == 'approved';

          // Log detailed info only in debug mode
          if (kDebugMode) {
            logger.d('[DEBUG] Product ID: ${doc.id}');
            logger.d('  - Name: ${data['name']}');
            logger.d('  - Status: $status');
            logger.d('  - isApproved field: $isApprovedField');
            logger.d('  - Approved by status: $isApprovedByStatus');
          }

          // Include if either condition is true
          if (isApprovedField || isApprovedByStatus) {
            data['id'] = doc.id; // Add document ID to data
            final product = Product.fromMap(data);
            approvedProducts.add(product);
            if (kDebugMode) {
              logger.d('  - INCLUDED in approved products');
            }
          } else {
            if (kDebugMode) {
              logger.d('  - EXCLUDED from approved products');
            }
          }
          if (kDebugMode) {
            logger.d('---');
          }
        }

        logger.d('[DEBUG] Total approved products: ${approvedProducts.length}');
        return approvedProducts;
      },
    ).handleError((error) {
      logger.e("Error fetching approved products: $error");
      return <Product>[];
    });
  }

  Stream<List<Product>> getAllProductsForAdmin() {
    logger.d('[DEBUG] getAllProductsForAdmin: Starting query...');
    return _firestore.collection('products').snapshots().map(
      (snapshot) {
        logger.d(
            '[DEBUG] getAllProductsForAdmin: Found ${snapshot.docs.length} total products in collection');
        if (kDebugMode) {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            logger.d(
                '[DEBUG] Product ID: ${doc.id}, isApproved: ${data['isApproved']}, status: ${data['status']}, name: ${data['name']}');
          }
        }
        return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
      },
    );
  }

  Future<void> approveProduct(String productId, bool isApproved) async {
    await _firestore.collection('products').doc(productId).update({
      'isApproved': isApproved,
      'status': isApproved ? 'approved' : 'pending_approval',
    });
    logger.i("Product $productId approval status set to $isApproved");
  }

  Future<void> rejectProduct(String productId, String reason) async {
    await _firestore.collection('products').doc(productId).update({
      'isApproved': false,
      'status': 'rejected',
      'rejectionReason': reason,
    });
    logger.i("Product $productId rejected. Reason: $reason");
  }

  // --- Cart Management ---
  Future<void> addCartItem(String userId, CartItem item) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(item.productId) // Use productId as doc ID for easy update/removal
        .set(item.toMap());
    logger.i("Cart item ${item.productId} added for user ");
  }

  Future<void> updateCartItemQuantity(
    String userId,
    String productId,
    int quantity,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .update({'quantity': quantity});
    logger.i("Cart item  quantity updated to  for user ");
  }

  Future<void> removeCartItem(String userId, String productId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();
    logger.i("Cart item  removed for user ");
  }

  Stream<List<CartItem>> getUserCart(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => CartItem.fromMap(doc.data())).toList(),
        );
  }

  Future<void> clearUserCart(String userId) async {
    final batch = _firestore.batch();
    final cartItems = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();
    for (var doc in cartItems.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    logger.i("Cart cleared for user ");
  }

  // --- Sustainable Activities ---
  Future<void> addSustainableActivity(SustainableActivity activity) async {
    final docId = activity.id.isEmpty
        ? generateNewDocId('sustainable_activities')
        : activity.id;
    await _firestore
        .collection('sustainable_activities')
        .doc(docId)
        .set(activity.copyWith(id: docId, createdAt: Timestamp.now()).toMap());
    logger.i("Sustainable activity ${activity.title} added with ID: ");
  }

  Future<void> updateSustainableActivity(SustainableActivity activity) async {
    await _firestore
        .collection('sustainable_activities')
        .doc(activity.id)
        .update(activity.toMap());
    logger.i(
      "Sustainable activity ${activity.title} updated with ID: ${activity.id}",
    );
  }

  Future<void> updateSustainableActivityByData(
    String activityId,
    Map<String, dynamic> updateData,
  ) async {
    await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .update(updateData);
    logger.i("Sustainable activity updated with ID: $activityId");
  }

  Future<void> deleteSustainableActivity(String activityId) async {
    await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .delete();
    logger.i("Sustainable activity  deleted.");
  }

  Stream<List<SustainableActivity>> getAllSustainableActivities() {
    return _firestore
        .collection('sustainable_activities')
        .where('isActive', isEqualTo: true)
        .where('submissionStatus', isEqualTo: 'approved')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SustainableActivity.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<SustainableActivity>> getAllSustainableActivitiesForAdmin() {
    return _firestore.collection('sustainable_activities').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => SustainableActivity.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<SustainableActivity?> getSustainableActivityById(
    String activityId,
  ) async {
    final doc = await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .get();
    return doc.exists ? SustainableActivity.fromMap(doc.data()!) : null;
  }

  Future<Map<String, dynamic>?> getSustainableActivityByIdAsMap(
    String activityId,
  ) async {
    final doc = await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .get();
    return doc.exists ? {'id': doc.id, ...doc.data()!} : null;
  }

  Stream<ActivitySummary> getSustainableActivitySummary() {
    return _firestore.collection('sustainable_activities').snapshots().map((
      snapshot,
    ) {
      final totalActivities = snapshot.docs.length;
      final activeActivities =
          snapshot.docs.where((doc) => doc.data()['isActive'] == true).length;
      final completedActivities = snapshot.docs.where((doc) {
        final endDate = (doc.data()['endDate'] as Timestamp?)?.toDate();
        return endDate != null && endDate.isBefore(DateTime.now());
      }).length;
      final upcomingActivities = snapshot.docs.where((doc) {
        final startDate = (doc.data()['startDate'] as Timestamp?)?.toDate();
        return startDate != null && startDate.isAfter(DateTime.now());
      }).length;

      return ActivitySummary(
        totalActivities: totalActivities,
        activeActivities: activeActivities,
        completedActivities: completedActivities,
        upcomingActivities: upcomingActivities,
      );
    });
  }

  Future<void> joinSustainableActivity(String activityId, String userId) async {
    final activityRef =
        _firestore.collection('sustainable_activities').doc(activityId);
    await activityRef.update({
      'participantIds': FieldValue.arrayUnion([userId]),
    });
    logger.i('User  joined activity ');
  }

  Future<bool> hasJoinedSustainableActivity(
    String activityId,
    String userId,
  ) async {
    final doc = await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .get();
    if (doc.exists) {
      final participants = List<String>.from(
        doc.data()?['participantIds'] ?? [],
      );
      return participants.contains(userId);
    }
    return false;
  }

  Stream<List<SustainableActivity>> getJoinedSustainableActivities(
    String userId,
  ) {
    return _firestore
        .collection('sustainable_activities')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SustainableActivity.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<SustainableActivity>> getActivitiesByOrganizer(
    String organizerId,
  ) {
    return _firestore
        .collection('sustainable_activities')
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SustainableActivity.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> toggleActivityActiveStatus(
    String activityId,
    bool isActive,
  ) async {
    await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .update({'isActive': isActive});
  }

  Stream<List<AppUser>> getParticipantsForActivity(String activityId) async* {
    final doc = await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .get();
    if (doc.exists) {
      final participantIds = List<String>.from(
        doc.data()?['participantIds'] ?? [],
      );
      if (participantIds.isNotEmpty) {
        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: participantIds)
            .get();
        yield usersSnapshot.docs
            .map((d) => AppUser.fromMap(d.data(), d.id))
            .toList();
      } else {
        yield [];
      }
    } else {
      yield [];
    }
  }

  // --- News & Articles --- (Commented out until NewsArticle model is available)
  Future<void> addNewsArticle(NewsArticle article) async {
    final docId =
        article.id.isEmpty ? generateNewDocId('news_articles') : article.id;
    await _firestore
        .collection('news_articles')
        .doc(docId)
        .set(article.copyWith(id: docId, createdAt: Timestamp.now()).toMap());
    logger.i("News article ${article.title} added with ID: ");
  }

  Future<void> updateNewsArticle(NewsArticle article) async {
    await _firestore
        .collection('news_articles')
        .doc(article.id)
        .update(article.toMap());
    logger.i("News article ${article.title} updated with ID: ${article.id}");
  }

  Future<void> deleteNewsArticle(String articleId) async {
    await _firestore.collection('news_articles').doc(articleId).delete();
    logger.i("News article  deleted.");
  }

  Stream<List<NewsArticle>> getAllNewsArticles() {
    return _firestore
        .collection('news_articles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NewsArticle.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<NewsArticle?> getNewsArticleById(String articleId) async {
    final doc =
        await _firestore.collection('news_articles').doc(articleId).get();
    return doc.exists ? NewsArticle.fromMap(doc.data()!, doc.id) : null;
  }

  // --- Notifications ---
  Future<void> sendNotification(AppNotification notification) async {
    final docId = notification.id.isEmpty
        ? generateNewDocId('notifications')
        : notification.id;
    await _firestore
        .collection('notifications')
        .doc(docId)
        .set(notification.copyWith(id: docId).toMap());
    logger.i("Notification sent to ${notification.userId} with ID: $docId");
  }

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
    logger.i("Notification $notificationId marked as read");
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
    logger.i("All unread notifications for user $userId marked as read.");
  }

  // --- Categories Management ---
  Future<void> addCategory(Category category) async {
    final docId =
        category.id.isEmpty ? generateNewDocId('categories') : category.id;
    await _firestore
        .collection('categories')
        .doc(docId)
        .set(category.copyWith(id: docId, createdAt: Timestamp.now()).toMap());
    logger.i("Category ${category.name} added with ID: $docId");
  }

  Future<void> updateCategory(Category category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
    logger.i("Category ${category.name} updated with ID: ${category.id}");
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
    logger.i("Category $categoryId deleted");
  }

  Stream<List<Category>> getCategories() {
    return _firestore
        .collection('categories')
        .where('status', isEqualTo: 'active')
        // Removed orderBy to avoid Firebase index requirement
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                // Basic validation before processing
                final data = doc.data();
                return data.containsKey('name') &&
                    data['name']?.toString().trim().isNotEmpty == true;
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id; // Add document ID to data
                  return Category.fromMap(data);
                } catch (e) {
                  // Log error for debugging but don't break the stream
                  _reportErrorStatic(
                      'getCategories_stream_parsing', e, StackTrace.current,
                      context: {'categoryId': doc.id});
                  return null;
                }
              })
              .where((category) => category != null)
              .cast<Category>()
              .toList()
            // Sort in-memory to maintain order without requiring Firebase index
            ..sort((a, b) => a.name.compareTo(b.name)),
        )
        .handleError((error) {
      logger.e("Error fetching categories stream: $error");
      _reportErrorStatic('getCategories_stream', error, StackTrace.current);
      return <Category>[];
    });
  }

  Stream<List<Product>> getProductsByCategoryId(String categoryId) {
    if (categoryId.trim().isEmpty) {
      logger.w('getProductsByCategoryId called with empty categoryId');
      return Stream.value(<Product>[]);
    }

    return _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                // Basic validation before processing
                final data = doc.data();
                return data.containsKey('name') &&
                    data['name']?.toString().trim().isNotEmpty == true &&
                    data.containsKey('price') &&
                    (data['price'] is num && (data['price'] as num) > 0);
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  final product = Product.fromMap(data);
                  return product.isValid ? product : null;
                } catch (e) {
                  _reportErrorStatic(
                      'getProductsByCategoryId_parsing', e, StackTrace.current,
                      context: {'productId': doc.id, 'categoryId': categoryId});
                  return null;
                }
              })
              .where((product) => product != null)
              .cast<Product>()
              .toList(),
        )
        .handleError((error) {
      logger.e("Error fetching products by category $categoryId: $error");
      _reportErrorStatic(
          'getProductsByCategoryId_stream', error, StackTrace.current,
          context: {'categoryId': categoryId});
      return <Product>[];
    });
  }

  Stream<List<Product>> getProductsByEcoLevel(EcoLevel ecoLevel) {
    int minScore, maxScore;
    switch (ecoLevel) {
      case EcoLevel.basic:
        minScore = 20;
        maxScore = 39;
        break;
      case EcoLevel.standard:
        minScore = 40;
        maxScore = 59;
        break;
      case EcoLevel.premium:
        minScore = 60;
        maxScore = 89;
        break;
      case EcoLevel.hero:
        minScore = 90;
        maxScore = 100;
        break;
    }

    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .where('ecoScore', isGreaterThanOrEqualTo: minScore)
        .where('ecoScore', isLessThanOrEqualTo: maxScore)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                // Validate eco score is within expected range
                final data = doc.data();
                final ecoScore = data['ecoScore'];
                return ecoScore is num &&
                    ecoScore >= minScore &&
                    ecoScore <= maxScore &&
                    data.containsKey('name') &&
                    data['name']?.toString().trim().isNotEmpty == true;
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  final product = Product.fromMap(data);
                  return product.isValid ? product : null;
                } catch (e) {
                  _reportErrorStatic(
                      'getProductsByEcoLevel_parsing', e, StackTrace.current,
                      context: {
                        'productId': doc.id,
                        'ecoLevel': ecoLevel.toString()
                      });
                  return null;
                }
              })
              .where((product) => product != null)
              .cast<Product>()
              .toList(),
        )
        .handleError((error) {
      logger.e("Error fetching products by eco level $ecoLevel: $error");
      _reportErrorStatic(
          'getProductsByEcoLevel_stream', error, StackTrace.current,
          context: {'ecoLevel': ecoLevel.toString()});
      return <Product>[];
    });
  }

  // --- Orders Management ---
  static Future<void> addOrder(app_order.Order order) async {
    return await _withRetryStatic('addOrder', () async {
      if (order.id.isEmpty) {
        throw ArgumentError('Order must have an ID');
      }

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('orders').doc(order.id).set(order.toMap());

      final logger = Logger();
      logger.i("Order added with ID: ${order.id}");
    });
  }

  static Future<void> updateOrder(app_order.Order order) async {
    return await _withRetryStatic('updateOrder', () async {
      if (order.id.isEmpty) {
        throw ArgumentError('Order must have an ID for update');
      }

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('orders').doc(order.id).update(order.toMap());

      final logger = Logger();
      logger.i("Order ${order.id} updated");
    });
  }

  Stream<List<app_order.Order>> getOrdersByUserId(String userId) {
    if (userId.trim().isEmpty) {
      return Stream.value(<app_order.Order>[]);
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                // Basic validation
                final data = doc.data();
                return data.containsKey('userId') &&
                    data.containsKey('orderDate');
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return app_order.Order.fromMap(data);
                } catch (e) {
                  _reportErrorStatic(
                      'getOrdersByUserId_parsing', e, StackTrace.current,
                      context: {'orderId': doc.id, 'userId': userId});
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<app_order.Order>()
              .toList(),
        )
        .handleError((error) {
      final logger = Logger();
      logger.e("Error fetching orders for user $userId: $error");
      _reportErrorStatic('getOrdersByUserId_stream', error, StackTrace.current,
          context: {'userId': userId});
      return <app_order.Order>[];
    });
  }

  Stream<List<app_order.Order>> getOrdersBySellerId(String sellerId) {
    if (sellerId.trim().isEmpty) {
      return Stream.value(<app_order.Order>[]);
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                // Basic validation
                final data = doc.data();
                return data.containsKey('sellerIds') &&
                    data.containsKey('orderDate');
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return app_order.Order.fromMap(data);
                } catch (e) {
                  _reportErrorStatic(
                      'getOrdersBySellerId_parsing', e, StackTrace.current,
                      context: {'orderId': doc.id, 'sellerId': sellerId});
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<app_order.Order>()
              .toList(),
        )
        .handleError((error) {
      final logger = Logger();
      logger.e("Error fetching orders for seller $sellerId: $error");
      _reportErrorStatic(
          'getOrdersBySellerId_stream', error, StackTrace.current,
          context: {'sellerId': sellerId});
      return <app_order.Order>[];
    });
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    return await _withRetryStatic('updateOrderStatus', () async {
      if (orderId.trim().isEmpty) {
        throw ArgumentError('Order ID cannot be empty');
      }
      if (status.trim().isEmpty) {
        throw ArgumentError('Status cannot be empty');
      }

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('orders').doc(orderId).update({
        'status': status,
      });

      final logger = Logger();
      logger.i("Order $orderId status updated to $status");
    });
  }

  /// Instance method for updating order status (for testing/mocking)
  Future<void> updateOrderStatusInstance(String orderId, String status) async {
    return await updateOrderStatus(orderId, status);
  }

  /// Instance method for getting seller data (for testing/mocking)
  Future<Map<String, dynamic>?> getSellerData(String sellerId) async {
    try {
      final sellerDoc =
          await _firestore.collection('sellers').doc(sellerId).get();
      if (!sellerDoc.exists) {
        return null;
      }
      return sellerDoc.data();
    } catch (e) {
      logger.e('Error getting seller data: $e');
      return null;
    }
  }

  // --- Investment Projects Management ---
  static Future<void> addInvestmentProject(InvestmentProject project) async {
    return await _withRetryStatic('addInvestmentProject', () async {
      if (project.id.isEmpty) {
        throw ArgumentError('Investment project must have an ID');
      }

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('investment_projects')
          .doc(project.id)
          .set(project.copyWith(createdAt: Timestamp.now()).toMap());

      final logger = Logger();
      logger.i(
          "Investment project ${project.title} added with ID: ${project.id}");
    });
  }

  static Future<void> updateInvestmentProject(InvestmentProject project) async {
    return await _withRetryStatic('updateInvestmentProject', () async {
      if (project.id.isEmpty) {
        throw ArgumentError('Investment project must have an ID for update');
      }

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('investment_projects')
          .doc(project.id)
          .update(project.toMap());

      final logger = Logger();
      logger.i("Investment project ${project.title} updated");
    });
  }

  static Future<void> deleteInvestmentProject(String projectId) async {
    return await _withRetryStatic('deleteInvestmentProject', () async {
      if (projectId.trim().isEmpty) {
        throw ArgumentError('Project ID cannot be empty');
      }

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('investment_projects').doc(projectId).delete();

      final logger = Logger();
      logger.i("Investment project $projectId deleted");
    });
  }

  Stream<List<InvestmentProject>> getApprovedInvestmentProjects() {
    return FirebaseFirestore.instance
        .collection('investment_projects')
        .where(
          'submissionStatus',
          isEqualTo: ProjectSubmissionStatus.approved.name,
        )
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                // Basic validation
                final data = doc.data();
                return data.containsKey('title') &&
                    data.containsKey('submissionStatus') &&
                    data.containsKey('isActive');
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return InvestmentProject.fromMap(data);
                } catch (e) {
                  _reportErrorStatic('getApprovedInvestmentProjects_parsing', e,
                      StackTrace.current,
                      context: {'projectId': doc.id});
                  return null;
                }
              })
              .where((project) => project != null)
              .cast<InvestmentProject>()
              .toList(),
        )
        .handleError((error) {
      final logger = Logger();
      logger.e("Error fetching approved investment projects: $error");
      _reportErrorStatic(
          'getApprovedInvestmentProjects_stream', error, StackTrace.current);
      return <InvestmentProject>[];
    });
  }

  Stream<List<InvestmentProject>> getAllInvestmentProjectsForAdmin() {
    return FirebaseFirestore.instance
        .collection('investment_projects')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                // Basic validation
                final data = doc.data();
                return data.containsKey('title');
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return InvestmentProject.fromMap(data);
                } catch (e) {
                  _reportErrorStatic('getAllInvestmentProjectsForAdmin_parsing',
                      e, StackTrace.current,
                      context: {'projectId': doc.id});
                  return null;
                }
              })
              .where((project) => project != null)
              .cast<InvestmentProject>()
              .toList(),
        )
        .handleError((error) {
      final logger = Logger();
      logger.e("Error fetching all investment projects for admin: $error");
      _reportErrorStatic(
          'getAllInvestmentProjectsForAdmin_stream', error, StackTrace.current);
      return <InvestmentProject>[];
    });
  }

  Stream<List<InvestmentProject>> getInvestmentProjectsByOwnerId(
    String ownerId,
  ) {
    if (ownerId.trim().isEmpty) {
      return Stream.value(<InvestmentProject>[]);
    }

    return FirebaseFirestore.instance
        .collection('investment_projects')
        .where('projectOwnerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                // Basic validation
                final data = doc.data();
                return data.containsKey('projectOwnerId') &&
                    data.containsKey('title');
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return InvestmentProject.fromMap(data);
                } catch (e) {
                  _reportErrorStatic('getInvestmentProjectsByOwnerId_parsing',
                      e, StackTrace.current,
                      context: {'projectId': doc.id, 'ownerId': ownerId});
                  return null;
                }
              })
              .where((project) => project != null)
              .cast<InvestmentProject>()
              .toList(),
        )
        .handleError((error) {
      final logger = Logger();
      logger.e("Error fetching investment projects for owner $ownerId: $error");
      _reportErrorStatic(
          'getInvestmentProjectsByOwnerId_stream', error, StackTrace.current,
          context: {'ownerId': ownerId});
      return <InvestmentProject>[];
    });
  }

  static Future<void> approveInvestmentProject(String projectId) async {
    return await _withRetryStatic('approveInvestmentProject', () async {
      if (projectId.trim().isEmpty) {
        throw ArgumentError('Project ID cannot be empty');
      }

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('investment_projects').doc(projectId).update({
        'submissionStatus': ProjectSubmissionStatus.approved.name,
        'isActive': true,
      });

      final logger = Logger();
      logger.i("Investment project $projectId approved");
    });
  }

  Future<void> rejectInvestmentProject(String projectId, String reason) async {
    await _firestore.collection('investment_projects').doc(projectId).update({
      'submissionStatus': ProjectSubmissionStatus.rejected.name,
      'rejectionReason': reason,
      'isActive': false,
    });
    logger.i("Investment project $projectId rejected: $reason");
  }

  // --- Image Upload ---
  Future<String> uploadImage(
    String folderPath,
    String filePath, {
    String? fileName,
  }) async {
    try {
      final file = File(filePath);
      final String uploadFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$folderPath/$uploadFileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      logger.i("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      logger.e("Error uploading image: $e");
      rethrow;
    }
  }

  Future<String> uploadImageBytes(
    String folderPath,
    String fileName,
    Uint8List bytes,
  ) async {
    try {
      final ref = _storage.ref().child('$folderPath/$fileName');
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      logger.i("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      logger.e("Error uploading image bytes: $e");
      rethrow;
    }
  }

  // --- Upload Methods ---
  Future<String> uploadWebImage(
    Uint8List imageBytes,
    String storagePath,
  ) async {
    try {
      logger.i("Attempting to upload web image to path: $storagePath");
      logger.i("Current user: ${_auth.currentUser?.uid}");

      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putData(imageBytes);
      final downloadURL = await uploadTask.ref.getDownloadURL();
      logger.i("Web image uploaded successfully: $downloadURL");
      return downloadURL;
    } catch (e) {
      logger.e("Error uploading web image to path $storagePath: $e");
      rethrow;
    }
  }

  Future<String> uploadImageFile(File imageFile, String storagePath) async {
    try {
      logger.i("Attempting to upload image file to path: $storagePath");
      logger.i("Current user: ${_auth.currentUser?.uid}");

      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(imageFile);
      final downloadURL = await uploadTask.ref.getDownloadURL();
      logger.i("Image file uploaded successfully: $downloadURL");
      return downloadURL;
    } catch (e) {
      logger.e("Error uploading image file to path $storagePath: $e");
      rethrow;
    }
  }

  Future<String> uploadVideoFile(File videoFile, String fileName) async {
    try {
      final ref = _storage.ref().child('videos/$fileName');
      final uploadTask = await ref.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      final downloadURL = await uploadTask.ref.getDownloadURL();
      logger.i("Video file uploaded: $downloadURL");
      return downloadURL;
    } catch (e) {
      logger.e("Error uploading video file: $e");
      rethrow;
    }
  }

  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      logger.i("Image deleted: $imageUrl");
    } catch (e) {
      logger.e("Error deleting image: $e");
      rethrow;
    }
  }

  // --- Order Methods ---
  Future<void> placeOrder(app_order.Order order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toMap());
      logger.i("Order placed: ${order.id}");
    } catch (e) {
      logger.e("Error placing order: $e");
      rethrow;
    }
  }

  Stream<List<app_order.Order>> getAllOrders() {
    return _firestore.collection('orders').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => app_order.Order.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<int> getTotalOrdersCount() async {
    final snapshot = await _firestore.collection('orders').get();
    return snapshot.docs.length;
  }

  Future<void> updateOrderStatusWithSlip(
    String orderId,
    String status,
    String? slipImageUrl,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'paymentSlipUrl': slipImageUrl,
        'updatedAt': Timestamp.now(),
      });
      logger.i("Order status updated: $orderId");
    } catch (e) {
      logger.e("Error updating order status: $e");
      rethrow;
    }
  }

  // --- Enhanced Product Approval Methods ---
  Future<void> approveProductWithDetails(
    String productId,
    int ecoScore, {
    String? categoryId,
    String? categoryName,
  }) async {
    final Map<String, dynamic> updates = {
      'status': 'approved',
      'isApproved': true,
      'ecoScore': ecoScore,
      'approvedAt': FieldValue.serverTimestamp(),
    };

    if (categoryId != null) updates['categoryId'] = categoryId;
    if (categoryName != null) updates['categoryName'] = categoryName;

    await _firestore.collection('products').doc(productId).update(updates);
    logger.i("Product $productId approved with ecoScore: $ecoScore");
  }

  // --- Product Status Queries ---
  Stream<List<Product>> getPendingProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'pending_approval')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList(),
        );
  }

  // --- Homepage Settings ---
  Future<HomepageSettings> getHomepageSettings() async {
    try {
      final doc =
          await _firestore.collection('app_settings').doc('homepage').get();
      if (doc.exists) {
        return HomepageSettings.fromMap(doc.data()!);
      } else {
        return HomepageSettings.defaultSettings();
      }
    } catch (e) {
      logger.e("Error getting homepage settings: $e");
      return HomepageSettings.defaultSettings();
    }
  }

  Future<void> updateHomepageSettings(HomepageSettings settings) async {
    await _firestore
        .collection('app_settings')
        .doc('homepage')
        .set(settings.toMap());
    logger.i("Homepage settings updated");
  }

  // --- Activity Approval Methods ---
  Future<void> approveSustainableActivity(String activityId) async {
    await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .update({'submissionStatus': 'approved', 'isActive': true});
    logger.i("Sustainable activity $activityId approved");

    // Fetch the approved activity details
    final activityDoc = await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .get();
    if (activityDoc.exists) {
      final activityData = activityDoc.data()!;
      // Create a NewsArticle for the community feed
      final newsArticle = NewsArticle(
        id: '', // Let Firestore generate ID
        title: activityData['title'] ?? 'กิจกรรมใหม่',
        summary: activityData['description'] ?? '',
        imageUrl: activityData['imageUrl'],
        originalUrl: null,
        source: activityData['organizerName'] ?? '',
        publishedDate: DateTime.now(),
        content: activityData['description'] ?? '',
      );
      await addNewsArticle(newsArticle);
      logger.i("Community feed post created for approved activity $activityId");
    }
  }

  Future<void> rejectSustainableActivity(
    String activityId,
    String reason,
  ) async {
    await _firestore
        .collection('sustainable_activities')
        .doc(activityId)
        .update({
      'submissionStatus': 'rejected',
      'rejectionReason': reason,
      'isActive': false,
    });
    logger.i("Sustainable activity $activityId rejected: $reason");
  }

  Stream<List<SustainableActivity>> getPendingSustainableActivities() {
    return _firestore
        .collection('sustainable_activities')
        .where('submissionStatus', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SustainableActivity.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<InvestmentProject>> getPendingInvestmentProjects() {
    return _firestore
        .collection('investment_projects')
        .where(
          'submissionStatus',
          isEqualTo: ProjectSubmissionStatus.pending.name,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvestmentProject.fromMap(doc.data()))
              .toList(),
        );
  }

  // --- Promotion Methods ---
  Stream<List<UnifiedPromotion>> getActivePromotions() {
    return _firestore.collection('promotions').snapshots().map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => UnifiedPromotion.fromMap(doc.data(), doc.id))
          .where(
            (promotion) =>
                promotion.isValid &&
                (promotion.endDate == null || promotion.endDate!.isAfter(now)),
          )
          .toList();
    }).handleError((error) {
      logger.e("Error fetching active promotions: $error");
      return <UnifiedPromotion>[];
    });
  }

  Future<void> createPromotion(UnifiedPromotion promotion) async {
    try {
      await _firestore
          .collection('promotions')
          .doc(promotion.id)
          .set(promotion.toMap());
      logger.i("Promotion created: ${promotion.id}");
    } catch (e) {
      logger.e("Error creating promotion: $e");
      rethrow;
    }
  }

  Future<void> updatePromotion(UnifiedPromotion promotion) async {
    try {
      await _firestore
          .collection('promotions')
          .doc(promotion.id)
          .update(promotion.toMap());
      logger.i("Promotion updated: ${promotion.id}");
    } catch (e) {
      logger.e("Error updating promotion: $e");
      rethrow;
    }
  }

  Future<void> deletePromotion(String promotionId) async {
    try {
      await _firestore.collection('promotions').doc(promotionId).delete();
      logger.i("Promotion deleted: $promotionId");
    } catch (e) {
      logger.e("Error deleting promotion: $e");
      rethrow;
    }
  }

  Stream<List<UnifiedPromotion>> getPromotions() {
    return _firestore.collection('promotions').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UnifiedPromotion.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addPromotion(UnifiedPromotion promotion) async {
    try {
      await _firestore
          .collection('promotions')
          .doc(promotion.id)
          .set(promotion.toMap());
      logger.i("Promotion added: ${promotion.id}");
    } catch (e) {
      logger.e("Error adding promotion: $e");
      rethrow;
    }
  }

  // --- User and Product Count Methods ---
  Future<int> getTotalUsersCount() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> getTotalProductsCount() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.length;
  }

  Future<int> getTotalApprovedProductsCount() async {
    final snapshot = await _firestore
        .collection('products')
        .where('isApproved', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Stream<int> getPendingProductsCountStream() {
    return _firestore
        .collection('products')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Product>> getPendingApprovalProducts() {
    return _firestore
        .collection('products')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList(),
        );
  }

  // --- Advanced AI Search Methods ---
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection('products')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map(
      (snapshot) {
        final products =
            snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();

        // 🧠 เรียกใช้ระบบค้นหา AI แบบใหม่
        return _executeAdvancedAISearch(products, query);
      },
    );
  }

  // 🤖 ระบบค้นหา AI ฉลาดที่สุด - ควบคุมได้ดี
  List<Product> _executeAdvancedAISearch(List<Product> products, String query) {
    if (query.trim().isEmpty) return products;

    final searchQuery = query.toLowerCase().trim();
    final searchResults = <ProductSearchResult>[];

    for (final product in products) {
      final score = _calculateIntelligentScore(product, searchQuery);
      if (score > 0) {
        searchResults.add(ProductSearchResult(product, score));
      }
    }

    // 🎯 เรียงลำดับตามคะแนน AI
    searchResults.sort((a, b) => b.score.compareTo(a.score));

    return searchResults.map((result) => result.product).toList();
  }

  // 🧠 คำนวณคะแนนความฉลาด AI
  double _calculateIntelligentScore(Product product, String query) {
    final name = product.name.toLowerCase();
    final description = product.description.toLowerCase();
    final fullText = '$name $description';

    double totalScore = 0.0;

    // ✨ Level 1: การตรงกันแบบสมบูรณ์
    totalScore += _exactMatchScore(name, description, query);

    // 🎯 Level 2: การค้นหาแบบเริ่มต้นคำ
    totalScore += _startWordScore(name, description, query);

    // 🔍 Level 3: การค้นหาแบบมีคำอยู่ในข้อความ
    totalScore += _containsScore(name, description, query);

    // 🧬 Level 4: การวิเคราะห์ตัวอักษร
    totalScore += _characterAnalysisScore(fullText, query);

    // 🌏 Level 5: การแปลภาษาไทย-อังกฤษ
    totalScore += _languageTranslationScore(fullText, query);

    // 🎨 Level 6: การเข้าใจบริบท
    totalScore += _contextualScore(product, query);

    // 🔤 Level 7: Fuzzy Matching
    totalScore += _fuzzyMatchingScore(name, description, query);

    // ⚡ Level 8: คำหลัก Keywords
    totalScore += _keywordMatchingScore(fullText, query);

    return totalScore;
  }

  // ✨ Level 1: การตรงกันแบบสมบูรณ์ (100 คะแนน)
  double _exactMatchScore(String name, String description, String query) {
    double score = 0.0;

    if (name == query) {
      score += 100.0;
    } else if (name.contains(query)) {
      score += 80.0;
    }

    if (description.contains(query)) {
      score += 60.0;
    }

    return score;
  }

  // 🎯 Level 2: การค้นหาแบบเริ่มต้นคำ (70 คะแนน)
  double _startWordScore(String name, String description, String query) {
    double score = 0.0;

    final nameWords = name.split(' ');
    final descWords = description.split(' ');

    for (final word in nameWords) {
      if (word.startsWith(query)) score += 70.0;
    }

    for (final word in descWords) {
      if (word.startsWith(query)) score += 50.0;
    }

    return score;
  }

  // 🔍 Level 3: การค้นหาแบบมีคำอยู่ในข้อความ (50 คะแนน)
  double _containsScore(String name, String description, String query) {
    double score = 0.0;

    if (name.contains(query)) score += 50.0;
    if (description.contains(query)) score += 30.0;

    return score;
  }

  // 🧬 Level 4: การวิเคราะห์ตัวอักษร (40 คะแนน)
  double _characterAnalysisScore(String text, String query) {
    if (query.isEmpty || text.isEmpty) return 0.0;

    int matchedChars = 0;
    for (int i = 0; i < query.length; i++) {
      if (text.contains(query[i])) {
        matchedChars++;
      }
    }

    final ratio = matchedChars / query.length;
    return ratio * 40.0;
  }

  // 🌏 Level 5: การแปลภาษาไทย-อังกฤษ (60 คะแนน)
  double _languageTranslationScore(String text, String query) {
    final translations = {
      // ไทย -> อังกฤษ
      'อ่าง': ['basin', 'sink', 'bowl'],
      'ล้าง': ['wash', 'clean', 'rinse'],
      'มือ': ['hand', 'hands'],
      'น้ำ': ['water'],
      'ต้นไม้': ['tree', 'plant'],
      'กระถาง': ['pot', 'planter'],
      'เก้าอี้': ['chair', 'seat'],
      'รีไซเคิล': ['recycle', 'eco'],
      // อังกฤษ -> ไทย
      'basin': ['อ่าง', 'ล้าง'],
      'sink': ['อ่าง', 'ล้าง'],
      'wash': ['ล้าง'],
      'hand': ['มือ'],
      'tree': ['ต้นไม้'],
      'plant': ['ต้นไม้', 'ปลูก'],
      'pot': ['กระถาง'],
      'chair': ['เก้าอี้'],
      'recycle': ['รีไซเคิล'],
    };

    double score = 0.0;
    for (final entry in translations.entries) {
      if (query.contains(entry.key)) {
        for (final translation in entry.value) {
          if (text.contains(translation)) {
            score += 60.0;
            break; // หยุดเมื่อเจอแปลแล้ว
          }
        }
      }
    }

    return score;
  }

  // 🎨 Level 6: การเข้าใจบริบท (45 คะแนน)
  double _contextualScore(Product product, String query) {
    final productText = '${product.name} ${product.description}'.toLowerCase();
    double score = 0.0;

    // วิเคราะห์ความต้องการ
    final intents = {
      'ล้าง': ['อ่าง', 'ล้างมือ', 'ทำความสะอาด', 'basin', 'wash'],
      'ปลูก': ['กระถาง', 'ต้นไม้', 'plant', 'pot'],
      'นั่ง': ['เก้าอี้', 'chair', 'seat'],
      'รักษ์': ['สิ่งแวดล้อม', 'รีไซเคิล', 'eco', 'green'],
    };

    for (final intent in intents.entries) {
      if (query.contains(intent.key)) {
        for (final keyword in intent.value) {
          if (productText.contains(keyword)) {
            score += 45.0;
            break;
          }
        }
      }
    }

    return score;
  }

  // 🔤 Level 7: Fuzzy Matching (35 คะแนน)
  double _fuzzyMatchingScore(String name, String description, String query) {
    double score = 0.0;

    final nameWords = name.split(' ');
    final descWords = description.split(' ');

    for (final word in nameWords) {
      final similarity = _calculateLevenshteinSimilarity(word, query);
      if (similarity > 0.6) score += similarity * 35.0;
    }

    for (final word in descWords) {
      final similarity = _calculateLevenshteinSimilarity(word, query);
      if (similarity > 0.6) score += similarity * 25.0;
    }

    return score;
  }

  // ⚡ Level 8: คำหลัก Keywords (55 คะแนน)
  double _keywordMatchingScore(String text, String query) {
    final keywords = _extractKeywords(text);
    double score = 0.0;

    for (final keyword in keywords) {
      if (keyword.contains(query) || query.contains(keyword)) {
        score += 55.0;
      }
    }

    return score;
  }

  // 🔧 Helper Methods สำหรับ AI

  double _calculateLevenshteinSimilarity(String s1, String s2) {
    if (s1.length < s2.length) {
      final temp = s1;
      s1 = s2;
      s2 = temp;
    }

    final bigLen = s1.length;
    if (bigLen == 0) return 1.0;

    final distance = _levenshteinDistance(s1, s2);
    return (bigLen - distance) / bigLen;
  }

  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  List<String> _extractKeywords(String text) {
    final words = text.split(' ').where((word) => word.length > 2).toList();
    final stopWords = [
      'และ',
      'หรือ',
      'ใน',
      'จาก',
      'ที่',
      'เพื่อ',
      'กับ',
      'แต่'
    ];

    return words.where((word) => !stopWords.contains(word)).toList();
  }

  // --- Investment Methods ---
  Future<InvestmentSummary> getInvestmentProjectSummary() async {
    try {
      final projectsSnapshot =
          await _firestore.collection('investment_projects').get();
      final totalProjects = projectsSnapshot.docs.length;

      double totalAmountRaised = 0;
      int activeProjects = 0;

      for (var doc in projectsSnapshot.docs) {
        final data = doc.data();
        totalAmountRaised += (data['currentAmount'] as num?)?.toDouble() ?? 0;
        if ((data['isActive'] as bool?) == true) {
          activeProjects++;
        }
      }

      return InvestmentSummary(
        totalProjects: totalProjects,
        activeProjects: activeProjects,
        totalAmountRaised: totalAmountRaised,
        upcomingActivities: 5, // Mock value for upcoming activities
      );
    } catch (e) {
      logger.e("Error getting investment summary: $e");
      rethrow;
    }
  }

  Stream<List<InvestmentProject>> getInvestmentProjects({
    String? sortBy,
    bool descending = false,
    bool? isActive,
  }) {
    Query query = _firestore.collection('investment_projects');

    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    if (sortBy != null) {
      query = query.orderBy(sortBy, descending: descending);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => InvestmentProject.fromMap(
                    doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<InvestmentProject?> getInvestmentProjectById(String projectId) async {
    try {
      final doc = await _firestore
          .collection('investment_projects')
          .doc(projectId)
          .get();
      if (doc.exists) {
        return InvestmentProject.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      logger.e("Error getting investment project: $e");
      rethrow;
    }
  }

  Future<void> investInProject(
    String projectId,
    String userId,
    double amount,
  ) async {
    try {
      final batch = _firestore.batch();

      // Get project details first
      final projectDoc = await _firestore
          .collection('investment_projects')
          .doc(projectId)
          .get();
      final projectData = projectDoc.data();
      final projectTitle =
          projectData?['title'] as String? ?? 'Unknown Project';

      // Update project current amount
      final projectRef =
          _firestore.collection('investment_projects').doc(projectId);
      batch.update(projectRef, {
        'currentAmount': FieldValue.increment(amount),
        'investorCount': FieldValue.increment(1),
      });

      // Add user investment record
      final userInvestmentRef = _firestore.collection('user_investments').doc();
      final userInvestment = UserInvestment(
        id: userInvestmentRef.id,
        userId: userId,
        projectId: projectId,
        projectTitle: projectTitle,
        amount: amount,
        investedAt: Timestamp.now(),
      );
      batch.set(userInvestmentRef, userInvestment.toMap());

      await batch.commit();
      logger.i("Investment successful: $projectId");
    } catch (e) {
      logger.e("Error investing in project: $e");
      rethrow;
    }
  }

  Future<void> buyMoreInvestment(String investmentId, double amount) async {
    try {
      await _firestore.collection('user_investments').doc(investmentId).update({
        'amount': FieldValue.increment(amount),
        'updatedAt': Timestamp.now(),
      });
      logger.i("Investment increased: $investmentId");
    } catch (e) {
      logger.e("Error buying more investment: $e");
      rethrow;
    }
  }

  Future<void> sellInvestment(String investmentId) async {
    try {
      await _firestore.collection('user_investments').doc(investmentId).update({
        'status': 'sold',
        'soldAt': Timestamp.now(),
      });
      logger.i("Investment sold: $investmentId");
    } catch (e) {
      logger.e("Error selling investment: $e");
      rethrow;
    }
  }

  Stream<List<UserInvestment>> getUserInvestments(String userId) {
    return _firestore
        .collection('user_investments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserInvestment.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<InvestmentProject>> getProjectsByProjectOwner(String ownerId) {
    return _firestore
        .collection('investment_projects')
        .where('projectOwnerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvestmentProject.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> toggleInvestmentProjectActiveStatus(
    String projectId,
    bool isActive,
  ) async {
    try {
      await _firestore.collection('investment_projects').doc(projectId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      logger.i("Project status updated: $projectId");
    } catch (e) {
      logger.e("Error updating project status: $e");
      rethrow;
    }
  }

  // --- Theme and App Settings Methods ---
  Stream<Map<String, dynamic>?> streamThemeSettingsDocument() {
    return _firestore
        .collection('app_settings')
        .doc('theme')
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  Future<void> updateThemeSettingsDocument(
    Map<String, dynamic> themeData,
  ) async {
    try {
      await _firestore
          .collection('app_settings')
          .doc('theme')
          .set(themeData, SetOptions(merge: true));
      logger.i("Theme settings updated");
    } catch (e) {
      logger.e("Error updating theme settings: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getAppSettingsDocument() async {
    try {
      final doc =
          await _firestore.collection('app_settings').doc('general').get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      logger.e("Error getting app settings: $e");
      rethrow;
    }
  }

  Future<void> updateAppSettingsDocument(Map<String, dynamic> settings) async {
    try {
      await _firestore
          .collection('app_settings')
          .doc('general')
          .set(settings, SetOptions(merge: true));
      logger.i("App settings updated");
    } catch (e) {
      logger.e("Error updating app settings: $e");
      rethrow;
    }
  }

  // --- Notification Methods ---
  Future<void> addNotification(AppNotification notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
      logger.i("Notification added: ${notification.id}");
    } catch (e) {
      logger.e("Error adding notification: $e");
      rethrow;
    }
  }

  // --- Static Page Methods ---
  Future<StaticPage?> getStaticPage(String pageId) async {
    try {
      final doc = await _firestore.collection('static_pages').doc(pageId).get();
      if (doc.exists) {
        return StaticPage.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      logger.e("Error getting static page: $e");
      rethrow;
    }
  }

  Stream<List<StaticPage>> getStaticPages() {
    return _firestore.collection('static_pages').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => StaticPage.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> saveStaticPage(StaticPage page) async {
    try {
      await _firestore
          .collection('static_pages')
          .doc(page.id)
          .set(page.toMap());
      logger.i("Static page saved: ${page.id}");
    } catch (e) {
      logger.e("Error saving static page: $e");
      rethrow;
    }
  }

  Future<void> deleteStaticPage(String pageId) async {
    try {
      await _firestore.collection('static_pages').doc(pageId).delete();
      logger.i("Static page deleted: $pageId");
    } catch (e) {
      logger.e("Error deleting static page: $e");
      rethrow;
    }
  }

  // --- Activity Reports Methods ---
  Stream<List<Map<String, dynamic>>> getAllActivityReports() {
    return _firestore.collection('activity_reports').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<void> updateActivityReport(
    String reportId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection('activity_reports')
          .doc(reportId)
          .update(data);
      logger.i("Activity report updated: $reportId");
    } catch (e) {
      logger.e("Error updating activity report: $e");
      rethrow;
    }
  }

  Future<void> addActivityReport(Map<String, dynamic> reportData) async {
    try {
      await _firestore.collection('activity_reports').add(reportData);
      logger.i("Activity report added");
    } catch (e) {
      logger.e("Error adding activity report: $e");
      rethrow;
    }
  }

  // --- Activity Reviews Methods ---
  Stream<List<Map<String, dynamic>>> getAllActivityReviews() {
    return _firestore.collection('activity_reviews').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<void> deleteActivityReview(String reviewId) async {
    try {
      await _firestore.collection('activity_reviews').doc(reviewId).delete();
      logger.i("Activity review deleted: $reviewId");
    } catch (e) {
      logger.e("Error deleting activity review: $e");
      rethrow;
    }
  }

  Future<void> addActivityReview(Map<String, dynamic> reviewData) async {
    try {
      await _firestore.collection('activity_reviews').add(reviewData);
      logger.i("Activity review added");
    } catch (e) {
      logger.e("Error adding activity review: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReviewsForActivity(
    String activityId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('activity_reviews')
          .where('activityId', isEqualTo: activityId)
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      logger.e("Error getting reviews for activity: $e");
      rethrow;
    }
  }

  // --- Sustainable Activities Methods ---
  Future<List<Map<String, dynamic>>> getSustainableActivities() async {
    try {
      final snapshot =
          await _firestore.collection('sustainable_activities').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      logger.e("Error getting sustainable activities: $e");
      rethrow;
    }
  }

  // --- Chat Methods ---
  Stream<List<Map<String, dynamic>>> streamChatRoomsForUser(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<void> markChatRoomAsRead(String chatRoomId, String userId) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'unreadBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      logger.e("Error marking chat room as read: $e");
      rethrow;
    }
  }

  Future<void> sendMessage(
    String chatRoomId,
    Map<String, dynamic> messageData,
  ) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(messageData);

      // Update last message in chat room
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': messageData['text'],
        'lastMessageTime': messageData['timestamp'],
      });
    } catch (e) {
      logger.e("Error sending message: $e");
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // --- Shipping Address Methods ---
  Future<Map<String, dynamic>?> getUserShippingAddress(String userId) async {
    try {
      final doc =
          await _firestore.collection('shipping_addresses').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      logger.e("Error getting user shipping address: $e");
      rethrow;
    }
  }

  Future<void> saveUserShippingAddress(
    String userId,
    Map<String, dynamic> addressData,
  ) async {
    try {
      await _firestore
          .collection('shipping_addresses')
          .doc(userId)
          .set(addressData);
      logger.i("Shipping address saved for user: $userId");
    } catch (e) {
      logger.e("Error saving shipping address: $e");
      rethrow;
    }
  }

  // --- Review Methods ---
  Future<void> addReview(Map<String, dynamic> reviewData) async {
    try {
      await _firestore.collection('reviews').add(reviewData);
      logger.i("Review added");
    } catch (e) {
      logger.e("Error adding review: $e");
      rethrow;
    }
  }

  Future<bool> hasUserReviewedProductInOrder(
    String userId,
    String productId,
    String orderId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('orderId', isEqualTo: orderId)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      logger.e("Error checking user review: $e");
      return false;
    }
  }

  // --- Seller Request Methods ---
  Future<void> requestToBeSeller(Map<String, dynamic> requestData) async {
    try {
      await _firestore.collection('seller_requests').add(requestData);
      logger.i("Seller request submitted");
    } catch (e) {
      logger.e("Error submitting seller request: $e");
      rethrow;
    }
  }

  // --- Project Questions and Updates ---
  Future<void> addProjectQuestion(Map<String, dynamic> questionData) async {
    try {
      await _firestore.collection('project_questions').add(questionData);
      logger.i("Project question added");
    } catch (e) {
      logger.e("Error adding project question: $e");
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getProjectQuestions(String projectId) {
    return _firestore
        .collection('project_questions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<void> answerProjectQuestion(String questionId, String answer) async {
    try {
      await _firestore.collection('project_questions').doc(questionId).update({
        'answer': answer,
        'answeredAt': FieldValue.serverTimestamp(),
      });
      logger.i("Project question answered: $questionId");
    } catch (e) {
      logger.e("Error answering project question: $e");
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getProjectUpdates(String projectId) {
    return _firestore
        .collection('project_updates')
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<void> addProjectUpdate(Map<String, dynamic> updateData) async {
    try {
      await _firestore.collection('project_updates').add(updateData);
      logger.i("Project update added");
    } catch (e) {
      logger.e("Error adding project update: $e");
      rethrow;
    }
  }

  // --- Mock QR Code Generation ---
  Future<String> generateMockQrCode() async {
    // This is a mock implementation
    // In a real app, you would generate actual QR codes
    return 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=payment_confirmation_${DateTime.now().millisecondsSinceEpoch}';
  }

  // --- Dynamic App Configuration Methods ---
  Future<Map<String, dynamic>?> getDynamicAppConfig() async {
    try {
      final doc =
          await _firestore.collection('app_settings').doc('app_config').get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      } else {
        logger.w("Dynamic app config document doesn't exist, creating default");
        return _createDefaultAppConfig();
      }
    } catch (e) {
      logger.e("Error getting dynamic app config: $e");
      // Return default config instead of null
      return _createDefaultAppConfig();
    }
  }

  Map<String, dynamic> _createDefaultAppConfig() {
    return {
      'id': 'main',
      'appName': 'Green Market',
      'appTagline': 'ตลาดออนไลน์เพื่อสิ่งแวดล้อม',
      'logoUrl': '',
      'faviconUrl': '',
      'heroImageUrl': '',
      'heroTitle': 'ยินดีต้อนรับสู่ Green Market',
      'heroSubtitle': 'แหล่งรวมสินค้าเพื่อสิ่งแวดล้อม',

      // Colors (using default teal theme)
      'primaryColorValue': 0xFF00695C,
      'secondaryColorValue': 0xFF26A69A,
      'accentColorValue': 0xFF4DB6AC,
      'backgroundColorValue': 0xFFF5F5F5,
      'surfaceColorValue': 0xFFFFFFFF,
      'errorColorValue': 0xFFE53E3E,
      'successColorValue': 0xFF38A169,
      'warningColorValue': 0xFFD69E2E,
      'infoColorValue': 0xFF3182CE,

      // Typography
      'primaryFontFamily': 'Sarabun',
      'secondaryFontFamily': 'Sarabun',
      'baseFontSize': 14.0,
      'titleFontSize': 18.0,
      'headingFontSize': 24.0,
      'captionFontSize': 12.0,

      // Layout
      'borderRadius': 8.0,
      'cardElevation': 2.0,
      'buttonHeight': 48.0,
      'inputHeight': 56.0,
      'spacing': 16.0,
      'padding': 16.0,

      // Feature toggles
      'enableDarkMode': true,
      'enableNotifications': true,
      'enableChat': true,
      'enableInvestments': true,
      'enableSustainableActivities': true,
      'enableReviews': true,
      'enablePromotions': true,
      'enableMultiLanguage': false,
      'enableGoogleSignIn': false,
      'enableFacebookSignIn': false,
      'enableAppleSignIn': false,
      'enableBiometricAuth': false,
      'enableOfflineMode': false,
      'enablePushNotifications': true,
      'enableEmailNotifications': true,
      'enableSMSNotifications': false,
      'enableLocationServices': false,
      'enableAnalytics': true,
      'enableCrashReporting': true,
      'enableDebugging': true,
      'enableMaintenanceMode': false,

      // Static texts
      'staticTexts': {
        'welcome_message': 'ยินดีต้อนรับ',
        'login_title': 'เข้าสู่ระบบ',
        'register_title': 'สมัครสมาชิก',
        'market_title': 'ตลาด',
        'cart_title': 'ตะกร้าสินค้า',
        'orders_title': 'คำสั่งซื้อ',
        'profile_title': 'โปรไฟล์',
        'settings_title': 'ตั้งค่า',
      },

      // Error/Success messages
      'errorMessages': {
        'network_error': 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        'login_failed': 'การเข้าสู่ระบบล้มเหลว',
        'registration_failed': 'การสมัครสมาชิกล้มเหลว',
        'generic_error': 'เกิดข้อผิดพลาด กรุณาลองใหม่',
      },

      'successMessages': {
        'login_success': 'เข้าสู่ระบบสำเร็จ',
        'registration_success': 'สมัครสมาชิกสำเร็จ',
        'update_success': 'อัปเดตข้อมูลสำเร็จ',
        'save_success': 'บันทึกข้อมูลสำเร็จ',
      },

      // Form labels/placeholders
      'labels': {
        'email': 'อีเมล',
        'password': 'รหัสผ่าน',
        'name': 'ชื่อ',
        'phone': 'เบอร์โทรศัพท์',
        'address': 'ที่อยู่',
      },

      'placeholders': {
        'enter_email': 'กรอกอีเมล',
        'enter_password': 'กรอกรหัสผ่าน',
        'enter_name': 'กรอกชื่อ',
        'enter_phone': 'กรอกเบอร์โทรศัพท์',
        'enter_address': 'กรอกที่อยู่',
      },

      // Button texts
      'buttonTexts': {
        'login': 'เข้าสู่ระบบ',
        'register': 'สมัครสมาชิก',
        'save': 'บันทึก',
        'cancel': 'ยกเลิก',
        'submit': 'ส่ง',
        'confirm': 'ยืนยัน',
        'delete': 'ลบ',
        'edit': 'แก้ไข',
        'add': 'เพิ่ม',
        'view': 'ดู',
        'buy_now': 'ซื้อเลย',
        'add_to_cart': 'เพิ่มลงตะกร้า',
      },

      // Don't include timestamp fields that cause parsing errors
      // 'createdAt': DateTime.now().millisecondsSinceEpoch,
      // 'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<void> updateDynamicAppConfig(dynamic config) async {
    try {
      Map<String, dynamic> configData;
      if (config is Map<String, dynamic>) {
        configData = config;
      } else {
        configData = config.toMap();
      }

      await _firestore
          .collection('app_config')
          .doc('main')
          .set(configData, SetOptions(merge: true));
      logger.i("Dynamic app config updated");
    } catch (e) {
      logger.e("Error updating dynamic app config: $e");
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> streamDynamicAppConfig() {
    return _firestore
        .collection('app_config')
        .doc('main')
        .snapshots()
        .map((doc) => doc.exists ? {'id': doc.id, ...doc.data()!} : null);
  }

  // ==================== ECO COINS MANAGEMENT ====================

  /// เพิ่ม Eco Coins ให้กับผู้ใช้
  Future<void> addEcoCoins(String userId, double coins, String reason) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final currentCoins = userDoc.data()?['ecoCoins'] as double? ?? 0.0;
          final newTotal = currentCoins + coins;

          // อัปเดตยอด Eco Coins
          transaction.update(userRef, {'ecoCoins': newTotal});

          // บันทึกประวัติการได้รับเหรียญ
          final historyRef = _firestore.collection('eco_coin_history').doc();
          transaction.set(historyRef, {
            'userId': userId,
            'amount': coins,
            'type': 'earned',
            'reason': reason,
            'balanceAfter': newTotal,
            'createdAt': FieldValue.serverTimestamp(),
          });

          logger.i("Added $coins Eco Coins to user $userId. Reason: $reason");
        }
      });
    } catch (e) {
      logger.e("Error adding Eco Coins to user $userId: $e");
      rethrow;
    }
  }

  /// คำนวณและให้เหรียญจากการซื้อสินค้า (0.1% ของราคา)
  Future<void> awardPurchaseCoins(String userId, double purchaseAmount) async {
    try {
      // คำนวณเหรียญ: 0.1% ของราคาสินค้า (ปัดลง)
      final coins = (purchaseAmount * 0.001);

      if (coins > 0) {
        await addEcoCoins(
          userId,
          coins,
          'การซื้อสินค้า ฿${purchaseAmount.toStringAsFixed(2)}',
        );

        logger.i("Awarded $coins Eco Coins for purchase of ฿$purchaseAmount");
      }
    } catch (e) {
      logger.e("Error awarding purchase coins: $e");
      rethrow;
    }
  }

  /// ใช้ Eco Coins (หักเหรียญ)
  Future<bool> useEcoCoins(String userId, double coins, String reason) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final currentCoins = userDoc.data()?['ecoCoins'] as double? ?? 0.0;

          if (currentCoins >= coins) {
            final newTotal = currentCoins - coins;

            // หักเหรียญ
            transaction.update(userRef, {'ecoCoins': newTotal});

            // บันทึกประวัติการใช้เหรียญ
            final historyRef = _firestore.collection('eco_coin_history').doc();
            transaction.set(historyRef, {
              'userId': userId,
              'amount': -coins,
              'type': 'used',
              'reason': reason,
              'balanceAfter': newTotal,
              'createdAt': FieldValue.serverTimestamp(),
            });

            logger.i(
              "Used $coins Eco Coins from user $userId. Reason: $reason",
            );
            return true;
          } else {
            logger.w(
              "Insufficient Eco Coins for user $userId. Has: $currentCoins, Needs: $coins",
            );
            return false;
          }
        }

        return false;
      });
    } catch (e) {
      logger.e("Error using Eco Coins for user $userId: $e");
      rethrow;
    }
  }

  /// ดึงประวัติ Eco Coins ของผู้ใช้
  Stream<List<Map<String, dynamic>>> getEcoCoinHistory(String userId) {
    return _firestore
        .collection('eco_coin_history')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// ให้เหรียญสำหรับการเข้าสู่ระบบประจำวัน (ปรับปรุงใหม่)
  Future<Map<String, dynamic>> checkDailyLoginReward(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'canClaim': false, 'message': 'ไม่พบข้อมูลผู้ใช้'};
      }

      final userData = userDoc.data()!;
      final lastLoginDate = userData['lastLoginDate'] != null
          ? (userData['lastLoginDate'] as Timestamp).toDate()
          : null;
      final consecutiveDays = userData['consecutiveLoginDays'] as int? ?? 0;
      final progress = userData['loginRewardProgress'] as double? ?? 0.0;

      // ตรวจสอบว่าเข้าสู่ระบบแล้ววันนี้หรือยัง
      if (lastLoginDate != null) {
        final lastLoginDay = DateTime(
          lastLoginDate.year,
          lastLoginDate.month,
          lastLoginDate.day,
        );
        if (lastLoginDay.isAtSameMomentAs(today)) {
          return {'canClaim': false, 'message': 'ได้รับรางวัลแล้ววันนี้'};
        }
      }

      // คำนวณวันต่อเนื่อง
      int newConsecutiveDays = consecutiveDays;
      if (lastLoginDate != null) {
        final yesterday = today.subtract(const Duration(days: 1));
        final lastLoginDay = DateTime(
          lastLoginDate.year,
          lastLoginDate.month,
          lastLoginDate.day,
        );

        if (lastLoginDay.isAtSameMomentAs(yesterday)) {
          // ล็อกอินต่อเนื่อง
          newConsecutiveDays += 1;
        } else {
          // ขาดวัน รีเซ็ต
          newConsecutiveDays = 1;
        }
      } else {
        newConsecutiveDays = 1;
      }

      // คำนวณ progress ใหม่ (เพิ่ม 0.1 ต่อวัน จนครบ 1.0 ใน 10 วัน แต่ให้รางวัลที่ 15 วัน)
      double newProgress =
          progress + (1.0 / 15.0); // เพิ่ม progress แบบ 1/15 ต่อวัน
      bool gotSpecialReward = false;
      int coinsAwarded = 0;

      // ตรวจสอบว่าครบ 15 วันหรือยัง
      if (newProgress >= 1.0 && newConsecutiveDays >= 15) {
        // ได้รางวัลพิเศษ 1 เหรียญ
        coinsAwarded = 1;
        newProgress = 0.0; // รีเซ็ต progress
        gotSpecialReward = true;

        await addEcoCoins(
          userId,
          coinsAwarded.toDouble(),
          'รางวัลล็อกอิน 15 วันต่อเนื่อง',
        );
      }

      // อัปเดตข้อมูล
      await _firestore.collection('users').doc(userId).update({
        'lastLoginDate': Timestamp.fromDate(today),
        'consecutiveLoginDays': newConsecutiveDays,
        'loginRewardProgress': newProgress,
      });

      logger.i(
        "Daily login updated for user $userId: $newConsecutiveDays days, progress: ${(newProgress * 100).toStringAsFixed(1)}%",
      );

      return {
        'rewarded': gotSpecialReward,
        'coinsAwarded': coinsAwarded,
        'consecutiveDays': newConsecutiveDays,
        'progress': newProgress,
        'message': gotSpecialReward
            ? 'ยินดีด้วย! ได้รับ $coinsAwarded เหรียญจากการล็อกอิน 15 วันต่อเนื่อง!'
            : 'ล็อกอินวันที่ $newConsecutiveDays ความคืบหน้า ${(newProgress * 100).toStringAsFixed(1)}%',
      };
    } catch (e) {
      logger.e("Error checking daily login reward: $e");
      return {'rewarded': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// Claim daily login reward
  Future<Map<String, dynamic>> claimDailyLoginReward(String userId) async {
    try {
      final checkResult = await checkDailyLoginReward(userId);
      if (checkResult['canClaim'] != true) {
        return checkResult;
      }

      final consecutiveDays = (checkResult['consecutiveDays'] ?? 0) + 1;
      final rewardCoins = _calculateLoginReward(consecutiveDays);

      await _firestore.collection('users').doc(userId).update({
        'lastLoginReward': Timestamp.now(),
        'consecutiveLoginDays': consecutiveDays,
        'ecoCoins': FieldValue.increment(rewardCoins),
      });

      return {
        'success': true,
        'consecutiveDays': consecutiveDays,
        'rewardCoins': rewardCoins,
        'message': 'รับรางวัลเข้าสู่ระบบสำเร็จ',
      };
    } catch (e) {
      logger.e("Error claiming daily login reward: $e");
      return {'success': false, 'message': 'เกิดข้อผิดพลาด'};
    }
  }

  int _calculateLoginReward(int consecutiveDays) {
    if (consecutiveDays <= 7) {
      return consecutiveDays * 10; // 10, 20, 30, 40, 50, 60, 70
    } else if (consecutiveDays <= 14) {
      return 70 +
          ((consecutiveDays - 7) * 15); // 85, 100, 115, 130, 145, 160, 175
    } else {
      return 175 + ((consecutiveDays - 14) * 20); // 195, 215, 235, etc.
    }
  }

  // ==================== COMMUNITY MANAGEMENT ====================

  /// สร้างโพสต์ใหม่ในชุมชน
  Future<String> createCommunityPost({
    required String userId,
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    List<String> tags = const [],
  }) async {
    try {
      // ดึงข้อมูลผู้ใช้
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      final userData = userDoc.data()!;
      final userDisplayName =
          userData['displayName'] ?? userData['name'] ?? 'ผู้ใช้';
      final userProfileImage = userData['photoUrl'];

      // สร้างโพสต์ใหม่
      final postRef = _firestore.collection('community_posts').doc();
      final post = {
        'id': postRef.id,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userProfileImage': userProfileImage,
        'content': content,
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'likes': <String>[],
        'commentCount': 0,
        'shareCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'isActive': true,
        'tags': tags,
      };

      await postRef.set(post);

      logger.i("Community post created: ${postRef.id}");
      return postRef.id;
    } catch (e) {
      logger.e("Error creating community post: $e");
      rethrow;
    }
  }

  /// แก้ไขโพสต์ในชุมชน
  Future<void> updateCommunityPost({
    required String postId,
    required String content,
    List<String>? imageUrls,
    String? videoUrl,
    List<String>? tags,
  }) async {
    try {
      final postRef = _firestore.collection('community_posts').doc(postId);

      final updateData = <String, dynamic>{
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrls != null) {
        updateData['imageUrls'] = imageUrls;
      }
      if (videoUrl != null) {
        updateData['videoUrl'] = videoUrl;
      }
      if (tags != null) {
        updateData['tags'] = tags;
      }

      await postRef.update(updateData);
      logger.i("Community post updated: $postId");
    } catch (e) {
      logger.e("Error updating community post: $e");
      rethrow;
    }
  }

  /// ดึงโพสต์ทั้งหมดในชุมชน (สำหรับ Feed)
  Stream<List<Map<String, dynamic>>> getCommunityPosts({
    int limit = 20,
    String? startAfter,
  }) {
    Query query = _firestore
        .collection('community_posts')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    });
  }

  /// ดึงโพสต์ของผู้ใช้คนใดคนหนึ่ง (สำหรับ Profile)
  Stream<List<Map<String, dynamic>>> getUserCommunityPosts(String userId) {
    return _firestore
        .collection('community_posts')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  /// กดไลค์/เลิกไลค์โพสต์
  Future<void> toggleLikeCommunityPost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('community_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('ไม่พบโพสต์');
        }

        final likes = List<String>.from(postDoc.data()?['likes'] ?? []);

        if (likes.contains(userId)) {
          // เลิกไลค์
          likes.remove(userId);
        } else {
          // ไลค์
          likes.add(userId);

          // ส่งการแจ้งเตือนให้เจ้าของโพสต์ (ถ้าไม่ใช่คนเดียวกัน)
          final postOwnerId = postDoc.data()?['userId'];
          if (postOwnerId != null && postOwnerId != userId) {
            final notification = {
              'id': _firestore.collection('notifications').doc().id,
              'recipientId': postOwnerId,
              'senderId': userId,
              'type': 'community_like',
              'title': 'มีคนไลค์โพสต์ของคุณ',
              'body': 'มีคนไลค์โพสต์ในชุมชนสีเขียว',
              'data': {'postId': postId},
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            };

            await _firestore
                .collection('notifications')
                .doc(notification['id'])
                .set(notification);
          }
        }

        transaction.update(postRef, {'likes': likes});
      });

      logger.i("Post $postId like toggled by user $userId");
    } catch (e) {
      logger.e("Error toggling like on post $postId: $e");
      rethrow;
    }
  }

  /// เพิ่มคอมเมนต์ในโพสต์
  Future<String> addCommentToCommunityPost({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      // ดึงข้อมูลผู้ใช้
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      final userData = userDoc.data()!;
      final userDisplayName = userData['displayName'] ?? 'ผู้ใช้';
      final userProfileImage = userData['photoUrl'];

      await _firestore.runTransaction((transaction) async {
        // สร้างคอมเมนต์ใหม่
        final commentRef = _firestore.collection('community_comments').doc();
        final comment = {
          'id': commentRef.id,
          'postId': postId,
          'userId': userId,
          'userDisplayName': userDisplayName,
          'userProfileImage': userProfileImage,
          'content': content,
          'likes': <String>[],
          'parentCommentId': parentCommentId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': null,
          'isActive': true,
        };

        transaction.set(commentRef, comment);

        // เพิ่ม commentCount ในโพสต์
        final postRef = _firestore.collection('community_posts').doc(postId);
        transaction.update(postRef, {'commentCount': FieldValue.increment(1)});

        // ส่งการแจ้งเตือนให้เจ้าของโพสต์
        final postDoc = await transaction.get(postRef);
        if (postDoc.exists) {
          final postOwnerId = postDoc.data()?['userId'];
          if (postOwnerId != null && postOwnerId != userId) {
            final notificationRef =
                _firestore.collection('notifications').doc();
            final notification = {
              'id': notificationRef.id,
              'recipientId': postOwnerId,
              'senderId': userId,
              'type': 'community_comment',
              'title': 'มีคนคอมเมนต์โพสต์ของคุณ',
              'body': content.length > 50
                  ? '${content.substring(0, 50)}...'
                  : content,
              'data': {'postId': postId, 'commentId': commentRef.id},
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            };

            transaction.set(notificationRef, notification);
          }
        }
      });

      logger.i("Comment added to post $postId");
      return '';
    } catch (e) {
      logger.e("Error adding comment to post $postId: $e");
      rethrow;
    }
  }

  /// ดึงคอมเมนต์ของโพสต์
  Stream<List<Map<String, dynamic>>> getCommunityPostComments(String postId) {
    return _firestore
        .collection('community_comments')
        .where('postId', isEqualTo: postId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  /// ดึงข้อมูลโพสต์เดียวด้วย ID
  Future<Map<String, dynamic>?> getCommunityPostById(String postId) async {
    try {
      final doc =
          await _firestore.collection('community_posts').doc(postId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      logger.e("Error getting community post by ID: $e");
      return null;
    }
  }

  /// แชร์โพสต์ (สร้างโพสต์ใหม่ที่อ้างอิงโพสต์เดิม)
  Future<String> shareCommunityPost({
    required String originalPostId,
    required String userId,
    String? additionalContent,
  }) async {
    try {
      // ดึงโพสต์ต้นฉบับ
      final originalPostDoc = await _firestore
          .collection('community_posts')
          .doc(originalPostId)
          .get();

      if (!originalPostDoc.exists) {
        throw Exception('ไม่พบโพสต์ต้นฉบับ');
      }

      final originalPostData = originalPostDoc.data()!;

      // สร้างโพสต์แชร์ใหม่
      final shareContent = additionalContent != null &&
              additionalContent.isNotEmpty
          ? '$additionalContent\n\n--- แชร์จาก ${originalPostData['userDisplayName']} ---\n${originalPostData['content']}'
          : '--- แชร์จาก ${originalPostData['userDisplayName']} ---\n${originalPostData['content']}';

      final sharedPostId = await createCommunityPost(
        userId: userId,
        content: shareContent,
        imageUrls: List<String>.from(originalPostData['imageUrls'] ?? []),
        videoUrl: originalPostData['videoUrl'],
        tags: List<String>.from(originalPostData['tags'] ?? []),
      );

      // เพิ่ม shareCount ในโพสต์ต้นฉบับ
      await _firestore.collection('community_posts').doc(originalPostId).update(
        {'shareCount': FieldValue.increment(1)},
      );

      // ส่งการแจ้งเตือนให้เจ้าของโพสต์ต้นฉบับ
      final originalPostOwnerId = originalPostData['userId'];
      if (originalPostOwnerId != userId) {
        final notification = {
          'id': _firestore.collection('notifications').doc().id,
          'recipientId': originalPostOwnerId,
          'senderId': userId,
          'type': 'community_share',
          'title': 'มีคนแชร์โพสต์ของคุณ',
          'body': 'โพสต์ของคุณถูกแชร์ในชุมชนสีเขียว',
          'data': {
            'originalPostId': originalPostId,
            'sharedPostId': sharedPostId,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('notifications')
            .doc(notification['id'])
            .set(notification);
      }

      logger.i("Post $originalPostId shared as $sharedPostId");
      return sharedPostId;
    } catch (e) {
      logger.e("Error sharing post $originalPostId: $e");
      rethrow;
    }
  }

  /// ลบโพสต์ (Soft delete)
  Future<void> deleteCommunityPost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('community_posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) {
        throw Exception('ไม่พบโพสต์');
      }

      final postData = postDoc.data()!;

      // ตรวจสอบสิทธิ์ (เฉพาะเจ้าของโพสต์หรือแอดมิน)
      if (postData['userId'] != userId) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final isAdmin = userDoc.data()?['isAdmin'] ?? false;

        if (!isAdmin) {
          throw Exception('ไม่มีสิทธิ์ลบโพสต์นี้');
        }
      }

      // Soft delete
      await postRef.update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': userId,
      });

      logger.i("Post $postId deleted by user $userId");
    } catch (e) {
      logger.e("Error deleting post $postId: $e");
      rethrow;
    }
  }

  /// ดึงสถิติของผู้ใช้ในชุมชน
  Future<Map<String, dynamic>> getUserCommunityStats(String userId) async {
    try {
      // นับจำนวนโพสต์
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      // นับจำนวนไลค์ที่ได้รับ
      int totalLikes = 0;
      for (final doc in postsSnapshot.docs) {
        final likes = List<String>.from(doc.data()['likes'] ?? []);
        totalLikes += likes.length;
      }

      // นับจำนวนคอมเมนต์ที่ได้รับ
      int totalComments = 0;
      for (final doc in postsSnapshot.docs) {
        totalComments += doc.data()['commentCount'] as int? ?? 0;
      }

      return {
        'totalPosts': postsSnapshot.docs.length,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      logger.e("Error getting user community stats: $e");
      return {
        'totalPosts': 0,
        'totalLikes': 0,
        'totalComments': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Update order shipping information
  Future<void> updateOrderShippingInfo(
    String orderId,
    Map<String, dynamic> shippingInfo,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update(shippingInfo);
      logger.i("Order shipping info updated for $orderId");
    } catch (e) {
      logger.e("Error updating order shipping info: $e");
      rethrow;
    }
  }

  /// Get shipping statistics
  Future<Map<String, dynamic>> getShippingStatistics({
    String? sellerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('orders');

      if (sellerId != null) {
        query = query.where('sellerId', isEqualTo: sellerId);
      }

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final ordersSnapshot =
          await query.where('status', whereIn: ['shipped', 'delivered']).get();

      final orders = ordersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      return {
        'totalOrders': orders.length,
        'totalShippingFees': orders.fold(
          0.0,
          (total, order) => total + (order['shippingFee'] ?? 0.0),
        ),
        'averageShippingFee': orders.isEmpty
            ? 0.0
            : orders.fold(
                  0.0,
                  (total, order) => total + (order['shippingFee'] ?? 0.0),
                ) /
                orders.length,
        'ordersByCarrier': _groupOrdersByCarrier(orders),
      };
    } catch (e) {
      logger.e("Error getting shipping statistics: $e");
      return {};
    }
  }

  Map<String, int> _groupOrdersByCarrier(List<Map<String, dynamic>> orders) {
    final Map<String, int> carrierCounts = {};
    for (final order in orders) {
      final carrier = order['shippingCarrier'] ?? 'Unknown';
      carrierCounts[carrier] = (carrierCounts[carrier] ?? 0) + 1;
    }
    return carrierCounts;
  }

  /// Eco Rewards Methods
  Stream<List<EcoReward>> getEcoRewards() {
    return _firestore
        .collection('ecoRewards')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EcoReward.fromMap(doc.data(), doc.id);
      }).toList();
    }).handleError((error) {
      logger.e("Error getting eco rewards: $error");
      return <EcoReward>[];
    });
  }

  Future<bool> createEcoReward(Map<String, dynamic> rewardData) async {
    try {
      await _firestore.collection('ecoRewards').add({
        ...rewardData,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      logger.e("Error creating eco reward: $e");
      return false;
    }
  }

  Future<bool> updateEcoReward(
    String rewardId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('ecoRewards').doc(rewardId).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      logger.e("Error updating eco reward: $e");
      return false;
    }
  }

  Future<bool> deleteEcoReward(String rewardId) async {
    try {
      await _firestore.collection('ecoRewards').doc(rewardId).delete();
      return true;
    } catch (e) {
      logger.e("Error deleting eco reward: $e");
      return false;
    }
  }

  Stream<List<redemption_model.RewardRedemption>> getUserRedemptions(
    String userId,
  ) {
    return _firestore
        .collection('redemptions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return redemption_model.RewardRedemption.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    }).handleError((error) {
      logger.e("Error getting user redemptions: $error");
      return <redemption_model.RewardRedemption>[];
    });
  }

  Stream<List<dynamic>> getAllRedemptions() {
    return _firestore
        .collection('redemptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    }).handleError((error) {
      logger.e("Error getting all redemptions: $error");
      return <dynamic>[];
    });
  }

  Future<bool> redeemEcoReward(
    String userId,
    String rewardId,
    int pointsCost,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentPoints = userData['ecoCoins'] ?? 0;

      if (currentPoints < pointsCost) {
        return false; // Not enough points
      }

      // Create redemption record
      await _firestore.collection('redemptions').add({
        'userId': userId,
        'rewardId': rewardId,
        'pointsCost': pointsCost,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      // Deduct points from user
      await _firestore.collection('users').doc(userId).update({
        'ecoCoins': FieldValue.increment(-pointsCost),
      });

      return true;
    } catch (e) {
      logger.e("Error redeeming eco reward: $e");
      return false;
    }
  }

  Future<bool> updateRedemptionStatus(
    String redemptionId,
    String status,
  ) async {
    try {
      await _firestore.collection('redemptions').doc(redemptionId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      logger.e("Error updating redemption status: $e");
      return false;
    }
  }

  /// Shipping Methods
  Future<List<Map<String, dynamic>>> getOrdersBySellerAndStatus(
    String sellerId,
    List<String> statuses,
  ) async {
    try {
      Query query = _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId);

      if (statuses.isNotEmpty) {
        query = query.where('status', whereIn: statuses);
      }

      final querySnapshot =
          await query.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      logger.e("Error getting orders by seller and status: $e");
      return [];
    }
  }

  /// Streams orders for a specific seller, filtered by status.
  Stream<List<Map<String, dynamic>>> streamOrdersForSellerByStatus(
    String sellerId,
    List<String> statuses,
  ) {
    try {
      Query query = _firestore
          .collection('orders')
          .where('sellerIds', arrayContains: sellerId);

      if (statuses.isNotEmpty) {
        query = query.where('status', whereIn: statuses);
      }

      return query.orderBy('orderDate', descending: true).snapshots().map(
            (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
    } catch (e) {
      logger.e("Error getting orders by seller and status: $e");
      return Stream.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersNeedingLabels(
    String sellerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: 'confirmed')
          .where('labelGenerated', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      logger.e("Error getting orders needing labels: $e");
      return [];
    }
  }

  Future<bool> bulkUpdateOrderStatuses(
    List<String> orderIds,
    String status,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final orderId in orderIds) {
        final orderRef = _firestore.collection('orders').doc(orderId);
        batch.update(orderRef, {
          'status': status,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      logger.e("Error bulk updating order statuses: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      logger.e("Error getting order by ID: $e");
      return null;
    }
  }

  Future<bool> addTrackingEvent(
    String orderId,
    Map<String, dynamic> eventData,
  ) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('trackingEvents')
          .add({...eventData, 'timestamp': Timestamp.now()});
      return true;
    } catch (e) {
      logger.e("Error adding tracking event: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTrackingEvents(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('trackingEvents')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      logger.e("Error getting tracking events: $e");
      return [];
    }
  }

  Future<List<Product>> getFeaturedProductsBySeller(String sellerId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .where('isFeatured', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  Future<Map<String, dynamic>> getShopReviewSummary(String sellerId) async {
    final snapshot = await _firestore
        .collection('shop_reviews')
        .where('sellerId', isEqualTo: sellerId)
        .get();
    double totalRating = 0;
    int count = snapshot.docs.length;
    for (var doc in snapshot.docs) {
      totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
    }
    return {'rating': count > 0 ? totalRating / count : 0.0, 'count': count};
  }

  // === Shop Customization Methods ===
  Future<ShopCustomization?> getShopCustomization(String sellerId) async {
    try {
      final doc = await _firestore
          .collection('shop_customizations')
          .doc(sellerId)
          .get();

      if (doc.exists) {
        return ShopCustomization.fromMap(doc.data()!);
      }

      // Return default customization if none exists
      return ShopCustomization(
        sellerId: sellerId,
        theme: ScreenShopTheme.greenEco,
        sections: [],
        colors: ShopColors(),
        layout: ShopLayout(),
        featuredProductIds: [],
        promotions: [],
      );
    } catch (e) {
      logger.e("Error getting shop customization: $e");
      return null;
    }
  }

  Future<void> saveShopCustomization(ShopCustomization customization) async {
    try {
      await _firestore
          .collection('shop_customizations')
          .doc(customization.sellerId)
          .set(customization.toMap());
      logger.i(
        "Shop customization saved for seller: ${customization.sellerId}",
      );
    } catch (e) {
      logger.e("Error saving shop customization: $e");
      rethrow;
    }
  }

  Future<List<Product>> getProductsBySellerId(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    } catch (e) {
      logger.e("Error getting products by seller ID: $e");
      return [];
    }
  }

  Future<void> updateShopTheme(String sellerId, ScreenShopTheme theme) async {
    try {
      await _firestore.collection('shop_customizations').doc(sellerId).update({
        'theme': theme.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i("Shop theme updated for seller: $sellerId");
    } catch (e) {
      logger.e("Error updating shop theme: $e");
      rethrow;
    }
  }

  Future<void> updateFeaturedProducts(
    String sellerId,
    List<String> productIds,
  ) async {
    try {
      await _firestore.collection('shop_customizations').doc(sellerId).update({
        'featuredProductIds': productIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i("Featured products updated for seller: $sellerId");
    } catch (e) {
      logger.e("Error updating featured products: $e");
      rethrow;
    }
  }

  Future<void> updateShopColors(String sellerId, ShopColors colors) async {
    try {
      await _firestore.collection('shop_customizations').doc(sellerId).update({
        'colors': colors.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i("Shop colors updated for seller: $sellerId");
    } catch (e) {
      logger.e("Error updating shop colors: $e");
      rethrow;
    }
  }

  Future<void> updateShopLayout(String sellerId, ShopLayout layout) async {
    try {
      await _firestore.collection('shop_customizations').doc(sellerId).update({
        'layout': layout.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i("Shop layout updated for seller: $sellerId");
    } catch (e) {
      logger.e("Error updating shop layout: $e");
      rethrow;
    }
  }

  /// Get current app version from package info
  Future<String> _getAppVersion() async {
    try {
      // In a real implementation, use package_info_plus
      // final packageInfo = await PackageInfo.fromPlatform();
      // return '${packageInfo.version}+${packageInfo.buildNumber}';

      // For now, return a meaningful version
      return '1.0.0+${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      logger.w('Failed to get app version: $e');
      return '1.0.0+unknown';
    }
  }

  /// Get device information for error reporting
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      // In a real implementation, use device_info_plus
      // final deviceInfo = DeviceInfoPlugin();
      // if (Platform.isAndroid) {
      //   final androidInfo = await deviceInfo.androidInfo;
      //   return {'platform': 'android', 'model': androidInfo.model};
      // } else if (Platform.isIOS) {
      //   final iosInfo = await deviceInfo.iosInfo;
      //   return {'platform': 'ios', 'model': iosInfo.model};
      // }

      return {
        'platform': 'flutter_web',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      logger.w('Failed to get device info: $e');
      return {'platform': 'unknown'};
    }
  }
}
