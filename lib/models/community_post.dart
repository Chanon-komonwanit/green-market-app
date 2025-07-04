// lib/models/community_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userProfileImage;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
  final List<String> likes; // รายชื่อ userId ที่กดไลค์
  final int commentCount;
  final int shareCount;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final bool isActive;
  final List<String> tags; // แท็กเช่น #eco #green #sustainable

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userProfileImage,
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
    this.likes = const [],
    this.commentCount = 0,
    this.shareCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.tags = const [],
  });

  // Helper getters
  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);

  // Factory constructor from Firestore document
  factory CommunityPost.fromMap(Map<String, dynamic> map, [String? docId]) {
    return CommunityPost(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'] ?? '',
      userProfileImage: map['userProfileImage'],
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      videoUrl: map['videoUrl'],
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      shareCount: map['shareCount'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'],
      isActive: map['isActive'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userProfileImage': userProfileImage,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'likes': likes,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'tags': tags,
    };
  }

  // CopyWith method for updating
  CommunityPost copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userProfileImage,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    List<String>? likes,
    int? commentCount,
    int? shareCount,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isActive,
    List<String>? tags,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'CommunityPost(id: $id, userId: $userId, content: $content, likeCount: $likeCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
