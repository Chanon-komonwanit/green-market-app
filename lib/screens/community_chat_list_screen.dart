// lib/screens/community_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/screens/community_chat_screen.dart';
import 'package:intl/intl.dart';

class CommunityChatListScreen extends StatefulWidget {
  const CommunityChatListScreen({super.key});

  @override
  State<CommunityChatListScreen> createState() =>
      _CommunityChatListScreenState();
}

class _CommunityChatListScreenState extends State<CommunityChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text(
          'แชท',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาการสนทนา...',
                prefixIcon: const Icon(Icons.search),
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Chat List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_chats')
                  .where('participants', arrayContains: currentUser.uid)
                  .orderBy('lastMessageTime', descending: true)
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

                final chats = snapshot.data?.docs ?? [];

                if (chats.isEmpty) {
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
                          'ยังไม่มีการสนทนา',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'เริ่มการสนทนาจากโปรไฟล์ของสมาชิก',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final data = chat.data() as Map<String, dynamic>;
                    return _buildChatItem(data, chat.id, currentUser.uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: const Color(0xFF059669),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChatItem(
      Map<String, dynamic> data, String chatId, String currentUserId) {
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final lastMessage = data['lastMessage'] ?? '';
    final lastMessageTime = data['lastMessageTime'] as Timestamp?;
    final lastMessageSender = data['lastMessageSender'] ?? '';
    final isUnread = lastMessageSender != currentUserId;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        String otherUserName = 'ผู้ใช้';
        String? otherUserPhoto;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          otherUserName = userData['displayName'] ?? 'ผู้ใช้';
          otherUserPhoto = userData['photoUrl'];
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty &&
            !otherUserName.toLowerCase().contains(_searchQuery) &&
            !lastMessage.toLowerCase().contains(_searchQuery)) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF059669),
              backgroundImage:
                  otherUserPhoto != null ? NetworkImage(otherUserPhoto) : null,
              child: otherUserPhoto == null
                  ? Text(
                      otherUserName.isNotEmpty
                          ? otherUserName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              otherUserName,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              lastMessage.isNotEmpty ? lastMessage : 'ยังไม่มีข้อความ',
              style: TextStyle(
                color: isUnread ? const Color(0xFF059669) : Colors.grey[600],
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
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isUnread ? const Color(0xFF059669) : Colors.grey[500],
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
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
                ),
              );
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Colors.white,
          ),
        );
      },
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
                          backgroundColor: const Color(0xFF059669),
                          backgroundImage: userPhoto != null
                              ? NetworkImage(userPhoto)
                              : null,
                          child: userPhoto == null
                              ? Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
