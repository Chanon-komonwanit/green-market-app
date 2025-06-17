// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId; // Optional: if navigating from chat list
  final String productId;
  final String productName;
  final String productImageUrl;
  final String buyerId;
  final String sellerId;
  // Optional: Pass names if fetched before navigating
  // final String? buyerName;
  // final String? sellerName;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.buyerId,
    required this.sellerId,
    // this.buyerName,
    // this.sellerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late FirebaseService _firebaseService;
  late User _currentUser;
  String _otherUserName = "ผู้ขาย"; // Default, will try to fetch

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _fetchOtherUserName();
    // Mark chat as read when screen opens, ensure chatId is not null or empty
    String effectiveChatId = widget.chatId ?? '';

    // If the passed chatId is null or empty, try to construct it
    if (effectiveChatId.isEmpty) {
      // This logic to construct chatId should ideally live within FirebaseService or be consistent with it.
      // For now, we'll assume that if chatId is not passed, it might be a new chat, and reading is not applicable yet.
    }
    // Only mark as read if we have a valid, non-empty chatId.
    if (effectiveChatId.isNotEmpty) {
      _firebaseService.markChatRoomAsRead(effectiveChatId, _currentUser.uid);
    }
  }

  Future<void> _fetchOtherUserName() async {
    String otherUserId =
        _currentUser.uid == widget.buyerId ? widget.sellerId : widget.buyerId;
    String? name = await _firebaseService.getUserDisplayName(otherUserId);
    if (mounted && name != null) {
      setState(() {
        _otherUserName = name;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }
    // Optimistically clear the text field
    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Prepare display names for the chat room document
    // Use fetched _otherUserName, and current user's display name or a default
    final String currentUserDisplayName = _currentUser.displayName ??
        _currentUser.email?.split('@')[0] ??
        "ผู้ใช้";
    final String buyerDisplayName = _currentUser.uid == widget.buyerId
        ? currentUserDisplayName
        : _otherUserName;
    final String sellerDisplayName = _currentUser.uid == widget.sellerId
        ? currentUserDisplayName
        : _otherUserName;

    try {
      await _firebaseService.sendChatMessage(
        widget.productId,
        widget.productName,
        widget.productImageUrl,
        widget.buyerId,
        widget.sellerId,
        _currentUser.uid,
        messageText,
        buyerName: buyerDisplayName, // Pass determined buyer name
        sellerName: sellerDisplayName, // Pass determined seller name
      );
    } catch (e) {
      // If sending fails, consider re-populating the text field or showing an error
      if (mounted) {
        _messageController.text = messageText; // Re-populate on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถส่งข้อความได้: $e')),
        );
      }
    }

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat messageTimeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align text to the start
          children: [
            Text(_otherUserName,
                style: AppTextStyles.subtitle
                    .copyWith(fontSize: 18, color: AppColors.white)),
            Text('เกี่ยวกับ: ${widget.productName}',
                style: AppTextStyles.body.copyWith(
                    // ignore: deprecated_member_use
                    fontSize: 12,
                    // ignore: deprecated_member_use
                    color: AppColors.white.withOpacity(0.8))),
          ],
        ),
        backgroundColor: AppColors.primaryGreen, // Theme AppBar
        iconTheme:
            const IconThemeData(color: AppColors.white), // Back button color
        actions: [
          if (widget.productImageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.productImageUrl),
                radius: 18,
              ),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.getChatMessages(
                  widget.productId, widget.buyerId, widget.sellerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child:
                        Text('เริ่มการสนทนาได้เลย!', style: AppTextStyles.body),
                  );
                }
                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message['senderId'] == _currentUser.uid;
                    final Timestamp? timestamp = message['timestamp'];
                    final String displayTime = timestamp != null
                        ? messageTimeFormat.format(timestamp.toDate().toLocal())
                        : '';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primaryGreen
                              : AppColors
                                  .lightBeige, // Use lightBeige for other's messages
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'] ?? '',
                              style: AppTextStyles.body.copyWith(
                                  color: isMe
                                      ? AppColors.white
                                      : AppColors.darkGrey,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayTime,
                              style: TextStyle(
                                color: isMe
                                    // ignore: deprecated_member_use
                                    ? AppColors.white.withOpacity(0.7)
                                    // ignore: deprecated_member_use
                                    : AppColors.earthyBrown.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            decoration:
                BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [
              BoxShadow(
                offset: const Offset(0, -1),
                blurRadius: 1,
                // ignore: deprecated_member_use
                color: AppColors.darkGrey.withOpacity(0.05),
              )
            ]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true, // Add a subtle fill color
                      fillColor: AppColors.lightBeige,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryGreen),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
