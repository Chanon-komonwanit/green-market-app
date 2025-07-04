// lib/screens/post_comments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/community_post.dart';
import '../models/community_comment.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../utils/community_sample_data.dart';

class PostCommentsScreen extends StatefulWidget {
  final CommunityPost post;

  const PostCommentsScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ความคิดเห็น'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Post Summary
          _buildPostSummary(),

          // Comments List
          Expanded(
            child: _buildCommentsList(),
          ),

          // Comment Input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.post.userProfileImage != null
                ? CachedNetworkImageProvider(widget.post.userProfileImage!)
                : null,
            child: widget.post.userProfileImage == null
                ? Icon(Icons.person, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.userDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post.content,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.post.likeCount}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.comment,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.post.commentCount}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.value(
        CommunitySampleData.getSampleComments(widget.post.id),
      ), // Using sample data for now
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'เกิดข้อผิดพลาด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
              ],
            ),
          );
        }

        final commentsData = snapshot.data ?? [];
        if (commentsData.isEmpty) {
          return _buildEmptyCommentsState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: commentsData.length,
          itemBuilder: (context, index) {
            final commentData = commentsData[index];
            final comment =
                CommunityComment.fromMap(commentData, commentData['id']);
            return _buildCommentItem(comment);
          },
        );
      },
    );
  }

  Widget _buildCommentItem(CommunityComment comment) {
    final isReply = comment.parentCommentId != null;

    return Container(
      margin: EdgeInsets.only(
        left: isReply ? 40 : 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: comment.userProfileImage != null
                ? CachedNetworkImageProvider(comment.userProfileImage!)
                : null,
            child: comment.userProfileImage == null
                ? Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: isReply ? 14 : 18,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(comment.createdAt.toDate(),
                            locale: 'th'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleCommentLike(comment),
                        child: Row(
                          children: [
                            Icon(
                              comment.likes.contains(
                                context.read<UserProvider>().currentUser?.id,
                              )
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: comment.likes.contains(
                                context.read<UserProvider>().currentUser?.id,
                              )
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              comment.likes.length.toString(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!isReply)
                        InkWell(
                          onTap: () => _replyToComment(comment),
                          child: Text(
                            'ตอบกลับ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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

  Widget _buildEmptyCommentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.comment_outlined,
                size: 60,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ยังไม่มีความคิดเห็น',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เป็นคนแรกที่แสดงความคิดเห็น',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          if (_replyingToCommentId != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ตอบกลับ $_replyingToUserName',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 16, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.currentUser;
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: user?.photoUrl != null
                        ? CachedNetworkImageProvider(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Icon(Icons.person, color: Colors.grey[600])
                        : null,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null
                        ? 'เขียนการตอบกลับ...'
                        : 'เขียนความคิดเห็น...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _replyToComment(CommunityComment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUserName = comment.userDisplayName;
    });
    _commentController.text = '@${comment.userDisplayName} ';
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
    _commentController.clear();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _isSubmitting) return;

    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firebaseService.addCommentToCommunityPost(
        postId: widget.post.id,
        userId: user.id,
        content: _commentController.text.trim(),
        parentCommentId: _replyingToCommentId,
      );

      _commentController.clear();
      _cancelReply();

      // Scroll to bottom to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มความคิดเห็นแล้ว')),
      );
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

  Future<void> _toggleCommentLike(CommunityComment comment) async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    try {
      // TODO: Implement comment like toggle in Firebase service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }
}
