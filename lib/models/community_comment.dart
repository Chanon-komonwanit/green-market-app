// lib/models/community_comment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String id;
  final String postId;
  final String userId;
  final String userDisplayName;
  final String? userProfileImage;
  final String content;
  final List<String> likes; // รายชื่อ userId ที่กดไลค์คอมเมนต์
  final String? parentCommentId; // สำหรับ reply comment
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final bool isActive;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    this.userProfileImage,
    required this.content,
    this.likes = const [],
    this.parentCommentId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // Helper getters
  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);
  bool get isReply => parentCommentId != null;

  // Factory constructor from Firestore document
  factory CommunityComment.fromMap(Map<String, dynamic> map, [String? docId]) {
    return CommunityComment(
      id: docId ?? map['id'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'] ?? '',
      userProfileImage: map['userProfileImage'],
      content: map['content'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      parentCommentId: map['parentCommentId'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'],
      isActive: map['isActive'] ?? true,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userProfileImage': userProfileImage,
      'content': content,
      'likes': likes,
      'parentCommentId': parentCommentId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  // CopyWith method for updating
  CommunityComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userDisplayName,
    String? userProfileImage,
    String? content,
    List<String>? likes,
    String? parentCommentId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isActive,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'CommunityComment(id: $id, postId: $postId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
