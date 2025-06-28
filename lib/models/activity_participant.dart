// lib/models/activity_participant.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityParticipant {
  final String id; // Document ID
  final String activityId;
  final String userId;
  final String userName; // For easier display
  final Timestamp joinedAt;

  ActivityParticipant({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.userName,
    required this.joinedAt,
  });

  factory ActivityParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError(
          'Missing data for ActivityParticipant with ID: ${doc.id}');
    }
    return ActivityParticipant(
      id: doc.id,
      activityId: data['activityId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? 'Unknown User',
      joinedAt: data['joinedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'activityId': activityId,
      'userId': userId,
      'userName': userName,
      'joinedAt': joinedAt,
    };
  }
}
