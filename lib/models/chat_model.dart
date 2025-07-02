import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTimestamp: map['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final String? imageUrl;

  // Enhanced features
  final String? fileUrl;
  final String? fileName;
  final String? fileType; // 'image', 'document', 'audio', 'video'
  final int? fileSize;
  final bool isRead;
  final Timestamp? readAt;
  final String messageType; // 'text', 'image', 'file', 'audio', 'video'
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata; // Additional data for future use

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.isRead = false,
    this.readAt,
    this.messageType = 'text',
    this.replyToMessageId,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileType: map['fileType'],
      fileSize: map['fileSize'],
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'],
      messageType: map['messageType'] ?? 'text',
      replyToMessageId: map['replyToMessageId'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'isRead': isRead,
      'readAt': readAt,
      'messageType': messageType,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    Timestamp? timestamp,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    bool? isRead,
    Timestamp? readAt,
    String? messageType,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      messageType: messageType ?? this.messageType,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isTextMessage => messageType == 'text';
  bool get isImageMessage => messageType == 'image';
  bool get isFileMessage => messageType == 'file';
  bool get isReply => replyToMessageId != null;

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
