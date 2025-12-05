// lib/screens/community_notifications_screen.dart
// การแจ้งเตือนเฉพาะชุมชนสีเขียว (Like, Comment, Share ในโพสต์ชุมชน)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/community_post.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/screens/post_comments_screen.dart';
import 'package:green_market/screens/eco_influence_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityNotificationsScreen extends StatefulWidget {
  const CommunityNotificationsScreen({super.key});

  @override
  State<CommunityNotificationsScreen> createState() =>
      _CommunityNotificationsScreenState();
}

class _CommunityNotificationsScreenState
    extends State<CommunityNotificationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('การแจ้งเตือน', style: AppTextStyles.headline),
          backgroundColor: AppColors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.grayPrimary),
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: Text('การแจ้งเตือน', style: AppTextStyles.headline),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.grayPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'ทำเครื่องหมายว่าอ่านแล้วทั้งหมด',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getCommunityNotifications(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                  'เกิดข้อผิดพลาดในการโหลดการแจ้งเตือน: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppColors.graySecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีการแจ้งเตือน',
                    style: AppTextStyles.subtitle,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'เมื่อมีคนกด Like, Comment หรือ Share\nโพสต์ของคุณในชุมชนสีเขียว\nคุณจะเห็นการแจ้งเตือนที่นี่',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.padding),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final notificationId = data['id'] as String;
    final type = data['type'] ?? 'general';
    final isRead = data['isRead'] ?? false;
    final createdAt = data['createdAt'] as Timestamp?;
    final body = data['body'] ?? 'มีข้อความใหม่';
    final senderId = data['senderId'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallPadding),
      color: isRead ? AppColors.white : AppColors.primaryTeal.withOpacity(0.05),
      elevation: isRead ? 1 : 2,
      child: ListTile(
        onTap: () => _handleNotificationTap(data, notificationId),
        leading: FutureBuilder<AppUser?>(
          future:
              senderId != null ? _firebaseService.getUserById(senderId) : null,
          builder: (context, userSnapshot) {
            final sender = userSnapshot.data;
            return CircleAvatar(
              radius: 22,
              backgroundColor: _getNotificationColor(type).withOpacity(0.2),
              backgroundImage: sender?.photoUrl != null
                  ? NetworkImage(sender!.photoUrl!)
                  : null,
              child: sender?.photoUrl == null
                  ? Icon(
                      _getNotificationIcon(type),
                      color: _getNotificationColor(type),
                      size: 20,
                    )
                  : null,
            );
          },
        ),
        title: Text(
          data['title'] ?? 'การแจ้งเตือนใหม่',
          style: AppTextStyles.bodyBold,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(createdAt),
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
      case 'community_like':
        return AppColors.errorRed;
      case 'comment':
      case 'community_comment':
        return AppColors.infoBlue;
      case 'community_share':
        return AppColors.primaryGreen;
      case 'content_violation':
        return Colors.red.shade700;
      default:
        return const Color(0xFF059669);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
      case 'community_like':
        return Icons.favorite;
      case 'comment':
      case 'community_comment':
        return Icons.comment;
      case 'community_share':
        return Icons.share;
      case 'content_violation':
        return Icons.warning_rounded;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'เมื่อสักครู่';
    return timeago.format(timestamp.toDate(), locale: 'th');
  }

  Future<void> _handleNotificationTap(
      Map<String, dynamic> data, String notificationId) async {
    // Mark as read
    await _firebaseService.markNotificationAsRead(notificationId);

    final type = data['type'] as String?;

    // ถ้าเป็นการแจ้งเตือนการละเมิด - นำทางไปหน้า Eco Influence (ประวัติการละเมิด)
    if (type == 'content_violation') {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EcoInfluenceScreen(),
          ),
        );
      }
      return;
    }

    // Navigate based on type
    final notificationData = data['data'] as Map<String, dynamic>?;
    final postId = notificationData?['postId'] as String?;

    if (postId != null) {
      try {
        final postData = await _firebaseService.getCommunityPostById(postId);
        if (postData != null && mounted) {
          final post = CommunityPost.fromMap(postData, postData['id']);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostCommentsScreen(post: post),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถเปิดโพสต์ได้: $e')),
          );
        }
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) return;

    try {
      await _firebaseService.markAllNotificationsAsRead(currentUser.id);

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
