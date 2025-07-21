import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String userId;
  final String friendId;
  final Timestamp createdAt;

  const Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
  });

  factory Friend.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Friend(
      id: docId ?? map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      friendId: map['friendId']?.toString() ?? '',
      createdAt:
          map['createdAt'] is Timestamp ? map['createdAt'] : Timestamp.now(),
    );
  }
}
