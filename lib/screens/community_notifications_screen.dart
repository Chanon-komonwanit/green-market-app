// lib/screens/community_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/feed_screen.dart';
import 'package:green_market/screens/comments_screen.dart';
import 'package:green_market/models/post.dart';

class CommunityNotificationsScreen extends StatefulWidget {
  const CommunityNotificationsScreen({super.key});

  @override
  State<CommunityNotificationsScreen> createState() =>
      _CommunityNotificationsScreenState();
}

class _CommunityNotificationsScreenState
    extends State<CommunityNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'การแจ้งเตือน',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีการแจ้งเตือน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'การแจ้งเตือนจะปรากฏที่นี่',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              return _buildNotificationCard(data, notification.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data, String notificationId) {
    final type = data['type'] ?? 'general';
    final isRead = data['isRead'] ?? false;
    final createdAt = data['createdAt'] as Timestamp?;
    final body = data['body'] ?? 'มีข้อความใหม่';
    final fromUserName = data['fromUserName'] ?? 'ผู้ใช้';
    final fromUserPhoto = data['fromUserPhoto'] as String?;

    return InkWell(
      onTap: () => _handleNotificationTap(data, notificationId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFF059669).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey.withOpacity(0.2) : const Color(0xFF059669).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image / Icon
            CircleAvatar(
              radius: 24,
              backgroundColor: _getNotificationColor(type),
              backgroundImage: fromUserPhoto != null ? NetworkImage(fromUserPhoto) : null,
              child: fromUserPhoto == null
                  ? Icon(
                      _getNotificationIcon(type),
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: fromUserName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' $body'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Unread indicator
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'mention':
        return Colors.orange;
      default:
        return const Color(0xFF059669);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'เมื่อสักครู่';
    
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> data, String notificationId) async {
    // Mark as read
    await FirebaseFirestore.instance
        .collection('community_notifications')
        .doc(notificationId)
        .update({'isRead': true});

    // Navigate based on type
    final type = data['type'] ?? 'general';
    final postId = data['postId'] as String?;

    if (postId != null && (type == 'like' || type == 'comment')) {
      // Navigate to post
      try {
        final postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get();

        if (postDoc.exists) {
          final post = Post.fromFirestore(postDoc);
          
          if (type == 'comment') {
            // Navigate to comments
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommentsScreen(post: post),
              ),
            );
          } else {
            // Navigate to feed
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FeedScreen(),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final notifications = await FirebaseFirestore.instance
          .collection('community_notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ทำเครื่องหมายว่าอ่านแล้วทั้งหมด'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }
}
