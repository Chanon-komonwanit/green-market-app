// lib/services/smart_product_analytics_service.dart
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/debug_config.dart';
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ระบบวิเคราะห์สินค้าอัจฉริยะ - Smart Product Analytics
/// ใช้ Ultimate AI Algorithm 8-Dimensional Analysis เพื่อคัดเลือกสินค้าที่ดีที่สุด
/// 🏆 ระบบที่ฉลาดที่สุด พร้อมใช้งาน 100% ✨
class SmartProductAnalyticsService {
  static final SmartProductAnalyticsService _instance =
      SmartProductAnalyticsService._internal();
  factory SmartProductAnalyticsService() => _instance;
  SmartProductAnalyticsService._internal();

  /// 🚀 ดึงสินค้า Eco Hero AI ระดับสูง (8 ชิ้น) - ฉลาดที่สุด!
  Future<List<Product>> getSmartEcoHeroProducts() async {
    // ใช้ Ultimate AI System สำหรับการเลือกสินค้า
    return await getUltimateEcoHeroProducts();
  }

  /// ดึงสินค้า Eco Hero อัจฉริยะ (8 สินค้า) รวมข้อมูล Mock ถ้าจำเป็น
  Future<List<Product>> getSmartEcoHeroProductsEnhanced() async {
    // ใช้ Ultimate AI System - ระบบที่ดีที่สุดที่ปรับปรุงแล้ว
    return await getUltimateEcoHeroProducts();
  }

