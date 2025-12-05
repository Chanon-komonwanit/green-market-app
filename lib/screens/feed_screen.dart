// lib/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/community_post.dart';
import 'package:green_market/widgets/post_card_widget.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/create_community_post_screen.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/post_comments_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/stories_bar.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/empty_state.dart';
import '../models/post_type.dart';
import '../widgets/smart_feed_algorithm.dart';
import '../widgets/trending_topics_section.dart';

class FeedScreen extends StatefulWidget {
  final String searchKeyword;
  const FeedScreen({super.key, this.searchKeyword = ''});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _posts = [];
  String _selectedFilter = 'all'; // all, following, popular
  PostType? _selectedPostType;

  List<Map<String, dynamic>> get _filteredPosts {
    var filtered = _posts;

    // Filter by search keyword
    if (widget.searchKeyword.isNotEmpty) {
      final keyword = widget.searchKeyword.toLowerCase();
      filtered = filtered.where((post) {
        final content = post['content']?.toString().toLowerCase() ?? '';
        final displayName =
            post['userDisplayName']?.toString().toLowerCase() ?? '';
        return content.contains(keyword) || displayName.contains(keyword);
      }).toList();
    }

    // Filter by post type
    if (_selectedPostType != null) {
      filtered = filtered.where((post) {
        final postType = post['postType']?.toString() ?? 'normal';
        return postType == _selectedPostType.toString().split('.').last;
      }).toList();
    }

    return filtered;
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
    _loadUserPreferences();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadUserPreferences() async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    if (currentUser != null) {
      // Load user interests and following (used internally)
      final List<String> userInterests = [
        'eco',
        'organic',
        'sustainable',
        'green'
      ];

      // Load following users
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('user_follows')
          .where('followerId', isEqualTo: currentUser.id)
          .get();

      final List<String> followingUserIds = followingSnapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      // Use these variables for smart feed algorithm if needed
      debugPrint('User interests: $userInterests');
      debugPrint('Following count: ${followingUserIds.length}');
    }
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

      // เรียงตาม createdAt อย่างเดียว (ไม่ต้องการ composite index)
      query = query.orderBy('createdAt', descending: true);
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
              return {
                'id': doc.id,
                ...data,
              };
            } else {
              return <String, dynamic>{'id': doc.id};
            }
          })
          .where((post) => post['isActive'] != false) // กรองฝั่ง client
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

      String errorMessage = 'ไม่สามารถโหลดโพสต์ได้';

      if (e.toString().contains('network')) {
        errorMessage = 'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'ไม่มีสิทธิ์เข้าถึงข้อมูล';
      } else if (e.toString().contains('firebase')) {
        errorMessage = 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage\nกรุณาลองใหม่อีกครั้ง'),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'รีเฟรช',
            textColor: Colors.white,
            onPressed: () => _loadInitialPosts(),
          ),
        ),
      );
    }
  }

  // Unused - Keeping for potential future use
  // ignore: unused_element
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
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = context.watch<UserProvider>();
    final currentUserId = userProvider.currentUser?.id ?? '';

    return CustomPullToRefresh(
      onRefresh: _loadInitialPosts,
      color: AppColors.accentGreen,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Stories Bar (Sticky)
          if (currentUserId.isNotEmpty)
            SliverToBoxAdapter(
              child: StoriesBar(currentUserId: currentUserId),
            ),

          // Filter Pills (แบบ TikTok)
          SliverToBoxAdapter(
            child: _buildModernFilterPills(),
          ),

          // Post Type Chips (แบบ Shopee)
          if (_selectedFilter == 'all')
            SliverToBoxAdapter(
              child: _buildPostTypeChips(),
            ),

          // Posts List
          _buildPostsList(currentUserId),

          // Loading More Indicator
          if (_isLoading && _posts.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildLoadingMoreIndicator(),
            ),

          // Bottom Padding
          SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // Modern Filter Pills แบบ TikTok
  Widget _buildModernFilterPills() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterPill(
            label: 'ทั้งหมด',
            value: 'all',
            icon: Icons.public,
            gradient: LinearGradient(
              colors: [AppColors.primaryTeal, AppColors.accentGreen],
            ),
          ),
          _buildFilterPill(
            label: 'กำลังติดตาม',
            value: 'following',
            icon: Icons.people,
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.purpleAccent],
            ),
          ),
          _buildFilterPill(
            label: 'ยอดนิยม',
            value: 'popular',
            icon: Icons.local_fire_department,
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
            ),
          ),
          _buildFilterPill(
            label: 'ใกล้ฉัน',
            value: 'nearby',
            icon: Icons.location_on,
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlue],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadInitialPosts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.graySecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.grayPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Post Type Chips แบบ Shopee
  Widget _buildPostTypeChips() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildTypeChip(
            label: 'ทั้งหมด',
            icon: '🌍',
            type: null,
          ),
          ...PostType.values.map((type) => _buildTypeChip(
                label: type.name,
                icon: type.icon,
                type: type,
              )),
        ],
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required String icon,
    required PostType? type,
  }) {
    final isSelected = _selectedPostType == type;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPostType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryTeal
                : AppColors.grayBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.grayPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(String currentUserId) {
    if (_posts.isEmpty && !_isLoading) {
      return SliverFillRemaining(
        child: EmptyPostState(
          onCreatePost: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateCommunityPostScreen(),
              ),
            );
          },
        ),
      );
    }

    if (_posts.isEmpty && _isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const PostCardShimmer(),
          childCount: 3,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final postData = _filteredPosts[index];
          final post = CommunityPost.fromMap(postData, postData['id']);

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: Opacity(
                  opacity: value,
                  child: PostCardWidget(
                    post: post,
                    onLike: () => _loadInitialPosts(),
                  ),
                ),
              );
            },
          );
        },
        childCount: _filteredPosts.length,
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'กำลังโหลดเพิ่มเติม...',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.graySecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inHours < 1) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inDays < 1) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }
}
