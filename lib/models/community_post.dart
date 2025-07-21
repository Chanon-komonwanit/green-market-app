// lib/models/community_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    List<String> safeStringList(dynamic value, String field) {
      try {
        if (value == null) return [];
        if (value is List<String>) return value;
        if (value is List) {
          return value
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
        }
        return [];
      } catch (e) {
        throw Exception('Field "$field" type error: $e, value=$value');
      }
    }

    Timestamp safeTimestamp(dynamic value, String field) {
      try {
        if (value is Timestamp) return value;
        if (value is DateTime) return Timestamp.fromDate(value);
        return Timestamp.now();
      } catch (e) {
        throw Exception('Field "$field" type error: $e, value=$value');
      }
    }

    try {
      return CommunityPost(
        id: docId ?? map['id']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        userDisplayName: map['userDisplayName']?.toString() ?? '',
        userProfileImage: map['userProfileImage']?.toString(),
        content: map['content']?.toString() ?? '',
        imageUrls: safeStringList(map['imageUrls'], 'imageUrls'),
        videoUrl: map['videoUrl']?.toString(),
        likes: safeStringList(map['likes'], 'likes'),
        commentCount: (map['commentCount'] is int)
            ? map['commentCount']
            : int.tryParse(map['commentCount']?.toString() ?? '') ?? 0,
        shareCount: (map['shareCount'] is int)
            ? map['shareCount']
            : int.tryParse(map['shareCount']?.toString() ?? '') ?? 0,
        createdAt: safeTimestamp(map['createdAt'], 'createdAt'),
        updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
        isActive: map['isActive'] is bool ? map['isActive'] : true,
        tags: safeStringList(map['tags'], 'tags'),
      );
    } catch (e, stack) {
      // log รายละเอียด error พร้อมข้อมูล map
      debugPrint('CommunityPost.fromMap ERROR: $e\n$stack\nmap=$map');
      rethrow;
    }
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
