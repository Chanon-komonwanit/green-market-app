// lib/services/notifications_init.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service สำหรับสร้างข้อมูลตัวอย่างการแจ้งเตือน
class NotificationsInitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// สร้างการแจ้งเตือนตัวอย่างสำหรับผู้ใช้
  Future<void> createSampleNotifications(String userId) async {
    final notifications = [
      {
        'userId': userId,
        'type': 'community_like',
        'title': '❤️ มีคนถูกใจโพสต์ของคุณ',
        'body': 'สมชาย ชอบโพสต์ "ปลูกผักอินทรีย์" ของคุณ',
        'senderId': 'sample_user_1',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {'postId': 'sample_post_1', 'type': 'like'}
      },
      {
        'userId': userId,
        'type': 'community_comment',
        'title': '💬 มีคนแสดงความคิดเห็นโพสต์ของคุณ',
        'body': 'สมหญิง แสดงความคิดเห็น: "สวยมากเลยค่ะ"',
        'senderId': 'sample_user_2',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'postId': 'sample_post_1',
          'commentId': 'sample_comment_1',
          'type': 'comment'
        }
      },
      {
        'userId': userId,
        'type': 'community_share',
        'title': '🔄 มีคนแชร์โพสต์ของคุณ',
        'body': 'สมศักดิ์ แชร์โพสต์ของคุณไปยังกลุ่มชุมชนสีเขียว',
        'senderId': 'sample_user_3',
        'isRead': true,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(hours: 2)),
        ),
        'data': {'postId': 'sample_post_1', 'type': 'share'}
      },
      {
        'userId': userId,
        'type': 'eco_challenge',
        'title': '🏆 ความท้าทายใหม่!',
        'body': 'มีความท้าทาย "ปลูกต้นไม้ 5 ต้น" รอคุณอยู่',
        'senderId': null,
        'isRead': false,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: 1)),
        ),
        'data': {'challengeId': 'sample_challenge_1', 'type': 'challenge'}
      },
      {
        'userId': userId,
        'type': 'eco_coins',
        'title': '💰 ได้รับ Eco Coins!',
        'body': 'คุณได้รับ 50 Eco Coins จากการทำภารกิจสำเร็จ',
        'senderId': null,
        'isRead': false,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(hours: 5)),
        ),
        'data': {'amount': 50, 'reason': 'challenge_completed', 'type': 'coins'}
      },
    ];

    try {
      print('📬 กำลังสร้างการแจ้งเตือนตัวอย่าง...');

      final batch = _firestore.batch();
      for (var notification in notifications) {
        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification);
      }

      await batch.commit();
      print('✅ สร้างการแจ้งเตือน ${notifications.length} รายการสำเร็จ!');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาด: $e');
    }
  }

  /// ลบการแจ้งเตือนตัวอย่างทั้งหมด
  Future<void> clearSampleNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ ลบการแจ้งเตือนตัวอย่างแล้ว');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาด: $e');
    }
  }
}
