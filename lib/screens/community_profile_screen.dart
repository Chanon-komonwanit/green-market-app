// lib/screens/community_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/app_user.dart';
import '../models/community_post.dart';
import '../models/story.dart';
import '../models/friend.dart';
import '../services/firebase_service.dart';
import '../services/story_service.dart';
import '../services/friend_service.dart';
import '../services/achievement_service.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card_widget.dart';
import '../widgets/achievement_badge_widget.dart';
import '../widgets/qr_profile_share_widget.dart';
import '../screens/community_chat_screen.dart';
import '../screens/create_community_post_screen.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/create_story_screen.dart';
import '../screens/story_viewer_screen.dart';
import '../utils/constants.dart';
import '../utils/thai_messages.dart';
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
  final AchievementService _achievementService = AchievementService();

  AppUser? _profileUser;
  List<CommunityPost> _userPosts = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  List<Story> _stories = [];
  List<Story> _highlights = [];
  List<Friend> _friends = [];
  List<Achievement> _userBadges = [];

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
    _loadUserBadges();
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
      debugPrint('${ThaiMessages.followError}: $e');
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

  Future<void> _loadUserBadges() async {
    try {
      final badges = await _achievementService.getUserBadges(_targetUserId);
      if (mounted) {
        setState(() {
          _userBadges = badges;
        });
      }
    } catch (e) {
      debugPrint('Error loading badges: $e');
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserPosts(),
      _loadUserStats(),
      _loadUserBadges(),
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
                        if (_isMyProfile) ...[
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SavedPostsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bookmark_border),
                            tooltip: 'โพสต์ที่บันทึก',
                          ),
                          IconButton(
                            onPressed: () {
                              QRProfileShareWidget.show(
                                context: context,
                                userId: _targetUserId,
                                userName: _profileUser?.displayName ?? 'ผู้ใช้',
                                userPhotoUrl: _profileUser?.photoUrl,
                              );
                            },
                            icon: const Icon(Icons.qr_code),
                            tooltip: 'แชร์ QR Code',
                          ),
                          IconButton(
                            onPressed: _showEditProfileDialog,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
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
    final postsCount = _userStats?['totalPosts'] ?? 0;
    final followersCount = _userStats?['followersCount'] ?? 0;
    final followingCount = _userStats?['followingCount'] ?? 0;

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Photo (like Facebook/TikTok)
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryTeal.withOpacity(0.3),
                      AppColors.emeraldPrimary.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _profileUser?.coverPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _profileUser!.coverPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.grayBorder,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryTeal.withOpacity(0.3),
                                AppColors.emeraldPrimary.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      )
                    : Container(),
              ),
              // Edit Cover Button (for own profile)
              if (_isMyProfile)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: InkWell(
                    onTap: _changeCoverImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt,
                              size: 16, color: AppColors.grayPrimary),
                          const SizedBox(width: 4),
                          Text('แก้ไขภาพปก',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.grayPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Profile Picture & Info Section
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: _isMyProfile ? _changeProfilePicture : null,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: AppColors.grayBorder,
                                backgroundImage: _profileUser?.photoUrl != null
                                    ? CachedNetworkImageProvider(
                                        _profileUser!.photoUrl!)
                                    : null,
                                child: _profileUser?.photoUrl == null
                                    ? const Icon(Icons.person,
                                        size: 60,
                                        color: AppColors.graySecondary)
                                    : null,
                              ),
                              if (_isMyProfile)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Material(
                                    color: AppColors.primaryTeal,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: _changeProfilePicture,
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.camera_alt_rounded,
                                          size: 16,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Action Buttons
                      if (_isMyProfile)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('แก้ไขโปรไฟล์'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceGray,
                            foregroundColor: AppColors.grayPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _showEditProfileDialog,
                        )
                      else ...[
                        ElevatedButton.icon(
                          icon: Icon(
                              _isFollowing
                                  ? Icons.person_remove
                                  : Icons.person_add,
                              size: 16),
                          label: Text(_isFollowing ? 'เลิกติดตาม' : 'ติดตาม'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing
                                ? AppColors.surfaceGray
                                : AppColors.primaryTeal,
                            foregroundColor: _isFollowing
                                ? AppColors.grayPrimary
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _followLoading ? null : _toggleFollow,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('ส่งข้อความ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceGray,
                            foregroundColor: AppColors.grayPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _navigateToChat(_profileUser!),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Name & Badge
                  Row(
                    children: [
                      Text(
                        _profileUser?.displayName ?? 'ผู้ใช้',
                        style: AppTextStyles.headline.copyWith(fontSize: 24),
                      ),
                      if (_profileUser?.isSeller ?? false) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  size: 14, color: AppColors.primaryTeal),
                              const SizedBox(width: 4),
                              Text(
                                'ผู้ขาย',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_profileUser?.isAdmin ?? false) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningAmber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.admin_panel_settings,
                                  size: 14, color: AppColors.warningAmber),
                              const SizedBox(width: 4),
                              Text(
                                'Admin',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.warningAmber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Bio
                  if (_profileUser?.bio?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      _profileUser!.bio!,
                      style: AppTextStyles.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Eco Coins Display
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentGreen.withOpacity(0.1),
                          AppColors.primaryTeal.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, size: 20, color: AppColors.accentGreen),
                        const SizedBox(width: 8),
                        Text(
                          '${_profileUser?.ecoCoins.toStringAsFixed(0) ?? '0'} Eco Coins',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Row (Posts, Followers, Following)
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'โพสต์',
                          postsCount.toString(),
                          Icons.article_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'ผู้ติดตาม',
                          followersCount.toString(),
                          Icons.people_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'กำลังติดตาม',
                          followingCount.toString(),
                          Icons.person_add_alt_outlined,
                        ),
                      ),
                    ],
                  ),

                  // Achievement Badges Section
                  if (_userBadges.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ความสำเร็จ (${_userBadges.length})',
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  constraints: const BoxConstraints(
                                    maxWidth: 500,
                                    maxHeight: 600,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'ความสำเร็จทั้งหมด',
                                            style: AppTextStyles.headline,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      Expanded(
                                        child: BadgeGridView(
                                          allAchievements: _achievementService
                                              .allAchievements,
                                          earnedAchievements: _userBadges,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text('ดูทั้งหมด'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _userBadges.length > 5 ? 5 : _userBadges.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: AchievementBadgeWidget(
                              achievement: _userBadges[index],
                              isEarned: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Stories / Highlights Row
                  if (_stories.isNotEmpty || _highlights.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add Story Button (own profile only)
                          if (_isMyProfile) _buildAddStoryButton(),

                          // Highlights
                          ..._highlights.map((highlight) => _buildStoryCircle(
                                highlight.imageUrl,
                                highlight.highlightTitle ?? 'Highlight',
                                true,
                                () => _showStoryViewer(highlight),
                              )),

                          // Active Stories
                          ..._stories.map((story) => _buildStoryCircle(
                                story.imageUrl,
                                story.caption ?? 'Story',
                                false,
                                () => _showStoryViewer(story),
                              )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primaryTeal),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headline.copyWith(fontSize: 18),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return GestureDetector(
      onTap: _showAddStoryDialog,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grayBorder, width: 2),
                color: AppColors.surfaceGray,
              ),
              child: Icon(Icons.add, size: 32, color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 6),
            Text(
              'สร้าง Story',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCircle(
      String imageUrl, String label, bool isHighlight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isHighlight
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryTeal,
                          AppColors.emeraldPrimary
                        ],
                      )
                    : null,
                border: Border.all(
                  color:
                      isHighlight ? Colors.transparent : AppColors.primaryTeal,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: CachedNetworkImageProvider(imageUrl),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      // ไม่จำกัดขนาดรูป - รับทุกขนาด (เหมือน Instagram/Facebook)
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        // ไม่ระบุ maxWidth/maxHeight ให้ ImagePicker
        // จะบีบอัดเองภายหลัง
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final currentUser = context.read<UserProvider>().currentUser;
      if (currentUser == null) return;

      // แสดงข้อความกำลังประมวลผล
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('กำลังบีบอัดและอัพโหลดรูปภาพ...'),
              ],
            ),
            duration: Duration(seconds: 30),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }

      // บีบอัดรูปภาพด้วย image package (รองรับทั้ง Web และ Mobile)
      final originalBytes = await image.readAsBytes();
      final originalSize = originalBytes.length;

      debugPrint(
          '📸 รูปต้นฉบับ: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Decode และบีบอัดรูปภาพ
      img.Image? originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('ไม่สามารถอ่านรูปภาพได้');
      }

      // Resize เป็น 512x512 (มาตรฐานรูปโปรไฟล์)
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.cubic, // คุณภาพสูง
      );

      // บีบอัดเป็น JPEG คุณภาพ 85%
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 85),
      );

      final compressedSize = compressedBytes.length;
      final savedPercent =
          ((originalSize - compressedSize) / originalSize * 100)
              .toStringAsFixed(1);

      debugPrint(
          '✅ รูปหลังบีบอัด: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      debugPrint('💾 ประหยัดพื้นที่: $savedPercent%');

      // Upload image with proper metadata
      final fileName =
          '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${currentUser.id}/$fileName');

      final bytes = compressedBytes;
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=3600',
      );

      debugPrint('Starting upload: profile_images/${currentUser.id}/$fileName');
      final uploadTask = storageRef.putData(bytes, metadata);

      final taskSnapshot = await uploadTask.whenComplete(() {});
      debugPrint('Upload state: ${taskSnapshot.state}');

      if (taskSnapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${taskSnapshot.state}');
      }

      final photoUrl = await storageRef.getDownloadURL();
      debugPrint('Got download URL: $photoUrl');

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({'photoUrl': photoUrl});

      // Reload profile
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ThaiMessages.profilePictureChangeSuccess)),
        );
      }
    } catch (e) {
      debugPrint('ข้อผิดพลาดในการเปลี่ยนรูปโปรไฟล์: $e');
      if (mounted) {
        String errorMessage = 'ไม่สามารถเปลี่ยนรูปโปรไฟล์ได้';
        String suggestion = '';

        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage = 'เกิดปัญหาการเชื่อมต่ออินเทอร์เน็ต';
          suggestion = 'กรุณาตรวจสอบสัญญาณและลองใหม่อีกครั้ง';
        } else if (e.toString().contains('storage') ||
            e.toString().contains('upload')) {
          errorMessage = 'ไม่สามารถอัพโหลดรูปภาพได้';
          suggestion = 'กรุณาลองเลือกรูปภาพใหม่อีกครั้ง';
        } else if (e.toString().contains('permission') ||
            e.toString().contains('unauthorized')) {
          errorMessage = 'ไม่มีสิทธิ์ในการเปลี่ยนรูปโปรไฟล์';
          suggestion = 'กรุณาเข้าสู่ระบบใหม่';
        } else if (e.toString().contains('format') ||
            e.toString().contains('invalid')) {
          errorMessage = 'รูปภาพมีรูปแบบที่ไม่รองรับ';
          suggestion = 'กรุณาเลือกไฟล์ JPG หรือ PNG เท่านั้น';
        } else if (e.toString().contains('decode') ||
            e.toString().contains('read')) {
          errorMessage = 'ไม่สามารถประมวลผลรูปภาพได้';
          suggestion = 'ไฟล์รูปภาพอาจเสียหาย กรุณาเลือกรูปอื่น';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage\n💡 $suggestion'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ลองอีกครั้ง',
              textColor: Colors.white,
              onPressed: () => _changeProfilePicture(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      // ไม่จำกัดขนาดรูป - รับทุกขนาด
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final currentUser = context.read<UserProvider>().currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ThaiMessages.authLoginRequired)),
          );
        }
        return;
      }

      // แสดงข้อความกำลังประมวลผล
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('กำลังบีบอัดและอัพโหลดภาพปก...'),
              ],
            ),
            duration: Duration(seconds: 30),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }

      // บีบอัดรูปภาพปก
      final originalBytes = await image.readAsBytes();
      final originalSize = originalBytes.length;

      debugPrint(
          '📸 ภาพปกต้นฉบับ: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      img.Image? originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('ไม่สามารถอ่านรูปภาพได้');
      }

      // Resize เป็น 1920x1080 (มาตรฐานภาพปก 16:9)
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: 1920,
        height: 1080,
        interpolation: img.Interpolation.cubic,
      );

      // บีบอัดเป็น JPEG คุณภาพ 80%
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 80),
      );

      final compressedSize = compressedBytes.length;
      final savedPercent =
          ((originalSize - compressedSize) / originalSize * 100)
              .toStringAsFixed(1);

      debugPrint(
          '✅ ภาพปกหลังบีบอัด: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      debugPrint('💾 ประหยัดพื้นที่: $savedPercent%');

      // Upload image to Firebase Storage with proper metadata
      final fileName =
          '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('cover_images/${currentUser.id}/$fileName');

      final bytes = compressedBytes;
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=3600',
      );

      debugPrint('Starting upload: cover_images/${currentUser.id}/$fileName');
      final uploadTask = storageRef.putData(bytes, metadata);

      final taskSnapshot = await uploadTask.whenComplete(() {});
      debugPrint('Upload state: ${taskSnapshot.state}');

      if (taskSnapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${taskSnapshot.state}');
      }

      final coverPhotoUrl = await storageRef.getDownloadURL();
      debugPrint('Got download URL: $coverPhotoUrl');

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({'coverPhotoUrl': coverPhotoUrl});

      // Reload profile
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ThaiMessages.coverPhotoChangeSuccess),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('ข้อผิดพลาดในการเปลี่ยนภาพปก: $e');
      if (mounted) {
        String errorMessage = 'ไม่สามารถเปลี่ยนภาพปกได้';
        String suggestion = '';

        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage = 'เกิดปัญหาการเชื่อมต่ออินเทอร์เน็ต';
          suggestion = 'กรุณาตรวจสอบสัญญาณและลองใหม่อีกครั้ง';
        } else if (e.toString().contains('storage') ||
            e.toString().contains('upload')) {
          errorMessage = 'ไม่สามารถอัพโหลดภาพปกได้';
          suggestion = 'กรุณาเลือกรูปภาพใหม่ขนาดไม่เกิน 10 MB';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'ไม่มีสิทธิ์ในการเปลี่ยนภาพปก';
          suggestion = 'กรุณาเข้าสู่ระบบใหม่';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage\n💡 $suggestion'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ลองอีกครั้ง',
              textColor: Colors.white,
              onPressed: () => _changeCoverImage(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Widget _buildStatsRow() {
    final postsCount = _userStats?['totalPosts'] ?? 0;
    final followersCount = _userStats?['followersCount'] ?? 0;
    final followingCount = _userStats?['followingCount'] ?? 0;
    final commentsCount = _userStats?['commentsCount'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('โพสต์', postsCount.toString()),
        _buildStatItem('ผู้ติดตาม', followersCount.toString()),
        _buildStatItem('กำลังติดตาม', followingCount.toString()),
        _buildStatItem('ความคิดเห็น', commentsCount.toString()),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Changed to min to prevent overflow
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
            Flexible(
              // Added Flexible to prevent overflow
              child: Text(
                'หากข้อมูลไม่แสดงหรือโหลดนาน กรุณาลองดึงเพื่อรีเฟรชหน้าจอ',
                style: TextStyle(fontSize: 14, color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กำลังอัปโหลดรูปโปรไฟล์...')),
        );
      }

      final bytes = await pickedFile.readAsBytes();
      final fileName =
          '${_profileUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${_profileUser!.id}/$fileName');

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded': DateTime.now().toIso8601String()},
      );

      await storageRef.putData(bytes, metadata);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_profileUser!.id)
          .update({
        'photoUrl': imageUrl,
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ!')),
        );
        _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddStoryDialog() {
    // Navigate to CreateStoryScreen instead of showing dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStoryScreen(),
      ),
    ).then((result) {
      // Reload stories after creating
      if (result == true) {
        _loadStories();
      }
    });
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
    // Navigate to full-screen StoryViewerScreen
    final currentUserId = context.read<UserProvider>().currentUser?.id;
    if (currentUserId == null) return;

    // Get all stories for this user (for swipe navigation)
    final allUserStories = [..._stories, ..._highlights]
        .where((s) => s.userId == story.userId)
        .toList();

    // Find initial index
    final initialIndex = allUserStories.indexWhere((s) => s.id == story.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          stories: allUserStories,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
          currentUserId: currentUserId,
        ),
      ),
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
