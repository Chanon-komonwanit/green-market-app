import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend.dart';

class FriendService {
  final _friendCollection = FirebaseFirestore.instance.collection('friends');

  // ตรวจสอบว่าติดตามหรือไม่
  Future<bool> isFollowing(String userId, String friendId) async {
    final query = await _friendCollection
        .where('userId', isEqualTo: userId)
        .where('friendId', isEqualTo: friendId)
        .get();
    return query.docs.isNotEmpty;
  }

  // ติดตามผู้ใช้
  Future<void> followUser(String userId, String friendId) async {
    await addFriend(userId, friendId);
  }

  // เลิกติดตามผู้ใช้
  Future<void> unfollowUser(String userId, String friendId) async {
    await removeFriend(userId, friendId);
  }

  Future<void> addFriend(String userId, String friendId) async {
    await _friendCollection.add({
      'userId': userId,
      'friendId': friendId,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final query = await _friendCollection
        .where('userId', isEqualTo: userId)
        .where('friendId', isEqualTo: friendId)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<Friend>> getFriends(String userId) {
    return _friendCollection.where('userId', isEqualTo: userId).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Friend.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<int> getFriendCount(String userId) async {
    final query =
        await _friendCollection.where('userId', isEqualTo: userId).get();
    return query.size;
  }
}
