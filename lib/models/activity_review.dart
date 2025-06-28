// lib/models/activity_review.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class ActivityReview {
  final String id;
  final String activityId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final Timestamp createdAt;

  ActivityReview({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ActivityReview.fromMap(Map<String, dynamic> map) {
    return ActivityReview(
      id: map['id'] as String,
      activityId: map['activityId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityId': activityId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }

  String get formattedDate =>
      DateFormat('dd/MM/yyyy').format(createdAt.toDate());
}