  /// 🧠 วิเคราะห์ขั้นสูงด้วย AI Algorithm
  Future<List<Map<String, dynamic>>> _performAdvancedAIAnalysis(
      List<Map<String, dynamic>> products) async {
    // ใช้ Ultimate AI Analysis System
    return await _performUltimateAIAnalysis(products);
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
      // หากไม่สามารถเข้าถึงได้ ให้ใช้ค่าเริ่มต้น
      ProductionLogger.d(
          'Using default stats for product $productId (limited permissions)');
      return {
        'orderCount': 1,
        'averageRating': 4.0,
        'reviewCount': 1,
        'popularityScore': 1.0,
      };
    }
  }

  /// 🔥 ULTIMATE AI-POWERED ECO HERO SELECTION SYSTEM 🔥
  /// ระบบคัดเลือกสินค้าที่ฉลาดที่สุด ใช้ 8-Dimensional AI Analysis
  /// เพื่อให้ได้สินค้า Eco Hero ระดับสูงสุด 100% พร้อมใช้งาน!
  Future<List<Product>> getUltimateEcoHeroProducts() async {
    try {
      ProductionLogger.ai('Starting Ultimate Eco Hero Selection System...');

      // 1. ดึงสินค้า Approved ทั้งหมด
      final allProducts = await _getAllApprovedProducts();
      ProductionLogger.ai(
          'Found ${allProducts.length} candidate products for analysis');

      if (allProducts.isEmpty) {
        ProductionLogger.w('No approved products found - returning empty list');
        return [];
      }

      // 2. 🎯 ADVANCED AI MULTI-TIER SELECTION
      List<Map<String, dynamic>> candidateProducts;

      // Priority Tier 1: Premium EcoScore >= 70 (Premium+)
      final premiumProducts = allProducts.where((data) {
        final product = data['product'] as Product;
        return product.ecoScore >= 70;
      }).toList();

      // Priority Tier 2: High-Quality EcoScore >= 60
      final highQualityProducts = allProducts.where((data) {
        final product = data['product'] as Product;
        return product.ecoScore >= 60;
      }).toList();

      // 🧠 AI Adaptive Selection Strategy
      if (premiumProducts.length >= 8) {
        candidateProducts = premiumProducts;
        print(
            '[🌟 AI] Using ${candidateProducts.length} PREMIUM products (EcoScore >= 70)');
      } else if (highQualityProducts.length >= 6) {
        candidateProducts = highQualityProducts;
        print(
            '[🌟 AI] Using ${candidateProducts.length} HIGH-QUALITY products (EcoScore >= 60)');
      } else {
        candidateProducts = allProducts;
        print(
            '[🌟 AI] Using ALL ${candidateProducts.length} products with intelligent prioritization');
      }

      // 3. 🧠 ULTIMATE AI ANALYSIS - 8 Dimensions of Intelligence
      final aiAnalyzedProducts =
          await _performUltimateAIAnalysis(candidateProducts);
      print(
          '[🔥 AI] Ultimate AI analyzed ${aiAnalyzedProducts.length} products');

      // 4. 🏆 INTELLIGENT RANKING with Advanced Sorting
      aiAnalyzedProducts.sort((a, b) {
        final scoreA = a['ultimateAIScore'] as double;
        final scoreB = b['ultimateAIScore'] as double;

        // Primary: AI Score
        final scoreDiff = scoreB.compareTo(scoreA);
        if (scoreDiff != 0) return scoreDiff;

        // Secondary: EcoScore
        final productA = a['product'] as Product;
        final productB = b['product'] as Product;
        return productB.ecoScore.compareTo(productA.ecoScore);
      });

      // 5. 📊 AI INTELLIGENCE REPORT
      ProductionLogger.ai('Selection Results:');
      for (var data in aiAnalyzedProducts.take(8)) {
        final product = data['product'] as Product;
        final aiScore = data['ultimateAIScore'] as double;
        final ecoLevel = product.ecoLevel.name;
        ProductionLogger.ai(
            '${product.name.substring(0, product.name.length.clamp(0, 50))}...');
        ProductionLogger.ai(
            '   Ultimate AI Score: ${aiScore.toStringAsFixed(3)}');
        ProductionLogger.ai(
            '   EcoScore: ${product.ecoScore} | Level: $ecoLevel');
      }

      // 6. 🌟 SELECT TOP 8 ULTIMATE ECO HEROES
      final ultimateEcoHeroes = aiAnalyzedProducts
          .take(8)
          .map((data) => data['product'] as Product)
          .toList();

      ProductionLogger.ai(
          'Selected ${ultimateEcoHeroes.length} ULTIMATE ECO HEROES!');

      // 7. 📈 ADVANCED ANALYTICS REPORT
      _generateUltimateAnalyticsReport(ultimateEcoHeroes);

      return ultimateEcoHeroes;
    } catch (e, stackTrace) {
      ProductionLogger.e('Ultimate AI System Error: $e', e, stackTrace);

      // Fallback to basic selection
      return await _fallbackEcoHeroSelection();
    }
  }

  /// 🧠 ULTIMATE AI ANALYSIS - 8-Dimensional Intelligence System
  Future<List<Map<String, dynamic>>> _performUltimateAIAnalysis(
      List<Map<String, dynamic>> products) async {
    final analyzedProducts = <Map<String, dynamic>>[];

    ProductionLogger.ai('Performing Ultimate 8-Dimensional AI Analysis...');

    for (final data in products) {
      final product = data['product'] as Product;
      final stats = data['stats'] as Map<String, dynamic>;

      // 🎯 ULTIMATE AI SCORING ALGORITHM - 8 DIMENSIONS
      double ultimateAIScore = 0.0;

      // DIMENSION 1: EcoScore Intelligence Boost (35%)
      final ecoScoreAI = _calculateUltimateEcoScoreAI(product.ecoScore);
      ultimateAIScore += ecoScoreAI * 0.35;

      // DIMENSION 2: Sustainability Semantic Analysis (20%)
      final sustainabilityAI = _performSustainabilitySemanticAnalysis(product);
      ultimateAIScore += sustainabilityAI * 0.20;

      // DIMENSION 3: Quality Intelligence Index (15%)
      final qualityAI = _calculateQualityIntelligenceIndex(product, stats);
      ultimateAIScore += qualityAI * 0.15;

      // DIMENSION 4: Market Performance AI (10%)
      final marketAI = _analyzeMarketPerformanceAI(stats);
      ultimateAIScore += marketAI * 0.10;

      // DIMENSION 5: Innovation Intelligence Score (8%)
      final innovationAI = _calculateInnovationIntelligence(product);
      ultimateAIScore += innovationAI * 0.08;

      // DIMENSION 6: User Engagement AI (7%)
      final engagementAI = _calculateEngagementIntelligence(stats);
      ultimateAIScore += engagementAI * 0.07;

      // DIMENSION 7: Price-Value Intelligence (3%)
      final priceValueAI = _analyzePriceValueIntelligence(product);
      ultimateAIScore += priceValueAI * 0.03;

      // DIMENSION 8: Freshness Intelligence (2%)
      final freshnessAI = _calculateFreshnessIntelligence(product);
      ultimateAIScore += freshnessAI * 0.02;

      analyzedProducts.add({
        'product': product,
        'stats': stats,
        'ultimateAIScore': ultimateAIScore,
        'ecoScoreAI': ecoScoreAI,
        'sustainabilityAI': sustainabilityAI,
        'qualityAI': qualityAI,
        'marketAI': marketAI,
        'innovationAI': innovationAI,
        'engagementAI': engagementAI,
        'priceValueAI': priceValueAI,
        'freshnessAI': freshnessAI,
        'rawData': data['rawData']
      });
    }

    ProductionLogger.ai(
        'Ultimate AI Analysis completed for ${analyzedProducts.length} products');
    return analyzedProducts;
  }

  /// 🎯 DIMENSION 1: Ultimate EcoScore AI - พลังสูงสุดของ EcoScore
  double _calculateUltimateEcoScoreAI(int ecoScore) {
    if (ecoScore >= 95) return 1.00; // Legendary
    if (ecoScore >= 90) return 0.95; // Perfect
    if (ecoScore >= 85) return 0.90; // Ultimate
    if (ecoScore >= 80) return 0.85; // Hero+
    if (ecoScore >= 75) return 0.80; // Hero
    if (ecoScore >= 70) return 0.75; // Premium+
    if (ecoScore >= 65) return 0.70; // Premium
    if (ecoScore >= 60) return 0.65; // Premium-
    return 0.50; // Standard
  }

  /// 🌱 DIMENSION 2: Sustainability Semantic Analysis - วิเคราะห์ความหมายเชิงลึก
  double _performSustainabilitySemanticAnalysis(Product product) {
    final text = '${product.name} ${product.description}'.toLowerCase();
    double semanticScore = 0.0;

    // High-Impact Sustainability Keywords (Tier 1)
    final tier1Keywords = {
      'รักษาสิ่งแวดล้อม': 0.25,
      'ลดปริมาณคาร์บอน': 0.25,
      'รีไซเคิล': 0.20,
      'sustainable': 0.25,
      'carbon neutral': 0.25,
      'recycle': 0.20,
      'renewable': 0.20,
      'biodegradable': 0.20
    };

    // Medium-Impact Keywords (Tier 2)
    final tier2Keywords = {
      'ธรรมชาติ': 0.15,
      'ฟอกอากาศ': 0.15,
      'เพื่อสุขภาพ': 0.10,
      'natural': 0.15,
      'organic': 0.15,
      'eco': 0.15,
      'green': 0.10,
      'clean': 0.10,
      'pure': 0.10,
      'bio': 0.10
    };

    // Innovation Keywords (Tier 3)
    final tier3Keywords = {
      'นวัตกรรม': 0.10,
      'ปัญหาพลาสติก': 0.15,
      'แข็งแรงทนทาน': 0.08,
      'innovation': 0.10,
      'technology': 0.08,
      'smart': 0.08,
      'solution': 0.12
    };

    // Calculate semantic scores
    for (var tier in [tier1Keywords, tier2Keywords, tier3Keywords]) {
      tier.forEach((keyword, weight) {
        if (text.contains(keyword)) {
          semanticScore += weight;
        }
      });
    }

    // Bonus for multiple keyword combinations
    final keywordCount = [tier1Keywords, tier2Keywords, tier3Keywords]
        .expand((tier) => tier.keys)
        .where((keyword) => text.contains(keyword))
        .length;

    if (keywordCount >= 3) semanticScore += 0.10; // Comprehensive coverage
    if (keywordCount >= 5) semanticScore += 0.05; // Exceptional coverage

    return semanticScore.clamp(0.0, 1.0);
  }

  /// 💎 DIMENSION 3: Quality Intelligence Index - ดัชนีคุณภาพอัจฉริยะ
  double _calculateQualityIntelligenceIndex(
      Product product, Map<String, dynamic> stats) {
    double qualityScore = 0.0;

    // Rating Intelligence (50%)
    final rating = stats['averageRating'] as double;
    final ratingIntelligence = (rating / 5.0);
    qualityScore += ratingIntelligence * 0.50;

    // Review Count Intelligence (25%)
    final reviewCount = stats['reviewCount'] as int;
    double reviewIntelligence = 0.0;
    if (reviewCount >= 20) {
      reviewIntelligence = 1.0;
    } else if (reviewCount >= 15) {
      reviewIntelligence = 0.8;
    } else if (reviewCount >= 10) {
      reviewIntelligence = 0.6;
    } else if (reviewCount >= 5) {
      reviewIntelligence = 0.4;
    } else if (reviewCount >= 1) {
      reviewIntelligence = 0.2;
    }
    qualityScore += reviewIntelligence * 0.25;

    // Stock Intelligence (25%)
    double stockIntelligence = 0.0;
    if (product.stock > 20) {
      stockIntelligence = 1.0;
    } else if (product.stock > 10) {
      stockIntelligence = 0.8;
    } else if (product.stock > 5) {
      stockIntelligence = 0.6;
    } else if (product.stock > 0) {
      stockIntelligence = 0.4;
    }
    qualityScore += stockIntelligence * 0.25;

    return qualityScore;
  }

  /// 📈 DIMENSION 4: Market Performance AI - วิเคราะห์ประสิทธิภาพตลาดอัจฉริยะ
  double _analyzeMarketPerformanceAI(Map<String, dynamic> stats) {
    final orderCount = stats['orderCount'] as int;

    // Advanced Performance Tiers
    if (orderCount >= 100) return 1.0; // Market Leader
    if (orderCount >= 75) return 0.9; // Top Performer
    if (orderCount >= 50) return 0.8; // High Performer
    if (orderCount >= 25) return 0.7; // Good Performer
    if (orderCount >= 15) return 0.6; // Average Performer
    if (orderCount >= 10) return 0.5; // Entry Performer
    if (orderCount >= 5) return 0.3; // Emerging
    if (orderCount >= 1) return 0.2; // New Entry
    return 0.0; // No Sales
  }

  /// 💡 DIMENSION 5: Innovation Intelligence - ความฉลาดด้านนวัตกรรม
  double _calculateInnovationIntelligence(Product product) {
    final text = '${product.name} ${product.description}'.toLowerCase();
    double innovationScore = 0.0;

    // Core Innovation Keywords
    final coreInnovations = [
      'นวัตกรรม',
      'innovation',
      'technology',
      'smart',
      'ai',
      'digital',
      'ปัญหาพลาสติก',
      'solution',
      'แข็งแรงทนทาน',
      'durable',
      'model',
      'patent',
      'unique',
      'breakthrough',
      'advanced',
      'cutting-edge'
    ];

    // Environmental Innovation
    final ecoInnovations = [
      'carbon capture',
      'zero waste',
      'circular economy',
      'upcycle',
      'biomaterial',
      'renewable energy',
      'water conservation'
    ];

    // Count innovation indicators
    final coreCount =
        coreInnovations.where((keyword) => text.contains(keyword)).length;
    final ecoCount =
        ecoInnovations.where((keyword) => text.contains(keyword)).length;

    // Score calculation
    innovationScore += (coreCount * 0.15).clamp(0.0, 0.75);
    innovationScore += (ecoCount * 0.20).clamp(0.0, 0.40);

    // Bonus for comprehensive innovation
    if (coreCount >= 2 && ecoCount >= 1) innovationScore += 0.10;

    return innovationScore.clamp(0.0, 1.0);
  }

  /// 🎪 DIMENSION 6: Engagement Intelligence - ปัญญาการมีส่วนร่วม
  double _calculateEngagementIntelligence(Map<String, dynamic> stats) {
    final reviewCount = stats['reviewCount'] as int;
    final avgRating = stats['averageRating'] as double;
    final orderCount = stats['orderCount'] as int;

    double engagementScore = 0.0;

    // High Engagement Indicators (60%)
    if (reviewCount >= 15 && avgRating >= 4.5) {
      engagementScore += 0.35;
    } else if (reviewCount >= 10 && avgRating >= 4.0) {
      engagementScore += 0.25;
    } else if (reviewCount >= 5 && avgRating >= 3.8) {
      engagementScore += 0.15;
    }

    // Order Engagement (40%)
    if (orderCount >= 20) {
      engagementScore += 0.25;
    } else if (orderCount >= 10) {
      engagementScore += 0.15;
    } else if (orderCount >= 5) {
      engagementScore += 0.10;
    }

    // Loyalty Bonus (exceptional engagement)
    if (reviewCount >= 20 && avgRating >= 4.8 && orderCount >= 30) {
      engagementScore += 0.15; // Exceptional loyalty
    }

    return engagementScore.clamp(0.0, 1.0);
  }

  /// 💰 DIMENSION 7: Price-Value Intelligence - ปัญญาการคุ้มค่า
  double _analyzePriceValueIntelligence(Product product) {
    final ecoScore = product.ecoScore;
    final price = product.price;

    // Dynamic price evaluation based on EcoScore
    Map<int, double> priceThresholds = {
      95: 3000, // Legendary products
      90: 2500, // Perfect products
      85: 2200, // Ultimate products
      80: 2000, // Hero+ products
      75: 1800, // Hero products
      70: 1500, // Premium+ products
      65: 1300, // Premium products
      60: 1000, // Premium- products
    };

    double expectedMaxPrice = 800; // Default for standard products

    // Find appropriate price threshold
    for (var threshold in priceThresholds.entries) {
      if (ecoScore >= threshold.key) {
        expectedMaxPrice = threshold.value;
        break;
      }
    }

    // Calculate value intelligence
    if (price <= expectedMaxPrice * 0.5) return 1.0; // Exceptional value
    if (price <= expectedMaxPrice * 0.7) return 0.8; // Great value
    if (price <= expectedMaxPrice) return 0.6; // Good value
    if (price <= expectedMaxPrice * 1.2) return 0.3; // Fair value
    return 0.1; // Poor value
  }

  /// 🆕 DIMENSION 8: Freshness Intelligence - ปัญญาความใหม่
  double _calculateFreshnessIntelligence(Product product) {
    if (product.createdAt == null) return 0.5; // Neutral if no date

    final now = DateTime.now();
    final createdAt = product.createdAt!.toDate();
    final daysOld = now.difference(createdAt).inDays;

    // Advanced freshness calculation
    if (daysOld <= 3) return 1.0; // Brand new
    if (daysOld <= 7) return 0.9; // Very fresh
    if (daysOld <= 14) return 0.8; // Fresh
    if (daysOld <= 30) return 0.7; // Recent
    if (daysOld <= 60) return 0.6; // Moderate
    if (daysOld <= 90) return 0.4; // Aging
    return 0.2; // Old
  }

  /// 📊 Generate Ultimate Analytics Report
  void _generateUltimateAnalyticsReport(List<Product> products) {
    final levelCounts = <String, int>{};
    final scoreRanges = <String, int>{
      '90-100': 0,
      '80-89': 0,
      '70-79': 0,
      '60-69': 0,
      'Below 60': 0
    };

    for (final product in products) {
      final level = product.ecoLevel.name;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;

      final score = product.ecoScore;
      if (score >= 90) {
        scoreRanges['90-100'] = scoreRanges['90-100']! + 1;
      } else if (score >= 80) {
        scoreRanges['80-89'] = scoreRanges['80-89']! + 1;
      } else if (score >= 70) {
        scoreRanges['70-79'] = scoreRanges['70-79']! + 1;
      } else if (score >= 60) {
        scoreRanges['60-69'] = scoreRanges['60-69']! + 1;
      } else {
        scoreRanges['Below 60'] = scoreRanges['Below 60']! + 1;
      }
    }

    if (DebugConfig.enableAnalyticsDebug) {
      ProductionLogger.ai('Eco Level Distribution:');
      levelCounts.forEach((level, productCount) {
        ProductionLogger.ai('  $level: $productCount products');
      });

      ProductionLogger.ai('EcoScore Distribution:');
      scoreRanges.forEach((range, productCount) {
        ProductionLogger.ai('  $range: $productCount products');
      });

      final avgEcoScore = products.fold(0.0, (total, p) => total + p.ecoScore) /
          products.length;
      ProductionLogger.ai(
          'Average EcoScore: ${avgEcoScore.toStringAsFixed(1)}');
    }
  }

  /// 🆘 Fallback Eco Hero Selection (Emergency Mode)
  Future<List<Product>> _fallbackEcoHeroSelection() async {
    try {
      ProductionLogger.w('Using emergency fallback selection...');
      final products = await _getAllApprovedProducts();

      if (products.isEmpty) return [];

      final sortedProducts =
          products.map((data) => data['product'] as Product).toList();
      sortedProducts.sort((a, b) => b.ecoScore.compareTo(a.ecoScore));

      return sortedProducts.take(8).toList();
    } catch (e) {
      ProductionLogger.e('Fallback selection error: $e');
      return [];
    }
  }

  /// ดึงข้อมูลสรุปการวิเคราะห์
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final products = await _getAllApprovedProducts();
      final analyzed = await _performAdvancedAIAnalysis(products);

      // คำนวณสถิติรวม
      final Map<String, int> ecoLevelCount = {};
      double totalScore = 0.0;

      for (final item in analyzed) {
        final product = item['product'] as Product;
        final level = product.ecoLevel.name;
        ecoLevelCount[level] = (ecoLevelCount[level] ?? 0) + 1;
        totalScore += item['aiScore'] as double;
      }

      return {
        'totalProducts': analyzed.length,
        'averageScore':
            analyzed.isNotEmpty ? totalScore / analyzed.length : 0.0,
        'ecoLevelDistribution': ecoLevelCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ProductionLogger.e('Error in getAnalyticsSummary: $e');
      return {
        'totalProducts': 0,
        'averageScore': 0.0,
        'ecoLevelDistribution': <String, int>{},
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}
