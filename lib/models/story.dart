// lib/models/story.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? caption;
  final Timestamp createdAt;
  final Timestamp expiresAt; // 24 hours from creation
  final List<String> viewedBy;
  final bool isActive;
  final int
      duration; // seconds for display (default 5 for image, video duration)
  final bool isHighlight;
  final String? highlightTitle;

  const Story({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.isActive = true,
    this.duration = 5,
    this.isHighlight = false,
    this.highlightTitle,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt.toDate());
  int get viewCount => viewedBy.length;
  bool isViewedBy(String userId) => viewedBy.contains(userId);
  String get imageUrl => mediaUrl; // Backward compatibility

  factory Story.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Story(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      mediaUrl: map['mediaUrl'] ?? map['imageUrl'] ?? '',
      mediaType: map['mediaType'] ?? 'image',
      caption: map['caption'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      expiresAt: map['expiresAt'] ??
          Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      isActive: map['isActive'] ?? true,
      duration: map['duration'] ?? 5,
      isHighlight: map['isHighlight'] ?? false,
      highlightTitle: map['highlightTitle'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'caption': caption,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'viewedBy': viewedBy,
      'isActive': isActive,
      'duration': duration,
      'isHighlight': isHighlight,
      'highlightTitle': highlightTitle,
    };
  }
}

class StoryGroup {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final List<Story> stories;
  final bool hasUnviewedStories;

  const StoryGroup({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.stories,
    required this.hasUnviewedStories,
  });

  int get totalStories => stories.length;
  int get unviewedCount => stories.where((s) => !s.isViewedBy(userId)).length;
}
