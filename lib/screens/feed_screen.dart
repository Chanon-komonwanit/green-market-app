// lib/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/community_post.dart';
import 'package:green_market/widgets/post_card_widget.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/create_community_post_screen.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/comment_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class FeedScreen extends StatefulWidget {
  final String searchKeyword;
  const FeedScreen({super.key, this.searchKeyword = ''});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> get _filteredPosts {
    if (widget.searchKeyword.isEmpty) return _posts;
    final keyword = widget.searchKeyword.toLowerCase();
    return _posts.where((post) {
      final content = post['content']?.toString().toLowerCase() ?? '';
      final displayName =
          post['userDisplayName']?.toString().toLowerCase() ?? '';
      return content.contains(keyword) || displayName.contains(keyword);
    }).toList();
  }

  bool _isLoading = false;
  bool _hasMore = true;
  String? _lastPostId;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPosts() async {
    _posts.clear();
    _hasMore = true;
    _lastPostId = null;
    await _loadMorePosts();
    setState(() {});
  }

  Future<void> _loadMorePosts() async {
    try {
      if (_isLoading || !_hasMore) return;
      _isLoading = true;
      const limit = 20;
      Query query = FirebaseFirestore.instance.collection('community_posts');
      // ตรวจสอบ field ก่อน query
      bool hasCreatedAt = true;
      bool hasIsActive = true;
      // ลอง query แบบปลอดภัย
      try {
        query = query.where('isActive', isEqualTo: true);
      } catch (_) {
        hasIsActive = false;
      }
      try {
        query = query.orderBy('createdAt', descending: true);
      } catch (_) {
        hasCreatedAt = false;
      }
      query = query.limit(limit);
      if (_lastPostId != null && _posts.isNotEmpty) {
        final lastPost = await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(_lastPostId)
            .get();
        query = query.startAfterDocument(lastPost);
      }
      final snapshot = await query.get();
      final newPosts = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data is Map<String, dynamic>) {
              // fallback หากไม่มี field
              return {
                'id': doc.id,
                ...data,
                if (!hasCreatedAt) 'createdAt': Timestamp.now(),
                if (!hasIsActive) 'isActive': true,
              };
            } else {
              return <String, dynamic>{'id': doc.id};
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
      if (newPosts.length < limit) _hasMore = false;
      if (newPosts.isNotEmpty) {
        _lastPostId = newPosts.last['id'];
        _posts.addAll(newPosts);
      }
      _isLoading = false;
      setState(() {});
    } catch (e) {
      _isLoading = false;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดโพสต์: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleLike(CommunityPost post, String userId, int index) async {
    final docRef =
        FirebaseFirestore.instance.collection('community_posts').doc(post.id);
    final isLiked = post.isLikedBy(userId);
    try {
      if (isLiked) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
      final updatedDoc = await docRef.get();
      final updatedData = updatedDoc.data();
      if (updatedData != null) {
        setState(() {
          _posts[index] = {'id': post.id, ...updatedData};
        });
      }
    } catch (e) {
      // สามารถแสดง SnackBar หรือ log error ได้
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการกดไลก์')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await _loadInitialPosts();
          },
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPosts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 0),
                      itemCount: _hasMore
                          ? _filteredPosts.length + 1
                          : _filteredPosts.length,
                      itemBuilder: (context, index) {
                        if (index >= _filteredPosts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryTeal),
                            ),
                          );
                        }
                        final post = CommunityPost.fromMap(
                            _filteredPosts[index], _filteredPosts[index]['id']);
                        final userProvider = context.read<UserProvider>();
                        final currentUserId =
                            userProvider.currentUser?.id ?? '';
                        final isLiked = post.isLikedBy(currentUserId);
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, (1 - value) * 40),
                              child: Opacity(
                                opacity: value,
                                child: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22)),
                                  color: Colors.white.withOpacity(0.97),
                                  shadowColor: Colors.greenAccent,
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor:
                                                      Colors.green[50],
                                                  backgroundImage:
                                                      post.userProfileImage !=
                                                                  null &&
                                                              post.userProfileImage!
                                                                  .isNotEmpty
                                                          ? NetworkImage(post
                                                              .userProfileImage!)
                                                          : null,
                                                  child: post.userProfileImage ==
                                                              null ||
                                                          post.userProfileImage!
                                                              .isEmpty
                                                      ? const Icon(Icons.person,
                                                          color: Colors.green,
                                                          size: 24)
                                                      : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(post.userDisplayName,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      16)),
                                                      Text(
                                                          _formatTime(post
                                                              .createdAt
                                                              .toDate()),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (post.hasImages &&
                                                post.imageUrls.length > 1) ...[
                                              const SizedBox(height: 14),
                                              SizedBox(
                                                height: 180,
                                                child: PageView.builder(
                                                  itemCount:
                                                      post.imageUrls.length,
                                                  controller: PageController(
                                                      viewportFraction: 0.92),
                                                  itemBuilder:
                                                      (context, imgIdx) =>
                                                          ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    child: Image.network(
                                                        post.imageUrls[imgIdx],
                                                        fit: BoxFit.cover,
                                                        width: double.infinity),
                                                  ),
                                                ),
                                              ),
                                            ] else if (post.hasImages) ...[
                                              const SizedBox(height: 14),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.network(
                                                    post.imageUrls.first,
                                                    fit: BoxFit.cover,
                                                    height: 180,
                                                    width: double.infinity),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            Text(post.content,
                                                style: const TextStyle(
                                                    fontSize: 17)),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.favorite,
                                                      color: isLiked
                                                          ? Colors.pink
                                                          : Colors.grey[400]),
                                                  onPressed: () {
                                                    _toggleLike(post,
                                                        currentUserId, index);
                                                  },
                                                ),
                                                Text('${post.likeCount}'),
                                                const SizedBox(width: 18),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.comment,
                                                      color: Colors.blueGrey),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            CommentScreen(
                                                                postId:
                                                                    post.id),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Text('${post.commentCount}'),
                                                const SizedBox(width: 18),
                                                IconButton(
                                                  icon: const Icon(Icons.share,
                                                      color: Colors.green),
                                                  onPressed: () {
                                                    final shareText =
                                                        '${post.userDisplayName} แชร์โพสต์ในชุมชนสีเขียว:\n${post.content}';
                                                    if (post.hasImages &&
                                                        post.imageUrls
                                                            .isNotEmpty) {
                                                      Share.share(shareText,
                                                          subject:
                                                              'Green Community',
                                                          sharePositionOrigin:
                                                              Rect.fromLTWH(
                                                                  0, 0, 1, 1));
                                                    } else {
                                                      Share.share(shareText,
                                                          subject:
                                                              'Green Community');
                                                    }
                                                  },
                                                ),
                                                const Spacer(),
                                                Icon(Icons.more_horiz,
                                                    color: Colors.grey[400]),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Row(
                                          children: [
                                            if (DateTime.now()
                                                    .difference(
                                                        post.createdAt.toDate())
                                                    .inHours <
                                                24)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.lightGreen[600],
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors.green
                                                            .withOpacity(0.18),
                                                        blurRadius: 6)
                                                  ],
                                                ),
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.fiber_new,
                                                        color: Colors.white,
                                                        size: 16),
                                                    SizedBox(width: 4),
                                                    Text('ใหม่',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                            if (post.likeCount > 10)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 8),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[700],
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors.orange
                                                            .withOpacity(0.18),
                                                        blurRadius: 6)
                                                  ],
                                                ),
                                                child: Row(
                                                  children: const [
                                                    Icon(
                                                        Icons
                                                            .local_fire_department,
                                                        color: Colors.white,
                                                        size: 16),
                                                    SizedBox(width: 4),
                                                    Text('ฮิต',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
        // ...ไม่มีปุ่ม FloatingActionButton ใน FeedScreen...
      ],
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
            Text(
              'หากข้อมูลไม่แสดงหรือโหลดนาน กรุณาลองดึงเพื่อรีเฟรชหน้าจอ',
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
