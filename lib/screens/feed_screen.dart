// lib/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/post.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/create_post_screen.dart';
import 'package:green_market/screens/community_profile_screen.dart';
import 'package:green_market/screens/comments_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/services/community_notification_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              '🌍 ชุมชนสีเขียว',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _navigateToCreatePost(),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _navigateToProfile(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Refresh the stream
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
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
              return _buildErrorState(snapshot.error.toString());
            }

            final posts = snapshot.data?.docs ?? [];

            if (posts.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = Post.fromFirestore(posts[index]);
                return _buildPostCard(post);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePost(),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = currentUser != null && post.isLikedBy(currentUser.uid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildPostHeader(post),

          // Content
          if (post.hasText) _buildPostText(post),
          if (post.hasImage) _buildPostImage(post),

          // Actions
          _buildPostActions(post, isLiked),
        ],
      ),
    );
  }

  Widget _buildPostHeader(Post post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToUserProfile(post.userId),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF059669),
              backgroundImage: post.userProfileImage != null
                  ? NetworkImage(post.userProfileImage!)
                  : null,
              child: post.userProfileImage == null
                  ? Text(
                      post.userName.isNotEmpty
                          ? post.userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _navigateToUserProfile(post.userId),
                  child: Text(
                    post.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeAgo(post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handlePostAction(value, post),
            itemBuilder: (context) => [
              if (FirebaseAuth.instance.currentUser?.uid == post.userId) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('แก้ไข'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('ลบ', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ] else ...[
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, size: 20),
                      SizedBox(width: 8),
                      Text('รายงาน'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostText(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        post.text,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPostImage(Post post) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 400),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
        child: Image.network(
          post.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF059669),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostActions(Post post, bool isLiked) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Like Button
          InkWell(
            onTap: () => _toggleLike(post),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 22,
                    color: isLiked ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isLiked ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Comment Button
          InkWell(
            onTap: () => _navigateToComments(post),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.commentCount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Share Button
          InkWell(
            onTap: () => _sharePost(post),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'แชร์',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'ยังไม่มีโพสต์ในชุมชน',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'เป็นคนแรกที่แบ่งปันเรื่องราวดีๆ กันเลย!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreatePost(),
              icon: const Icon(Icons.add),
              label: const Text('สร้างโพสต์แรก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation Methods
  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  void _navigateToProfile() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityProfileScreen(userId: currentUser.uid),
        ),
      );
    }
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityProfileScreen(userId: userId),
      ),
    );
  }

  void _navigateToComments(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(post: post),
      ),
    );
  }

  // Action Methods
  void _toggleLike(Post post) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.currentUser;

    if (currentUser == null || userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')),
      );
      return;
    }

    try {
      final isLiked = post.isLikedBy(currentUser.uid);
      List<String> updatedLikes = List.from(post.likes);

      if (isLiked) {
        updatedLikes.remove(currentUser.uid);
      } else {
        updatedLikes.add(currentUser.uid);

        // Send notification for new like
        await CommunityNotificationService.sendLikeNotification(
          postId: post.id,
          postOwnerId: post.userId,
          liker: currentUser.uid,
          likerName: userData.displayName ?? 'ผู้ใช้',
          likerPhoto: userData.photoUrl,
        );
      }

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id)
          .update({'likes': updatedLikes});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _sharePost(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แชร์โพสต์'),
        content: const Text('ฟีเจอร์แชร์จะเปิดให้ใช้งานเร็วๆ นี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _handlePostAction(String action, Post post) {
    switch (action) {
      case 'edit':
        _editPost(post);
        break;
      case 'delete':
        _deletePost(post);
        break;
      case 'report':
        _reportPost(post);
        break;
    }
  }

  void _editPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(editPost: post),
      ),
    );
  }

  void _deletePost(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบโพสต์'),
        content: const Text('คุณแน่ใจหรือไม่ที่จะลบโพสต์นี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(post.id)
                    .update({'isActive': false});

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบโพสต์แล้ว')),
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

  void _reportPost(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รายงานโพสต์'),
        content: const Text('ขอบคุณสำหรับการรายงาน เราจะตรวจสอบโพสต์นี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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
