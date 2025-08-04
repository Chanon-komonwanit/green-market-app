// lib/utils/cleanup_restored_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CleanupRestoredData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ลบข้อมูลที่สร้างขึ้นเพื่อการกู้คืนทั้งหมด
  static Future<Map<String, dynamic>> cleanupAllRestoredData() async {
    final results = <String, dynamic>{};
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('ไม่มีผู้ใช้ล็อกอิน กรุณาล็อกอินก่อน');
    }

    print('🧹 เริ่มลบข้อมูลที่กู้คืนมา...');

    try {
      // ลบข้อมูลที่สร้างขึ้นสำหรับการกู้คืน
      results['categories'] = await _cleanupCategories();
      results['products'] = await _cleanupProducts();
      results['community_posts'] = await _cleanupCommunityPosts();
      results['sustainable_activities'] = await _cleanupSustainableActivities();
      results['green_investments'] = await _cleanupGreenInvestments();
      results['eco_challenges'] = await _cleanupEcoChallenges();
      results['eco_rewards'] = await _cleanupEcoRewards();
      results['news_articles'] = await _cleanupNewsArticles();
      results['static_pages'] = await _cleanupStaticPages();
      results['orders'] = await _cleanupOrders();
      results['test_data'] = await _cleanupTestData();

      results['status'] = 'SUCCESS';
      results['message'] = 'ลบข้อมูลที่กู้คืนมาทั้งหมดสำเร็จ';
    } catch (e) {
      results['status'] = 'ERROR';
      results['error'] = e.toString();
      print('❌ เกิดข้อผิดพลาดในการลบข้อมูล: $e');
      rethrow;
    }

    return results;
  }

  /// ลบหมวดหมู่สินค้าที่สร้างขึ้น
  static Future<int> _cleanupCategories() async {
    print('🗑️ กำลังลบหมวดหมู่สินค้าที่สร้างขึ้น...');

    // รายการ ID ของหมวดหมู่ที่เราสร้างขึ้น
    final categoryIds = [
      'eco_food',
      'eco_fashion',
      'eco_home',
      'eco_beauty',
      'eco_tech',
    ];

    int count = 0;
    for (final categoryId in categoryIds) {
      try {
        await _firestore.collection('categories').doc(categoryId).delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบหมวดหมู่ $categoryId: $e');
      }
    }

    print('✅ ลบหมวดหมู่สินค้า $count หมวดหมู่');
    return count;
  }

  /// ลบสินค้าตัวอย่างที่สร้างขึ้น
  static Future<int> _cleanupProducts() async {
    print('🗑️ กำลังลบสินค้าตัวอย่างที่สร้างขึ้น...');

    // รายการ ID ของสินค้าที่เราสร้างขึ้น
    final productIds = [
      'prod_001',
      'prod_002',
      'prod_003',
      'prod_004',
      'prod_005',
    ];

    int count = 0;
    for (final productId in productIds) {
      try {
        await _firestore.collection('products').doc(productId).delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบสินค้า $productId: $e');
      }
    }

    print('✅ ลบสินค้าตัวอย่าง $count รายการ');
    return count;
  }

  /// ลบโพสชุมชนที่สร้างขึ้น
  static Future<int> _cleanupCommunityPosts() async {
    print('🗑️ กำลังลบโพสชุมชนที่สร้างขึ้น...');

    // รายการ ID ของโพสต์ที่เราสร้างขึ้น
    final postIds = [
      'post_001',
      'post_002',
      'post_003',
    ];

    int count = 0;
    for (final postId in postIds) {
      try {
        await _firestore.collection('community_posts').doc(postId).delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบโพสต์ $postId: $e');
      }
    }

    print('✅ ลบโพสชุมชน $count โพสต์');
    return count;
  }

  /// ลบกิจกรรมสิ่งแวดล้อมที่สร้างขึ้น
  static Future<int> _cleanupSustainableActivities() async {
    print('🗑️ กำลังลบกิจกรรมสิ่งแวดล้อมที่สร้างขึ้น...');

    final activityIds = [
      'activity_001',
      'activity_002',
      'activity_003',
    ];

    int count = 0;
    for (final activityId in activityIds) {
      try {
        await _firestore
            .collection('sustainable_activities')
            .doc(activityId)
            .delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบกิจกรรม $activityId: $e');
      }
    }

    print('✅ ลบกิจกรรมสิ่งแวดล้อม $count กิจกรรม');
    return count;
  }

  /// ลบการลงทุนเพื่อสิ่งแวดล้อมที่สร้างขึ้น
  static Future<int> _cleanupGreenInvestments() async {
    print('🗑️ กำลังลบการลงทุนเพื่อสิ่งแวดล้อมที่สร้างขึ้น...');

    final investmentIds = [
      'invest_001',
      'invest_002',
    ];

    int count = 0;
    for (final investmentId in investmentIds) {
      try {
        await _firestore
            .collection('green_investments')
            .doc(investmentId)
            .delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบการลงทุน $investmentId: $e');
      }
    }

    print('✅ ลบการลงทุนเพื่อสิ่งแวดล้อม $count โครงการ');
    return count;
  }

  /// ลบความท้าทายสิ่งแวดล้อมที่สร้างขึ้น
  static Future<int> _cleanupEcoChallenges() async {
    print('🗑️ กำลังลบความท้าทายสิ่งแวดล้อมที่สร้างขึ้น...');

    final challengeIds = [
      'challenge_001',
      'challenge_002',
    ];

    int count = 0;
    for (final challengeId in challengeIds) {
      try {
        await _firestore.collection('eco_challenges').doc(challengeId).delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบความท้าทาย $challengeId: $e');
      }
    }

    print('✅ ลบความท้าทายสิ่งแวดล้อม $count ความท้าทาย');
    return count;
  }

  /// ลบรางวัล Eco Coins ที่สร้างขึ้น
  static Future<int> _cleanupEcoRewards() async {
    print('🗑️ กำลังลบรางวัล Eco Coins ที่สร้างขึ้น...');

    final rewardIds = [
      'reward_001',
      'reward_002',
      'reward_003',
    ];

    int count = 0;
    for (final rewardId in rewardIds) {
      try {
        await _firestore.collection('ecoRewards').doc(rewardId).delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบรางวัล $rewardId: $e');
      }
    }

    print('✅ ลบรางวัล Eco Coins $count รางวัล');
    return count;
  }

  /// ลบข่าวสารที่สร้างขึ้น
  static Future<int> _cleanupNewsArticles() async {
    print('🗑️ กำลังลบข่าวสารที่สร้างขึ้น...');

    final articleIds = [
      'news_001',
      'news_002',
    ];

    int count = 0;
    for (final articleId in articleIds) {
      try {
        await _firestore.collection('news_articles').doc(articleId).delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบข่าว $articleId: $e');
      }
    }

    print('✅ ลบข่าวสาร $count บทความ');
    return count;
  }

  /// ลบหน้าเว็บสำคัญที่สร้างขึ้น
  static Future<int> _cleanupStaticPages() async {
    print('🗑️ กำลังลบหน้าเว็บสำคัญที่สร้างขึ้น...');

    final pageIds = [
      'about_us',
      'privacy_policy',
      'terms_of_service',
    ];

    int count = 0;
    for (final pageId in pageIds) {
      try {
        await _firestore.collection('static_pages').doc(pageId).delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบหน้าเว็บ $pageId: $e');
      }
    }

    print('✅ ลบหน้าเว็บสำคัญ $count หน้า');
    return count;
  }

  /// ลบคำสั่งซื้อตัวอย่างที่สร้างขึ้น
  static Future<int> _cleanupOrders() async {
    print('🗑️ กำลังลบคำสั่งซื้อตัวอย่างที่สร้างขึ้น...');

    final orderIds = [
      'order_001',
    ];

    int count = 0;
    for (final orderId in orderIds) {
      try {
        await _firestore.collection('orders').doc(orderId).delete();
        count++;
      } catch (e) {
        print('⚠️ ไม่สามารถลบคำสั่งซื้อ $orderId: $e');
      }
    }

    print('✅ ลบคำสั่งซื้อตัวอย่าง $count คำสั่งซื้อ');
    return count;
  }

  /// ลบข้อมูลทดสอบ
  static Future<int> _cleanupTestData() async {
    print('🗑️ กำลังลบข้อมูลทดสอบ...');

    int count = 0;

    try {
      // ลบ test_connection collection ทั้งหมด
      final testSnapshot = await _firestore.collection('test_connection').get();
      for (final doc in testSnapshot.docs) {
        await doc.reference.delete();
        count++;
      }
    } catch (e) {
      print('⚠️ ไม่สามารถลบข้อมูลทดสอบ: $e');
    }

    print('✅ ลบข้อมูลทดสอบ $count รายการ');
    return count;
  }

  /// ตรวจสอบว่าข้อมูลที่เราสร้างขึ้นถูกลบหมดแล้วหรือไม่
  static Future<Map<String, dynamic>> verifyCleanup() async {
    print('🔍 กำลังตรวจสอบการลบข้อมูล...');

    final results = <String, dynamic>{};

    try {
      // ตรวจสอบแต่ละ collection ว่ายังมีข้อมูลที่เราสร้างขึ้นอยู่หรือไม่
      final collectionsToCheck = {
        'categories': [
          'eco_food',
          'eco_fashion',
          'eco_home',
          'eco_beauty',
          'eco_tech'
        ],
        'products': [
          'prod_001',
          'prod_002',
          'prod_003',
          'prod_004',
          'prod_005'
        ],
        'community_posts': ['post_001', 'post_002', 'post_003'],
        'sustainable_activities': [
          'activity_001',
          'activity_002',
          'activity_003'
        ],
        'green_investments': ['invest_001', 'invest_002'],
        'eco_challenges': ['challenge_001', 'challenge_002'],
        'ecoRewards': ['reward_001', 'reward_002', 'reward_003'],
        'news_articles': ['news_001', 'news_002'],
        'static_pages': ['about_us', 'privacy_policy', 'terms_of_service'],
        'orders': ['order_001'],
      };

      for (final entry in collectionsToCheck.entries) {
        final collection = entry.key;
        final docIds = entry.value;

        int remainingCount = 0;
        for (final docId in docIds) {
          final doc = await _firestore.collection(collection).doc(docId).get();
          if (doc.exists) {
            remainingCount++;
          }
        }

        results[collection] = {
          'total_expected': docIds.length,
          'remaining': remainingCount,
          'cleaned_successfully': remainingCount == 0,
        };
      }

      // ตรวจสอบ test_connection
      final testSnapshot =
          await _firestore.collection('test_connection').limit(1).get();
      results['test_connection'] = {
        'remaining': testSnapshot.docs.length,
        'cleaned_successfully': testSnapshot.docs.isEmpty,
      };

      results['overall_status'] = 'SUCCESS';
      results['timestamp'] = DateTime.now().toIso8601String();
    } catch (e) {
      results['overall_status'] = 'ERROR';
      results['error'] = e.toString();
    }

    return results;
  }

  /// ลบเฉพาะข้อมูลผู้ใช้ที่สร้างขึ้นสำหรับการกู้คืน (ไม่ลบข้อมูลผู้ใช้จริง)
  static Future<Map<String, dynamic>> cleanupEmergencyUserData() async {
    print('👤 กำลังลบข้อมูลผู้ใช้ที่สร้างขึ้นสำหรับการกู้คืน...');

    final results = <String, dynamic>{};
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('ไม่มีผู้ใช้ล็อกอิน');
    }

    try {
      // ตรวจสอบว่าข้อมูลผู้ใช้เป็นข้อมูลที่สร้างขึ้นสำหรับการกู้คืนหรือไม่
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // ตรวจสอบว่าเป็นข้อมูลที่สร้างขึ้นใหม่หรือไม่ (เช่น bio = 'ผู้ดูแลระบบและผู้ขายใน Green Market')
        if (userData['bio']
                ?.toString()
                .contains('ผู้ดูแลระบบและผู้ขายใน Green Market') ==
            true) {
          // ถ้าเป็นข้อมูลที่เราสร้างขึ้น ให้รีเซ็ตเป็นข้อมูลพื้นฐานเท่านั้น
          await _firestore.collection('users').doc(currentUser.uid).update({
            'bio': null,
            'phoneNumber': null,
            'ecoCoins': 0.0,
            'consecutiveLoginDays': 0,
            'motto': null,
          });
          results['user_data_reset'] = true;
        } else {
          results['user_data_reset'] = false;
          results['message'] = 'ไม่พบข้อมูลผู้ใช้ที่สร้างขึ้นสำหรับการกู้คืน';
        }
      }

      results['status'] = 'SUCCESS';
    } catch (e) {
      results['status'] = 'ERROR';
      results['error'] = e.toString();
    }

    return results;
  }
}
