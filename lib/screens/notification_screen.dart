// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/app_notification.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:intl/intl.dart'; // <--- แก้ไข: Uncomment import intl

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firebaseService.markNotificationAsRead(notificationId);
      // อาจจะมีการ feedback ให้ผู้ใช้ เช่น SnackBar แต่สำหรับตอนนี้ปล่อยว่างไว้ก่อน
    } catch (e) {
      print("Error marking notification as read: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;
    try {
      await _firebaseService.markAllNotificationsAsRead(_currentUserId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('แจ้งเตือนทั้งหมดถูกทำเครื่องหมายว่าอ่านแล้ว')),
        );
      }
    } catch (e) {
      print("Error marking all notifications as read: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะทั้งหมด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('การแจ้งเตือน'),
        ),
        body: const Center(
          child: Text('ไม่พบผู้ใช้งาน กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text('อ่านทั้งหมด',
                style: TextStyle(
                    color:
                        Theme.of(context).appBarTheme.actionsIconTheme?.color ??
                            Colors.white)),
          )
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _firebaseService.getUserNotifications(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching notifications: ${snapshot.error}");
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีการแจ้งเตือน'));
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final bool isRead = notification.isRead;
              final Color tileColor =
                  isRead ? Colors.transparent : Colors.blue.shade50;
              final FontWeight titleFontWeight =
                  isRead ? FontWeight.normal : FontWeight.bold;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                color: tileColor,
                child: ListTile(
                  leading: Icon(
                    _getNotificationIcon(notification.type),
                    color:
                        isRead ? Colors.grey : Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(fontWeight: titleFontWeight),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.body),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(notification.createdAt.toDate()),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.mark_chat_read_outlined,
                              color: Colors.green),
                          tooltip: 'ทำเครื่องหมายว่าอ่านแล้ว',
                          onPressed: () => _markAsRead(notification.id),
                        ),
                  onTap: () {
                    if (!isRead) {
                      _markAsRead(notification.id);
                    }
                    // TODO: ในอนาคต อาจจะมีการ navigate ไปยังหน้าจอที่เกี่ยวข้อง
                    // เช่น ถ้า type เป็น 'order_status' และ relatedId มีค่า
                    // ก็อาจจะ navigate ไปยังหน้า OrderDetailsScreen(orderId: notification.relatedId)
                    // หรือถ้าเป็น 'new_product_approved' อาจจะไปหน้า ProductDetailScreen(productId: notification.relatedId)
                    print(
                        'Notification tapped: ${notification.id}, type: ${notification.type}, relatedId: ${notification.relatedId}');
                    // Example navigation:
                    // if (notification.type == 'order_update' && notification.relatedId != null) {
                    //   Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: notification.relatedId!)));
                    // }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'order_update':
        return Icons.receipt_long;
      case 'product_approved':
        return Icons.check_circle_outline;
      case 'new_message':
        return Icons.message_outlined;
      default:
        return Icons.notifications;
    }
  }
}
