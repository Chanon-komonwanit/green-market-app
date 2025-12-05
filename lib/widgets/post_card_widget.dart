// lib/widgets/post_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/community_post.dart';
import '../models/app_user.dart';
import '../models/post_location.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../screens/post_comments_screen.dart';
import '../screens/community_profile_screen.dart';
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
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนกดถูกใจ'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Optimistic UI update
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      await _firebaseService.toggleLikeCommunityPost(
          widget.post.id, currentUserId);

      widget.onLike?.call();
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });

      debugPrint('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActivity = widget.post.tags.contains('activity');
    final isAchievement = widget.post.tags.contains('achievement');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 3),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header - สไตล์ Instagram
          _buildModernUserHeader(),

          // Badge สำหรับกิจกรรมพิเศษ
          if (isActivity || isAchievement) _buildModernBadge(isActivity),

          // Location
          if (widget.post.location != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _buildLocation(),
            ),

          // Tagged Users
          if (widget.post.taggedUserIds.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildTaggedUsers(),
            ),

          // Post Content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: HashtagTextWidget(
                text: widget.post.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                ),
              ),
            ),

          // Images - แบบ Instagram
          if (widget.post.imageUrls.isNotEmpty) _buildModernImages(),

          // Video
          if (widget.post.videoUrl != null) _buildVideoThumbnail(),

          // Tags
          if (widget.post.tags.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildModernTags(),
            ),

          // Action Buttons - สไตล์ Instagram
          _buildModernActionButtons(),

          // Likes count และ comments
          _buildModernStats(),
        ],
      ),
    );
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
          autoPlay: true, // เล่นอัตโนมัติแบบ mute ตามมาตรฐาน social media
          showControls: true,
        ),
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

  Future<void> _reportPost() async {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    // Show report dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รายงานโพสต์'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('เนื้อหาไม่เหมาะสม'),
              onTap: () => Navigator.pop(context, 'inappropriate'),
            ),
            ListTile(
              title: const Text('สแปม'),
              onTap: () => Navigator.pop(context, 'spam'),
            ),
            ListTile(
              title: const Text('การล่วงล้อ'),
              onTap: () => Navigator.pop(context, 'harassment'),
            ),
            ListTile(
              title: const Text('ข้อมูลเท็จ'),
              onTap: () => Navigator.pop(context, 'false_info'),
            ),
            ListTile(
              title: const Text('อื่นๆ'),
              onTap: () => Navigator.pop(context, 'other'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        // Save report to Firestore
        await FirebaseFirestore.instance.collection('reports').add({
          'postId': widget.post.id,
          'reportedBy': currentUserId,
          'reason': reason,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ รายงานโพสต์เรียบร้อยแล้ว'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error reporting post: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }

  Future<void> _copyPostLink() async {
    try {
      // Create deep link URL for this post
      final postUrl =
          'https://greenmarket.app/community/post/${widget.post.id}';

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: postUrl));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ คัดลอกลิงก์เรียบร้อยแล้ว'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId == null) return;

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

  // ============================================================================
  // NEW METHODS: Tagged Users Display
  // ============================================================================

  Widget _buildTaggedUsers() {
    if (widget.post.taggedUserIds.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 18,
            color: Color(0xFF10B981),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Text(
                  'กับ ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ...widget.post.taggedUserNames.entries
                    .take(3)
                    .map((entry) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityProfileScreen(
                                userId: entry.key,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      );
                    })
                    .expand((widget) => [
                          widget,
                          Text(', ',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]))
                        ])
                    .take(widget.post.taggedUserNames.entries.length * 2 - 1),
                if (widget.post.taggedUserIds.length > 3)
                  Text(
                    ' และอีก ${widget.post.taggedUserIds.length - 3} คน',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // NEW METHODS: Location Display
  // ============================================================================

  Widget _buildLocation() {
    if (widget.post.location == null) return const SizedBox.shrink();

    final location = widget.post.location!;

    return GestureDetector(
      onTap: () => _openLocationDialog(location),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    location.typeColor.withOpacity(0.15),
                    location.typeColor.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                location.typeIcon,
                color: location.typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.address != null) ...[
                    SizedBox(height: 2),
                    Text(
                      location.displayAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationDialog(PostLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(location.typeIcon, color: location.typeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.address != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.graySecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.address!,
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.graySecondary),
                const SizedBox(width: 8),
                Text(
                  location.typeName,
                  style: AppTextStyles.body.copyWith(
                    color: location.typeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.my_location,
                    size: 16, color: AppColors.graySecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'พิกัด: ${location.latitude.toStringAsFixed(6)}, '
                    '${location.longitude.toStringAsFixed(6)}',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Open in Google Maps
              // final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
              // launch(url);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ฟีเจอร์เปิดแผนที่จะเพิ่มในเร็วๆ นี้'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child: const Text('เปิดในแผนที่'),
          ),
        ],
      ),
    );
  }

  // ===== Modern UI Functions =====

  Widget _buildModernUserHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Row(
        children: [
          // Avatar พร้อม gradient ring แบบ Instagram Stories
          Container(
            padding: EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CommunityProfileScreen(userId: widget.post.userId),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: _postUser?.profileImageUrl != null
                      ? CachedNetworkImageProvider(_postUser!.profileImageUrl!)
                      : null,
                  child: _postUser?.profileImageUrl == null
                      ? Icon(Icons.person, color: Colors.grey[400], size: 26)
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _postUser?.displayName ?? 'ผู้ใช้',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF111827),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      timeago.format(widget.post.createdAt.toDate(),
                          locale: 'th'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // More Options
          IconButton(
            onPressed: _showMoreOptions,
            icon: Icon(Icons.more_vert),
            iconSize: 22,
            color: Colors.grey[700],
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildModernBadge(bool isActivity) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActivity
              ? [
                  Color(0xFF10B981).withOpacity(0.12),
                  Color(0xFF059669).withOpacity(0.08)
                ]
              : [
                  Colors.amber.withOpacity(0.12),
                  Colors.orange.withOpacity(0.08)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActivity
              ? Color(0xFF10B981).withOpacity(0.3)
              : Colors.amber.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActivity
                  ? Color(0xFF10B981).withOpacity(0.2)
                  : Colors.amber.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActivity ? Icons.eco_rounded : Icons.emoji_events_rounded,
              color: isActivity ? Color(0xFF059669) : Colors.amber[800],
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Text(
            isActivity ? '🌱 กิจกรรมสีเขียว' : '🏆 ความสำเร็จสีเขียว',
            style: TextStyle(
              color: isActivity ? Color(0xFF047857) : Colors.amber[900],
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernImages() {
    if (widget.post.imageUrls.isEmpty) return SizedBox.shrink();

    if (widget.post.imageUrls.length == 1) {
      // รูปเดี่ยว
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: widget.post.imageUrls.first,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 380,
            placeholder: (context, url) => Container(
              height: 380,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                  strokeWidth: 3,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 380,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded,
                      color: Colors.grey[300], size: 56),
                  SizedBox(height: 8),
                  Text(
                    'โหลดรูปภาพไม่สำเร็จ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (widget.post.imageUrls.length == 2) {
      // 2 รูป แบ่งครึ่งจอ
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: widget.post.imageUrls.asMap().entries.map((entry) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: entry.key == 0 ? 4 : 0,
                  left: entry.key == 1 ? 4 : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: entry.value,
                    fit: BoxFit.cover,
                    height: 240,
                    placeholder: (context, url) => Container(
                      height: 240,
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else if (widget.post.imageUrls.length == 3) {
      // 3 รูบ - 1 ใหญ่ + 2 เล็กข้างล่าง
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrls[0],
                  fit: BoxFit.cover,
                  height: 280,
                  placeholder: (context, url) => Container(
                    height: 280,
                    color: Colors.grey[100],
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF10B981))),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrls[1],
                      fit: BoxFit.cover,
                      height: 136,
                      placeholder: (context, url) => Container(
                        height: 136,
                        color: Colors.grey[100],
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF10B981), strokeWidth: 2)),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrls[2],
                      fit: BoxFit.cover,
                      height: 136,
                      placeholder: (context, url) => Container(
                        height: 136,
                        color: Colors.grey[100],
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF10B981), strokeWidth: 2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 4+ รูป - แสดง 4 รูปแรกพร้อม indicator
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrls[0],
                      fit: BoxFit.cover,
                      height: 160,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrls[1],
                      fit: BoxFit.cover,
                      height: 160,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrls[2],
                      fit: BoxFit.cover,
                      height: 160,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.post.imageUrls[3],
                          fit: BoxFit.cover,
                          height: 160,
                          width: double.infinity,
                        ),
                        if (widget.post.imageUrls.length > 4)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '+${widget.post.imageUrls.length - 4}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildModernTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.post.tags.map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF10B981).withOpacity(0.12),
                Color(0xFF059669).withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFF10B981).withOpacity(0.25),
              width: 1.2,
            ),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              color: Color(0xFF047857),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Like Button พร้อม Animation
          GestureDetector(
            onTap: _toggleLike,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _isLiked
                    ? Colors.red.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(_isLiked),
                      size: 26,
                      color: _isLiked ? Colors.red[600] : Colors.grey[700],
                    ),
                  ),
                  if (_likesCount > 0) ...[
                    SizedBox(width: 6),
                    Text(
                      '$_likesCount',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _isLiked ? Colors.red[600] : Colors.grey[800],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 4),
          // Comment Button
          _buildActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: Colors.grey[700]!,
            count: widget.post.commentCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostCommentsScreen(post: widget.post),
                ),
              );
            },
          ),
          SizedBox(width: 4),
          // Share Button
          _buildActionButton(
            icon: Icons.send_rounded,
            iconColor: Colors.grey[700]!,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => ShareDialog(post: widget.post),
              );
            },
          ),
          Spacer(),
          // Save Button
          GestureDetector(
            onTap: _toggleSave,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _isSaved
                    ? Color(0xFF10B981).withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 26,
                color: _isSaved ? Color(0xFF10B981) : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    int? count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 26, color: iconColor),
            if (count != null && count > 0) ...[
              SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernStats() {
    if (_likesCount == 0 && widget.post.commentCount == 0) {
      return SizedBox(height: 8);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Likes count
          if (_likesCount > 0)
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () {
                  // TODO: แสดงรายชื่อคนที่ถูกใจ
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('$_likesCount คนถูกใจโพสต์นี้'),
                        ],
                      ),
                      backgroundColor: Color(0xFF1F2937),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_likesCount ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                      TextSpan(
                        text: 'ถูกใจ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Comments count
          if (widget.post.commentCount > 0)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostCommentsScreen(post: widget.post),
                  ),
                );
              },
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'ดูทั้งหมด ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    TextSpan(
                      text: '${widget.post.commentCount} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                    TextSpan(
                      text: 'ความคิดเห็น',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[600],
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
}
