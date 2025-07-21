import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _chatRef = FirebaseFirestore.instance.collection('chats');

  Stream<QuerySnapshot> getUserChats(String userId) {
    return _chatRef.where('participants', arrayContains: userId).snapshots();
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> message) async {
    await _chatRef.doc(chatId).collection('messages').add(message);
  }
}
