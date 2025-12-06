import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ระบบติดตามการมองเห็นสินค้า (Product View Tracking Service)
/// บันทึกว่าผู้ใช้เห็นสินค้าจากไหน (marketplace, search, shop, profile, direct)
class ProductViewTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// บันทึกการเข้าชมสินค้า
  ///
  /// [productId] - ID ของสินค้า
  /// [sellerId] - ID ของผู้ขาย
  /// [source] - แหล่งที่มา (marketplace, search, shop, profile, direct)
  /// [searchQuery] - คำค้นหา (ถ้ามีจาก search)
  /// [referrer] - URL หรือหน้าที่มา
  Future<void> trackProductView({
    required String productId,
    required String sellerId,
    required ViewSource source,
    String? searchQuery,
    String? referrer,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      final now = DateTime.now();

      final viewData = {
        'productId': productId,
        'sellerId': sellerId,
        'userId': userId,
        'source': source.value,
        'sourceName': source.displayName,
        'searchQuery': searchQuery,
        'referrer': referrer,
        'viewedAt': Timestamp.fromDate(now),
        'date': _getDateKey(now),
        'hour': now.hour,
        'dayOfWeek': now.weekday,
        'isGuest': userId == null,
        ...?additionalData,
      };

      // บันทึกลง collection หลัก
      await _firestore.collection('product_views').add(viewData);

      // อัปเดตสถิติสินค้า (เพิ่ม view count)
      await _updateProductStats(productId, source);

      // อัปเดตสถิติผู้ขาย
      await _updateSellerStats(sellerId, source, now);

      print('[ViewTracking] Tracked view: $productId from ${source.value}');
    } catch (e) {
      print('[ViewTracking] Error tracking view: $e');
      // ไม่ throw error เพื่อไม่ให้รบกวนการทำงานหลัก
    }
  }

  /// อัปเดตสถิติของสินค้า
  Future<void> _updateProductStats(String productId, ViewSource source) async {
    try {
      final statsRef = _firestore.collection('product_stats').doc(productId);

      await _firestore.runTransaction((transaction) async {
        final statsDoc = await transaction.get(statsRef);

        Map<String, dynamic> stats;
        if (statsDoc.exists) {
          stats = statsDoc.data()!;
        } else {
          stats = {
            'productId': productId,
            'totalViews': 0,
            'viewsBySource': {},
            'lastViewedAt': null,
          };
        }

        // เพิ่ม total views
        stats['totalViews'] = (stats['totalViews'] ?? 0) + 1;

        // เพิ่ม views ตาม source
        final viewsBySource =
            Map<String, int>.from(stats['viewsBySource'] ?? {});
        viewsBySource[source.value] = (viewsBySource[source.value] ?? 0) + 1;
        stats['viewsBySource'] = viewsBySource;

        // อัปเดตเวลา
        stats['lastViewedAt'] = FieldValue.serverTimestamp();

        transaction.set(statsRef, stats, SetOptions(merge: true));
      });
    } catch (e) {
      print('[ViewTracking] Error updating product stats: $e');
    }
  }

  /// อัปเดตสถิติของผู้ขาย
  Future<void> _updateSellerStats(
    String sellerId,
    ViewSource source,
    DateTime viewDate,
  ) async {
    try {
      final dateKey = _getDateKey(viewDate);
      final statsRef = _firestore
          .collection('seller_view_stats')
          .doc(sellerId)
          .collection('daily')
          .doc(dateKey);

      await _firestore.runTransaction((transaction) async {
        final statsDoc = await transaction.get(statsRef);

        Map<String, dynamic> stats;
        if (statsDoc.exists) {
          stats = statsDoc.data()!;
        } else {
          stats = {
            'sellerId': sellerId,
            'date': dateKey,
            'totalViews': 0,
            'viewsBySource': {},
            'viewsByHour': {},
          };
        }

        // เพิ่ม total views
        stats['totalViews'] = (stats['totalViews'] ?? 0) + 1;

        // เพิ่ม views ตาม source
        final viewsBySource =
            Map<String, int>.from(stats['viewsBySource'] ?? {});
        viewsBySource[source.value] = (viewsBySource[source.value] ?? 0) + 1;
        stats['viewsBySource'] = viewsBySource;

        // เพิ่ม views ตามชั่วโมง
        final hour = viewDate.hour.toString();
        final viewsByHour = Map<String, int>.from(stats['viewsByHour'] ?? {});
        viewsByHour[hour] = (viewsByHour[hour] ?? 0) + 1;
        stats['viewsByHour'] = viewsByHour;

        transaction.set(statsRef, stats, SetOptions(merge: true));
      });
    } catch (e) {
      print('[ViewTracking] Error updating seller stats: $e');
    }
  }

  /// ดึงสถิติการเข้าชมของสินค้า
  Future<ProductViewStats?> getProductViewStats(String productId) async {
    try {
      final doc =
          await _firestore.collection('product_stats').doc(productId).get();

      if (!doc.exists) {
        return ProductViewStats(
          productId: productId,
          totalViews: 0,
          viewsBySource: {},
          lastViewedAt: null,
        );
      }

      final data = doc.data()!;
      return ProductViewStats(
        productId: productId,
        totalViews: data['totalViews'] ?? 0,
        viewsBySource: Map<String, int>.from(data['viewsBySource'] ?? {}),
        lastViewedAt: data['lastViewedAt'] != null
            ? (data['lastViewedAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      print('[ViewTracking] Error getting product stats: $e');
      return null;
    }
  }

  /// ดึงสถิติการเข้าชมของผู้ขายในช่วงเวลา
  Future<List<SellerViewStats>> getSellerViewStats(
    String sellerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startKey = _getDateKey(startDate);
      final endKey = _getDateKey(endDate);

      final snapshot = await _firestore
          .collection('seller_view_stats')
          .doc(sellerId)
          .collection('daily')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
          .orderBy(FieldPath.documentId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SellerViewStats(
          sellerId: sellerId,
          date: doc.id,
          totalViews: data['totalViews'] ?? 0,
          viewsBySource: Map<String, int>.from(data['viewsBySource'] ?? {}),
          viewsByHour: Map<String, int>.from(data['viewsByHour'] ?? {}),
        );
      }).toList();
    } catch (e) {
      print('[ViewTracking] Error getting seller stats: $e');
      return [];
    }
  }

  /// ดึงสินค้ายอดนิยม (ตาม views) ของผู้ขาย
  Future<List<ProductViewStats>> getTopViewedProducts(
    String sellerId, {
    int limit = 10,
    DateTime? since,
  }) async {
    try {
      Query query = _firestore
          .collection('product_views')
          .where('sellerId', isEqualTo: sellerId);

      if (since != null) {
        query = query.where('viewedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();

      // นับจำนวน views ของแต่ละสินค้า
      final Map<String, Map<String, dynamic>> productViews = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final productId = data['productId'] as String;
        final source = data['source'] as String;

        if (!productViews.containsKey(productId)) {
          productViews[productId] = {
            'productId': productId,
            'totalViews': 0,
            'viewsBySource': <String, int>{},
          };
        }

        productViews[productId]!['totalViews'] =
            (productViews[productId]!['totalViews'] as int) + 1;

        final viewsBySource =
            productViews[productId]!['viewsBySource'] as Map<String, int>;
        viewsBySource[source] = (viewsBySource[source] ?? 0) + 1;
      }

      // เรียงลำดับตามจำนวน views
      final sorted = productViews.values.toList()
        ..sort((a, b) =>
            (b['totalViews'] as int).compareTo(a['totalViews'] as int));

      // เอาแค่ limit รายการแรก
      final topProducts = sorted.take(limit).map((data) {
        return ProductViewStats(
          productId: data['productId'] as String,
          totalViews: data['totalViews'] as int,
          viewsBySource: Map<String, int>.from(data['viewsBySource'] as Map),
          lastViewedAt: null,
        );
      }).toList();

      return topProducts;
    } catch (e) {
      print('[ViewTracking] Error getting top viewed products: $e');
      return [];
    }
  }

  /// ดึงสถิติการเข้าชมแบบ real-time
  Stream<ProductViewStats> watchProductViewStats(String productId) {
    return _firestore
        .collection('product_stats')
        .doc(productId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return ProductViewStats(
          productId: productId,
          totalViews: 0,
          viewsBySource: {},
          lastViewedAt: null,
        );
      }

      final data = doc.data()!;
      return ProductViewStats(
        productId: productId,
        totalViews: data['totalViews'] ?? 0,
        viewsBySource: Map<String, int>.from(data['viewsBySource'] ?? {}),
        lastViewedAt: data['lastViewedAt'] != null
            ? (data['lastViewedAt'] as Timestamp).toDate()
            : null,
      );
    });
  }

  /// ลบข้อมูลการเข้าชมเก่า (สำหรับ maintenance)
  Future<void> cleanOldViewData({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('product_views')
          .where('viewedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500) // จำกัดการลบครั้งละ 500 รายการ
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('[ViewTracking] Cleaned ${snapshot.docs.length} old view records');
    } catch (e) {
      print('[ViewTracking] Error cleaning old data: $e');
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}

// ==================== MODELS ====================

/// แหล่งที่มาของการเข้าชมสินค้า
enum ViewSource {
  marketplace('marketplace', 'ตลาดกลาง', 'ผู้ซื้อเห็นในหน้าตลาด'),
  search('search', 'การค้นหา', 'ผู้ซื้อค้นหาและเจอสินค้า'),
  shop('shop', 'หน้าร้าน', 'เข้าชมจากหน้าร้านโดยตรง'),
  profile('profile', 'โปรไฟล์', 'เข้าชมจากโปรไฟล์ผู้ขาย'),
  direct('direct', 'ลิงก์ตรง', 'เข้าจากลิงก์โดยตรง'),
  promotion('promotion', 'โปรโมชั่น', 'เข้าจากหน้าโปรโมชั่น'),
  category('category', 'หมวดหมู่', 'เข้าจากการเลือกหมวดหมู่'),
  recommendation('recommendation', 'แนะนำ', 'ระบบแนะนำสินค้า'),
  notification('notification', 'การแจ้งเตือน', 'จากการแจ้งเตือน'),
  share('share', 'แชร์', 'ผู้ใช้แชร์ลิงก์สินค้า');

  final String value;
  final String displayName;
  final String description;

  const ViewSource(this.value, this.displayName, this.description);

  static ViewSource fromString(String value) {
    return ViewSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => ViewSource.direct,
    );
  }
}

/// สถิติการเข้าชมของสินค้า
class ProductViewStats {
  final String productId;
  final int totalViews;
  final Map<String, int> viewsBySource;
  final DateTime? lastViewedAt;

  ProductViewStats({
    required this.productId,
    required this.totalViews,
    required this.viewsBySource,
    this.lastViewedAt,
  });

  /// คำนวณเปอร์เซ็นต์ของแต่ละ source
  Map<String, double> getSourcePercentages() {
    if (totalViews == 0) return {};

    return viewsBySource.map((source, count) {
      return MapEntry(source, (count / totalViews) * 100);
    });
  }

  /// หา source ที่มี views มากที่สุด
  String? getTopSource() {
    if (viewsBySource.isEmpty) return null;

    return viewsBySource.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'totalViews': totalViews,
      'viewsBySource': viewsBySource,
      'lastViewedAt': lastViewedAt?.toIso8601String(),
    };
  }

  factory ProductViewStats.fromMap(Map<String, dynamic> map) {
    return ProductViewStats(
      productId: map['productId'] as String,
      totalViews: map['totalViews'] as int,
      viewsBySource: Map<String, int>.from(map['viewsBySource'] as Map),
      lastViewedAt: map['lastViewedAt'] != null
          ? DateTime.parse(map['lastViewedAt'] as String)
          : null,
    );
  }
}

