// lib/widgets/post_card_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/community_post.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../screens/post_comments_screen.dart';
import '../widgets/share_dialog.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/hashtag_text_widget.dart';
import '../utils/constants.dart';
import '../screens/create_community_post_screen.dart';
import 'package:provider/provider.dart';

class PostCardWidget extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCardWidget({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  final FirebaseService _firebaseService = FirebaseService();
  AppUser? _postUser;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isSaved = false;
  bool _saveLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPostUser();
    _initializeLikeStatus();
    _checkSavedStatus();
  }

  Future<void> _loadPostUser() async {
    try {
      final user = await _firebaseService.getUserById(widget.post.userId);
      if (mounted) {
        setState(() {
          _postUser = user;
        });
      }
    } catch (e) {
      debugPrint('Error loading post user: $e');
    }
  }

  void _initializeLikeStatus() {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    setState(() {
      _isLiked =
          currentUserId != null && widget.post.likes.contains(currentUserId);
      _likesCount = widget.post.likes.length;
    });
  }

  Future<void> _toggleLike() async {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _firebaseService.toggleLikeCommunityPost(
          widget.post.id, currentUserId);

      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });

      widget.onLike?.call();
    } catch (e) {
      debugPrint('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActivity = widget.post.tags.contains('activity');
    final isAchievement = widget.post.tags.contains('achievement');
    // Use warningAmber for achievement badge color (amber)
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.padding, vertical: AppTheme.smallPadding),
      elevation: AppTheme.cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge for Activity or Achievement
              if (isActivity || isAchievement)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActivity
                        ? AppColors.primaryTeal.withOpacity(0.15)
                        : AppColors.warningAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActivity ? Icons.eco : Icons.emoji_events,
                        color: isActivity
                            ? AppColors.primaryTeal
                            : AppColors.warningAmber,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActivity ? 'กิจกรรมสีเขียว' : 'ความสำเร็จสีเขียว',
                        style: AppTextStyles.captionBold.copyWith(
                          color: isActivity
                              ? AppColors.primaryTealDark
                              : AppColors.warningAmber,
                        ),
                      ),
                    ],
                  ),
                ),

              // User Header
              _buildUserHeader(),

              const SizedBox(height: 12),

              // Post Content
              if (widget.post.content.isNotEmpty) ...[
                HashtagTextWidget(
                  text: widget.post.content,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 12),
              ],

              // Images
              if (widget.post.imageUrls.isNotEmpty) ...[
                _buildImages(),
                const SizedBox(height: 12),
              ],

              // Video (if any)
              if (widget.post.videoUrl != null) ...[
                _buildVideoThumbnail(),
                const SizedBox(height: 12),
              ],

              // Tags
              if (widget.post.tags.isNotEmpty) ...[
                _buildTags(),
                const SizedBox(height: 12),
              ],

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        // Profile Image
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.grayBorder,
          backgroundImage: _postUser?.photoUrl != null
              ? CachedNetworkImageProvider(_postUser!.photoUrl!)
              : null,
          child: _postUser?.photoUrl == null
              ? const Icon(Icons.person, color: AppColors.graySecondary)
              : null,
        ),

        const SizedBox(width: AppTheme.padding),

        // User Name and Time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_postUser?.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
                  style: AppTextStyles.bodyBold),
              Text(
                timeago.format(widget.post.createdAt.toDate(), locale: 'th'),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),

        // More Options
        IconButton(
          onPressed: () {
            _showMoreOptions();
          },
          icon: const Icon(Icons.more_vert),
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildImages() {
    if (widget.post.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: CachedNetworkImage(
          imageUrl: widget.post.imageUrls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          placeholder: (context, url) => Container(
            height: 200,
            color: AppColors.surfaceGray,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: AppColors.surfaceGray,
            child: const Icon(Icons.error),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.post.imageUrls.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.only(
                  right: index < widget.post.imageUrls.length - 1 ? 8 : 0),
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceGray,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceGray,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildVideoThumbnail() {
    if (widget.post.videoUrl == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 400,
        ),
        child: VideoPlayerWidget(
          videoUrl: widget.post.videoUrl!,
          autoPlay: false, // ไม่เล่นอัตโนมัติในฟีด (ประหยัดแบต)
          showControls: true,
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: widget.post.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Text(
            '#$tag',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryTealDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          // Like Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleLike,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isLiked
                          ? AppColors.errorRed
                          : AppColors.graySecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _likesCount.toString(),
                      style: AppTextStyles.captionBold.copyWith(
                        color: _isLiked
                            ? AppColors.errorRed
                            : AppColors.grayPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Comment Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostCommentsScreen(post: widget.post),
                  ),
                );
                widget.onComment?.call();
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.graySecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.post.commentCount.toString(),
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.grayPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Share Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => ShareDialog(post: widget.post),
                );
                widget.onShare?.call();
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.graySecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.post.shareCount.toString(),
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.grayPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Save Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saveLoading ? null : _toggleSave,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Icon(
                  _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: _isSaved
                      ? AppColors.primaryTeal
                      : AppColors.graySecondary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    final isMyPost = currentUserId == widget.post.userId;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMyPost) ...[
                // Options for the post owner
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('แก้ไขโพสต์'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateCommunityPostScreen(postToEdit: widget.post),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.errorRed),
                  title: const Text('ลบโพสต์',
                      style: TextStyle(color: AppColors.errorRed)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePost();
                  },
                ),
              ] else ...[
                // Options for other users
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('รายงานโพสต์'),
                  onTap: () {
                    Navigator.pop(context);
                    _reportPost();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('คัดลอกลิงก์'),
                onTap: () {
                  Navigator.pop(context);
                  _copyPostLink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletePost() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบโพสต์'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('ลบ', style: TextStyle(color: AppColors.errorRed)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final currentUserId = context.read<UserProvider>().currentUser?.id;
        await _firebaseService.deleteCommunityPost(
            widget.post.id, currentUserId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบโพสต์เรียบร้อยแล้ว')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }

  void _reportPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('รายงานโพสต์เรียบร้อยแล้ว')),
    );
  }

  void _copyPostLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกลิงก์เรียบร้อยแล้ว')),
    );
  }

  Future<void> _toggleSave() async {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId == null) return;

    setState(() => _saveLoading = true);

    try {
      if (_isSaved) {
        // Unsave
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('saved_posts')
            .doc(widget.post.id)
            .delete();

        if (mounted) {
          setState(() => _isSaved = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เลิกบันทึกโพสต์แล้ว')),
          );
        }
      } else {
        // Save
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('saved_posts')
            .doc(widget.post.id)
            .set({
          'postId': widget.post.id,
          'savedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('บันทึกโพสต์แล้ว'),
              action: SnackBarAction(
                label: 'ดู',
                onPressed: () {
                  Navigator.pushNamed(context, '/saved_posts');
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saveLoading = false);
    }
  }

  Future<void> _checkSavedStatus() async {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('saved_posts')
          .doc(widget.post.id)
          .get();

      if (mounted) {
        setState(() => _isSaved = doc.exists);
      }
    } catch (e) {
      debugPrint('Error checking saved status: $e');
    }
  }
}
