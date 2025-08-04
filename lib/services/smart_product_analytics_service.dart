// lib/services/smart_product_analytics_service.dart
import '../models/product.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ระบบวิเคราะห์สินค้าอัจฉริยะ - Smart Product Analytics
/// ใช้ algorithm หลายชั้นเพื่อคัดเลือกสินค้าที่ดีที่สุด
class SmartProductAnalyticsService {
  static final SmartProductAnalyticsService _instance =
      SmartProductAnalyticsService._internal();
  factory SmartProductAnalyticsService() => _instance;
  SmartProductAnalyticsService._internal();

  /// ค่าน้ำหนักสำหรับการคำนวณคะแนน (AI-like scoring system)
  static const Map<String, double> _weightFactors = {
    'ecoScore': 0.35, // 35% - ระดับความเป็นมิตรกับสิ่งแวดล้อม (สำคัญที่สุด)
    'reviewScore': 0.25, // 25% - คะแนนรีวิว
    'orderCount': 0.20, // 20% - ยอดสั่งซื้อ
    'availability': 0.10, // 10% - สถานะความพร้อมขาย
    'recency': 0.05, // 5% - ความใหม่ของสินค้า
    'priceCompetitive': 0.05 // 5% - ความเหมาะสมของราคา
  };

  /// ดึงสินค้า Eco Hero อัจฉริยะ (8 สินค้า)
  Future<List<Product>> getSmartEcoHeroProducts() async {
    try {
      print(
          '[DEBUG] SmartProductAnalyticsService: Starting getSmartEcoHeroProducts...');

      // 1. ดึงสินค้าทั้งหมดที่ approved
      final allProducts = await _getAllApprovedProducts();
      print(
          '[DEBUG] SmartProductAnalyticsService: Found ${allProducts.length} approved products');

      if (allProducts.isEmpty) {
        print(
            '[DEBUG] SmartProductAnalyticsService: No approved products found');
        return [];
      }

      // 2. คำนวณคะแนนฉลาดสำหรับแต่ละสินค้า
      final analyzedProducts = await _analyzeProducts(allProducts);
      print(
          '[DEBUG] SmartProductAnalyticsService: Analyzed ${analyzedProducts.length} products');

      // 3. เรียงลำดับตามคะแนนรวม
      analyzedProducts
          .sort((a, b) => b['totalScore'].compareTo(a['totalScore']));

      // Debug: แสดงคะแนนของแต่ละสินค้า
      print('[DEBUG] SmartProductAnalyticsService: Product scores:');
      for (var data in analyzedProducts) {
        final product = data['product'] as Product;
        final score = data['totalScore'] as double;
        print(
            '  - ${product.name}: ${score.toStringAsFixed(2)} (EcoScore: ${product.ecoScore})');
      }

      // 4. เลือก 8 สินค้าแรก (หรือน้อยกว่าถ้ามีไม่ถึง)
      final selectedProducts = analyzedProducts
          .take(8)
          .map((data) => data['product'] as Product)
          .toList();

      print(
          '[DEBUG] SmartProductAnalyticsService: Selected ${selectedProducts.length} products for Eco Hero');
      return selectedProducts;
    } catch (e) {
      print('Error in getSmartEcoHeroProducts: $e');
      return [];
    }
  }

  /// ดึงสินค้า Eco Hero อัจฉริยะ (8 สินค้า) รวมข้อมูล Mock ถ้าจำเป็น
  Future<List<Product>> getSmartEcoHeroProductsEnhanced() async {
    try {
      // 1. ดึงสินค้าจริงก่อน
      final realProducts = await getSmartEcoHeroProducts();

      // 2. ถ้ามีสินค้าจริงครบ 8 รายการแล้ว ให้ return ทันที
      if (realProducts.length >= 8) {
        return realProducts.take(8).toList();
      }

      // 3. ถ้าสินค้าจริงไม่ครบ ให้เติมด้วยสินค้าที่มี ecoScore สูงสุด
      final allProducts = await _getAllApprovedProducts();

      if (allProducts.isEmpty) {
        return realProducts;
      }

      // เรียงตาม ecoScore และเลือกที่ยังไม่ได้เลือก
      final remainingProducts = allProducts
          .where((productData) {
            final product = productData['product'] as Product;
            return !realProducts.any((selected) => selected.id == product.id);
          })
          .map((data) => data['product'] as Product)
          .toList();

      remainingProducts.sort((a, b) => b.ecoScore.compareTo(a.ecoScore));

      // รวมสินค้าจริง + เสริม ให้ครบ 8 รายการ
      final supplementProducts =
          remainingProducts.take(8 - realProducts.length).toList();

      return [...realProducts, ...supplementProducts];
    } catch (e) {
      print('Error in getSmartEcoHeroProductsEnhanced: $e');
      return [];
    }
  }

