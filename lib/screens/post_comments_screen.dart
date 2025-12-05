// lib/screens/post_comments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/community_post.dart';
import '../models/community_comment.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';

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
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: Text('ความคิดเห็น', style: AppTextStyles.headline),
        backgroundColor: AppColors.white,
        elevation: 1,
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
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.grayBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.grayBorder,
            backgroundImage: widget.post.userProfileImage != null
                ? CachedNetworkImageProvider(widget.post.userProfileImage!)
                : null,
            child: widget.post.userProfileImage == null
                ? const Icon(Icons.person,
                    color: AppColors.graySecondary, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.post.userDisplayName,
                    style: AppTextStyles.bodyBold),
                const SizedBox(height: 4),
                Text(
                  widget.post.content,
                  style: AppTextStyles.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getCommunityPostComments(widget.post.id),
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
                const Icon(Icons.error_outline,
                    size: 60, color: AppColors.errorRed),
                const SizedBox(height: 16),
                Text(
                  'เกิดข้อผิดพลาด',
                  style: AppTextStyles.subtitle
                      .copyWith(color: AppColors.errorRed),
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
          padding: const EdgeInsets.symmetric(vertical: AppTheme.smallPadding),
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
        left: isReply ? 40.0 : AppTheme.padding,
        right: AppTheme.padding,
        bottom: AppTheme.smallPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: AppColors.grayBorder,
            backgroundImage: comment.userProfileImage != null
                ? CachedNetworkImageProvider(comment.userProfileImage!)
                : null,
            child: comment.userProfileImage == null
                ? Icon(
                    Icons.person,
                    color: AppColors.graySecondary,
                    size: isReply ? 14 : 18,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.padding),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userDisplayName,
                        style: AppTextStyles.bodyBold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(comment.createdAt.toDate(),
                            locale: 'th'),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.content, style: AppTextStyles.body),
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
                              color: comment.likes.contains(context
                                      .read<UserProvider>()
                                      .currentUser
                                      ?.id)
                                  ? AppColors.errorRed
                                  : AppColors.graySecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              comment.likes.length.toString(),
                              style: AppTextStyles.caption,
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
                            style: AppTextStyles.caption
                                .copyWith(fontWeight: FontWeight.w600),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.largePadding),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 60,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: AppTheme.largePadding),
          Text('ยังไม่มีความคิดเห็น', style: AppTextStyles.subtitle),
          const SizedBox(height: AppTheme.smallPadding),
          Text(
            'เป็นคนแรกที่แสดงความคิดเห็นในโพสต์นี้',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.grayBorder),
        ),
      ),
      child: Column(
        children: [
          if (_replyingToCommentId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: AppColors.infoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ตอบกลับ $_replyingToUserName',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.infoBlue,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: _cancelReply,
                    child:
                        Icon(Icons.close, size: 16, color: AppColors.infoBlue),
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
                    radius: 20,
                    backgroundColor: AppColors.grayBorder,
                    backgroundImage: user?.photoUrl != null
                        ? CachedNetworkImageProvider(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.graySecondary)
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius * 2),
                      borderSide: const BorderSide(color: AppColors.grayBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius * 2),
                      borderSide:
                          const BorderSide(color: AppColors.primaryTeal),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.padding,
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
                  color: AppColors.primaryTeal,
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
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: AppColors.white, size: 20),
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
        const SnackBar(
            content: Text('เพิ่มความคิดเห็นแล้ว'),
            backgroundColor: AppColors.successGreen),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppColors.errorRed),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _toggleCommentLike(CommunityComment comment) async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเข้าสู่ระบบก่อน'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    try {
      final commentRef = FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.post.id)
          .collection('comments')
          .doc(comment.id);

      final isLiked = comment.likes.contains(user.id);

      if (isLiked) {
        // Unlike
        await commentRef.update({
          'likes': FieldValue.arrayRemove([user.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Like
        await commentRef.update({
          'likes': FieldValue.arrayUnion([user.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLiked ? '❤️ เลิกถูกใจแล้ว' : '❤️ ถูกใจแล้ว'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error toggling comment like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถถูกใจได้\nกรุณาลองใหม่อีกครั้ง'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'ลองอีกครั้ง',
              textColor: Colors.white,
              onPressed: () => _toggleCommentLike(comment),
            ),
          ),
        );
      }
    }
  }
}
