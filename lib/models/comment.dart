import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userDisplayName;
  final String? userProfileImage;
  final String content;
  final Timestamp createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    this.userProfileImage,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Comment(
      id: docId ?? map['id']?.toString() ?? '',
      postId: map['postId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userDisplayName: map['userDisplayName']?.toString() ?? '',
      userProfileImage: map['userProfileImage']?.toString(),
      content: map['content']?.toString() ?? '',
      createdAt:
          map['createdAt'] is Timestamp ? map['createdAt'] : Timestamp.now(),
    );
  }
}
