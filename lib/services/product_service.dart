import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/models/review.dart';
import 'package:flutter/foundation.dart';

/// Product cache entry with expiry
class CachedProduct {
  final Product product;
  final DateTime cachedAt;

  CachedProduct(this.product, this.cachedAt);

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(minutes: 10);
}

/// Product list cache entry with expiry
class CachedProductList {
  final List<Product> products;
  final DateTime cachedAt;
  final String query;

  CachedProductList(this.products, this.cachedAt, this.query);

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(minutes: 10);
}

/// Validation result for product data
class ProductValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ProductValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// Product analytics data
class ProductAnalytics {
  final int totalViews;
  final int totalOrders;
  final double averageRating;
  final int reviewCount;
  final double conversionRate;
  final Map<String, int> viewsByDate;

  ProductAnalytics({
    required this.totalViews,
    required this.totalOrders,
    required this.averageRating,
    required this.reviewCount,
    required this.conversionRate,
    required this.viewsByDate,
  });
}

/// Product search result with relevance score
class ProductSearchResult {
  final Product product;
  final double score;

  ProductSearchResult(this.product, this.score);
}

/// Enhanced Product Service with comprehensive product management features
/// Provides caching, validation, performance optimizations, and analytics
class ProductService {
  static const String _tag = 'ProductService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Caching configuration
  static const int _maxCacheSize = 100;

  // Cache for products
  final Map<String, CachedProduct> _productCache = {};
  final Map<String, CachedProductList> _listCache = {};

  // Performance tracking
  final Map<String, DateTime> _operationTimes = {};

  // Validation rules
  static const int _minNameLength = 3;
  static const int _maxNameLength = 100;
  static const int _minDescriptionLength = 10;
  static const int _maxDescriptionLength = 1000;
  static const double _minPrice = 0.01;
  static const double _maxPrice = 1000000.0;
  static const int _minStock = 0;
  static const int _maxStock = 999999;

  // PRODUCT CRUD OPERATIONS

