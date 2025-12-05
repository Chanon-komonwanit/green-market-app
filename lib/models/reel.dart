// lib/models/reel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final String? soundTrack; // Background music
  final List<String> hashtags;
  final List<String> likes;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final Timestamp createdAt;
  final bool isActive;
  final int duration; // Video duration in seconds
  final bool allowDuet;
  final bool allowStitch;
  final String? originalReelId; // For duets/stitches

  const Reel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.caption,
    this.soundTrack,
    this.hashtags = const [],
    this.likes = const [],
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    required this.createdAt,
    this.isActive = true,
    this.duration = 15,
    this.allowDuet = true,
    this.allowStitch = true,
    this.originalReelId,
  });

  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);
  bool get isDuet => originalReelId != null;

  factory Reel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Reel(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      caption: map['caption'] ?? '',
      soundTrack: map['soundTrack'],
      hashtags: List<String>.from(map['hashtags'] ?? []),
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      shareCount: map['shareCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
      duration: map['duration'] ?? 15,
      allowDuet: map['allowDuet'] ?? true,
      allowStitch: map['allowStitch'] ?? true,
      originalReelId: map['originalReelId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'soundTrack': soundTrack,
      'hashtags': hashtags,
      'likes': likes,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'viewCount': viewCount,
      'createdAt': createdAt,
      'isActive': isActive,
      'duration': duration,
      'allowDuet': allowDuet,
      'allowStitch': allowStitch,
      'originalReelId': originalReelId,
    };
  }
}
