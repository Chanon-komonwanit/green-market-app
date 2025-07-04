// d:/Development/green_market/lib/services/firebase_service.dart
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List;
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
import 'package:green_market/models/homepage_settings.dart';
import 'package:green_market/models/investment_project.dart';
import 'package:green_market/models/investment_summary.dart';
import 'package:green_market/models/news_article_model.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/models/order_item.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/project_question.dart';
import 'package:green_market/models/project_update.dart';
import 'package:green_market/models/promotion.dart';
import 'package:green_market/models/review.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/models/static_page.dart';
import 'package:green_market/models/sustainable_activity.dart';
import 'package:green_market/models/theme_settings.dart';
import 'package:green_market/models/user_investment.dart';
import 'package:green_market/utils/constants.dart';
import 'package:logger/logger.dart';

class FirebaseService {
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
      return GoogleSignIn();
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
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      logger.e("Sign-in Error: $e");
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      logger.e("User Creation Error: ");
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
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        logger.w("Google sign-in was cancelled by the user.");
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      logger.i("Google sign-in successful, signing in with credential.");
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      logger.e("Google Sign-In Error: ");
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
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      logger.e('Error getting user by ID: $e');
      return null;
    }
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
    if (shopDescription != null)
      updateData['shopDescription'] = shopDescription;
    if (motto != null) updateData['motto'] = motto;
    if (website != null) updateData['website'] = website; // เพิ่ม field ใหม่
    if (facebook != null) updateData['facebook'] = facebook; // เพิ่ม field ใหม่
    if (instagram != null)
      updateData['instagram'] = instagram; // เพิ่ม field ใหม่
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
        .count()
        .get();
    return snapshot.count ?? 0;
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
    return _firestore
        .collection('products')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID to data
            return Product.fromMap(data);
          }).toList(),
        )
        .handleError((error) {
      logger.e("Error fetching approved products: $error");
      return <Product>[];
    });
  }

  Stream<List<Product>> getAllProductsForAdmin() {
    return _firestore.collection('products').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList(),
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
  /*
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
    final doc = await _firestore.collection('news_articles').doc(articleId).get();
    return doc.exists ? NewsArticle.fromMap(doc.data()!, doc.id) : null;
  }
  */

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
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID to data
            return Category.fromMap(data);
          }).toList(),
        )
        .handleError((error) {
      logger.e("Error fetching categories: $error");
      return <Category>[];
    });
  }

  Stream<List<Product>> getProductsByCategoryId(String categoryId) {
    return _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList(),
        );
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
        .where('ecoScore', isGreaterThanOrEqualTo: minScore)
        .where('ecoScore', isLessThanOrEqualTo: maxScore)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList(),
        );
  }

  // --- Orders Management ---
  Future<void> addOrder(app_order.Order order) async {
    final docId = order.id.isEmpty ? generateNewDocId('orders') : order.id;
    await _firestore
        .collection('orders')
        .doc(docId)
        .set(order.copyWith(id: docId).toMap());
    logger.i("Order added with ID: $docId");
  }

  Future<void> updateOrder(app_order.Order order) async {
    await _firestore.collection('orders').doc(order.id).update(order.toMap());
    logger.i("Order ${order.id} updated");
  }

  Stream<List<app_order.Order>> getOrdersByUserId(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => app_order.Order.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<app_order.Order>> getOrdersBySellerId(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => app_order.Order.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
    });
    logger.i("Order $orderId status updated to $status");
  }

  // --- Investment Projects Management ---
  Future<void> addInvestmentProject(InvestmentProject project) async {
    final docId = project.id.isEmpty
        ? generateNewDocId('investment_projects')
        : project.id;
    await _firestore
        .collection('investment_projects')
        .doc(docId)
        .set(project.copyWith(id: docId, createdAt: Timestamp.now()).toMap());
    logger.i("Investment project ${project.title} added with ID: $docId");
  }

  Future<void> updateInvestmentProject(InvestmentProject project) async {
    await _firestore
        .collection('investment_projects')
        .doc(project.id)
        .update(project.toMap());
    logger.i("Investment project ${project.title} updated");
  }

  Future<void> deleteInvestmentProject(String projectId) async {
    await _firestore.collection('investment_projects').doc(projectId).delete();
    logger.i("Investment project $projectId deleted");
  }

  Stream<List<InvestmentProject>> getApprovedInvestmentProjects() {
    return _firestore
        .collection('investment_projects')
        .where(
          'submissionStatus',
          isEqualTo: ProjectSubmissionStatus.approved.name,
        )
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvestmentProject.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<InvestmentProject>> getAllInvestmentProjectsForAdmin() {
    return _firestore.collection('investment_projects').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => InvestmentProject.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<InvestmentProject>> getInvestmentProjectsByOwnerId(
    String ownerId,
  ) {
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

  Future<void> approveInvestmentProject(String projectId) async {
    await _firestore.collection('investment_projects').doc(projectId).update({
      'submissionStatus': ProjectSubmissionStatus.approved.name,
      'isActive': true,
    });
    logger.i("Investment project $projectId approved");
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
  Future<String> uploadWebImage(Uint8List imageBytes, String fileName) async {
    try {
      final ref = _storage.ref().child('images/$fileName');
      final uploadTask = await ref.putData(imageBytes);
      final downloadURL = await uploadTask.ref.getDownloadURL();
      logger.i("Web image uploaded: $downloadURL");
      return downloadURL;
    } catch (e) {
      logger.e("Error uploading web image: $e");
      rethrow;
    }
  }

  Future<String> uploadImageFile(File imageFile, String fileName) async {
    try {
      final ref = _storage.ref().child('images/$fileName');
      final uploadTask = await ref.putFile(imageFile);
      final downloadURL = await uploadTask.ref.getDownloadURL();
      logger.i("Image file uploaded: $downloadURL");
      return downloadURL;
    } catch (e) {
      logger.e("Error uploading image file: $e");
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
  Stream<List<Promotion>> getActivePromotions() {
    return _firestore.collection('promotions').snapshots().map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => Promotion.fromMap(doc.data()))
          .where(
            (promotion) => promotion.isActive && promotion.endDate.isAfter(now),
          )
          .toList();
    }).handleError((error) {
      logger.e("Error fetching active promotions: $error");
      return <Promotion>[];
    });
  }

  Future<void> createPromotion(Promotion promotion) async {
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

  Future<void> updatePromotion(Promotion promotion) async {
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

  Stream<List<Promotion>> getPromotions() {
    return _firestore.collection('promotions').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Promotion.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> addPromotion(Promotion promotion) async {
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

  // --- Search Methods ---
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection('products')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromMap(doc.data()))
              .where(
                (product) =>
                    product.name.toLowerCase().contains(query.toLowerCase()) ||
                    product.description.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
              )
              .toList(),
        );
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
        return {'rewarded': false, 'message': 'ไม่พบข้อมูลผู้ใช้'};
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
          return {'rewarded': false, 'message': 'ได้รับรางวัลแล้ววันนี้'};
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

  // === รางวัล Eco Rewards ===

  /// ดึงรายการรางวัลทั้งหมด
  Stream<List<EcoReward>> getEcoRewards() {
    return _firestore
        .collection('eco_rewards')
        .where('isActive', isEqualTo: true)
        .orderBy('requiredCoins', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EcoReward.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// สร้างรางวัลใหม่ (สำหรับแอดมิน)
  Future<String> createEcoReward(EcoReward reward) async {
    try {
      final docRef =
          await _firestore.collection('eco_rewards').add(reward.toMap());
      logger.i("Created eco reward: ${reward.title}");
      return docRef.id;
    } catch (e) {
      logger.e("Error creating eco reward: $e");
      rethrow;
    }
  }

  /// อัปเดตรางวัล (สำหรับแอดมิน)
  Future<void> updateEcoReward(String rewardId, dynamic data) async {
    try {
      if (data is EcoReward) {
        await _firestore
            .collection('eco_rewards')
            .doc(rewardId)
            .update(data.toMap());
      } else if (data is Map<String, dynamic>) {
        await _firestore.collection('eco_rewards').doc(rewardId).update(data);
      } else {
        throw ArgumentError('Data must be EcoReward or Map<String, dynamic>');
      }
      logger.i("Updated eco reward: $rewardId");
    } catch (e) {
      logger.e("Error updating eco reward: $e");
      rethrow;
    }
  }

  /// ลบรางวัล (สำหรับแอดมิน)
  Future<void> deleteEcoReward(String rewardId) async {
    try {
      await _firestore.collection('eco_rewards').doc(rewardId).update({
        'isActive': false,
      });
      logger.i("Deleted eco reward: $rewardId");
    } catch (e) {
      logger.e("Error deleting eco reward: $e");
      rethrow;
    }
  }

  /// แลกรางวัล
  Future<String> redeemEcoReward(String userId, String rewardId) async {
    return await _firestore.runTransaction((transaction) async {
      // ดึงข้อมูลผู้ใช้
      final userDoc = await transaction.get(
        _firestore.collection('users').doc(userId),
      );
      if (!userDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      final userData = userDoc.data()!;
      final currentCoins = userData['ecoCoins'] as double? ?? 0.0;

      // ดึงข้อมูลรางวัล
      final rewardDoc = await transaction.get(
        _firestore.collection('eco_rewards').doc(rewardId),
      );
      if (!rewardDoc.exists) {
        throw Exception('ไม่พบรางวัลที่เลือก');
      }

      final rewardData = rewardDoc.data()!;
      final reward = EcoReward.fromMap(rewardData, rewardDoc.id);

      // ตรวจสอบเงื่อนไข
      if (!reward.isAvailable) {
        throw Exception('รางวัลนี้ไม่สามารถแลกได้ในขณะนี้');
      }

      if (currentCoins < reward.requiredCoins) {
        throw Exception(
          'เหรียญไม่เพียงพอ ต้องการ ${reward.requiredCoins} เหรียญ',
        );
      }

      if (reward.remainingQuantity <= 0) {
        throw Exception('รางวัลหมดแล้ว');
      }

      // หักเหรียญ
      transaction.update(_firestore.collection('users').doc(userId), {
        'ecoCoins': currentCoins - reward.requiredCoins,
      });

      // เพิ่มจำนวนที่แลกแล้ว
      transaction.update(_firestore.collection('eco_rewards').doc(rewardId), {
        'redeemedCount': reward.redeemedCount + 1,
      });

      // สร้างประวัติการแลก
      final redemptionRef = _firestore.collection('reward_redemptions').doc();
      final redemption = RewardRedemption(
        id: redemptionRef.id,
        userId: userId,
        rewardId: rewardId,
        rewardTitle: reward.title,
        coinsUsed: reward.requiredCoins.round(),
        status: 'pending',
        redeemedAt: DateTime.now(),
      );
      transaction.set(redemptionRef, redemption.toMap());

      logger.i("User $userId redeemed reward: ${reward.title}");
      return redemptionRef.id;
    });
  }

  /// ดึงประวัติการแลกรางวัลของผู้ใช้
  Stream<List<RewardRedemption>> getUserRedemptions(String userId) {
    return _firestore
        .collection('reward_redemptions')
        .where('userId', isEqualTo: userId)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RewardRedemption.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// ดึงประวัติการแลกรางวัลทั้งหมด (สำหรับแอดมิน)
  Stream<List<RewardRedemption>> getAllRedemptions() {
    return _firestore
        .collection('reward_redemptions')
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RewardRedemption.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// อัปเดตสถานะการแลกรางวัล (สำหรับแอดมิน)
  Future<void> updateRedemptionStatus(
    String redemptionId,
    String status, {
    String? notes,
  }) async {
    try {
      final updateData = {'status': status};
      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _firestore
          .collection('reward_redemptions')
          .doc(redemptionId)
          .update(updateData);
      logger.i("Updated redemption status: $redemptionId -> $status");
    } catch (e) {
      logger.e("Error updating redemption status: $e");
      rethrow;
    }
  }

  /// ฟังก์ชันสำหรับการรับเหรียญจากการล็อกอินประจำวัน (ปลอดภัยต่อการแฮ็ก)
  /// ใช้ระบบความปลอดภัยแบบ server-side validation เพื่อป้องกันการโกง
  Future<Map<String, dynamic>> claimDailyLoginReward(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // === ความปลอดภัยขั้นที่ 1: ตรวจสอบผู้ใช้ ===
      if (userId.isEmpty) {
        logger.w("Attempted to claim daily reward with empty userId");
        return {
          'success': false,
          'message': 'ข้อมูลผู้ใช้ไม่ถูกต้อง',
          'error': 'INVALID_USER',
        };
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        logger.w("User not found: $userId");
        return {
          'success': false,
          'message': 'ไม่พบข้อมูลผู้ใช้',
          'error': 'USER_NOT_FOUND',
        };
      }

      final userData = userDoc.data()!;

      // === ความปลอดภัยขั้นที่ 2: ตรวจสอบเวลาจริง (Time Verification) ===
      final lastLoginDate = userData['lastLoginDate'] != null
          ? (userData['lastLoginDate'] as Timestamp).toDate()
          : null;

      if (lastLoginDate != null) {
        final lastLoginDay = DateTime(
          lastLoginDate.year,
          lastLoginDate.month,
          lastLoginDate.day,
        );

        // ตรวจสอบว่าได้รับรางวัลแล้ววันนี้หรือยัง
        if (lastLoginDay.isAtSameMomentAs(today)) {
          logger.w("User $userId already claimed reward today");
          return {
            'success': false,
            'message': 'วันนี้ได้รับรางวัลแล้ว กรุณากลับมาพรุ่งนี้',
            'error': 'ALREADY_CLAIMED_TODAY',
          };
        }
      }

      // === ความปลอดภัยขั้นที่ 3: Rate Limiting ===
      final lastClaimAttempt = userData['lastClaimAttempt'] != null
          ? (userData['lastClaimAttempt'] as Timestamp).toDate()
          : null;

      if (lastClaimAttempt != null) {
        final timeDiff = now.difference(lastClaimAttempt).inMinutes;
        if (timeDiff < 5) {
          // ห้ามเรียกใช้เร็วกว่า 5 นาที
          logger.w("Rate limit exceeded for user $userId");
          return {
            'success': false,
            'message': 'กรุณารอสักครู่ก่อนเรียกใช้งานอีกครั้ง',
            'error': 'RATE_LIMIT_EXCEEDED',
          };
        }
      }

      // === ความปลอดภัยขั้นที่ 4: Anti-Cheat Detection ===
      final consecutiveDays = userData['consecutiveLoginDays'] as int? ?? 0;
      final progress = userData['loginRewardProgress'] as double? ?? 0.0;

      // ตรวจสอบค่าที่ผิดปกติ
      if (consecutiveDays < 0 || consecutiveDays > 1000) {
        logger.e(
          "Suspicious consecutive days detected for user $userId: $consecutiveDays",
        );
        return {
          'success': false,
          'message': 'ตรวจพบข้อมูลผิดปกติ กรุณาติดต่อฝ่ายสนับสนุน',
          'error': 'SUSPICIOUS_DATA',
        };
      }

      if (progress < 0.0 || progress > 1.0) {
        logger.e("Suspicious progress detected for user $userId: $progress");
        return {
          'success': false,
          'message': 'ตรวจพบข้อมูลผิดปกติ กรุณาติดต่อฝ่ายสนับสนุน',
          'error': 'SUSPICIOUS_DATA',
        };
      }

      // === ความปลอดภัยขั้นที่ 5: การตรวจสอบลำดับของการล็อกอิน ===
      int newConsecutiveDays = 1;
      if (lastLoginDate != null) {
        final yesterday = today.subtract(const Duration(days: 1));
        final lastLoginDay = DateTime(
          lastLoginDate.year,
          lastLoginDate.month,
          lastLoginDate.day,
        );

        if (lastLoginDay.isAtSameMomentAs(yesterday)) {
          // ล็อกอินต่อเนื่อง
          newConsecutiveDays = consecutiveDays + 1;
        } else if (lastLoginDay.isBefore(yesterday)) {
          // ขาดวัน รีเซ็ต
          newConsecutiveDays = 1;
        } else {
          // วันที่ผิดปกติ (อนาคต)
          logger.e(
            "Future date detected for user $userId: $lastLoginDay vs $today",
          );
          return {
            'success': false,
            'message': 'ตรวจพบวันที่ผิดปกติ',
            'error': 'INVALID_DATE',
          };
        }
      }

      // === คำนวณรางวัล ===
      // ให้ 0.1 เหรียญทุกวันที่ล็อกอิน
      double dailyCoins = 0.1;
      String rewardMessage = '';

      // ให้รางวัลพิเศษเมื่อครบ 15 วัน (1 เหรียญเพิ่ม)
      bool gotSpecialReward = false;
      double totalCoinsAwarded = dailyCoins; // เริ่มต้นด้วย 0.1 เหรียญประจำวัน

      if (newConsecutiveDays > 0 && newConsecutiveDays % 15 == 0) {
        gotSpecialReward = true;
        totalCoinsAwarded += 1.0; // เพิ่ม 1 เหรียญโบนัส
        rewardMessage =
            'ยินดีด้วย! ได้รับ ${totalCoinsAwarded.toStringAsFixed(1)} เหรียญ (0.1 ประจำวัน + 1.0 โบนัส 15 วัน)';
      } else {
        rewardMessage =
            'ได้รับ 0.1 เหรียญจากการล็อกอิน (วันที่ $newConsecutiveDays)';
      }

      // คำนวณ progress สำหรับแสดงผล (0-15 วัน)
      double newProgress = (newConsecutiveDays % 15) / 15.0;

      // === ความปลอดภัยขั้นที่ 6: Transaction ป้องกัน Race Condition ===
      final result = await _firestore.runTransaction((transaction) async {
        // อ่านข้อมูลล่าสุดอีกครั้งใน transaction
        final freshUserDoc = await transaction.get(
          _firestore.collection('users').doc(userId),
        );
        if (!freshUserDoc.exists) {
          throw Exception('USER_NOT_FOUND');
        }

        final freshData = freshUserDoc.data()!;
        final freshLastLogin = freshData['lastLoginDate'] != null
            ? (freshData['lastLoginDate'] as Timestamp).toDate()
            : null;

        // ตรวจสอบอีกครั้งว่าไม่ได้รับรางวัลแล้ววันนี้
        if (freshLastLogin != null) {
          final freshLastLoginDay = DateTime(
            freshLastLogin.year,
            freshLastLogin.month,
            freshLastLogin.day,
          );
          if (freshLastLoginDay.isAtSameMomentAs(today)) {
            throw Exception('ALREADY_CLAIMED_TODAY');
          }
        }

        // อัปเดตข้อมูลใน transaction
        final updateData = {
          'lastLoginDate': Timestamp.fromDate(today),
          'consecutiveLoginDays': newConsecutiveDays,
          'loginRewardProgress': newProgress,
          'lastClaimAttempt': Timestamp.fromDate(now),
        };

        // เพิ่มเหรียญทุกวัน (0.1 เหรียญ + โบนัสถ้ามี)
        final currentCoins = freshData['ecoCoins'] as double? ?? 0.0;
        updateData['ecoCoins'] = currentCoins + totalCoinsAwarded;

        transaction.update(
          _firestore.collection('users').doc(userId),
          updateData,
        );

        return {
          'success': true,
          'rewarded': gotSpecialReward,
          'coinsAwarded': totalCoinsAwarded,
          'consecutiveDays': newConsecutiveDays,
          'progress': newProgress,
          'message': rewardMessage,
        };
      });

      // === ความปลอดภัยขั้นที่ 7: Audit Logging ===
      await _firestore.collection('audit_logs').add({
        'userId': userId,
        'action': 'CLAIM_DAILY_LOGIN_REWARD',
        'timestamp': Timestamp.fromDate(now),
        'success': true,
        'details': {
          'consecutiveDays': newConsecutiveDays,
          'coinsAwarded': totalCoinsAwarded,
          'rewarded': gotSpecialReward,
        },
        'metadata': {'userAgent': 'Flutter App', 'version': '1.0.0'},
      });

      logger.i(
        "Daily login reward claimed for user $userId: "
        "Days: $newConsecutiveDays, Coins: $totalCoinsAwarded, Rewarded: $gotSpecialReward",
      );

      return result;
    } catch (e) {
      // === ความปลอดภัยขั้นที่ 8: Error Logging ===
      logger.e("Error claiming daily login reward for user $userId: $e");

      // บันทึก error ลง audit log
      await _firestore.collection('audit_logs').add({
        'userId': userId,
        'action': 'CLAIM_DAILY_LOGIN_REWARD',
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'success': false,
        'error': e.toString(),
        'metadata': {'userAgent': 'Flutter App', 'version': '1.0.0'},
      });

      if (e.toString().contains('ALREADY_CLAIMED_TODAY')) {
        return {
          'success': false,
          'message': 'วันนี้ได้รับรางวัลแล้ว กรุณากลับมาพรุ่งนี้',
          'error': 'ALREADY_CLAIMED_TODAY',
        };
      }

      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง',
        'error': 'UNKNOWN_ERROR',
      };
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
      final userProfileImage = userData['profileImageUrl'];

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
      final userDisplayName =
          userData['displayName'] ?? userData['name'] ?? 'ผู้ใช้';
      final userProfileImage = userData['profileImageUrl'];

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
        transaction.update(postRef, {
          'commentCount': FieldValue.increment(1),
        });

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
      await _firestore
          .collection('community_posts')
          .doc(originalPostId)
          .update({
        'shareCount': FieldValue.increment(1),
      });

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
}
