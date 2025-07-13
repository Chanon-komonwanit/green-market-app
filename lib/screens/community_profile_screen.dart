// lib/screens/community_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_user.dart';
import '../models/community_post.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card_widget.dart';
import '../screens/community_chat_screen.dart';
import '../screens/create_community_post_screen.dart';
import '../utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user profile

  const CommunityProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();

  AppUser? _profileUser;
  List<CommunityPost> _userPosts = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _loadUserPosts();
    _loadUserStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _targetUserId {
    return widget.userId ?? context.read<UserProvider>().currentUser?.id ?? '';
  }

  bool get _isMyProfile {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    return _targetUserId == currentUserId;
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _firebaseService.getUserById(_targetUserId);
      if (mounted) {
        setState(() {
          _profileUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดโปรไฟล์: $e')),
        );
      }
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      // Convert Stream to List by taking first value
      final postsStream = _firebaseService.getUserCommunityPosts(_targetUserId);
      final postsData = await postsStream.first;

      // Convert Map data to CommunityPost objects
      final posts = postsData
          .map((data) => CommunityPost.fromMap(data, data['id']))
          .toList();

      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดโพสต์: $e')),
        );
      }
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _firebaseService.getUserCommunityStats(_targetUserId);
      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserPosts(),
      _loadUserStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      title: Text(_profileUser?.displayName ?? 'โปรไฟล์'),
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.grayPrimary,
                      elevation: 1,
                      pinned: true,
                      floating: true,
                      actions: [
                        if (_isMyProfile)
                          IconButton(
                            onPressed: _showEditProfileDialog,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                      ],
                    ),
                    SliverToBoxAdapter(child: _buildProfileHeader()),
                    SliverPersistentHeader(
                      delegate: _SliverTabBarDelegate(_buildTabBar()),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(),
                    _buildStatsTab(),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isMyProfile
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCommunityPostScreen(),
                  ),
                );
                if (result == true) {
                  _refreshData();
                }
              },
              backgroundColor: AppColors.primaryTeal,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.white,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.grayBorder,
            backgroundImage: _profileUser?.photoUrl != null
                ? CachedNetworkImageProvider(_profileUser!.photoUrl!)
                : null,
            child: _profileUser?.photoUrl == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.graySecondary,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _profileUser?.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          if (_profileUser?.bio?.isNotEmpty == true)
            Text(
              _profileUser!.bio!,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          _buildStatsRow(),
          if (!_isMyProfile && _profileUser != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToChat(_profileUser!),
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('ส่งข้อความ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showComingSoonSnackBar('ติดตาม'),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('ติดตาม'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      side: const BorderSide(color: AppColors.primaryTeal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final postsCount = _userStats?['totalPosts'] ?? 0;
    final likesCount = _userStats?['totalLikes'] ?? 0;
    final commentsCount = _userStats?['totalComments'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('โพสต์', postsCount.toString()),
        _buildStatItem('ถูกใจ', likesCount.toString()),
        _buildStatItem('ความคิดเห็น', commentsCount.toString()),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headline.copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.primaryTeal,
      unselectedLabelColor: AppColors.graySecondary,
      indicatorColor: AppColors.primaryTeal,
      labelStyle: AppTextStyles.bodyBold,
      tabs: const [
        Tab(
          icon: Icon(Icons.grid_on),
          text: 'โพสต์',
        ),
        Tab(
          icon: Icon(Icons.analytics),
          text: 'สถิติ',
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dynamic_feed_outlined,
              size: 64,
              color: AppColors.graySecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _isMyProfile ? 'คุณยังไม่มีโพสต์' : 'ผู้ใช้ยังไม่มีโพสต์',
              style: AppTextStyles.subtitle,
            ),
            if (_isMyProfile) ...[
              const SizedBox(height: 8),
              Text(
                'แตะปุ่ม + เพื่อสร้างโพสต์แรกของคุณ',
                style: AppTextStyles.body,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return PostCardWidget(
          post: post,
          onLike: _refreshData,
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สถิติโดยรวม', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  _buildStatListItem(
                      'จำนวนโพสต์', _userStats?['totalPosts'] ?? 0),
                  _buildStatListItem(
                      'ถูกใจทั้งหมด', _userStats?['totalLikes'] ?? 0),
                  _buildStatListItem(
                      'คอมเมนต์ทั้งหมด', _userStats?['totalComments'] ?? 0),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Activity Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('กิจกรรมล่าสุด', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  if (_userPosts.isNotEmpty) ...[
                    _buildActivityItem(
                      'โพสต์ล่าสุด',
                      _userPosts.first.createdAt.toDate(),
                      Icons.post_add,
                    ),
                  ] else ...[
                    const Text('ยังไม่มีกิจกรรม'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatListItem(String label, int value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTextStyles.body),
      trailing: Text(
        value.toString(),
        style: AppTextStyles.bodyBold,
      ),
    );
  }

  Widget _buildActivityItem(String title, DateTime date, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(timeago.format(date, locale: 'th')),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('แก้ไขโปรไฟล์'),
          content: const Text('ฟีเจอร์แก้ไขโปรไฟล์จะพร้อมใช้งานเร็วๆ นี้'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToChat(AppUser otherUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityChatScreen(
          otherUserId: otherUser.id,
          otherUserName: otherUser.displayName ?? 'ผู้ใช้',
          otherUserPhoto: otherUser.photoUrl,
        ),
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ฟีเจอร์$featureจะพร้อมใช้งานเร็วๆ นี้')),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
