import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story.dart';

class StoryService {
  final _storyCollection = FirebaseFirestore.instance.collection('stories');

  Future<void> addStory(Story story) async {
    await _storyCollection.add({
      'userId': story.userId,
      'imageUrl': story.imageUrl,
      'caption': story.caption,
      'createdAt': story.createdAt,
      'isHighlight': story.isHighlight,
      'highlightTitle': story.highlightTitle,
    });
  }

  Stream<List<Story>> getUserStories(String userId) {
    return _storyCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Story.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Story>> getHighlights(String userId) {
    return _storyCollection
        .where('userId', isEqualTo: userId)
        .where('isHighlight', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Story.fromMap(doc.data(), doc.id))
            .toList());
  }
}
