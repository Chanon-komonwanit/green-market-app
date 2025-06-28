// lib/models/review.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class Review {
  final String id;
  final String productId;
  final String orderId; // Added orderId
  final String userId;
  final String userName;
  final String? userPhotoUrl; // Added userPhotoUrl
  final double rating;
  final String comment;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userPhotoUrl,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String,
      productId: map['productId'] as String,
      orderId: map['orderId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String,
      createdAt: map['createdAt'] as Timestamp,
      userPhotoUrl: map['userPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }

  Review copyWith({
    String? id,
    String? productId,
    String? orderId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? comment,
    Timestamp? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedDate =>
      DateFormat('dd MMM yyyy').format(createdAt.toDate());
}