  /// Get product by ID with caching
  Future<Product?> getProductById(String productId) async {
    try {
      _startOperationTimer('getProductById');

      // Check cache first
      if (_productCache.containsKey(productId)) {
        final cached = _productCache[productId]!;
        if (!cached.isExpired) {
          _endOperationTimer('getProductById');
          return cached.product;
        }
        _productCache.remove(productId);
      }

      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) {
        _endOperationTimer('getProductById');
        return null;
      }

      final product = Product.fromMap(doc.data()!);

      // Cache the result
      _cacheProduct(productId, product);

      _endOperationTimer('getProductById');
      return product;
    } catch (e) {
      _logError('getProductById', e);
      _endOperationTimer('getProductById');
      return null;
    }
  }

  /// Get products with advanced filtering and caching
  Future<List<Product>> getProducts({
    int limit = 20,
    String? category,
    String? sellerId,
    double? minPrice,
    double? maxPrice,
    bool? isApproved,
    String? sortBy = 'createdAt',
    bool descending = true,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      _startOperationTimer('getProducts');

      final cacheKey = _generateListCacheKey(limit, category, sellerId,
          minPrice, maxPrice, isApproved, sortBy, descending);

      // Check cache first (only for first page)
      if (startAfter == null && _listCache.containsKey(cacheKey)) {
        final cached = _listCache[cacheKey]!;
        if (!cached.isExpired) {
          _endOperationTimer('getProducts');
          return cached.products;
        }
        _listCache.remove(cacheKey);
      }

      Query query = _firestore.collection('products');

      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (sellerId != null && sellerId.isNotEmpty) {
        query = query.where('sellerId', isEqualTo: sellerId);
      }

      if (isApproved != null) {
        query = query.where('isApproved', isEqualTo: isApproved);
      }

      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      // Apply sorting
      query = query.orderBy(sortBy ?? 'createdAt', descending: descending);

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Cache the result (only first page)
      if (startAfter == null) {
        _cacheProductList(cacheKey, products);
      }

      // Cache individual products
      for (final product in products) {
        _cacheProduct(product.id, product);
      }

      _endOperationTimer('getProducts');
      return products;
    } catch (e) {
      _logError('getProducts', e);
      _endOperationTimer('getProducts');
      return [];
    }
  }

  /// Search products with advanced features
  Future<List<Product>> searchProducts({
    required String searchTerm,
    int limit = 20,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool searchInDescription = true,
  }) async {
    try {
      _startOperationTimer('searchProducts');

      if (searchTerm.trim().isEmpty) {
        return getProducts(
            limit: limit,
            category: category,
            minPrice: minPrice,
            maxPrice: maxPrice);
      }

      final searchTermLower = searchTerm.toLowerCase().trim();
      final searchWords =
          searchTermLower.split(' ').where((word) => word.isNotEmpty).toList();

      Query query = _firestore
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true);

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Apply price filters
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      final snapshot =
          await query.limit(limit * 2).get(); // Get more for filtering
      final allProducts = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Client-side search with scoring
      final searchResults = <ProductSearchResult>[];

      for (final product in allProducts) {
        final score =
            _calculateSearchScore(product, searchWords, searchInDescription);
        if (score > 0) {
          searchResults.add(ProductSearchResult(product, score));
        }
      }

      // Sort by relevance score and return top results
      searchResults.sort((a, b) => b.score.compareTo(a.score));
      final products =
          searchResults.take(limit).map((result) => result.product).toList();

      _endOperationTimer('searchProducts');
      return products;
    } catch (e) {
      _logError('searchProducts', e);
      _endOperationTimer('searchProducts');
      return [];
    }
  }

  /// Add new product with comprehensive validation
  Future<String?> addProduct(Product product) async {
    try {
      _startOperationTimer('addProduct');

      // Validate product data
      final validation = validateProduct(product);
      if (!validation.isValid) {
        _logError(
            'addProduct', 'Validation failed: ${validation.errors.join(', ')}');
        _endOperationTimer('addProduct');
        return null;
      }

      // Check seller permissions
      if (!await _validateSellerPermissions(product.sellerId)) {
        _logError('addProduct', 'Invalid seller permissions');
        _endOperationTimer('addProduct');
        return null;
      }

      // Generate product ID and prepare data
      final productId = _firestore.collection('products').doc().id;
      final productData = product.toMap();

      // Add metadata
      productData.addAll({
        'id': productId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'status': 'pending_approval', // Requires admin approval
        'isActive': true,
      });

      // Add to Firestore
      await _firestore.collection('products').doc(productId).set(productData);

      // Create updated product for cache
      final enhancedProduct = Product.fromMap(productData);
      _cacheProduct(productId, enhancedProduct);

      // Clear related list caches
      _clearListCaches();

      // Log activity
      await _logProductActivity(
          productId, 'created', {'sellerId': product.sellerId});

      _endOperationTimer('addProduct');
      return productId;
    } catch (e) {
      _logError('addProduct', e);
      _endOperationTimer('addProduct');
      return null;
    }
  }

  /// Update product with validation
  Future<bool> updateProduct(Product product) async {
    try {
      _startOperationTimer('updateProduct');

      // Validate product data
      final validation = validateProduct(product);
      if (!validation.isValid) {
        _logError('updateProduct',
            'Validation failed: ${validation.errors.join(', ')}');
        _endOperationTimer('updateProduct');
        return false;
      }

      // Check seller permissions
      if (!await _validateSellerPermissions(product.sellerId)) {
        _logError('updateProduct', 'Invalid seller permissions');
        _endOperationTimer('updateProduct');
        return false;
      }

      // Prepare update data
      final updateData = product.toMap();
      updateData['updatedAt'] = Timestamp.now();

      // Update in Firestore
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(updateData);

      // Update cache
      _cacheProduct(product.id, product);

      // Clear related list caches
      _clearListCaches();

      // Log activity
      await _logProductActivity(
          product.id, 'updated', {'sellerId': product.sellerId});

      _endOperationTimer('updateProduct');
      return true;
    } catch (e) {
      _logError('updateProduct', e);
      _endOperationTimer('updateProduct');
      return false;
    }
  }

  /// Delete product (soft delete)
  Future<bool> deleteProduct(String productId) async {
    try {
      _startOperationTimer('deleteProduct');

      final product = await getProductById(productId);
      if (product == null) {
        _endOperationTimer('deleteProduct');
        return false;
      }

      // Check seller permissions
      if (!await _validateSellerPermissions(product.sellerId)) {
        _logError('deleteProduct', 'Invalid seller permissions');
        _endOperationTimer('deleteProduct');
        return false;
      }

      // Soft delete - mark as inactive
      await _firestore.collection('products').doc(productId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from cache
      _productCache.remove(productId);

      // Clear related list caches
      _clearListCaches();

      // Log activity
      await _logProductActivity(
          productId, 'deleted', {'sellerId': product.sellerId});

      _endOperationTimer('deleteProduct');
      return true;
    } catch (e) {
      _logError('deleteProduct', e);
      _endOperationTimer('deleteProduct');
      return false;
    }
  }

  // PRODUCT ANALYTICS

  /// Get comprehensive product analytics
  Future<ProductAnalytics?> getProductAnalytics(String productId) async {
    try {
      _startOperationTimer('getProductAnalytics');

      final product = await getProductById(productId);
      if (product == null) {
        _endOperationTimer('getProductAnalytics');
        return null;
      }

      // Get analytics data in parallel
      final futures = await Future.wait([
        _getProductViews(productId),
        _getProductOrders(productId),
        _getProductReviews(productId),
        _getProductViewsByDate(productId),
      ]);

      final totalViews = futures[0] as int;
      final totalOrders = futures[1] as int;
      final reviewData = futures[2] as Map<String, dynamic>;
      final viewsByDate = futures[3] as Map<String, int>;

      final conversionRate =
          totalViews > 0 ? (totalOrders / totalViews) * 100 : 0.0;

      final analytics = ProductAnalytics(
        totalViews: totalViews,
        totalOrders: totalOrders,
        averageRating: reviewData['averageRating'] ?? 0.0,
        reviewCount: reviewData['reviewCount'] ?? 0,
        conversionRate: conversionRate,
        viewsByDate: viewsByDate,
      );

      _endOperationTimer('getProductAnalytics');
      return analytics;
    } catch (e) {
      _logError('getProductAnalytics', e);
      _endOperationTimer('getProductAnalytics');
      return null;
    }
  }

  /// Record product view
  Future<void> recordProductView(String productId, {String? userId}) async {
    try {
      // Update product view count
      await _firestore.collection('products').doc(productId).update({
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });

      // Record detailed view analytics
      await _firestore.collection('product_analytics').add({
        'productId': productId,
        'userId': userId,
        'action': 'view',
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });

      // Update cache if exists (remove to force refresh)
      if (_productCache.containsKey(productId)) {
        _productCache.remove(productId);
      }
    } catch (e) {
      _logError('recordProductView', e);
    }
  }

  // VALIDATION METHODS

  /// Comprehensive product validation
  ProductValidationResult validateProduct(Product product) {
    final errors = <String>[];
    final warnings = <String>[];

    // Name validation
    if (product.name.trim().isEmpty) {
      errors.add('ชื่อสินค้าจำเป็นต้องกรอก');
    } else if (product.name.trim().length < _minNameLength) {
      errors.add('ชื่อสินค้าต้องมีอย่างน้อย $_minNameLength ตัวอักษร');
    } else if (product.name.trim().length > _maxNameLength) {
      errors.add('ชื่อสินค้าต้องมีไม่เกิน $_maxNameLength ตัวอักษร');
    }

    // Description validation
    if (product.description.trim().isEmpty) {
      errors.add('คำอธิบายสินค้าจำเป็นต้องกรอก');
    } else if (product.description.trim().length < _minDescriptionLength) {
      errors
          .add('คำอธิบายสินค้าต้องมีอย่างน้อย $_minDescriptionLength ตัวอักษร');
    } else if (product.description.trim().length > _maxDescriptionLength) {
      errors.add('คำอธิบายสินค้าต้องมีไม่เกิน $_maxDescriptionLength ตัวอักษร');
    }

    // Price validation
    if (product.price < _minPrice) {
      errors.add('ราคาสินค้าต้องมากกว่า $_minPrice บาท');
    } else if (product.price > _maxPrice) {
      errors.add('ราคาสินค้าต้องไม่เกิน $_maxPrice บาท');
    }

    // Stock validation
    if (product.stock < _minStock) {
      errors.add('จำนวนสต็อกต้องมากกว่าหรือเท่ากับ $_minStock');
    } else if (product.stock > _maxStock) {
      errors.add('จำนวนสต็อกต้องไม่เกิน $_maxStock');
    }

    // Category validation (using categoryId from Product model)
    if (product.categoryId.trim().isEmpty) {
      errors.add('หมวดหมู่สินค้าจำเป็นต้องเลือก');
    }

    // Images validation
    if (product.imageUrls.isEmpty) {
      errors.add('ต้องมีรูปภาพสินค้าอย่างน้อย 1 รูป');
    } else if (product.imageUrls.length > 10) {
      warnings.add('มีรูปภาพเยอะ อาจทำให้โหลดช้า');
    }

    // Seller validation
    if (product.sellerId.trim().isEmpty) {
      errors.add('ข้อมูลผู้ขายไม่ถูกต้อง');
    }

    // Warning for low stock
    if (product.stock < 10) {
      warnings.add('สต็อกสินค้าเหลือน้อย');
    }

    // Warning for high price
    if (product.price > 10000) {
      warnings.add('ราคาสินค้าสูง ควรตรวจสอบความถูกต้อง');
    }

    return ProductValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // HELPER METHODS

  /// Cache a single product
  void _cacheProduct(String productId, Product product) {
    if (_productCache.length >= _maxCacheSize) {
      // Remove oldest entry
      final oldestKey = _productCache.keys.first;
      _productCache.remove(oldestKey);
    }
    _productCache[productId] = CachedProduct(product, DateTime.now());
  }

  /// Cache a product list
  void _cacheProductList(String cacheKey, List<Product> products) {
    if (_listCache.length >= _maxCacheSize) {
      // Remove oldest entry
      final oldestKey = _listCache.keys.first;
      _listCache.remove(oldestKey);
    }
    _listCache[cacheKey] =
        CachedProductList(products, DateTime.now(), cacheKey);
  }

  /// Generate cache key for product lists
  String _generateListCacheKey(
      int limit,
      String? category,
      String? sellerId,
      double? minPrice,
      double? maxPrice,
      bool? isApproved,
      String? sortBy,
      bool descending) {
    return 'products_${limit}_${category ?? ''}_${sellerId ?? ''}_'
        '${minPrice ?? ''}_${maxPrice ?? ''}_${isApproved ?? ''}_'
        '${sortBy ?? ''}_$descending';
  }

  /// Clear all list caches
  void _clearListCaches() {
    _listCache.clear();
  }

  /// Calculate search relevance score
  double _calculateSearchScore(
      Product product, List<String> searchWords, bool searchInDescription) {
    double score = 0.0;
    final nameLower = product.name.toLowerCase();
    final descriptionLower = product.description.toLowerCase();

    for (final word in searchWords) {
      // Exact match in name (highest score)
      if (nameLower.contains(word)) {
        score += 10.0;
      }

      // Exact match in description
      if (searchInDescription && descriptionLower.contains(word)) {
        score += 5.0;
      }

      // Category match (using categoryId and categoryName)
      if (product.categoryId.toLowerCase().contains(word) ||
          (product.categoryName?.toLowerCase().contains(word) ?? false)) {
        score += 3.0;
      }
    }

    // Boost score for approved products (using status field)
    if (product.status == 'approved' || product.approvalStatus == 'approved') {
      score *= 1.2;
    }

    // Boost score for active products
    if (product.isActive) {
      score *= 1.1;
    }

    // Boost score based on rating (using averageRating from Product model)
    if (product.averageRating > 0) {
      score *= (1.0 + (product.averageRating / 10.0));
    }

    return score;
  }

  /// Validate seller permissions
  Future<bool> _validateSellerPermissions(String sellerId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Admin can manage all products
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data()?['isAdmin'] == true) {
        return true;
      }

      // Seller can only manage their own products
      return currentUser.uid == sellerId;
    } catch (e) {
      return false;
    }
  }

  /// Get product views count
  Future<int> _getProductViews(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      return doc.data()?['viewCount'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get product orders count
  Future<int> _getProductOrders(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('items', arrayContains: {'productId': productId})
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get product reviews data
  Future<Map<String, dynamic>> _getProductReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'averageRating': 0.0, 'reviewCount': 0};
      }

      double totalRating = 0;
      for (final doc in snapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }

      return {
        'averageRating': totalRating / snapshot.docs.length,
        'reviewCount': snapshot.docs.length,
      };
    } catch (e) {
      return {'averageRating': 0.0, 'reviewCount': 0};
    }
  }

  /// Get product views by date
  Future<Map<String, int>> _getProductViewsByDate(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('product_analytics')
          .where('productId', isEqualTo: productId)
          .where('action', isEqualTo: 'view')
          .get();

      final viewsByDate = <String, int>{};
      for (final doc in snapshot.docs) {
        final date = doc.data()['date'] as String? ?? '';
        viewsByDate[date] = (viewsByDate[date] ?? 0) + 1;
      }

      return viewsByDate;
    } catch (e) {
      return {};
    }
  }

  /// Log product activity
  Future<void> _logProductActivity(
      String productId, String action, Map<String, dynamic>? metadata) async {
    try {
      await _firestore.collection('product_activity_logs').add({
        'productId': productId,
        'action': action,
        'userId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      // Ignore logging errors
    }
  }

  /// Start operation timer for performance tracking
  void _startOperationTimer(String operation) {
    _operationTimes[operation] = DateTime.now();
  }

  /// End operation timer and log performance
  void _endOperationTimer(String operation) {
    final startTime = _operationTimes.remove(operation);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      if (kDebugMode) {
        print('[$_tag] $operation took ${duration.inMilliseconds}ms');
      }
    }
  }

  /// Log errors for debugging
  void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      print('[$_tag] Error in $operation: $error');
    }
  }

  /// Clear all caches
  void clearCache() {
    _productCache.clear();
    _listCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'productCacheSize': _productCache.length,
      'listCacheSize': _listCache.length,
      'productCacheHitRate': _productCache.isNotEmpty
          ? _productCache.values.where((p) => !p.isExpired).length /
              _productCache.length
          : 0.0,
      'listCacheHitRate': _listCache.isNotEmpty
          ? _listCache.values.where((l) => !l.isExpired).length /
              _listCache.length
          : 0.0,
    };
  }
}
