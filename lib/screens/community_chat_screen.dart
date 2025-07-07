// lib/screens/community_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/models/app_user.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _chatId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChatId();
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
          title: const Text('แชท'),
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF059669),
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages List
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
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                    ),
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
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ยังไม่มีข้อความ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'เริ่มการสนทนาด้วยการส่งข้อความ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
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

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey,
                  width: 0.2,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
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
    final message = data['message'] ?? '';
    final senderName = data['senderName'] ?? 'ผู้ใช้';

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
              backgroundColor: const Color(0xFF059669),
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
                color: isMe ? const Color(0xFF059669) : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  if (!isMe)
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe ? Colors.white : const Color(0xFF1F2937),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[500],
                    ),
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
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      };

      // Add message to chat
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
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser.uid,
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
