// lib/models/community_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'post_type.dart';
import 'post_location.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userProfileImage;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
  final Map<String, String>
      reactions; // userId -> reactionType (like, love, wow, etc.)
  final List<String> likes; // รายชื่อ userId ที่กดไลค์ (backward compatibility)
  final int commentCount;
  final int shareCount;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final bool isActive;
  final List<String> tags; // แท็กเช่น #eco #green #sustainable
  final PostType postType; // ประเภทโพสต์
  final String? productId; // ถ้าเป็นโพสต์ขายสินค้า
  final String? activityId; // ถ้าเป็นโพสต์กิจกรรม
  final bool isPinned; // ปักหมุดโพสต์
  final List<String> mentions; // @username mentions
  final int viewCount; // จำนวนคนดู
  final List<String> savedBy; // Users who bookmarked this post
  final Map<String, dynamic>? pollData; // Poll data if post type is poll
  final String? originalPostId; // If this is a repost, ID of original post
  final String? originalUserId; // Original post author ID
  final String? originalUserName; // Original post author name
  final String? repostComment; // Comment added when reposting

  // NEW: Friend tagging and location features
  final List<String> taggedUserIds; // IDs of users tagged in this post
  final Map<String, String> taggedUserNames; // {userId: displayName}
  final PostLocation? location; // Location/check-in data

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userProfileImage,
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
    this.reactions = const {},
    this.likes = const [],
    this.commentCount = 0,
    this.shareCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.tags = const [],
    this.postType = PostType.normal,
    this.productId,
    this.activityId,
    this.isPinned = false,
    this.mentions = const [],
    this.viewCount = 0,
    this.savedBy = const [],
    this.pollData,
    this.originalPostId,
    this.originalUserId,
    this.originalUserName,
    this.repostComment,
    this.taggedUserIds = const [],
    this.taggedUserNames = const {},
    this.location,
  });

  // Helper getters
  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get isRepost => originalPostId != null;
  int get likeCount => reactions.length; // Total reactions
  int get totalLikes => likes.length; // Backward compatibility
  bool isLikedBy(String userId) =>
      reactions.containsKey(userId) || likes.contains(userId);
  String? getReactionBy(String userId) => reactions[userId];
  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (var reaction in reactions.values) {
      counts[reaction] = (counts[reaction] ?? 0) + 1;
    }
    return counts;
  }

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
        reactions: map['reactions'] is Map
            ? Map<String, String>.from(map['reactions'])
            : {},
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
        postType: _parsePostType(map['postType']),
        productId: map['productId']?.toString(),
        activityId: map['activityId']?.toString(),
        isPinned: map['isPinned'] ?? false,
        mentions: safeStringList(map['mentions'], 'mentions'),
        viewCount: map['viewCount'] ?? 0,
        originalPostId: map['originalPostId']?.toString(),
        originalUserId: map['originalUserId']?.toString(),
        originalUserName: map['originalUserName']?.toString(),
        repostComment: map['repostComment']?.toString(),
        taggedUserIds: safeStringList(map['taggedUserIds'], 'taggedUserIds'),
        taggedUserNames: map['taggedUserNames'] is Map
            ? Map<String, String>.from(map['taggedUserNames'])
            : {},
        location: map['location'] != null
            ? PostLocation.fromMap(Map<String, dynamic>.from(map['location']))
            : null,
      );
    } catch (e, stack) {
      // log รายละเอียด error พร้อมข้อมูล map
      debugPrint('CommunityPost.fromMap ERROR: $e\n$stack\nmap=$map');
      rethrow;
    }
  }

  static PostType _parsePostType(dynamic value) {
    if (value == null) return PostType.normal;
    if (value is PostType) return value;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'activity':
        return PostType.activity;
      case 'announcement':
        return PostType.announcement;
      case 'poll':
        return PostType.poll;
      case 'marketplace':
        return PostType.marketplace;
      default:
        return PostType.normal;
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
      'reactions': reactions,
      'likes': likes,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'tags': tags,
      'postType': postType.toString().split('.').last,
      'productId': productId,
      'activityId': activityId,
      'isPinned': isPinned,
      'mentions': mentions,
      'viewCount': viewCount,
      'savedBy': savedBy,
      'pollData': pollData,
      'originalPostId': originalPostId,
      'originalUserId': originalUserId,
      'originalUserName': originalUserName,
      'repostComment': repostComment,
      'taggedUserIds': taggedUserIds,
      'taggedUserNames': taggedUserNames,
      if (location != null) 'location': location!.toMap(),
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
    Map<String, String>? reactions,
    List<String>? likes,
    int? commentCount,
    int? shareCount,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isActive,
    List<String>? tags,
    PostType? postType,
    String? productId,
    String? activityId,
    bool? isPinned,
    List<String>? mentions,
    int? viewCount,
    List<String>? taggedUserIds,
    Map<String, String>? taggedUserNames,
    PostLocation? location,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      reactions: reactions ?? this.reactions,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      postType: postType ?? this.postType,
      productId: productId ?? this.productId,
      activityId: activityId ?? this.activityId,
      isPinned: isPinned ?? this.isPinned,
      mentions: mentions ?? this.mentions,
      viewCount: viewCount ?? this.viewCount,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds,
      taggedUserNames: taggedUserNames ?? this.taggedUserNames,
      location: location ?? this.location,
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
