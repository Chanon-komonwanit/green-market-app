import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final Timestamp createdAt;
  final bool isHighlight;
  final String? highlightTitle;

  const Story({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
    this.isHighlight = false,
    this.highlightTitle,
  });

  factory Story.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Story(
      id: docId ?? map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      caption: map['caption']?.toString(),
      createdAt:
          map['createdAt'] is Timestamp ? map['createdAt'] : Timestamp.now(),
      isHighlight: map['isHighlight'] ?? false,
      highlightTitle: map['highlightTitle']?.toString(),
    );
  }
}
