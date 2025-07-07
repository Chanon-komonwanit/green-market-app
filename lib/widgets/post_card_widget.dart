// lib/widgets/post_card_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/community_post.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../screens/post_comments_screen.dart';
import '../widgets/share_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPostUser();
    _initializeLikeStatus();
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.green.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.greenAccent.withOpacity(0.08),
          highlightColor: Colors.greenAccent.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                _buildUserHeader(),
                const SizedBox(height: 10),
                // Post Content
                if (widget.post.content.isNotEmpty) ...[
                  Text(
                    widget.post.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Colors.grey[900],
                        ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Images
                if (widget.post.imageUrls.isNotEmpty) ...[
                  _buildImages(),
                  const SizedBox(height: 10),
                ],
                // Video (if any)
                if (widget.post.videoUrl != null) ...[
                  _buildVideoThumbnail(),
                  const SizedBox(height: 10),
                ],
                // Tags
                if (widget.post.tags.isNotEmpty) ...[
                  _buildTags(),
                  const SizedBox(height: 10),
                ],
                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        // Profile Image with gradient border (IG style)
        Container(
          padding: const EdgeInsets.all(2.2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.greenAccent.shade100,
                Colors.teal.shade400,
                Colors.blue.shade200,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: _postUser?.photoUrl != null
                ? CachedNetworkImageProvider(_postUser!.photoUrl!)
                : null,
            child: _postUser?.photoUrl == null
                ? Icon(Icons.person, color: Colors.grey[600])
                : null,
          ),
        ),
        const SizedBox(width: 12),
        // User Name and Time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _postUser?.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal[800],
                    ),
              ),
              Text(
                timeago.format(widget.post.createdAt.toDate(), locale: 'th'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
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
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: widget.post.imageUrls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[300],
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
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
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
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill,
          color: Colors.white,
          size: 64,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.shade50,
                Colors.greenAccent.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.teal.shade100, width: 1),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              color: Colors.teal[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Like Button
        InkWell(
          onTap: _toggleLike,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.redAccent.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.redAccent : Colors.teal[400],
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  _likesCount.toString(),
                  style: TextStyle(
                    color: _isLiked ? Colors.redAccent : Colors.teal[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        // Comment Button
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostCommentsScreen(post: widget.post),
              ),
            );
            widget.onComment?.call();
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.blueAccent.withOpacity(0.10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: Colors.blue[400],
                  size: 21,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.post.commentCount.toString(),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        // Share Button
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => ShareDialog(post: widget.post),
            );
            widget.onShare?.call();
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.tealAccent.withOpacity(0.10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.share_outlined,
                  color: Colors.teal[400],
                  size: 21,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.post.shareCount.toString(),
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Time ago
        Text(
          timeago.format(widget.post.createdAt.toDate(), locale: 'th'),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
      ],
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
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('แก้ไขโพสต์'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to edit post
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('ลบโพสต์',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePost();
                  },
                ),
              ] else ...[
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
              child: const Text('ลบ', style: TextStyle(color: Colors.red)),
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
}
