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
import 'create_community_post_screen.dart';

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
      appBar: AppBar(
        title: Text(_isMyProfile ? 'โปรไฟล์ของฉัน' : 'โปรไฟล์'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isMyProfile)
            IconButton(
              onPressed: () {
                // TODO: Navigate to edit profile
                _showEditProfileDialog();
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                slivers: [
                  // Profile Header
                  SliverToBoxAdapter(child: _buildProfileHeader()),

                  // Tab Bar
                  SliverToBoxAdapter(child: _buildTabBar()),

                  // Tab Content
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostsTab(),
                        _buildStatsTab(),
                      ],
                    ),
                  ),
                ],
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
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[400]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: _profileUser?.photoUrl != null
                ? CachedNetworkImageProvider(_profileUser!.photoUrl!)
                : null,
            child: _profileUser?.photoUrl == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            _profileUser?.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Bio or Description
          if (_profileUser?.bio?.isNotEmpty == true)
            Text(
              _profileUser!.bio!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 20),

          // Stats Row
          _buildStatsRow(),

          const SizedBox(height: 16),

          // Action Buttons
          if (!_isMyProfile && _profileUser != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommunityChatScreen(
                            otherUserId: _profileUser!.id,
                            otherUserName:
                                _profileUser!.displayName ?? 'ผู้ใช้',
                            otherUserPhoto: _profileUser!.photoUrl,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('ส่งข้อความ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement follow functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('ฟีเจอร์ติดตามจะมาเร็วๆ นี้')),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('ติดตาม'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF059669)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
    final postsCount = _userStats?['postsCount'] ?? 0;
    final likesCount = _userStats?['likesCount'] ?? 0;
    final sharesCount = _userStats?['sharesCount'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('โพสต์', postsCount),
        _buildStatItem('ถูกใจ', likesCount),
        _buildStatItem('แชร์', sharesCount),
      ],
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green,
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
      ),
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
              Icons.post_add,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isMyProfile ? 'คุณยังไม่มีโพสต์' : 'ผู้ใช้ยังไม่มีโพสต์',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_isMyProfile) ...[
              const SizedBox(height: 8),
              Text(
                'แตะปุ่ม + เพื่อสร้างโพสต์แรกของคุณ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
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
          onTap: () {
            // TODO: Navigate to post detail
            _openPostDetail(post);
          },
          onLike: () {
            _refreshData();
          },
          onComment: () {
            // TODO: Navigate to comments
            _openComments(post);
          },
          onShare: () {
            // TODO: Share functionality
            _sharePost(post);
          },
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
                  Text(
                    'สถิติโดยรวม',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('จำนวนโพสต์', _userStats?['postsCount'] ?? 0),
                  _buildStatRow('ถูกใจทั้งหมด', _userStats?['likesCount'] ?? 0),
                  _buildStatRow('แชร์ทั้งหมด', _userStats?['sharesCount'] ?? 0),
                  _buildStatRow(
                      'คอมเมนต์ทั้งหมด', _userStats?['commentsCount'] ?? 0),
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
                  Text(
                    'กิจกรรมล่าสุด',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
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

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, DateTime date, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(_formatDate(date)),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  void _openPostDetail(CommunityPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('ฟีเจอร์รายละเอียดโพสต์จะพร้อมใช้งานเร็วๆ นี้')),
    );
  }

  void _openComments(CommunityPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ฟีเจอร์คอมเมนต์จะพร้อมใช้งานเร็วๆ นี้')),
    );
  }

  void _sharePost(CommunityPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ฟีเจอร์แชร์จะพร้อมใช้งานเร็วๆ นี้')),
    );
  }
}
