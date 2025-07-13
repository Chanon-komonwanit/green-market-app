// lib/screens/community_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/community_chat_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityChatListScreen extends StatefulWidget {
  const CommunityChatListScreen({super.key});

  @override
  State<CommunityChatListScreen> createState() =>
      _CommunityChatListScreenState();
}

class _CommunityChatListScreenState extends State<CommunityChatListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;

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

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryTeal, AppColors.emeraldPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22059B6A),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.forum_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('เปิดโลกสีเขียว',
                            style: AppTextStyles.headline.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            )),
                        const SizedBox(height: 2),
                        Text('แชทของฉัน',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin:
                const EdgeInsets.only(top: 18, left: 18, right: 18, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาการสนทนา... ',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.graySecondary),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Chat List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.streamCommunityChats(currentUser.id),
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
                final allChats = snapshot.data ?? [];

                final filteredChats = allChats.where((chat) {
                  if (_searchQuery.isEmpty) return true;
                  final lastMessage =
                      (chat['lastMessage'] as String? ?? '').toLowerCase();
                  final participantInfo =
                      chat['participantInfo'] as Map<String, dynamic>? ?? {};
                  final otherUserId = (chat['participants'] as List<dynamic>)
                      .firstWhere((id) => id != currentUser.id,
                          orElse: () => '');
                  final otherUserName = (participantInfo[otherUserId]
                              as Map<String, dynamic>?)?['displayName']
                          as String? ??
                      '';
                  return lastMessage.contains(_searchQuery) ||
                      otherUserName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_rounded,
                            size: 72, color: AppColors.primaryTeal),
                        const SizedBox(height: 18),
                        Text('ยังไม่มีการสนทนา',
                            style: AppTextStyles.subtitle
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('เริ่มการสนทนากับเพื่อนในชุมชนสีเขียว!',
                            style: AppTextStyles.body,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    final chatData = filteredChats[index];
                    return _buildChatItem(chatData, currentUser.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewChatDialog,
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('เริ่มแชทใหม่'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chatData, String currentUserId) {
    final chatId = chatData['id'] as String;
    // ใช้ chatId ในอนาคตสำหรับฟีเจอร์เพิ่มเติม เช่น pin, mute, ฯลฯ
    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    final participantInfo =
        chatData['participantInfo'] as Map<String, dynamic>? ?? {};
    final otherUserInfo =
        participantInfo[otherUserId] as Map<String, dynamic>? ?? {};

    final otherUserName = otherUserInfo['displayName'] as String? ??
        '\u0e1c\u0e39\u0e49\u0e43\u0e0a\u0e49';
    final otherUserPhoto = otherUserInfo['photoUrl'] as String?;

    final lastMessage = chatData['lastMessage'] as String? ?? '';
    final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
    final lastMessageSender = chatData['lastMessageSender'] as String? ?? '';
    final isUnread = lastMessageSender != currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.primaryTeal.withOpacity(0.2),
          backgroundImage:
              otherUserPhoto != null ? NetworkImage(otherUserPhoto) : null,
          child: otherUserPhoto == null
              ? Text(
                  otherUserName.isNotEmpty
                      ? otherUserName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.headline
                      .copyWith(color: AppColors.primaryTeal, fontSize: 20),
                )
              : null,
        ),
        title: Text(
          otherUserName,
          style: isUnread ? AppTextStyles.bodyBold : AppTextStyles.body,
        ),
        subtitle: Text(
          lastMessage.isNotEmpty
              ? lastMessage
              : '\u0e22\u0e31\u0e07\u0e44\u0e21\u0e48\u0e21\u0e35\u0e02\u0e49\u0e2d\u0e04\u0e27\u0e32\u0e21',
          style: AppTextStyles.bodySmall.copyWith(
            color: isUnread ? AppColors.primaryTeal : AppColors.graySecondary,
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTimestamp(lastMessageTime),
              style: AppTextStyles.caption.copyWith(
                color:
                    isUnread ? AppColors.primaryTeal : AppColors.graySecondary,
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isUnread) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityChatScreen(
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserPhoto: otherUserPhoto,
                ),
              ));
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        tileColor: isUnread
            ? AppColors.primaryTeal.withOpacity(0.05)
            : AppColors.white,
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
      return '${difference.inMinutes} นาที';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('E', 'th').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เริ่มการสนทนาใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลือกสมาชิกที่ต้องการสนทนา'),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('id',
                      isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final users = snapshot.data?.docs ?? [];

                if (users.isEmpty) {
                  return const Text('ไม่พบสมาชิก');
                }

                return SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userData = user.data() as Map<String, dynamic>;
                      final userName = userData['displayName'] ?? 'ผู้ใช้';
                      final userPhoto = userData['photoUrl'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primaryTeal.withOpacity(0.2),
                          backgroundImage: userPhoto != null
                              ? NetworkImage(userPhoto)
                              : null,
                          child: userPhoto == null
                              ? Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : 'U',
                                  style: AppTextStyles.bodyBold
                                      .copyWith(color: AppColors.primaryTeal),
                                )
                              : null,
                        ),
                        title: Text(userName),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityChatScreen(
                                otherUserId: user.id,
                                otherUserName: userName,
                                otherUserPhoto: userPhoto,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}
