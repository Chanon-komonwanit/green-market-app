// lib/models/app_notification.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId; // ID ของผู้รับการแจ้งเตือน
  final String title;
  final String body;
  final String type; // เช่น 'order_status', 'product_approved', 'chat_message'
  final String? relatedId; // เช่น orderId, productId, chatId
  final Timestamp createdAt;
  bool isRead; // สถานะอ่านแล้ว/ยังไม่อ่าน

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
  });

  // สร้าง AppNotification object จาก Firestore DocumentSnapshot
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError(
          'Failed to parse notification from Firestore: data is null for doc ${doc.id}');
    }
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      relatedId: data['relatedId'] as String?,
      // Ensure createdAt is always a valid Timestamp from Firestore,
      // or default to Timestamp.now() if it's null or not a Timestamp.
      // This prevents errors during deserialization if the data is malformed or missing.
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  // แปลง AppNotification object ไปเป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}
