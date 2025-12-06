// lib/screens/activity_notifications_screen.dart
// การแจ้งเตือนเฉพาะกิจกรรมเพื่อสังคมและสิ่งแวดล้อม (Activity Notifications)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityNotificationsScreen extends StatefulWidget {
  const ActivityNotificationsScreen({super.key});

  @override
  State<ActivityNotificationsScreen> createState() =>
      _ActivityNotificationsScreenState();
}

class _ActivityNotificationsScreenState
    extends State<ActivityNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('th', timeago.ThMessages());
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('การแจ้งเตือนกิจกรรม'),
          backgroundColor: AppColors.primaryGreen,
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('การแจ้งเตือนกิจกรรม', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'ทำเครื่องหมายว่าอ่านแล้วทั้งหมด',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.id)
            .where('category', whereIn: [
              'activity',
              'event',
              'eco_challenge',
              'participation'
            ])
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: AppColors.graySecondary),
                  SizedBox(height: 16),
                  Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                ],
              ),
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
                    size: 80,
                    color: AppColors.graySecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีการแจ้งเตือน',
                    style: AppTextStyles.subtitle,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'การแจ้งเตือนเกี่ยวกับกิจกรรม\nจะแสดงที่นี่',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildNotificationCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      String notificationId, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'general';
    final isRead = data['isRead'] as bool? ?? false;
    final title = data['title'] as String? ?? 'การแจ้งเตือน';
    final body = data['body'] as String? ?? '';
    final timestamp = data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isRead
              ? Colors.transparent
              : AppColors.primaryGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getColorByType(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconByType(type),
              color: _getColorByType(type), size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF2E2E2E),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 8),
              Text(
                timeago.format(timestamp.toDate(), locale: 'th'),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: !isRead
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.circle, color: Colors.white, size: 8),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _markAsRead(notificationId),
      ),
    );
  }

  IconData _getIconByType(String type) {
    switch (type) {
      case 'new_activity':
        return Icons.event_available;
      case 'activity_update':
        return Icons.update;
      case 'activity_completed':
        return Icons.check_circle;
      case 'eco_challenge':
        return Icons.emoji_events;
      case 'participation':
        return Icons.group;
      case 'reward':
        return Icons.card_giftcard;
      default:
        return Icons.eco;
    }
  }

  Color _getColorByType(String type) {
    switch (type) {
      case 'new_activity':
        return Colors.green;
      case 'activity_update':
        return Colors.blue;
      case 'activity_completed':
        return Colors.purple;
      case 'eco_challenge':
        return Colors.orange;
      case 'participation':
        return Colors.teal;
      case 'reward':
        return Colors.amber;
      default:
        return AppColors.primaryGreen;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.id)
          .where('category',
              whereIn: ['activity', 'event', 'eco_challenge', 'participation'])
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ทำเครื่องหมายอ่านแล้วทั้งหมด'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }
}
