// lib/screens/chat_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_market/screens/chat_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูรายการแชท'));
    }
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      // AppBar is part of HomeScreen now for this tab
      // appBar: AppBar(
      //   title: const Text('รายการแชท'),
      // ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firebaseService.getChatRoomsForUser(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      // ignore: deprecated_member_use
                      size: 80,
                      // ignore: deprecated_member_use
                      color: AppColors.darkGrey.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  Text('ยังไม่มีรายการแชท', style: AppTextStyles.subtitle),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data!;
          final DateFormat timeFormat = DateFormat('HH:mm');

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              final String otherUserName =
                  room['otherUserDisplayName'] ?? 'ผู้ใช้';
              final String lastMessage = room['lastMessage'] ?? '';
              final Timestamp? lastTimestamp = room['lastTimestamp'];
              final String displayTime = lastTimestamp != null
                  ? timeFormat.format(lastTimestamp.toDate().toLocal())
                  : '';
              final int unreadCount = room['unreadCount'] ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: room['productImageUrl'] != null &&
                          room['productImageUrl'].isNotEmpty
                      ? NetworkImage(room['productImageUrl'])
                      : null,
                  backgroundColor: AppColors.lightGrey,
                  child: room['productImageUrl'] == null ||
                          room['productImageUrl'].isEmpty
                      ? const Icon(Icons.storefront,
                          color: AppColors.primaryGreen)
                      : null,
                ),
                title: Text(
                    '$otherUserName (สินค้า: ${room['productName'] ?? 'N/A'})',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: unreadCount > 0
                          ? AppColors.primaryGreen
                          : AppColors.darkGrey),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(displayTime,
                        style: AppTextStyles.body
                            .copyWith(fontSize: 12, color: AppColors.darkGrey)),
                    if (unreadCount > 0) const SizedBox(height: 4),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId:
                          room['chatId'], // Pass chatId if available and needed
                      productId: room['productId'],
                      productName: room['productName'],
                      productImageUrl: room['productImageUrl'],
                      buyerId: room['buyerId'],
                      sellerId: room['sellerId'],
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
