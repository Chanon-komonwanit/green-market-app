// lib/models/app_notification.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String
      type; // e.g., 'order_status_update', 'product_approved', 'seller_application_approved'
  final String? relatedId; // ID of the related entity (order, product, etc.)
  final bool isRead; // Added isRead status
  final Timestamp createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      relatedId: map['relatedId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  AppNotification copyWith({
    bool? isRead,
    required String id,
  }) {
    return AppNotification(
      // Removed deprecated withOpacity
      id: id, userId: userId, title: title, body: body, type: type,
      relatedId: relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get formattedDate =>
      DateFormat('dd MMM yyyy HH:mm').format(createdAt.toDate());
}
