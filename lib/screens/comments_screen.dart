// lib/screens/comments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/post.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/community_notification_service.dart';

class CommentsScreen extends StatefulWidget {
  final Post post;

  const CommentsScreen({
    super.key,
    required this.post,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'ความคิดเห็น',
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
          // Post Preview
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF059669),
                  backgroundImage: widget.post.userProfileImage != null
                      ? NetworkImage(widget.post.userProfileImage!)
                      : null,
                  child: widget.post.userProfileImage == null
                      ? Text(
                          widget.post.userName.isNotEmpty
                              ? widget.post.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.post.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimeAgo(widget.post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.post.text,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('postId', isEqualTo: widget.post.id)
                  .where('isActive', isEqualTo: true)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF059669),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }

                final comments = snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'ยังไม่มีความคิดเห็น',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'เป็นคนแรกที่แสดงความคิดเห็น!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = Comment.fromFirestore(comments[index]);
                    return _buildCommentItem(comment);
                  },
                );
              },
            ),
          ),

          // Comment Input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyComment = currentUser?.uid == comment.userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF059669),
            backgroundImage: comment.userProfileImage != null
                ? NetworkImage(comment.userProfileImage!)
                : null,
            child: comment.userProfileImage == null
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimeAgo(comment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isMyComment) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _deleteComment(comment),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      height: 1.3,
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

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final currentUser = userProvider.currentUser;
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF059669),
                    backgroundImage: currentUser?.photoUrl != null
                        ? NetworkImage(currentUser!.photoUrl!)
                        : null,
                    child: currentUser?.photoUrl == null
                        ? Text(
                            currentUser?.displayName?.isNotEmpty == true
                                ? currentUser!.displayName![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  decoration: InputDecoration(
                    hintText: 'เขียนความคิดเห็น...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF059669)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSubmitting ? null : _submitComment,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isSubmitting
                        ? Colors.grey[400]
                        : const Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitComment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')),
      );
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.currentUser;

      // Add comment
      await FirebaseFirestore.instance.collection('comments').add({
        'postId': widget.post.id,
        'userId': currentUser.uid,
        'userName': userData?.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
        'userProfileImage': userData?.photoUrl,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Update comment count in post
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({
        'commentCount': FieldValue.increment(1),
      });

      // Send notification for new comment
      await CommunityNotificationService.sendCommentNotification(
        postId: widget.post.id,
        postOwnerId: widget.post.userId,
        commenter: currentUser.uid,
        commenterName: userData?.displayName ?? 'ผู้ใช้',
        commenterPhoto: userData?.photoUrl,
        comment: text,
      );

      _commentController.clear();
      _commentFocus.unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _deleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบความคิดเห็น'),
        content: const Text('คุณแน่ใจหรือไม่ที่จะลบความคิดเห็นนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('comments')
                    .doc(comment.id)
                    .update({'isActive': false});

                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.post.id)
                    .update({
                  'commentCount': FieldValue.increment(-1),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบความคิดเห็นแล้ว')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                );
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}
