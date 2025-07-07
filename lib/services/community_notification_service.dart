// lib/services/community_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityNotificationService {
  static const String _collection = 'community_notifications';

  // Send like notification
  static Future<void> sendLikeNotification({
    required String postId,
    required String postOwnerId,
    required String liker,
    required String likerName,
    String? likerPhoto,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == postOwnerId) return;

    try {
      await FirebaseFirestore.instance.collection(_collection).add({
        'userId': postOwnerId,
        'type': 'like',
        'title': 'มีคนไลค์โพสต์ของคุณ',
        'body': 'ได้กดไลค์โพสต์ของคุณ',
        'fromUserId': currentUserId,
        'fromUserName': likerName,
        'fromUserPhoto': likerPhoto,
        'postId': postId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send like notification: $e');
    }
  }

  // Send comment notification
  static Future<void> sendCommentNotification({
    required String postId,
    required String postOwnerId,
    required String commenter,
    required String commenterName,
    String? commenterPhoto,
    required String comment,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == postOwnerId) return;

    try {
      await FirebaseFirestore.instance.collection(_collection).add({
        'userId': postOwnerId,
        'type': 'comment',
        'title': 'มีคนแสดงความคิดเห็นโพสต์ของคุณ',
        'body':
            'ได้แสดงความคิดเห็น: ${comment.length > 50 ? '${comment.substring(0, 50)}...' : comment}',
        'fromUserId': currentUserId,
        'fromUserName': commenterName,
        'fromUserPhoto': commenterPhoto,
        'postId': postId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send comment notification: $e');
    }
  }

  // Send follow notification
  static Future<void> sendFollowNotification({
    required String followedUserId,
    required String follower,
    required String followerName,
    String? followerPhoto,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == followedUserId) return;

    try {
      await FirebaseFirestore.instance.collection(_collection).add({
        'userId': followedUserId,
        'type': 'follow',
        'title': 'มีคนติดตามคุณ',
        'body': 'ได้เริ่มติดตามคุณ',
        'fromUserId': currentUserId,
        'fromUserName': followerName,
        'fromUserPhoto': followerPhoto,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send follow notification: $e');
    }
  }

  // Send message notification
  static Future<void> sendMessageNotification({
    required String recipientId,
    required String sender,
    required String senderName,
    String? senderPhoto,
    required String message,
    required String chatId,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == recipientId) return;

    try {
      await FirebaseFirestore.instance.collection(_collection).add({
        'userId': recipientId,
        'type': 'message',
        'title': 'ข้อความใหม่',
        'body': 'ได้ส่งข้อความถึงคุณ',
        'fromUserId': currentUserId,
        'fromUserName': senderName,
        'fromUserPhoto': senderPhoto,
        'data': {
          'chatId': chatId,
          'message':
              message.length > 50 ? '${message.substring(0, 50)}...' : message,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send message notification: $e');
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete old notifications (keep only last 100)
  static Future<void> cleanupOldNotifications(String userId) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(150)
          .get();

      if (notifications.docs.length > 100) {
        final toDelete = notifications.docs.skip(100);
        final batch = FirebaseFirestore.instance.batch();

        for (final doc in toDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      print('Failed to cleanup old notifications: $e');
    }
  }
}