  /// ดึงสินค้าทั้งหมดที่ approved พร้อมข้อมูลสถิติ
  Future<List<Map<String, dynamic>>> _getAllApprovedProducts() async {
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore
        .collection('products')
        .where('isApproved', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .get();

    final List<Map<String, dynamic>> products = [];

    for (final doc in snapshot.docs) {
      final productData = doc.data();
      final product = Product.fromMap(productData);

      // ดึงข้อมูลสถิติเพิ่มเติม
      final stats = await _getProductStatistics(product.id);

      products.add({
        'product': product,
        'stats': stats,
        'rawData': productData,
      });
    }

    return products;
  }

  /// ดึงสถิติสินค้า (ยอดขาย, รีวิว, ฯลฯ)
  Future<Map<String, dynamic>> _getProductStatistics(String productId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // ดึงข้อมูลคำสั่งซื้อ
      final ordersSnapshot = await firestore
          .collection('orders')
          .where('items', arrayContains: {'productId': productId}).get();

      // ดึงข้อมูลรีวิว
      final reviewsSnapshot = await firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      // คำนวณสถิติ
      int orderCount = ordersSnapshot.docs.length;
      double averageRating = 0.0;
      int reviewCount = reviewsSnapshot.docs.length;

      if (reviewCount > 0) {
        double totalRating = 0.0;
        for (final doc in reviewsSnapshot.docs) {
          totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
        }
        averageRating = totalRating / reviewCount;
      }

      return {
        'orderCount': orderCount,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
      };
    } catch (e) {
      print('Error getting product statistics for $productId: $e');
      return {
        'orderCount': 0,
        'averageRating': 0.0,
        'reviewCount': 0,
      };
    }
  }

  /// วิเคราะห์และให้คะแนนสินค้า (AI-like Algorithm)
  Future<List<Map<String, dynamic>>> _analyzeProducts(
      List<Map<String, dynamic>> products) async {
    final List<Map<String, dynamic>> analyzedProducts = [];

    // หาค่า min/max สำหรับการ normalize
    final normalizationFactors = _calculateNormalizationFactors(products);

    for (final productData in products) {
      final product = productData['product'] as Product;
      final stats = productData['stats'] as Map<String, dynamic>;

      // คำนวณคะแนนแต่ละด้าน
      final scores =
          _calculateIndividualScores(product, stats, normalizationFactors);

      // คำนวณคะแนนรวม (weighted sum)
      double totalScore = 0.0;
      _weightFactors.forEach((factor, weight) {
        totalScore += (scores[factor] ?? 0.0) * weight;
      });

      // เก็บข้อมูลการวิเคราะห์
      analyzedProducts.add({
        'product': product,
        'stats': stats,
        'scores': scores,
        'totalScore': totalScore,
        'ranking': _getEcoRanking(product.ecoScore),
      });
    }

    return analyzedProducts;
  }

  /// คำนวณค่าสำหรับ normalize ข้อมูล
  Map<String, double> _calculateNormalizationFactors(
      List<Map<String, dynamic>> products) {
    double maxEcoScore = 0;
    double maxOrderCount = 0;
    double maxRating = 5.0; // Rating ขั้นสูงสุดคือ 5
    int maxDaysOld = 0;
    double maxPrice = 0;

    final now = DateTime.now();

    for (final productData in products) {
      final product = productData['product'] as Product;
      final stats = productData['stats'] as Map<String, dynamic>;

      maxEcoScore = product.ecoScore.toDouble() > maxEcoScore
          ? product.ecoScore.toDouble()
          : maxEcoScore;

      maxOrderCount = (stats['orderCount'] as int) > maxOrderCount
          ? (stats['orderCount'] as int).toDouble()
          : maxOrderCount;

      maxPrice = product.price > maxPrice ? product.price : maxPrice;

      // คำนวณอายุสินค้า
      if (product.createdAt != null) {
        final createdAt = product.createdAt!.toDate();
        final daysOld = now.difference(createdAt).inDays;
        maxDaysOld = daysOld > maxDaysOld ? daysOld : maxDaysOld;
      }
    }

    return {
      'maxEcoScore': maxEcoScore > 0 ? maxEcoScore : 100,
      'maxOrderCount': maxOrderCount > 0 ? maxOrderCount : 1,
      'maxRating': maxRating,
      'maxDaysOld': maxDaysOld > 0 ? maxDaysOld.toDouble() : 1.0,
      'maxPrice': maxPrice > 0 ? maxPrice : 1,
    };
  }

