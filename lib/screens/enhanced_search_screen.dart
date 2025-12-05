// lib/screens/enhanced_search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/community_post.dart';
import '../screens/community_profile_screen.dart';
import '../screens/post_comments_screen.dart';
import '../widgets/post_card_widget.dart';

/// Enhanced Search Screen
/// ค้นหาแบบละเอียด: Users, Groups, Posts พร้อม filters และ recent searches
class EnhancedSearchScreen extends StatefulWidget {
  const EnhancedSearchScreen({super.key});

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<String> _recentSearches = [];
  String _searchQuery = '';
  bool _isSearching = false;

  // Filters
  String _postTypeFilter = 'all'; // all, discussion, product, activity
  String _dateFilter = 'all'; // all, today, week, month

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches = prefs.getStringList('recent_searches') ?? [];
      });
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];

      // Remove if already exists
      searches.remove(query);
      // Add to front
      searches.insert(0, query);
      // Keep only last 10
      if (searches.length > 10) {
        searches.removeRange(10, searches.length);
      }

      await prefs.setStringList('recent_searches', searches);
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      debugPrint('Error saving search: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      setState(() {
        _recentSearches = [];
      });
    } catch (e) {
      debugPrint('Error clearing searches: $e');
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    _saveSearch(query);
  }

  DateTime _getDateFilterStart() {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      default:
        return DateTime(2020, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ค้นหา...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _isSearching = false;
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'โพสต์'),
                  Tab(text: 'ผู้ใช้'),
                  Tab(text: 'กลุ่ม'),
                ],
              ),
              if (_isSearching && _tabController.index == 0) _buildFilters(),
            ],
          ),
        ),
      ),
      body: _isSearching
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildUsersTab(),
                _buildGroupsTab(),
              ],
            )
          : _buildRecentSearches(),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Post Type Filter
          Expanded(
            child: DropdownButton<String>(
              value: _postTypeFilter,
              isExpanded: true,
              dropdownColor: AppColors.primaryTeal,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('ทุกประเภท')),
                DropdownMenuItem(value: 'discussion', child: Text('📝 พูดคุย')),
                DropdownMenuItem(value: 'product', child: Text('🛍️ สินค้า')),
                DropdownMenuItem(value: 'activity', child: Text('🎯 กิจกรรม')),
              ],
              onChanged: (value) {
                setState(() {
                  _postTypeFilter = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Date Filter
          Expanded(
            child: DropdownButton<String>(
              value: _dateFilter,
              isExpanded: true,
              dropdownColor: AppColors.primaryTeal,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('ทุกช่วงเวลา')),
                DropdownMenuItem(value: 'today', child: Text('วันนี้')),
                DropdownMenuItem(value: 'week', child: Text('สัปดาห์นี้')),
                DropdownMenuItem(value: 'month', child: Text('เดือนนี้')),
              ],
              onChanged: (value) {
                setState(() {
                  _dateFilter = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.graySecondary),
            const SizedBox(height: 16),
            Text(
              'ค้นหาอะไรดี?',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.graySecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'ค้นหาโพสต์ ผู้ใช้ หรือกลุ่มได้ที่นี่',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('การค้นหาล่าสุด', style: AppTextStyles.bodyBold),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text('ล้างทั้งหมด',
                    style: TextStyle(color: AppColors.errorRed)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return ListTile(
                leading: Icon(Icons.history, color: AppColors.graySecondary),
                title: Text(search),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: AppColors.graySecondary),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final searches =
                        prefs.getStringList('recent_searches') ?? [];
                    searches.remove(search);
                    await prefs.setStringList('recent_searches', searches);
                    setState(() {
                      _recentSearches.remove(search);
                    });
                  },
                ),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    Query query = FirebaseFirestore.instance
        .collection('community_posts')
        .where('isActive', isEqualTo: true);

    // Apply filters
    if (_postTypeFilter != 'all') {
      query = query.where('postType', isEqualTo: _postTypeFilter);
    }

    if (_dateFilter != 'all') {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: _getDateFilterStart());
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          query.orderBy('createdAt', descending: true).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final posts = snapshot.data?.docs ?? [];

        // Filter by search query (content, tags)
        final filteredPosts = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final content = (data['content'] as String? ?? '').toLowerCase();
          final tags = List<String>.from(data['tags'] ?? []);
          final query = _searchQuery.toLowerCase();

          return content.contains(query) ||
              tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();

        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off,
                    size: 64, color: AppColors.graySecondary),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบโพสต์',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.graySecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'ลองค้นหาด้วยคำอื่น',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final postDoc = filteredPosts[index];
            final post = CommunityPost.fromMap(
              postDoc.data() as Map<String, dynamic>,
              postDoc.id,
            );
            return PostCardWidget(
              post: post,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostCommentsScreen(post: post),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('displayName')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];

        // Filter by search query
        final filteredUsers = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final displayName =
              (data['displayName'] as String? ?? '').toLowerCase();
          final email = (data['email'] as String? ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();

          return displayName.contains(query) || email.contains(query);
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search,
                    size: 64, color: AppColors.graySecondary),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบผู้ใช้',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.graySecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userDoc = filteredUsers[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final displayName = userData['displayName'] ?? 'Unknown';
            final photoUrl = userData['photoUrl'];
            final ecoCoins = userData['ecoCoins'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                title: Text(displayName, style: AppTextStyles.bodyBold),
                subtitle: Row(
                  children: [
                    Icon(Icons.monetization_on,
                        size: 14, color: AppColors.warningAmber),
                    const SizedBox(width: 4),
                    Text('$ecoCoins เหรียญ', style: AppTextStyles.caption),
                  ],
                ),
                trailing:
                    Icon(Icons.chevron_right, color: AppColors.graySecondary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommunityProfileScreen(userId: userDoc.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_groups')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final groups = snapshot.data?.docs ?? [];

        // Filter by search query
        final filteredGroups = groups.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] as String? ?? '').toLowerCase();
          final description =
              (data['description'] as String? ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();

          return name.contains(query) || description.contains(query);
        }).toList();

        if (filteredGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 64, color: AppColors.graySecondary),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบกลุ่ม',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.graySecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredGroups.length,
          itemBuilder: (context, index) {
            final groupDoc = filteredGroups[index];
            final groupData = groupDoc.data() as Map<String, dynamic>;
            final name = groupData['name'] ?? 'Unknown';
            final description = groupData['description'] ?? '';
            final photoUrl = groupData['photoUrl'];
            final memberCount = (groupData['members'] as List?)?.length ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? const Icon(Icons.group, size: 28)
                      : null,
                ),
                title: Text(name, style: AppTextStyles.bodyBold),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: 14, color: AppColors.graySecondary),
                        const SizedBox(width: 4),
                        Text('$memberCount สมาชิก',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
                trailing:
                    Icon(Icons.chevron_right, color: AppColors.graySecondary),
                onTap: () {
                  // Navigate to group detail (if exists)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เปิดกลุ่ม: $name')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
