// lib/models/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id; // Firestore document ID
  final String productId;
  final String userId;
  final String orderId; // To link review to a specific order
  final String userName; // Display name of the reviewer
  final double rating; // e.g., 1.0 to 5.0
  final String comment;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.orderId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      orderId: data['orderId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'orderId': orderId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