/// สถิติการเข้าชมของผู้ขายรายวัน
class SellerViewStats {
  final String sellerId;
  final String date; // YYYYMMDD format
  final int totalViews;
  final Map<String, int> viewsBySource;
  final Map<String, int> viewsByHour;

  SellerViewStats({
    required this.sellerId,
    required this.date,
    required this.totalViews,
    required this.viewsBySource,
    required this.viewsByHour,
  });

  /// แปลง date string เป็น DateTime
  DateTime getDate() {
    final year = int.parse(date.substring(0, 4));
    final month = int.parse(date.substring(4, 6));
    final day = int.parse(date.substring(6, 8));
    return DateTime(year, month, day);
  }

  /// หาช่วงเวลาที่มี views มากที่สุด
  String getPeakHour() {
    if (viewsByHour.isEmpty) return 'ไม่มีข้อมูล';

    final peakHourEntry =
        viewsByHour.entries.reduce((a, b) => a.value > b.value ? a : b);

    return '${peakHourEntry.key}:00 น.';
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'date': date,
      'totalViews': totalViews,
      'viewsBySource': viewsBySource,
      'viewsByHour': viewsByHour,
    };
  }

  factory SellerViewStats.fromMap(Map<String, dynamic> map) {
    return SellerViewStats(
      sellerId: map['sellerId'] as String,
      date: map['date'] as String,
      totalViews: map['totalViews'] as int,
      viewsBySource: Map<String, int>.from(map['viewsBySource'] as Map),
      viewsByHour: Map<String, int>.from(map['viewsByHour'] as Map),
    );
  }
}
