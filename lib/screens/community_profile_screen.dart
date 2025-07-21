// lib/screens/community_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/community_post.dart';
import '../models/story.dart';
import '../models/friend.dart';
import '../services/firebase_service.dart';
import '../services/story_service.dart';
import '../services/friend_service.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card_widget.dart';
import '../screens/community_chat_screen.dart';
import '../screens/create_community_post_screen.dart';
import '../utils/constants.dart';
import 'dart:io';
import 'package:timeago/timeago.dart' as timeago;

class CommunityProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user profile
  final bool hideCreatePostButton;

  const CommunityProfileScreen({
    super.key,
    this.userId,
    this.hideCreatePostButton = false,
  });

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  final StoryService _storyService = StoryService();
  final FriendService _friendService = FriendService();

  AppUser? _profileUser;
  List<CommunityPost> _userPosts = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  List<Story> _stories = [];
  List<Story> _highlights = [];
  List<Friend> _friends = [];

  // สถานะติดตาม/เลิกติดตาม
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _loadUserPosts();
    _loadUserStats();
    _loadStories();
    _loadHighlights();
    _loadFriends();
    _checkFollowingStatus();
  }

  // ตรวจสอบสถานะติดตาม
  Future<void> _checkFollowingStatus() async {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId == null || _isMyProfile || _profileUser == null) return;
    try {
      final isFollowing =
          await _friendService.isFollowing(currentUserId, _targetUserId);
      if (mounted) setState(() => _isFollowing = isFollowing);
    } catch (e) {
      debugPrint('Error checking following status: $e');
    }
  }

  // ดำเนินการติดตาม/เลิกติดตาม
  Future<void> _toggleFollow() async {
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (_followLoading) return; // ป้องกันกดซ้ำ
    if (currentUserId == null || _isMyProfile || _profileUser == null) {
      debugPrint('ข้อมูลผู้ใช้ไม่ครบ');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถดำเนินการได้')),
      );
      return;
    }
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await _friendService.unfollowUser(currentUserId, _targetUserId);
        if (mounted) setState(() => _isFollowing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เลิกติดตามแล้ว')),
        );
      } else {
        await _friendService.followUser(currentUserId, _targetUserId);
        if (mounted) setState(() => _isFollowing = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ติดตามแล้ว')),
        );
      }
      // อัปเดตสถานะเพื่อนทันที
      _loadFriends();
    } catch (e, st) {
      debugPrint('Follow error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
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

  Future<void> _loadStories() async {
    _storyService.getUserStories(_targetUserId).listen((stories) {
      if (mounted) setState(() => _stories = stories);
    });
  }

  Future<void> _loadHighlights() async {
    _storyService.getHighlights(_targetUserId).listen((highlights) {
      if (mounted) setState(() => _highlights = highlights);
    });
  }

  Future<void> _loadFriends() async {
    _friendService.getFriends(_targetUserId).listen((friends) {
      if (mounted) setState(() => _friends = friends);
    });
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
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'ค้นหาเพื่อน',
                          onPressed: _showFriendSearchDialog,
                        ),
                        if (!_isMyProfile && _profileUser != null)
                          _followLoading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(_isFollowing
                                      ? Icons.person_remove_alt_1
                                      : Icons.person_add_alt_1),
                                  tooltip:
                                      _isFollowing ? 'เลิกติดตาม' : 'ติดตาม',
                                  onPressed: _toggleFollow,
                                ),
                        // ปุ่มฟีเจอร์เร็วๆนี้
                        IconButton(
                          icon: const Icon(Icons.new_releases),
                          tooltip: 'ฟีเจอร์เร็วๆนี้',
                          onPressed: () =>
                              _showComingSoonSnackBar('ฟีเจอร์ใหม่'),
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
      floatingActionButton: null,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // รูปโปรไฟล์ (กดเปลี่ยนได้ถ้าเป็นของตัวเอง)
          Center(
            child: GestureDetector(
              onTap: _isMyProfile ? _showAddStoryDialog : null,
              child: CircleAvatar(
                radius: 54,
                backgroundColor: AppColors.grayBorder,
                backgroundImage: _profileUser?.photoUrl != null
                    ? CachedNetworkImageProvider(_profileUser!.photoUrl!)
                    : null,
                child: _profileUser?.photoUrl == null
                    ? const Icon(Icons.person,
                        size: 54, color: AppColors.graySecondary)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // สตอรี่และ highlights
          if (_stories.isNotEmpty || _highlights.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._highlights.map((highlight) => GestureDetector(
                        onTap: () => _showStoryViewer(highlight),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage:
                                    NetworkImage(highlight.imageUrl),
                                backgroundColor: AppColors.primaryTeal,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                highlight.highlightTitle ?? 'Highlight',
                                style: AppTextStyles.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      )),
                  ..._stories.map((story) => GestureDetector(
                        onTap: () => _showStoryViewer(story),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage: NetworkImage(story.imageUrl),
                                backgroundColor: AppColors.grayBorder,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                story.caption ?? 'Story',
                                style: AppTextStyles.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          // ชื่อ
          Text(
            _profileUser?.displayName ?? '',
            style: AppTextStyles.headline,
            textAlign: TextAlign.center,
          ),
          // bio/quote
          if ((_profileUser?.bio?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Text(
                _profileUser!.bio!,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ),
          // แสดงอีเมล
          if ((_profileUser?.showEmail ?? false) &&
              (_profileUser?.email.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                _profileUser!.email,
                style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          if ((_profileUser?.showFacebook ?? false) &&
              (_profileUser?.facebook?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Facebook: ${_profileUser!.facebook!}',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ),
          if ((_profileUser?.showInstagram ?? false) &&
              (_profileUser?.instagram?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Instagram: ${_profileUser!.instagram!}',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ),
          if ((_profileUser?.showLine ?? false) &&
              (_profileUser?.lineId?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Line ID: ${_profileUser!.lineId!}',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ),
          // ปุ่มสร้างโพสต์ (เฉพาะโปรไฟล์ตัวเอง)
          if (_isMyProfile && !widget.hideCreatePostButton)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('สร้างโพสต์ใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
              ),
            ),
          // ปุ่มแชท (เฉพาะเมื่อดูโปรไฟล์คนอื่น)
          if (!_isMyProfile && _profileUser != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('แชทกับผู้ใช้'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  _navigateToChat(_profileUser!);
                },
              ),
            ),
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
      labelStyle: AppTextStyles.bodyBold.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: AppColors.primaryTeal,
        shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
      ),
      tabs: const [
        Tab(
          icon: Icon(Icons.grid_on, size: 30),
          child: Text('ฟีส',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal)),
        ),
        Tab(
          icon: Icon(Icons.analytics, size: 28),
          child: Text('โปรไฟร์',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal)),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userPosts.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(height: 32),
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีโพสต์ในโปรไฟล์นี้',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'หากข้อมูลไม่แสดงหรือโหลดนาน กรุณาลองดึงเพื่อรีเฟรชหน้าจอ',
            style: TextStyle(fontSize: 14, color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
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
          // สถิติแบบ row ด้านบน
          _buildStatsRow(),
          const SizedBox(height: 16),
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
                  _userPosts.isNotEmpty
                      ? _buildActivityItem(
                          'โพสต์ล่าสุด',
                          _userPosts.first.createdAt.toDate(),
                          Icons.post_add,
                        )
                      : const Text('ยังไม่มีกิจกรรม'),
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
    final nameController =
        TextEditingController(text: _profileUser?.displayName ?? '');
    final bioController = TextEditingController(text: _profileUser?.bio ?? '');
    final facebookController =
        TextEditingController(text: _profileUser?.facebook ?? '');
    final instagramController =
        TextEditingController(text: _profileUser?.instagram ?? '');
    final lineController =
        TextEditingController(text: _profileUser?.lineId ?? '');
    // เพิ่ม controller สำหรับ visibility
    bool showEmail = _profileUser?.showEmail ?? false;
    bool showFacebook = _profileUser?.showFacebook ?? false;
    bool showInstagram = _profileUser?.showInstagram ?? false;
    bool showLine = _profileUser?.showLine ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('แก้ไขโปรไฟล์'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // แสดงรูปโปรไฟล์ปัจจุบัน
                    if (_profileUser?.photoUrl != null)
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            CachedNetworkImageProvider(_profileUser!.photoUrl!),
                      )
                    else
                      const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person, size: 40),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('เปลี่ยนรูปโปรไฟล์'),
                      onPressed: () async {
                        _pickAndUploadProfileImage();
                        await _loadUserProfile();
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'ชื่อ'),
                    ),
                    TextField(
                      controller: bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: facebookController,
                      decoration: const InputDecoration(labelText: 'Facebook'),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.facebook, size: 20),
                        const SizedBox(width: 8),
                        const Text('แสดง Facebook'),
                        const Spacer(),
                        Switch(
                          value: showFacebook,
                          onChanged: (val) {
                            setStateDialog(() {
                              showFacebook = val;
                            });
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: instagramController,
                      decoration: const InputDecoration(labelText: 'Instagram'),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 20),
                        const SizedBox(width: 8),
                        const Text('แสดง Instagram'),
                        const Spacer(),
                        Switch(
                          value: showInstagram,
                          onChanged: (val) {
                            setStateDialog(() {
                              showInstagram = val;
                            });
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: lineController,
                      decoration: const InputDecoration(labelText: 'Line ID'),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 20),
                        const SizedBox(width: 8),
                        const Text('แสดง Line ID'),
                        const Spacer(),
                        Switch(
                          value: showLine,
                          onChanged: (val) {
                            setStateDialog(() {
                              showLine = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 20),
                        const SizedBox(width: 8),
                        const Text('แสดงอีเมลในโปรไฟล์'),
                        const Spacer(),
                        Switch(
                          value: showEmail,
                          onChanged: (val) {
                            setStateDialog(() {
                              showEmail = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_profileUser?.id)
                        .update({
                      'displayName': nameController.text.trim(),
                      'bio': bioController.text.trim(),
                      'facebook': facebookController.text.trim(),
                      'instagram': instagramController.text.trim(),
                      'lineId': lineController.text.trim(),
                      'showEmail': showEmail,
                      'showFacebook': showFacebook,
                      'showInstagram': showInstagram,
                      'showLine': showLine,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _loadUserProfile();
                    }
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
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
    // สำหรับปุ่มติดตาม ให้เพิ่ม/ลบเพื่อนจริง
    if (feature == 'ติดตาม' && !_isMyProfile && _profileUser != null) {
      final currentUserId = context.read<UserProvider>().currentUser?.id;
      final isFriend = _friends.any((f) => f.friendId == _profileUser!.id);
      if (isFriend) {
        _friendService.removeFriend(currentUserId!, _profileUser!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบเพื่อนเรียบร้อย')),
        );
      } else {
        _friendService.addFriend(currentUserId!, _profileUser!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มเพื่อนเรียบร้อย')),
        );
      }
      _loadFriends();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ฟีเจอร์$featureจะพร้อมใช้งานเร็วๆ นี้')),
      );
    }
  }

  void _pickAndUploadProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null || _profileUser == null) return;
      final file = pickedFile;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${_profileUser!.id}.jpg');
      await storageRef.putData(await file.readAsBytes());
      final imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_profileUser!.id)
          .update({
        'photoUrl': imageUrl,
      });
      if (mounted) {
        _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปโปรไฟล์: $e')),
        );
      }
    }
  }

  void _showAddStoryDialog() {
    final captionController = TextEditingController();
    bool isHighlight = false;
    final highlightTitleController = TextEditingController();
    XFile? selectedImage;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('เพิ่มสตอรี่'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text('เลือกภาพ'),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 70);
                        if (picked != null) {
                          setState(() => selectedImage = picked);
                        }
                      },
                    ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Image.file(File(selectedImage!.path), height: 120),
                      ),
                    TextField(
                      controller: captionController,
                      decoration: const InputDecoration(
                          labelText: 'คำอธิบาย (caption)'),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isHighlight,
                          onChanged: (val) =>
                              setState(() => isHighlight = val ?? false),
                        ),
                        const Text('บันทึกเป็น Highlight'),
                      ],
                    ),
                    if (isHighlight)
                      TextField(
                        controller: highlightTitleController,
                        decoration:
                            const InputDecoration(labelText: 'ชื่อ Highlight'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedImage == null || _profileUser == null) return;
                    final file = File(selectedImage!.path);
                    final storageRef = FirebaseStorage.instance.ref().child(
                        'stories/${_profileUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
                    await storageRef.putData(await file.readAsBytes());
                    final imageUrl = await storageRef.getDownloadURL();
                    final story = Story(
                      id: '',
                      userId: _profileUser!.id,
                      imageUrl: imageUrl,
                      caption: captionController.text.trim(),
                      createdAt: Timestamp.now(),
                      isHighlight: isHighlight,
                      highlightTitle: isHighlight
                          ? highlightTitleController.text.trim()
                          : null,
                    );
                    await _storyService.addStory(story);
                    Navigator.pop(context);
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFriendSearchDialog() {
    final searchController = TextEditingController();
    List<AppUser> searchResults = [];
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('ค้นหาเพื่อน'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                        labelText: 'ค้นหาด้วยชื่อหรืออีเมล'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => isLoading = true);
                      final query = searchController.text.trim().toLowerCase();
                      final usersSnap = await FirebaseFirestore.instance
                          .collection('users')
                          .where('displayName', isGreaterThanOrEqualTo: query)
                          .where('displayName',
                              isLessThanOrEqualTo: '$query\uf8ff')
                          .get();
                      searchResults = usersSnap.docs
                          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
                          .where((u) => u.id != _profileUser?.id)
                          .toList();
                      setState(() => isLoading = false);
                    },
                    child: const Text('ค้นหา'),
                  ),
                  if (isLoading)
                    const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator()),
                  if (searchResults.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, idx) {
                          final user = searchResults[idx];
                          final isFriend =
                              _friends.any((f) => f.friendId == user.id);
                          return ListTile(
                            leading: user.photoUrl != null
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(user.photoUrl!))
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user.displayName ?? 'ผู้ใช้'),
                            subtitle: Text(user.email),
                            trailing: isFriend
                                ? IconButton(
                                    icon: const Icon(Icons.person_remove,
                                        color: Colors.red),
                                    tooltip: 'ลบเพื่อน',
                                    onPressed: () async {
                                      await _friendService.removeFriend(
                                          _profileUser!.id, user.id);
                                      setState(() {
                                        _friends.removeWhere(
                                            (f) => f.friendId == user.id);
                                      });
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.person_add,
                                        color: Colors.green),
                                    tooltip: 'เพิ่มเพื่อน',
                                    onPressed: () async {
                                      await _friendService.addFriend(
                                          _profileUser!.id, user.id);
                                      setState(() {
                                        _friends.add(Friend(
                                            id: '',
                                            userId: _profileUser!.id,
                                            friendId: user.id,
                                            createdAt: Timestamp.now()));
                                      });
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ปิด'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStoryViewer(Story story) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(story.imageUrl),
              if (story.caption != null && story.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(story.caption!),
                ),
            ],
          ),
        );
      },
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
