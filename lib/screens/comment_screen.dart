import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/comment.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:provider/provider.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _sendComment() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('comments').add({
        'postId': widget.postId,
        'userId': user.id,
        'userDisplayName': user.displayName,
        'userProfileImage': user.profileImageUrl,
        'content': _controller.text.trim(),
        'createdAt': Timestamp.now(),
      });
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งคอมเมนต์')),
      );
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ความคิดเห็น')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('postId', isEqualTo: widget.postId)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีความคิดเห็น'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final comment = Comment.fromMap(
                        docs[index].data() as Map<String, dynamic>,
                        docs[index].id);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.userProfileImage != null &&
                                comment.userProfileImage!.isNotEmpty
                            ? NetworkImage(comment.userProfileImage!)
                            : null,
                        child: comment.userProfileImage == null ||
                                comment.userProfileImage!.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(comment.userDisplayName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(comment.content),
                      trailing: Text(_formatTime(comment.createdAt.toDate()),
                          style: const TextStyle(fontSize: 12)),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'แสดงความคิดเห็น...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    key: Key('comment-input'),
                    autofillHints: const ['username'],
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.green),
                        onPressed: _sendComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inHours < 1) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inDays < 1) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }
}
