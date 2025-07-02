// lib/services/enhanced_chat_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_model.dart';

class EnhancedChatService {
  static final EnhancedChatService _instance = EnhancedChatService._internal();
  factory EnhancedChatService() => _instance;
  EnhancedChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Send text message
  Future<void> sendTextMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
    String? replyToMessageId,
  }) async {
    final messageId = _firestore.collection('chat_rooms').doc().id;

    final message = ChatMessage(
      id: messageId,
      senderId: senderId,
      text: text,
      timestamp: Timestamp.now(),
      messageType: 'text',
      replyToMessageId: replyToMessageId,
    );

    await _saveMessage(chatRoomId, message);
    await _updateChatRoomLastMessage(chatRoomId, text, senderId);
  }

  // Send image message
  Future<void> sendImageMessage({
    required String chatRoomId,
    required String senderId,
    required XFile imageFile,
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _firestore.collection('chat_rooms').doc().id;

      // Upload image to Firebase Storage
      final imageUrl = await _uploadFile(
        file: File(imageFile.path),
        folder: 'chat_images',
        fileName: '${messageId}_${imageFile.name}',
      );

      final message = ChatMessage(
        id: messageId,
        senderId: senderId,
        text: caption ?? '',
        timestamp: Timestamp.now(),
        imageUrl: imageUrl,
        messageType: 'image',
        replyToMessageId: replyToMessageId,
        metadata: {
          'originalFileName': imageFile.name,
          'fileSize': await imageFile.length(),
        },
      );

      await _saveMessage(chatRoomId, message);
      await _updateChatRoomLastMessage(chatRoomId, '📷 ส่งรูปภาพ', senderId);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending image message: $e');
      }
      rethrow;
    }
  }

  // Send file message
  Future<void> sendFileMessage({
    required String chatRoomId,
    required String senderId,
    required File file,
    required String fileName,
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _firestore.collection('chat_rooms').doc().id;
      final fileSize = await file.length();

      // Check file size limit (10MB)
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('ไฟล์มีขนาดใหญ่เกิน 10MB');
      }

      // Upload file to Firebase Storage
      final fileUrl = await _uploadFile(
        file: file,
        folder: 'chat_files',
        fileName: '${messageId}_$fileName',
      );

      final fileType = _getFileType(fileName);

      final message = ChatMessage(
        id: messageId,
        senderId: senderId,
        text: caption ?? '',
        timestamp: Timestamp.now(),
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
        messageType: 'file',
        replyToMessageId: replyToMessageId,
      );

      await _saveMessage(chatRoomId, message);
      await _updateChatRoomLastMessage(
          chatRoomId, '📎 ส่งไฟล์: $fileName', senderId);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending file message: $e');
      }
      rethrow;
    }
  }

  // Pick and send image
  Future<void> pickAndSendImage({
    required String chatRoomId,
    required String senderId,
    String? caption,
    String? replyToMessageId,
    ImageSource source = ImageSource.gallery,
  }) async {
    final XFile? imageFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (imageFile != null) {
      await sendImageMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        imageFile: imageFile,
        caption: caption,
        replyToMessageId: replyToMessageId,
      );
    }
  }

  // Pick and send file
  Future<void> pickAndSendFile({
    required String chatRoomId,
    required String senderId,
    String? caption,
    String? replyToMessageId,
    List<String>? allowedExtensions,
  }) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      await sendFileMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        file: file,
        fileName: fileName,
        caption: caption,
        replyToMessageId: replyToMessageId,
      );
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking message as read: $e');
      }
    }
  }

  // Mark all messages as read for a user
  Future<void> markAllMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final batch = _firestore.batch();
      final messagesQuery = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all messages as read: $e');
      }
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final unreadQuery = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return unreadQuery.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
      return 0;
    }
  }

  // Stream messages with enhanced features
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Search messages
  Future<List<ChatMessage>> searchMessages({
    required String chatRoomId,
    required String query,
    int limit = 50,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - consider using Algolia for better search
      final messagesQuery = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit * 3) // Get more to filter
          .get();

      final messages = messagesQuery.docs
          .map((doc) => ChatMessage.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .where((message) =>
              message.text.toLowerCase().contains(query.toLowerCase()) ||
              (message.fileName?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .take(limit)
          .toList();

      return messages;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching messages: $e');
      }
      return [];
    }
  }

  // Delete message
  Future<void> deleteMessage({
    required String chatRoomId,
    required String messageId,
    bool deleteForEveryone = false,
  }) async {
    try {
      if (deleteForEveryone) {
        await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(messageId)
            .delete();
      } else {
        // Soft delete - mark as deleted for sender only
        await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(messageId)
            .update({
          'isDeleted': true,
          'deletedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting message: $e');
      }
      rethrow;
    }
  }

  // Private helper methods
  Future<String> _uploadFile({
    required File file,
    required String folder,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('$folder/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveMessage(String chatRoomId, ChatMessage message) async {
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Future<void> _updateChatRoomLastMessage(
    String chatRoomId,
    String lastMessage,
    String senderId,
  ) async {
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': lastMessage,
      'lastMessageTimestamp': Timestamp.now(),
      'lastSenderId': senderId,
    });
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (['pdf'].contains(extension)) {
      return 'document';
    } else if (['mp3', 'wav', 'aac', 'm4a'].contains(extension)) {
      return 'audio';
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return 'video';
    } else {
      return 'document';
    }
  }
}
