// lib/screens/simple_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/simple_chat.dart';
import 'package:green_market/screens/simple_chat_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';

class SimpleChatListScreen extends StatelessWidget {
  const SimpleChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('กรุณาเข้าสู่ระบบเพื่อใช้งานแชท'),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data?.docs
                  .map((doc) => SimpleChatRoom.fromFirestore(doc))
                  .toList() ??
              [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: AppColors.modernGrey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ยังไม่มีรายการแชท',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เริ่มต้นการสนทนาใหม่จากสินค้าที่สนใจ',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.modernGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return _buildChatRoomTile(context, chatRoom, currentUser.uid);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatDialog(context),
        backgroundColor: AppColors.primaryTeal,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildChatRoomTile(
      BuildContext context, SimpleChatRoom chatRoom, String currentUserId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.lightTeal,
          child: const Icon(Icons.chat, color: AppColors.primaryTeal),
        ),
        title: Text(
          chatRoom.roomName,
          style: AppTextStyles.bodyBold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          chatRoom.lastMessage.isNotEmpty
              ? '${chatRoom.lastSenderName}: ${chatRoom.lastMessage}'
              : 'ยังไม่มีข้อความ',
          style: AppTextStyles.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTime(chatRoom.lastMessageTime),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.modernGrey,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleChatScreen(chatRoom: chatRoom),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final DateTime yesterday = now.subtract(const Duration(days: 1));

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'เมื่อวาน';
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  void _showCreateChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สร้างแชทใหม่'),
        content: const Text('ฟีเจอร์นี้จะเปิดให้ใช้งานเร็วๆ นี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}
