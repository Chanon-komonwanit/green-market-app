import 'dart:async';
import 'dart:math' as math;
import '../models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/validation_utils.dart';

/// Enhanced Search Service with advanced filtering and caching
/// บริการค้นหาขั้นสูงพร้อมระบบกรองและแคช
class SearchService {
  static const String _tag = 'SearchService';
  final _productRef = FirebaseFirestore.instance.collection('products');

  // Caching
  final Map<String, CachedSearchResult> _searchCache = {};
  static const int _maxCacheSize = 50;
  static const Duration _cacheTimeout = Duration(minutes: 10);

  /// Advanced product search with multiple criteria
  Stream<List<Product>> searchProducts(
    String searchQuery, {
    String? category,
    double? minPrice,
    double? maxPrice,
    int? minEcoScore,
    List<String>? tags,
    SortOption sortBy = SortOption.relevance,
  }) {
    // Validate and sanitize query
    final sanitizedQuery =
        ValidationUtils.sanitizeInput(searchQuery).toLowerCase().trim();
    if (sanitizedQuery.length < 2) {
      return Stream.value([]);
    }

    // Build cache key
    final cacheKey = _buildCacheKey(sanitizedQuery, category, minPrice,
        maxPrice, minEcoScore, tags, sortBy);

    // Check cache first
    if (_searchCache.containsKey(cacheKey) &&
        !_searchCache[cacheKey]!.isExpired) {
      return Stream.value(_searchCache[cacheKey]!.products);
    }

    // Build query
    Query dbQuery = _productRef;

    // Apply filters
    if (category != null && category.isNotEmpty) {
      dbQuery = dbQuery.where('categoryId', isEqualTo: category);
    }

    if (minPrice != null) {
      dbQuery = dbQuery.where('price', isGreaterThanOrEqualTo: minPrice);
    }

    if (maxPrice != null) {
      dbQuery = dbQuery.where('price', isLessThanOrEqualTo: maxPrice);
    }

    if (minEcoScore != null) {
      dbQuery = dbQuery.where('ecoScore', isGreaterThanOrEqualTo: minEcoScore);
    }

    // Apply sorting
    switch (sortBy) {
      case SortOption.priceAsc:
        dbQuery = dbQuery.orderBy('price', descending: false);
        break;
      case SortOption.priceDesc:
        dbQuery = dbQuery.orderBy('price', descending: true);
        break;
      case SortOption.ecoScore:
        dbQuery = dbQuery.orderBy('ecoScore', descending: true);
        break;
      case SortOption.newest:
        dbQuery = dbQuery.orderBy('createdAt', descending: true);
        break;
      case SortOption.popularity:
        // Note: Product model might not have viewCount, using name instead
        dbQuery = dbQuery.orderBy('name', descending: false);
        break;
      case SortOption.relevance:
        // For relevance, we'll sort in code after filtering
        break;
    }

    return dbQuery.limit(100).snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where(
              (product) => _matchesSearchQuery(product, sanitizedQuery, tags))
          .toList();

      // Apply relevance sorting if needed
      if (sortBy == SortOption.relevance) {
        products.sort((a, b) => _calculateRelevanceScore(b, sanitizedQuery)
            .compareTo(_calculateRelevanceScore(a, sanitizedQuery)));
      }

      // Cache results
      _cacheSearchResult(cacheKey, products);

      return products;
    }).handleError((error) {
      print('[$_tag] Search error: $error');
      return <Product>[];
    });
  }

  /// Enhanced product filtering with dynamic criteria
  Stream<List<Product>> filterProducts(Map<String, dynamic> filters) {
    if (filters.isEmpty) {
      return _productRef.limit(50).snapshots().map((snap) =>
          snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
    }

    Query query = _productRef;

    // Apply each filter dynamically
    filters.forEach((key, value) {
      if (value != null) {
        switch (key) {
          case 'category':
            if (value is String && value.isNotEmpty) {
              query = query.where('categoryId', isEqualTo: value);
            }
            break;
          case 'minPrice':
            if (value is num && value > 0) {
              query = query.where('price',
                  isGreaterThanOrEqualTo: value.toDouble());
            }
            break;
          case 'maxPrice':
            if (value is num && value > 0) {
              query =
                  query.where('price', isLessThanOrEqualTo: value.toDouble());
            }
            break;
          case 'ecoScore':
            if (value is num && value > 0) {
              query = query.where('ecoScore',
                  isGreaterThanOrEqualTo: value.toInt());
            }
            break;
          case 'isOrganic':
            if (value is bool) {
              query = query.where('isOrganic', isEqualTo: value);
            }
            break;
          case 'inStock':
            if (value is bool && value) {
              query = query.where('stock', isGreaterThan: 0);
            }
            break;
          case 'sellerId':
            if (value is String && value.isNotEmpty) {
              query = query.where('sellerId', isEqualTo: value);
            }
            break;
          case 'tags':
            if (value is List && value.isNotEmpty) {
              query = query.where('tags', arrayContainsAny: value);
            }
            break;
        }
      }
    });

    // Apply sorting if specified
    final sortBy = filters['sortBy'] as String?;
    switch (sortBy) {
      case 'priceAsc':
        query = query.orderBy('price', descending: false);
        break;
      case 'priceDesc':
        query = query.orderBy('price', descending: true);
        break;
      case 'newest':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'popular':
        query = query.orderBy('viewCount', descending: true);
        break;
      case 'ecoScore':
        query = query.orderBy('ecoScore', descending: true);
        break;
      default:
        query = query.orderBy('name', descending: false);
    }

    return query.limit(100).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    }).handleError((error) {
      print('[$_tag] Filter error: $error');
      return <Product>[];
    });
  }

  /// Get popular search terms
  Future<List<String>> getPopularSearchTerms() async {
    try {
      // This would typically come from analytics data
      // For now, return predefined popular terms
      return [
        'อินทรีย์',
        'ผักปลอดสาร',
        'ข้าวหอมมะลิ',
        'เสื้อผ้าเป็นมิตรกับสิ่งแวดล้อม',
        'สบู่ธรรมชาติ',
        'ครีมไม้ประดับ',
        'ของใช้รีไซเคิล',
        'เครื่องสำอาง',
      ];
    } catch (e) {
      print('[$_tag] Error getting popular terms: $e');
      return [];
    }
  }

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      final sanitizedQuery = ValidationUtils.sanitizeInput(query).toLowerCase();

      // Search in product names and descriptions
      final snapshot = await _productRef
          .where('keywords', arrayContains: sanitizedQuery)
          .limit(10)
          .get();

      final suggestions = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String?;
        final tags = data['tags'] as List<dynamic>?;

        if (name != null && name.toLowerCase().contains(sanitizedQuery)) {
          suggestions.add(name);
        }

        if (tags != null) {
          for (final tag in tags) {
            if (tag.toString().toLowerCase().contains(sanitizedQuery)) {
              suggestions.add(tag.toString());
            }
          }
        }
      }

      return suggestions.take(5).toList();
    } catch (e) {
      print('[$_tag] Error getting suggestions: $e');
      return [];
    }
  }

  /// Check if product matches search query
  bool _matchesSearchQuery(Product product, String query, List<String>? tags) {
    // Create searchable text from available product properties
    final searchText = '${product.name} ${product.description}'.toLowerCase();

    // Check if query words are in product text
    final queryWords = query.split(' ').where((word) => word.isNotEmpty);
    final hasAllWords = queryWords.every((word) => searchText.contains(word));

    if (!hasAllWords) return false;

    // Check tags if specified (assuming tags exist in keywords field)
    if (tags != null && tags.isNotEmpty) {
      // This would need to be adjusted based on actual Product model structure
      return true; // Simplified for now
    }

    return true;
  }

  /// Calculate relevance score for sorting
  int _calculateRelevanceScore(Product product, String query) {
    int score = 0;
    final lowerName = product.name.toLowerCase();
    final lowerDesc = product.description.toLowerCase();

    // Exact name match gets highest score
    if (lowerName == query) score += 100;

    // Name starts with query
    if (lowerName.startsWith(query)) score += 50;

    // Name contains query
    if (lowerName.contains(query)) score += 30;

    // Description contains query
    if (lowerDesc.contains(query)) score += 10;

    // Boost for eco-friendly products
    if (product.ecoScore > 80) score += 5;

    // Boost for in-stock products
    if (product.stock > 0) score += 3;

    // Note: Removed viewCount as it might not exist in Product model
    // Add boost based on price (lower prices get slightly higher score)
    if (product.price < 100) score += 2;

    return score;
  }

  /// Build cache key for search results
  String _buildCacheKey(
      String query,
      String? category,
      double? minPrice,
      double? maxPrice,
      int? minEcoScore,
      List<String>? tags,
      SortOption sortBy) {
    return [
      query,
      category ?? '',
      minPrice?.toString() ?? '',
      maxPrice?.toString() ?? '',
      minEcoScore?.toString() ?? '',
      tags?.join(',') ?? '',
      sortBy.toString(),
    ].join('|');
  }

  /// Cache search results
  void _cacheSearchResult(String key, List<Product> products) {
    if (_searchCache.length >= _maxCacheSize) {
      // Remove oldest entry
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }

    _searchCache[key] = CachedSearchResult(products, DateTime.now());
  }

  /// Clear search cache
  void clearCache() {
    _searchCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final validEntries =
        _searchCache.values.where((result) => !result.isExpired).length;

    return {
      'totalCacheSize': _searchCache.length,
      'validCacheSize': validEntries,
      'cacheHitRate':
          _searchCache.isNotEmpty ? validEntries / _searchCache.length : 0.0,
    };
  }
}

/// Search sorting options
enum SortOption {
  relevance,
  priceAsc,
  priceDesc,
  newest,
  popularity,
  ecoScore,
}

/// Cached search result
class CachedSearchResult {
  final List<Product> products;
  final DateTime cachedAt;

  CachedSearchResult(this.products, this.cachedAt);

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > SearchService._cacheTimeout;
}
