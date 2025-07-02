// d:/Development/green_market/lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String buyerId;
  final String sellerId;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.buyerId,
    required this.sellerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FirebaseService? _firebaseService;
  User? _currentUser;
  String _otherUserName = "ผู้ขาย";
  String? _initError;

  @override
  void initState() {
    super.initState();
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser == null) {
        _initError = 'ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่';
        return;
      }
      _firebaseService = Provider.of<FirebaseService>(context, listen: false);
      if (_firebaseService == null) {
        _initError = 'FirebaseService ไม่พร้อมใช้งาน';
        return;
      }
      if (widget.buyerId.isEmpty ||
          widget.sellerId.isEmpty ||
          widget.productId.isEmpty) {
        _initError = 'ข้อมูลแชทไม่ครบถ้วน';
        return;
      }
      _fetchOtherUserName();
      String effectiveChatId = widget.chatId ?? '';
      if (effectiveChatId.isNotEmpty) {
        _firebaseService!
            .markChatRoomAsRead(effectiveChatId, _currentUser!.uid);
      }
    } catch (e) {
      _initError = 'เกิดข้อผิดพลาด: ' + e.toString();
    }
  }

  Future<void> _fetchOtherUserName() async {
    if (_currentUser == null || _firebaseService == null) return;
    String otherUserId =
        _currentUser!.uid == widget.buyerId ? widget.sellerId : widget.buyerId;
    String? name = await _firebaseService!.getUserDisplayName(otherUserId);
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
    if (_currentUser == null || _firebaseService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('ไม่สามารถส่งข้อความได้: ไม่พบผู้ใช้หรือบริการ Firebase')),
      );
      return;
    }
    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final messageData = {
        'text': messageText,
        'senderId': _currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'productId': widget.productId,
        'productName': widget.productName,
        'productImageUrl': widget.productImageUrl,
      };

      // Create or get chat room ID
      final chatRoomId =
          '${widget.buyerId}_${widget.sellerId}_${widget.productId}';

      await _firebaseService!.sendMessage(chatRoomId, messageData);
    } catch (e) {
      if (mounted) {
        _messageController.text = messageText;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถส่งข้อความได้: $e')),
        );
      }
    }

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

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('แชท'),
          backgroundColor: AppColors.primaryGreen,
        ),
        body: Center(
          child: Text(_initError!,
              style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }
    if (_currentUser == null || _firebaseService == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('แชท'),
          backgroundColor: AppColors.primaryGreen,
        ),
        body: const Center(
          child: Text('ไม่พบข้อมูลผู้ใช้หรือบริการ Firebase',
              style: TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_otherUserName,
                style: AppTextStyles.subtitle
                    .copyWith(fontSize: 18, color: AppColors.white)),
            Text('เกี่ยวกับ: ${widget.productName}',
                style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.white.withAlpha((0.8 * 255).round()))),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.white),
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
              stream: _firebaseService!.getChatMessages(
                  '${widget.buyerId}_${widget.sellerId}_${widget.productId}'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }
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
                    final bool isMe = message['senderId'] == _currentUser!.uid;
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
                              : AppColors.lightBeige,
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
                              (message['text'] ?? message['message'] ?? ''),
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
                                    ? AppColors.white
                                        .withAlpha((0.7 * 255).round())
                                    : AppColors.earthyBrown
                                        .withAlpha((0.7 * 255).round()),
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
                color: AppColors.darkGrey.withAlpha((0.05 * 255).round()),
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
                      filled: true,
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
