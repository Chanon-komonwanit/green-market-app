// lib/services/firebase_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/review.dart'; // Correct import for Review model
import 'package:green_market/models/promotion.dart'; // Import Promotion model
import 'package:green_market/utils/constants.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/models/category.dart';
import 'package:green_market/models/app_notification.dart';
import 'dart:async'; // For StreamTransformer
import 'package:flutter/foundation.dart'
    hide Category; // For Uint8List (kIsWeb)

// For better maintainability, collection names are centralized here.
class _FirestoreCollections {
  static const String users = 'users';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String chats = 'chats';
  static const String messages = 'messages'; // Subcollection within chats
  static const String categories = 'categories';
  static const String notifications = 'notifications';
  static const String reviews = 'reviews';
  static const String shops = 'shops';
  static const String addresses = 'addresses'; // Subcollection within users
  static const String promotions =
      'promotions'; // New collection for promotions
}

// TODO: Consider using a dedicated logging package instead of print() for production.
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // --- Authentication ---
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // Check if the signed-in user is the designated admin
      final user = result.user;
      if (user != null &&
          user.email?.toLowerCase() == kAdminEmail.toLowerCase()) {
        // Ensure the isAdmin field is set in Firestore for the admin user
        // TODO: Consider moving admin email to a configuration file/environment variable.
        // Also ensure basic user data exists for the admin
        final adminDocRef =
            _firestore.collection(_FirestoreCollections.users).doc(user.uid);
        try {
          // Check if the document exists to conditionally set 'createdAt'
          final adminDocSnapshot = await adminDocRef.get();
          Map<String, dynamic> adminData = {
            'isAdmin': true,
            'email': user.email,
            'isSeller': true,
            'displayName':
                user.displayName ?? user.email?.split('@')[0] ?? 'Admin',
            'sellerApplicationStatus': 'approved',
          };
          if (!adminDocSnapshot.exists ||
              adminDocSnapshot.data()?['createdAt'] == null) {
            adminData['createdAt'] = FieldValue.serverTimestamp();
          }
          await adminDocRef.set(adminData, SetOptions(merge: true));
          print(
              "FirebaseService: Admin document for ${user.uid} set/updated successfully with isAdmin: true.");
        } on FirebaseException catch (fe) {
          print(
              "FirebaseService: Firestore error setting admin data for ${user.uid}: ${fe.code} - ${fe.message}");
          // Optionally, rethrow or handle more gracefully if this is critical for admin login
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Error signing in: ${e.code} - ${e.message}');
      // Rethrow to allow UI to display specific error messages
      throw Exception('Sign in failed: ${e.message}');
    } on FirebaseException catch (fe) {
      // Catch general Firebase exceptions (like Firestore)
      print(
          'A Firebase error occurred during sign in process: ${fe.code} - ${fe.message}');
      throw Exception('Sign in failed: A Firebase error occurred.');
    } catch (e) {
      print('An unexpected error occurred during sign in: $e');
      throw Exception('Sign in failed: An unexpected error occurred.');
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      // Prevent admin email from being registered through the public sign-up form
      if (email.toLowerCase() == kAdminEmail.toLowerCase()) {
        throw FirebaseAuthException(
            code: 'admin-registration-not-allowed',
            message: 'This email address is reserved.');
      }
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      // Save user role to Firestore
      await _firestore
          .collection(_FirestoreCollections.users)
          .doc(result.user!.uid)
          .set({
        'email': email,
        'displayName': email.split('@')[0], // Default display name
        'createdAt': FieldValue.serverTimestamp(),
        'isSeller': false, // Default to not a seller
        'isAdmin': false, // Default to not an admin for regular sign-ups
        'sellerApplicationStatus': 'none', // Initial status
      });
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Error signing up: ${e.code} - ${e.message}');
      rethrow; // Rethrow to allow UI to handle specific Firebase Auth errors
    } catch (e) {
      print('An unexpected error occurred during sign up: $e');
      throw Exception("Sign up failed: An unexpected error occurred.");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- User Management ---
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_FirestoreCollections.users)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        print(
            "FirebaseService: User document for $uid does not exist or has no data.");
        return null;
      }
    } catch (e, s) {
      print('Error getting user data for $uid: $e');
      print('Stacktrace: $s');
      // Consider rethrowing or returning a specific error state
    }
    return null;
  }

  Future<void> updateUserProfile(
      String uid, String? displayName, String? phoneNumber) async {
    try {
      await _firestore.collection(_FirestoreCollections.users).doc(uid).set(
        {
          if (displayName != null) 'displayName': displayName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile.');
    }
  }

  Future<String?> getUserDisplayName(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_FirestoreCollections.users)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>?;
        final displayName = data?['displayName']?.toString();
        final emailPart = (data?['email']?.toString())?.split('@')[0];
        return displayName ?? emailPart;
      } else {
        print(
            "FirebaseService: User document for $uid does not exist or has no data (for displayName).");
        return null;
      }
    } catch (e) {
      print('Error getting user display name: $e');
      // Consider rethrowing or returning a specific error state
    }
    return null;
  }

  // --- Product Management (for Sellers/Admin) ---
  // Consolidate image upload logic
  Future<String?> _uploadDataToStorage(
      String storagePath, String fileName, Uint8List data,
      {String? contentType}) async {
    try {
      Reference ref = _storage.ref().child(storagePath).child(fileName);
      SettableMetadata? metadata = contentType != null
          ? SettableMetadata(contentType: contentType)
          : null;
      UploadTask uploadTask =
          metadata != null ? ref.putData(data, metadata) : ref.putData(data);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading data to $storagePath/$fileName: $e');
      // Rethrow to allow UI to handle upload failures
      throw Exception('Image upload failed.');
    }
  }

  Future<String?> uploadImageFile(String storagePath, String filePath,
      {String? fileName}) async {
    try {
      String effectiveFileName = (fileName?.isNotEmpty == true)
          ? fileName!
          : '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      Reference ref =
          _storage.ref().child(storagePath).child(effectiveFileName);
      UploadTask uploadTask = ref.putFile(File(filePath));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Image upload failed.');
    }
  }

  Future<String?> uploadImageBytes(
      String storagePath, String fileName, Uint8List bytes) async {
    return _uploadDataToStorage(storagePath, fileName, bytes);
  }

  Future<void> addProduct(Product product) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.products)
          .add(product.toFirestore());
    } catch (e) {
      print('Error adding product: $e');
      throw Exception('Failed to add product.');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.products)
          .doc(product.id)
          .update(product.toFirestoreForUpdate());
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to update product.');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      DocumentSnapshot productDoc = await _firestore
          .collection(_FirestoreCollections.products)
          .doc(productId)
          .get();
      if (productDoc.exists) {
        Product productToDelete = Product.fromFirestore(productDoc);
        for (String imageUrl in productToDelete.imageUrls) {
          await deleteImageByUrl(imageUrl);
        }
      }
      await _firestore
          .collection(_FirestoreCollections.products)
          .doc(productId)
          .delete();
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to delete product.');
    }
  }

  Future<void> rejectProduct(String productId, {String? reason}) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.products)
          .doc(productId)
          .update({
        'isApproved': false, // Mark as not approved
        'status': 'rejected', // Add a status field
        if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(
          'FirebaseService: Product $productId rejected ${reason != null ? "with reason: $reason" : ""}');
    } catch (e) {
      print('Error rejecting product $productId: $e');
      throw Exception('Failed to reject product.');
    }
  }

  // --- Product Retrieval (for Buyers) ---
  Stream<List<Product>> getApprovedProducts() {
    return _firestore
        .collection(_FirestoreCollections.products)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching approved products: $error");
      print("Stacktrace: $stackTrace");
      sink.addError(Exception("Failed to fetch products: ${error.toString()}"),
          stackTrace);
    }));
  }

  Stream<List<Product>> getProductsByEcoLevel(EcoLevel level) {
    int minScore, maxScore;
    switch (level) {
      case EcoLevel.starter:
        minScore = 1;
        maxScore = 34;
        break;
      case EcoLevel.moderate:
        minScore = 35;
        maxScore = 69;
        break;
      case EcoLevel.hero:
        minScore = 70;
        maxScore = 100;
        break;
    }
    return _firestore
        .collection(_FirestoreCollections.products)
        .where('isApproved', isEqualTo: true)
        .where('ecoScore', isGreaterThanOrEqualTo: minScore)
        .where('ecoScore', isLessThanOrEqualTo: maxScore)
        .orderBy('ecoScore', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching products by eco level ($level): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception(
              "Failed to fetch products by eco level: ${error.toString()}"),
          stackTrace);
    }));
  }

  Stream<List<Product>> getProductsByCategoryId(String categoryId) {
    return _firestore
        .collection(_FirestoreCollections.products)
        .where('isApproved', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching products by category ID ($categoryId): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception(
              "Failed to fetch products by category: ${error.toString()}"),
          stackTrace);
    }));
  }

  Stream<List<Product>> searchProducts(String query) {
    if (query.isEmpty) {
      return Stream.value([]); // Return empty stream for empty query
    }
    String searchQuery = query.toLowerCase();

    // WARNING: Client-side filtering. Not scalable for large datasets.
    // Consider using a dedicated search service like Algolia, Typesense, or Elasticsearch.
    return _firestore
        .collection(_FirestoreCollections.products)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) =>
              product.name.toLowerCase().contains(searchQuery) ||
              (product.categoryName?.toLowerCase().contains(searchQuery) ??
                  false) ||
              (product.description.toLowerCase().contains(searchQuery)))
          .toList();
    }).transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error searching products (query: $query): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(Exception("Failed to search products: ${error.toString()}"),
          stackTrace);
    }));
  }

  // --- Admin Specific ---
  Stream<List<Product>> getPendingProducts() {
    return _firestore
        .collection(_FirestoreCollections.products)
        .where('isApproved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching pending products: $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch pending products: ${error.toString()}"),
          stackTrace);
    }));
  }

  // Made public for use in other parts of the app
  int calculateLevelFromEcoScore(int ecoScore) {
    if (ecoScore >= 70 && ecoScore <= 100) return 3; // Hero
    if (ecoScore >= 35 && ecoScore <= 69) return 2; // Moderate
    if (ecoScore >= 1 && ecoScore <= 34) return 1; // Starter
    print(
        "FirebaseService: Warning: ecoScore $ecoScore is outside defined ranges (1-100) for level assignment. Setting level to 0.");
    return 0; // Default or out-of-range level
  }

  Future<void> approveProduct(String productId, int ecoScore,
      {String? categoryId, String? categoryName}) async {
    try {
      final Map<String, dynamic> updateData = {
        'isApproved': true,
        'ecoScore': ecoScore,
        'approvedAt': FieldValue.serverTimestamp(),
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        updateData['categoryId'] = categoryId;
      }
      if (categoryName != null &&
          categoryName.isNotEmpty &&
          categoryId != null &&
          categoryId.isNotEmpty) {
        updateData['categoryName'] = categoryName;
      }
      updateData['level'] = calculateLevelFromEcoScore(ecoScore);
      await _firestore
          .collection(_FirestoreCollections.products)
          .doc(productId)
          // Use update instead of set to avoid overwriting other fields
          .update(updateData);
      print(
          "Product $productId approved with ecoScore: $ecoScore, level: ${updateData['level']}");
    } catch (e) {
      print('Error approving product: $e');
      throw Exception('Failed to approve product.');
    }
  }

  // --- Product Retrieval (for Sellers) ---
  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return _firestore
        .collection(_FirestoreCollections.products)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching products by seller ($sellerId): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch seller products: ${error.toString()}"),
          stackTrace);
    }));
  }

  // --- Order Management ---
  Future<app_order.Order?> placeOrder(app_order.Order order) async {
    try {
      final docRef = await _firestore
          .collection(_FirestoreCollections.orders)
          .add(order.toFirestore());
      // Fetch the newly created document to ensure it has all fields (like server timestamps)
      final newOrderSnapshot = await docRef.get();
      if (newOrderSnapshot.exists) {
        return app_order.Order.fromFirestore(newOrderSnapshot);
      }
      throw Exception("Failed to retrieve newly created order.");
    } catch (e) {
      print('Error placing order: $e');
      throw Exception('Failed to place order.');
    }
  }

  Stream<List<app_order.Order>> getOrdersForUser(String userId) {
    return _firestore
        .collection(_FirestoreCollections.orders)
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.Order.fromFirestore(doc))
            .toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching orders for user ($userId): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch user orders: ${error.toString()}"),
          stackTrace);
    }));
  }

  Stream<List<app_order.Order>> getAllOrders() {
    return _firestore
        .collection(_FirestoreCollections.orders)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.Order.fromFirestore(doc))
            .toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching all orders: $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch all orders: ${error.toString()}"),
          stackTrace);
    }));
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.orders)
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status.');
    }
  }

  Future<void> updateOrderStatusWithSlip(
      String orderId, String newStatus, String? slipUrl) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.orders)
          .doc(orderId)
          .update({
        'status': newStatus,
        'paymentSlipUrl': slipUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating order status with slip: $e');
      throw Exception('Failed to update order status with payment slip.');
    }
  }

  // --- Chat Management ---
  String _getChatId(String buyerId, String sellerId, String productId) {
    List<String> ids = [buyerId, sellerId];
    ids.sort();
    return '${ids[0]}_${ids[1]}_$productId';
  }

  Stream<List<Map<String, dynamic>>> getChatMessages(
      String productId, String buyerId, String sellerId) {
    String chatId = _getChatId(buyerId, sellerId, productId);
    return _firestore
        .collection(_FirestoreCollections.chats)
        .doc(chatId)
        .collection(_FirestoreCollections.messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching chat messages for chat ID ($chatId): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch chat messages: ${error.toString()}"),
          stackTrace);
    }));
  }

  Future<void> sendChatMessage(
      String productId,
      String productName,
      String productImage,
      String buyerId,
      String sellerId,
      String senderId,
      String message,
      {String? buyerName,
      String? sellerName}) async {
    String chatId = _getChatId(buyerId, sellerId, productId);
    try {
      await _firestore
          .collection(_FirestoreCollections.chats)
          .doc(chatId)
          .collection(_FirestoreCollections.messages)
          .add({
        'senderId': senderId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_FirestoreCollections.chats).doc(chatId).set(
        {
          'productId': productId,
          'productName': productName,
          'productImageUrl': productImage,
          'buyerId': buyerId,
          'sellerId': sellerId,
          'participants': [buyerId, sellerId],
          'lastMessage': message,
          'lastMessageSenderId': senderId,
          'lastTimestamp': FieldValue.serverTimestamp(),
          'buyerDisplayName': buyerName ?? 'ผู้ซื้อ',
          'sellerDisplayName': sellerName ?? 'ผู้ขาย',
          if (senderId == buyerId)
            'unreadCountSeller': FieldValue.increment(1)
          else if (senderId == sellerId)
            'unreadCountBuyer': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error sending chat message: $e');
      throw Exception('Failed to send chat message.');
    }
  }

  Stream<List<Map<String, dynamic>>> getChatRoomsForUser(String userId) {
    // TODO: Consider creating a ChatRoomSummary model for better type safety and reusability.
    return _firestore
        .collection(_FirestoreCollections.chats)
        .where('participants', arrayContains: userId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          print("Error: Chat room data is null for doc ${doc.id}");
          return <String, dynamic>{
            'chatId': doc.id,
            'error': 'Data is null',
            'unreadCount': 0
          };
        }
        String buyerId = data['buyerId']?.toString() ?? '';
        String sellerId = data['sellerId']?.toString() ?? '';

        String otherUserId;
        String otherUserDisplayName;

        if (userId == buyerId) {
          otherUserId = sellerId;
          otherUserDisplayName =
              data['sellerDisplayName']?.toString() ?? 'ผู้ขาย';
        } else {
          otherUserId = buyerId;
          otherUserDisplayName =
              data['buyerDisplayName']?.toString() ?? 'ผู้ซื้อ';
        }

        int unreadCount = 0;
        if (userId == buyerId && data['unreadCountBuyer'] != null) {
          unreadCount = (data['unreadCountBuyer'] as num?)?.toInt() ?? 0;
        } else if (userId == sellerId && data['unreadCountSeller'] != null) {
          unreadCount = (data['unreadCountSeller'] as num?)?.toInt() ?? 0;
        }

        return {
          'chatId': doc.id,
          'productId': data['productId']?.toString(),
          'productName': data['productName']?.toString(),
          'productImageUrl': data['productImageUrl']?.toString(),
          'buyerId': buyerId,
          'sellerId': sellerId,
          'lastMessage': data['lastMessage']?.toString(),
          'lastTimestamp': data['lastTimestamp'] as Timestamp?,
          'otherUserId': otherUserId,
          'otherUserDisplayName': otherUserDisplayName,
          'unreadCount': unreadCount,
        };
      }).toList();
    }).transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching chat rooms for user ($userId): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch chat rooms: ${error.toString()}"),
          stackTrace);
    }));
  }

  Future<void> markChatRoomAsRead(String chatId, String userId) async {
    try {
      final chatDocRef =
          _firestore.collection(_FirestoreCollections.chats).doc(chatId);
      final chatDoc = await chatDocRef.get();
      if (chatDoc.exists) {
        final data = chatDoc.data(); // data will be Map<String, dynamic>?
        if (data != null && userId == data['buyerId']?.toString()) {
          await chatDocRef.update({'unreadCountBuyer': 0});
        } else if (data != null && userId == data['sellerId']?.toString()) {
          await chatDocRef.update({'unreadCountSeller': 0});
        }
      }
    } catch (e) {
      print('Error marking chat room as read: $e');
      throw Exception('Failed to mark chat room as read.');
    }
  }

  Future<String> generateMockQrCode(double amount) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      const String baseQrUrl =
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=';
      return '$baseQrUrl${Uri.encodeComponent('Amount: ${amount.toStringAsFixed(2)} THB')}';
    } catch (e) {
      print('Error generating mock QR code: $e');
      // For a real app, this might throw or return a specific error indicator.
      return '';
    }
  }

  // --- Category Management ---
  Future<void> addCategory(Category category) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.categories)
          .add(category.toFirestore());
    } catch (e) {
      print('Error adding category: $e');
      throw Exception('Failed to add category.');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.categories)
          .doc(category.id)
          .update(category.toFirestore());
    } catch (e) {
      print('Error updating category: $e');
      throw Exception('Failed to update category.');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.categories)
          .doc(categoryId)
          .delete();
    } catch (e) {
      print('Error deleting category: $e');
      throw Exception('Failed to delete category.');
    }
  }

  Stream<List<Category>> getCategories() {
    return _firestore
        .collection(_FirestoreCollections.categories)
        .orderBy('name', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching categories: $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch categories: ${error.toString()}"),
          stackTrace);
    }));
  }

  Future<String?> uploadWebImage(
      String storagePath, String fileName, Uint8List imageBytes) async {
    // Uses the consolidated _uploadDataToStorage method
    return _uploadDataToStorage(storagePath, fileName, imageBytes,
        contentType: 'image/jpeg');
  }

  Stream<List<app_order.Order>> getOrdersForSeller(String sellerId) {
    return _firestore
        .collection(_FirestoreCollections.orders)
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.Order.fromFirestore(doc))
            .toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching orders for seller ($sellerId): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch seller orders: ${error.toString()}"),
          stackTrace);
    }));
  }

  // --- Notification Management ---
  Future<void> addNotification(AppNotification notification) async {
    try {
      if (notification.userId.isEmpty) {
        print(
            "Error: userId is empty in notification. Notification not added.");
        return;
      }
      await _firestore
          .collection(_FirestoreCollections.notifications)
          .add(notification.toFirestore());
    } catch (e) {
      print('Error adding notification: $e');
      throw Exception('Failed to add notification.');
    }
  }

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection(_FirestoreCollections.notifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching user notifications ($userId): $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch user notifications: ${error.toString()}"),
          stackTrace);
    }));
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.notifications)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read.');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_FirestoreCollections.notifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return;
      }

      WriteBatch batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read.');
    }
  }

  Future<bool> hasUserReviewedProductInOrder(
      String userId, String orderId, String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_FirestoreCollections.reviews)
          .where('userId', isEqualTo: userId)
          .where('orderId', isEqualTo: orderId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user reviewed product: $e');
      // Depending on UI needs, might rethrow or return a specific error state.
      return false;
    }
  }

  Future<void> saveUserShippingAddress(
      String userId, Map<String, dynamic> addressData) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.users)
          .doc(userId)
          .collection(_FirestoreCollections.addresses)
          .doc('default_shipping')
          .set(addressData);
    } catch (e) {
      print('Error saving shipping address: $e');
      throw Exception('Failed to save shipping address.');
    }
  }

  Future<Map<String, dynamic>?> getUserShippingAddress(String userId) async {
    try {
      final doc = await _firestore
          .collection(_FirestoreCollections.users)
          .doc(userId)
          .collection(_FirestoreCollections.addresses)
          .doc('default_shipping')
          .get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting shipping address: $e');
      // Consider rethrowing or returning a specific error state
      return null;
    }
  }

  Future<void> requestToBeSeller(String userId) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.users)
          .doc(userId)
          .update({
        'sellerApplicationStatus': 'pending',
        'sellerApplicationTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user to seller: $e');
      throw Exception('Failed to submit seller application. Please try again.');
    }
  }

  Future<void> deleteImageByUrl(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      Reference photoRef = _storage.refFromURL(imageUrl);
      await photoRef.delete();
      print('Successfully deleted image: $imageUrl');
    } catch (e) {
      print('Error deleting image by URL: $e. URL: $imageUrl');
    }
  }

  // --- Shop Management (for Sellers) ---
  Future<Map<String, dynamic>?> getShopDetails(String sellerId) async {
    try {
      final doc = await _firestore
          .collection(_FirestoreCollections.shops)
          .doc(sellerId)
          .get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting shop details: $e');
      // Consider rethrowing or returning a specific error state
      return null;
    }
  }

  Future<void> updateShopDetails(
      String sellerId, String shopName, String shopDescription,
      {String? shopImageUrl}) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.shops)
          .doc(sellerId)
          .set({
        'shopName': shopName,
        'shopDescription': shopDescription,
        if (shopImageUrl != null) 'shopImageUrl': shopImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating shop details: $e');
      throw Exception('Failed to update shop details.');
    }
  }

  // --- Review Management ---
  Future<void> addReview(Review review) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.reviews)
          .add(review.toFirestore());
      // TODO: Implement Cloud Function to update product's average rating and review count.
      // This is crucial for scalability and data consistency.
    } catch (e) {
      print('FirebaseService: Error adding review: $e');
      throw Exception('Failed to submit review.');
    }
  }

  Stream<List<Review>> getReviewsForProduct(String productId) {
    return _firestore
        .collection(_FirestoreCollections.reviews)
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching reviews for product $productId: $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch product reviews: ${error.toString()}"),
          stackTrace);
    }));
  }

  // --- Admin: Seller Application Management ---
  Stream<List<Map<String, dynamic>>> getPendingSellerApplications() {
    return _firestore
        .collection(_FirestoreCollections.users)
        .where('sellerApplicationStatus', isEqualTo: 'pending')
        .orderBy('sellerApplicationTimestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) {
                print(
                    "Error: Seller application data is null for doc ${doc.id}");
                return <String, dynamic>{
                  'uid': doc.id,
                  'error': 'Data is null',
                };
              }
              data['uid'] = doc.id;
              return data;
            }).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching pending seller applications: $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch seller applications: ${error.toString()}"),
          stackTrace);
    }));
  }

  Future<void> approveSellerApplication(String userId) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.users)
          .doc(userId)
          .update({
        'isSeller': true,
        'sellerApplicationStatus': 'approved',
      });
      // TODO: Send notification to user about approval.
      print('FirebaseService: Seller application approved for $userId');
    } catch (e) {
      print('Error approving seller application for $userId: $e');
      throw Exception('Failed to approve seller application.');
    }
  }

  Future<void> rejectSellerApplication(String userId, {String? reason}) async {
    try {
      await _firestore
          .collection(_FirestoreCollections.users)
          .doc(userId)
          .update({
        'sellerApplicationStatus': 'rejected',
        if (reason != null && reason.isNotEmpty)
          'sellerApplicationRejectionReason': reason,
        // Optionally, reset isSeller if it could have been true from a previous state
        // 'isSeller': false,
      });
      print('FirebaseService: Seller application rejected for $userId');
    } catch (e) {
      print('Error rejecting seller application for $userId: $e');
      throw Exception('Failed to reject seller application.');
    }
  }

  Stream<int> getTotalOrdersCount() {
    return _firestore
        .collection(_FirestoreCollections.orders)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching total orders count: $error");
      sink.addError(
          Exception("Failed to fetch total orders count: ${error.toString()}"),
          stackTrace);
    }));
  }

  Stream<int> getTotalUsersCount() {
    return _firestore
        .collection(_FirestoreCollections.users)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching total users count: $error");
      sink.addError(
          Exception("Failed to fetch total users count: ${error.toString()}"),
          stackTrace);
    }));
  }

  Stream<int> getTotalProductsCount() {
    return _firestore
        .collection(_FirestoreCollections.products)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching total products count: $error");
      sink.addError(
          Exception(
              "Failed to fetch total products count: ${error.toString()}"),
          stackTrace);
    }));
  }

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore
        .collection(_FirestoreCollections.users)
        .orderBy('createdAt',
            descending: true) // Optional: order by creation date
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['uid'] = doc.id; // Add document ID to the data map
              return data;
            }).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching all users: $error");
      print("Stacktrace: $stackTrace");
      sink.addError(Exception("Failed to fetch all users: ${error.toString()}"),
          stackTrace);
    }));
  }

  Future<void> updateUserRolesAndStatus(
      String userId, Map<String, dynamic> updates) async {
    try {
      final userDocRef =
          _firestore.collection(_FirestoreCollections.users).doc(userId);

      // Safety check: Prevent accidentally removing admin rights from the main admin account via UI
      if (updates.containsKey('isAdmin') && updates['isAdmin'] == false) {
        final userDoc = await userDocRef.get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null &&
              userData['email']?.toLowerCase() == kAdminEmail.toLowerCase()) {
            print(
                "FirebaseService: Critical action blocked. Cannot remove admin rights from the primary admin account (${userData['email']}) via this method.");
            throw Exception("ไม่สามารถลบสิทธิ์แอดมินออกจากบัญชีแอดมินหลักได้");
          }
        }
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await userDocRef.update(updates);
      print(
          'FirebaseService: User roles/status updated for $userId with data: $updates');
    } catch (e) {
      print('Error updating user roles/status for $userId: $e');
      // Rethrow specific exceptions if needed, or a generic one
      if (e is Exception && e.toString().contains("ไม่สามารถลบสิทธิ์แอดมิน")) {
        rethrow;
      }
      throw Exception('Failed to update user roles/status.');
    }
  }

  Future<void> updateUserSuspensionStatus(String userId, bool suspend,
      {String? reason}) async {
    try {
      final userDocRef =
          _firestore.collection(_FirestoreCollections.users).doc(userId);

      // Safety check: Prevent suspending the main admin account
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null &&
            userData['email']?.toLowerCase() == kAdminEmail.toLowerCase() &&
            suspend) {
          print(
              "FirebaseService: Critical action blocked. Cannot suspend the primary admin account (${userData['email']}).");
          throw Exception("ไม่สามารถระงับบัญชีแอดมินหลักได้");
        }
      }

      Map<String, dynamic> updates = {
        'isSuspended': suspend,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (suspend && reason != null && reason.isNotEmpty) {
        updates['suspensionReason'] = reason;
      } else if (!suspend) {
        // Optionally clear the reason when unsuspending
        updates['suspensionReason'] = FieldValue.delete();
      }
      await userDocRef.update(updates);
      print(
          'FirebaseService: User $userId suspension status set to $suspend ${suspend && reason != null ? "with reason: $reason" : ""}');
    } catch (e) {
      print('Error updating user suspension status for $userId: $e');
      if (e is Exception &&
          e.toString().contains("ไม่สามารถระงับบัญชีแอดมินหลักได้")) {
        rethrow;
      }
      throw Exception('Failed to update user suspension status.');
    }
  }

  // --- Promotion Management (Admin) ---
  Stream<List<Promotion>> getPromotions() {
    return _firestore
        .collection(_FirestoreCollections.promotions)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Promotion.fromFirestore(doc)).toList())
        .transform(StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
      print("Error fetching promotions: $error");
      print("Stacktrace: $stackTrace");
      sink.addError(
          Exception("Failed to fetch promotions: ${error.toString()}"),
          stackTrace);
    }));
  }

  // --- Other
  Future<Map<String, dynamic>?> getSellerById(String sellerId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_FirestoreCollections.users)
          .doc(sellerId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        print(
            "FirebaseService: Seller document for $sellerId does not exist or has no data.");
        return null;
      }
    } catch (e, s) {
      print('Error getting seller data for $sellerId: $e');
      print('Stacktrace: $s');
      // Consider rethrowing or returning a specific error state
    }
    return null;
  }

  // This method is used by AdminPanelScreen for adding products on non-web platforms
  Future<String?> uploadImage(String storagePath, String filePath,
      {required String fileName}) async {
    try {
      // The fileName is already constructed with UUID in AdminPanelScreen, so we can use it directly.
      Reference ref = _storage.ref().child(storagePath).child(fileName);
      UploadTask uploadTask = ref.putFile(File(filePath));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print(
          'Error uploading image file ($filePath) as $fileName to $storagePath: $e');
      throw Exception('Image upload failed.');
    }
  }
}

// TODO: For a large application like Shopee, consider breaking this FirebaseService into smaller, more focused services
// e.g., AuthService, ProductService, OrderService, ChatService, AdminService, etc.
// This improves modularity, testability, and maintainability.