  /// คำนวณคะแนนแต่ละด้าน (0.0 - 1.0)
  Map<String, double> _calculateIndividualScores(
    Product product,
    Map<String, dynamic> stats,
    Map<String, double> normFactors,
  ) {
    final scores = <String, double>{};

    // 1. Eco Score (35%) - ยิ่งสูงยิ่งดี
    scores['ecoScore'] = product.ecoScore / normFactors['maxEcoScore']!;

    // 2. Review Score (25%) - คะแนนรีวิวเฉลี่ย
    scores['reviewScore'] =
        (stats['averageRating'] as double) / normFactors['maxRating']!;

    // 3. Order Count (20%) - ยิ่งขายดียิ่งดี
    scores['orderCount'] =
        (stats['orderCount'] as int) / normFactors['maxOrderCount']!;

    // 4. Availability (10%) - สินค้าพร้อมขายหรือไม่
    scores['availability'] = (product.stock > 0) ? 1.0 : 0.0;

    // 5. Recency (5%) - สินค้าใหม่ได้คะแนนสูงกว่า
    if (product.createdAt != null) {
      final daysOld =
          DateTime.now().difference(product.createdAt!.toDate()).inDays;
      scores['recency'] = 1.0 - (daysOld / normFactors['maxDaysOld']!);
      scores['recency'] = scores['recency']!.clamp(0.0, 1.0);
    } else {
      scores['recency'] = 0.5; // ค่าเฉลี่ยถ้าไม่มีข้อมูล
    }

    // 6. Price Competitive (5%) - ราคาเหมาะสมกับระดับ eco
    scores['priceCompetitive'] = _calculatePriceCompetitiveScore(product);

    return scores;
  }

  /// คำนวณคะแนนความเหมาะสมของราคา
  double _calculatePriceCompetitiveScore(Product product) {
    final ecoScore = product.ecoScore;
    final price = product.price;

    // กำหนดช่วงราคาที่เหมาะสมตามระดับ eco
    double expectedMaxPrice;
    if (ecoScore >= 80) {
      expectedMaxPrice = 2000; // Eco Hero/Legend
    } else if (ecoScore >= 60) {
      expectedMaxPrice = 1500; // Eco Premium
    } else if (ecoScore >= 40) {
      expectedMaxPrice = 1000; // Eco Standard
    } else {
      expectedMaxPrice = 500; // Eco Basic
    }

    // คำนวณคะแนน (ราคาน้อยกว่าที่คาดหวัง = คะแนนสูง)
    if (price <= expectedMaxPrice) {
      return 1.0 - (price / expectedMaxPrice);
    } else {
      return 0.0; // ราคาแพงเกินไป
    }
  }

  /// กำหนดระดับ Eco Ranking
  String _getEcoRanking(int ecoScore) {
    if (ecoScore >= 80) return 'Eco Legend';
    if (ecoScore >= 60) return 'Eco Hero';
    if (ecoScore >= 40) return 'Eco Premium';
    if (ecoScore >= 20) return 'Eco Standard';
    return 'Eco Basic';
  }

  /// ดึงข้อมูลสรุปการวิเคราะห์
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final products = await _getAllApprovedProducts();
      final analyzed = await _analyzeProducts(products);

      // คำนวณสถิติรวม
      final Map<String, int> ecoLevelCount = {};
      double totalScore = 0.0;

      for (final item in analyzed) {
        final ranking = item['ranking'] as String;
        ecoLevelCount[ranking] = (ecoLevelCount[ranking] ?? 0) + 1;
        totalScore += item['totalScore'] as double;
      }

      return {
        'totalProducts': analyzed.length,
        'averageScore':
            analyzed.isNotEmpty ? totalScore / analyzed.length : 0.0,
        'ecoLevelDistribution': ecoLevelCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error in getAnalyticsSummary: $e');
      return {
        'totalProducts': 0,
        'averageScore': 0.0,
        'ecoLevelDistribution': <String, int>{},
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}
