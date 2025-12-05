// lib/screens/community_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:green_market/widgets/chat_media_picker.dart';
import 'package:green_market/widgets/message_read_receipt.dart';
import 'package:green_market/services/content_moderation_service.dart';
import 'dart:io';

class CommunityChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const CommunityChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  void _showShareActivityDialog() async {
    // ตัวอย่างข้อมูลกิจกรรม สามารถเชื่อมต่อกับระบบกิจกรรมจริงได้
    const activityId = 'sample-activity-id';
    const title = 'ปลูกต้นไม้ร่วมกัน';
    const description = 'เข้าร่วมกิจกรรมปลูกต้นไม้เพื่อโลกสีเขียวของเรา!';
    const imageUrl =
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80';
    const ecoCoinsReward = 50;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แชร์กิจกรรม'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.bodyBold),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: AppTextStyles.caption),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl,
                  height: 80, width: 120, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.monetization_on,
                    color: AppColors.successGreen, size: 16),
                SizedBox(width: 4),
                Text('รางวัล: $ecoCoinsReward Eco Coins',
                    style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendActivityCard(
                activityId: activityId,
                title: title,
                description: description,
                imageUrl: imageUrl,
                ecoCoinsReward: ecoCoinsReward,
              );
            },
            child: const Text('แชร์กิจกรรม'),
          ),
        ],
      ),
    );
  }

  // Example: Send activity card (for future extensibility)
  Future<void> _sendActivityCard({
    required String activityId,
    required String title,
    required String description,
    String? imageUrl,
    int? ecoCoinsReward,
  }) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.currentUser;
      if (currentUser == null || userData == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }
      final messageData = {
        'senderId': currentUser.uid,
        'senderName': userData.displayName ?? 'ผู้ใช้',
        'type': 'activity',
        'activityId': activityId,
        'activityTitle': title,
        'activityDescription': description,
        'activityImageUrl': imageUrl,
        'ecoCoinsReward': ecoCoinsReward,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('community_chats')
          .doc(_chatId)
          .collection('messages')
          .add(messageData);
      // Update chat metadata
      await FirebaseFirestore.instance
          .collection('community_chats')
          .doc(_chatId)
          .set({
        'participants': [currentUser.uid, widget.otherUserId],
        'lastMessage': '[กิจกรรม] $title',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser.uid,
        'participantInfo': {
          currentUser.uid: {
            'displayName': userData.displayName ?? 'ผู้ใช้',
            'photoUrl': userData.photoUrl,
          },
          widget.otherUserId: {
            'displayName': widget.otherUserName,
            'photoUrl': widget.otherUserPhoto,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      // Send notification to other user
      await _sendNotification(
          '[กิจกรรม] $title', userData.displayName ?? 'ผู้ใช้');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _chatId;
  bool _isLoading = false;
  bool _isTyping = false;
  final ContentModerationService _moderationService =
      ContentModerationService();

  @override
  void initState() {
    super.initState();
    _initializeChatId();
    _messageController.addListener(_onTextChanged);
    _updateOnlineStatus(true);
  }

  void _onTextChanged() {
    final isTyping = _messageController.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      _updateTypingStatus(isTyping);
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await updateUserOnlineStatus(currentUser.uid, isOnline);
    }
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await updateTypingStatus(
        chatId: _chatId,
        userId: currentUser.uid,
        isTyping: isTyping,
      );
    }
  }

  void _initializeChatId() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      // Create consistent chat ID by sorting user IDs
      final userIds = [currentUserId, widget.otherUserId];
      userIds.sort();
      _chatId = '${userIds[0]}_${userIds[1]}';
    }
  }

  @override
  void dispose() {
    _updateTypingStatus(false);
    _updateOnlineStatus(false);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('แชท', style: AppTextStyles.headline),
          backgroundColor: AppColors.white,
          elevation: 1,
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }
    // Main chat UI
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryTeal.withOpacity(0.2),
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : 'U',
                      style: AppTextStyles.headline
                          .copyWith(color: AppColors.primaryTeal, fontSize: 18),
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.otherUserName,
                          style: AppTextStyles.headline,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6),
                      OnlineStatusIndicator(userId: widget.otherUserId),
                    ],
                  ),
                  TypingIndicator(
                    chatId: _chatId,
                    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.eco, color: AppColors.primaryTeal),
              tooltip: 'แชร์กิจกรรม',
              onPressed: _showShareActivityDialog,
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primaryTeal),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.graySecondary,
                        ),
                        SizedBox(height: 16),
                        Text('ยังไม่มีข้อความ', style: AppTextStyles.subtitle),
                        SizedBox(height: 8),
                        Text('เริ่มการสนทนาด้วยการส่งข้อความ',
                            style: AppTextStyles.body),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;
                    return _buildMessageBubble(data, currentUser.uid);
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.grayBorder,
                  width: 0.2,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_photo_alternate,
                      color: AppColors.primaryTeal),
                  onPressed: () async {
                    await ChatMediaPicker.show(
                      context: context,
                      onMediaSelected: (mediaType, filePath) async {
                        await _sendMediaMessage(mediaType, filePath);
                      },
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius * 2),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceGray,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: AppColors.white,
                          ),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, String currentUserId) {
    final isMe = data['senderId'] == currentUserId;
    final timestamp = data['timestamp'] as Timestamp?;
    final type = data['type'] ?? 'text';
    final senderName = data['senderName'] ?? 'ผู้ใช้';
    final message = data['message'] ?? '';
    final isRead = data['isRead'] ?? false;

    Widget bubbleContent;
    if (type == 'activity') {
      // Activity card bubble
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: AppColors.primaryTeal, size: 18),
              const SizedBox(width: 6),
              Text('กิจกรรมสีเขียว',
                  style: AppTextStyles.captionBold
                      .copyWith(color: AppColors.primaryTealDark)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data['activityTitle'] ?? '',
            style: AppTextStyles.bodyBold,
          ),
          if ((data['activityDescription'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                data['activityDescription'],
                style: AppTextStyles.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (data['ecoCoinsReward'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Icon(Icons.monetization_on,
                      color: AppColors.successGreen, size: 16),
                  const SizedBox(width: 4),
                  Text('รางวัล: ${data['ecoCoinsReward']} Eco Coins',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          if ((data['activityImageUrl'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['activityImageUrl'],
                  height: 100,
                  width: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      );
    } else if (type == 'image') {
      // Image message
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(senderName,
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.bold)),
          if (!isMe) const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              data['mediaUrl'] ?? '',
              fit: BoxFit.cover,
              width: 250,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 250,
                  height: 150,
                  color: AppColors.grayBorder,
                  child:
                      Icon(Icons.broken_image, color: AppColors.graySecondary),
                );
              },
            ),
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? AppColors.white : AppColors.grayPrimary,
                ),
              ),
            ),
        ],
      );
    } else if (type == 'video') {
      // Video message
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(senderName,
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.bold)),
          if (!isMe) const SizedBox(height: 4),
          Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.grayBorder,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.play_circle_outline,
                    size: 64, color: AppColors.white),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'วิดีโอ',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? AppColors.white : AppColors.grayPrimary,
                ),
              ),
            ),
        ],
      );
    } else {
      // Normal text bubble
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(senderName,
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.bold)),
          if (!isMe) const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isMe ? AppColors.white : AppColors.grayPrimary,
              height: 1.3,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.grayBorder,
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                style: AppTextStyles.bodyBold
                    .copyWith(color: AppColors.primaryTeal),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryTeal : AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bubbleContent,
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(timestamp),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: isMe
                              ? AppColors.white.withOpacity(0.8)
                              : AppColors.graySecondary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        MessageReadReceipt(
                          messageId: data['messageId'] ?? '',
                          senderId: data['senderId'] ?? '',
                          sentAt: timestamp,
                          isRead: isRead,
                          readAt: data['readAt'] as Timestamp?,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('E HH:mm', 'th').format(time);
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Content moderation check
    final moderationResult = await _moderationService.moderateContent(message);

    if (moderationResult.severity == ModerationSeverity.high) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ข้อความของคุณมีเนื้อหาไม่เหมาะสม กรุณาแก้ไขก่อนส่ง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.currentUser;

      if (currentUser == null || userData == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      final cleanedMessage = moderationResult.cleanedContent;

      final messageRef = await FirebaseFirestore.instance
          .collection('community_chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': userData.displayName ?? 'ผู้ใช้',
        'message': cleanedMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'isRead': false,
      });

      // Update message with its ID for read receipts
      await messageRef.update({'messageId': messageRef.id});

      // Update chat metadata
      await FirebaseFirestore.instance
          .collection('community_chats')
          .doc(_chatId)
          .set({
        'participants': [currentUser.uid, widget.otherUserId],
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser.uid,
        'participantInfo': {
          currentUser.uid: {
            'displayName': userData.displayName ?? 'ผู้ใช้',
            'photoUrl': userData.photoUrl,
          },
          widget.otherUserId: {
            'displayName': widget.otherUserName,
            'photoUrl': widget.otherUserPhoto,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Clear input
      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // Send notification to other user
      await _sendNotification(message, userData.displayName ?? 'ผู้ใช้');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMediaMessage(MediaType mediaType, String filePath) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.currentUser;

      if (currentUser == null || userData == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      // Upload media to Firebase Storage
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_media')
          .child(_chatId)
          .child(fileName);

      final uploadTask = await storageRef.putFile(File(filePath));
      final mediaUrl = await uploadTask.ref.getDownloadURL();

      // Send media message
      final messageRef = await FirebaseFirestore.instance
          .collection('community_chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': userData.displayName ?? 'ผู้ใช้',
        'message': '',
        'mediaUrl': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': mediaType == MediaType.image ? 'image' : 'video',
        'isRead': false,
      });

      await messageRef.update({'messageId': messageRef.id});

      // Update chat metadata
      await FirebaseFirestore.instance
          .collection('community_chats')
          .doc(_chatId)
          .set({
        'participants': [currentUser.uid, widget.otherUserId],
        'lastMessage': mediaType == MediaType.image ? '📷 รูปภาพ' : '🎥 วิดีโอ',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser.uid,
        'participantInfo': {
          currentUser.uid: {
            'displayName': userData.displayName ?? 'ผู้ใช้',
            'photoUrl': userData.photoUrl,
          },
          widget.otherUserId: {
            'displayName': widget.otherUserName,
            'photoUrl': widget.otherUserPhoto,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // Send notification
      await _sendNotification(
        mediaType == MediaType.image ? '📷 ส่งรูปภาพ' : '🎥 ส่งวิดีโอ',
        userData.displayName ?? 'ผู้ใช้',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งไฟล์: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNotification(String message, String senderName) async {
    try {
      await FirebaseFirestore.instance
          .collection('community_notifications')
          .add({
        'userId': widget.otherUserId,
        'type': 'message',
        'title': 'ข้อความใหม่',
        'body': 'ได้ส่งข้อความถึงคุณ',
        'fromUserId': FirebaseAuth.instance.currentUser?.uid,
        'fromUserName': senderName,
        'data': {
          'chatId': _chatId,
          'message': message,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignore notification errors
      print('Failed to send notification: $e');
    }
  }
}
