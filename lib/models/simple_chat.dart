// lib/models/simple_chat.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderName;
  final Timestamp lastMessageTime;
  final String roomName;

  SimpleChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderName,
    required this.lastMessageTime,
    required this.roomName,
  });

  factory SimpleChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SimpleChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastSenderName: data['lastSenderName'] ?? '',
      lastMessageTime: data['lastMessageTime'] ?? Timestamp.now(),
      roomName: data['roomName'] ?? 'แชทกลุ่ม',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderName': lastSenderName,
      'lastMessageTime': lastMessageTime,
      'roomName': roomName,
    };
  }
}

class SimpleChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final Timestamp timestamp;

  SimpleChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  factory SimpleChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SimpleChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'ไม่ทราบชื่อ',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
