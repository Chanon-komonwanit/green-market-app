// lib/models/post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String text;
  final String? imageUrl;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<String> tags;
  final String type; // 'text', 'image', 'mixed'

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.text,
    this.imageUrl,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.tags,
    required this.type,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'ผู้ใช้ไม่ระบุชื่อ',
      userProfileImage: data['userProfileImage'],
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      type: data['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'text': text,
      'imageUrl': imageUrl,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'tags': tags,
      'type': type,
    };
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasText => text.isNotEmpty;
  int get likesCount => likes.length;

  bool isLikedBy(String userId) => likes.contains(userId);

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImage,
    String? text,
    String? imageUrl,
    List<String>? likes,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? tags,
    String? type,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      type: type ?? this.type,
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String text;
  final DateTime createdAt;
  final bool isActive;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.text,
    required this.createdAt,
    required this.isActive,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'ผู้ใช้ไม่ระบุชื่อ',
      userProfileImage: data['userProfileImage'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
