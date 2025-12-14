// lib/screens/sustainable_activities_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import '../utils/constants.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';
import 'create_activity_screen.dart';
import 'activity_list_screen.dart';
import 'admin_approve_activities_screen.dart';
import 'activity_notifications_screen.dart';

class SustainableActivitiesHubScreen extends StatefulWidget {
  const SustainableActivitiesHubScreen({super.key});

  @override
  State<SustainableActivitiesHubScreen> createState() =>
      _SustainableActivitiesHubScreenState();
}

class _SustainableActivitiesHubScreenState
    extends State<SustainableActivitiesHubScreen>
    with TickerProviderStateMixin {
  bool isAdmin = false;
  late TabController _tabController;
  late AnimationController _bookmarkAnimationController;

  // Search & Filter States
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedProvince = 'ทั้งหมด';
  String _sortBy = 'newest'; // newest, popular, nearest
  bool _showActiveOnly = false;

  // Bookmark State
  Set<String> _bookmarkedActivities = {};

  // Real-time Leaderboard Data
  List<Map<String, dynamic>> _leaderboardUsers = [];

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  // Premium Real-time Leaderboard Section
  Widget _buildLeaderboardSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9C4), Color(0xFFFFE082), Color(0xFFFFD54F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: Color(0xFFFFA000), size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF57C00),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadLeaderboard,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('รีเฟรช'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF57C00),
                        backgroundColor: Colors.white.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_leaderboardUsers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'กำลังโหลดข้อมูล...',
                        style: TextStyle(
                          color: Color(0xFFF57C00),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ..._leaderboardUsers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final leader = entry.value;
                    return _buildLeaderCard(
                      rank: index + 1,
                      name: leader['name'],
                      points: leader['points'],
                      badge: leader['badge'],
                      isTop3: index < 3,
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderCard({
    required int rank,
    required String name,
    required int points,
    required String badge,
    required bool isTop3,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop3 ? Colors.white : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop3
              ? const Color(0xFFFFA000).withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isTop3 ? 2 : 1,
        ),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: const Color(0xFFFFA000).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTop3
                    ? [const Color(0xFFFFA000), const Color(0xFFFFB300)]
                    : [Colors.grey.shade400, Colors.grey.shade500],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            badge,
            style: const TextStyle(fontSize: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                    fontSize: isTop3 ? 16 : 15,
                    color: const Color(0xFF424242),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.eco, size: 14, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text(
                      '$points คะแนน',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isTop3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA000), Color(0xFFFFB300)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'TOP 3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedActivityCard(BuildContext context, Activity activity) {
    final String title =
        (activity.title.isNotEmpty) ? activity.title : 'กิจกรรมไม่ระบุชื่อ';
    final String desc =
        (activity.description.isNotEmpty) ? activity.description : '-';
    final String province =
        (activity.province.isNotEmpty) ? activity.province : '-';
    final bool isBookmarked = _bookmarkedActivities.contains(activity.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityListScreen(
                title: title,
              ),
            ),
          );
        },
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.teal.withOpacity(0.13)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.eco,
                        color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Animated Bookmark button
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                      CurvedAnimation(
                        parent: _bookmarkAnimationController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked
                            ? const Color(0xFFFFA000)
                            : Colors.grey.shade400,
                        size: 22,
                      ),
                      onPressed: () => _toggleBookmark(activity.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.teal, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      province,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (activity.isActive == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('เปิดรับสมัคร',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bookmarkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    checkAdminRole();
    _loadBookmarkedActivities();
    _loadLeaderboard();
  }

  Future<void> checkAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final adminEmails = ['admin@greenmarket.com', 'manager@greenmarket.com'];
      setState(() {
        isAdmin = adminEmails.contains(user.email) || user.uid == 'admin_uid';
      });
    }
  }

  // Load user's bookmarked activities
  Future<void> _loadBookmarkedActivities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user_bookmarks')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _bookmarkedActivities =
                Set<String>.from((data?['activities'] as List<dynamic>?) ?? []);
          });
        }
      } catch (e) {
        print('Error loading bookmarks: $e');
      }
    }
  }

  // Toggle bookmark with animation and haptic feedback
  Future<void> _toggleBookmark(String activityId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Haptic Feedback
    HapticFeedback.mediumImpact();

    // Trigger animation
    _bookmarkAnimationController.forward().then((_) {
      _bookmarkAnimationController.reverse();
    });

    setState(() {
      if (_bookmarkedActivities.contains(activityId)) {
        _bookmarkedActivities.remove(activityId);
      } else {
        _bookmarkedActivities.add(activityId);
      }
    });

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _bookmarkedActivities.contains(activityId)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _bookmarkedActivities.contains(activityId)
                    ? 'บันทึกกิจกรรมแล้ว'
                    : 'ยกเลิกการบันทึก',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      await FirebaseFirestore.instance
          .collection('user_bookmarks')
          .doc(user.uid)
          .set({
        'activities': _bookmarkedActivities.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving bookmark: $e');
    }
  }

  // Load real-time leaderboard
  Future<void> _loadLeaderboard() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('ecoCoins', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> leaders = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        leaders.add({
          'name': data['displayName'] ?? 'ผู้ใช้',
          'points': (data['ecoCoins'] ?? 0.0).toInt(),
          'badge': _getBadgeEmoji(leaders.length),
          'userId': doc.id,
        });
      }

      setState(() {
        _leaderboardUsers = leaders;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
    }
  }

  String _getBadgeEmoji(int index) {
    if (index == 0) return '🥇';
    if (index == 1) return '🥈';
    if (index == 2) return '🥉';
    return '🏅';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.groups, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'กิจกรรมเพื่อความยั่งยืน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ปุ่มแจ้งเตือนกิจกรรม
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'การแจ้งเตือนกิจกรรม',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityNotificationsScreen(),
                ),
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminApproveActivitiesScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'เกี่ยวกับกิจกรรม',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('กิจกรรมเพื่อความยั่งยืน'),
                  content: const Text(
                      'เข้าร่วมกิจกรรมเพื่อสังคมและสิ่งแวดล้อม พร้อมระบบ badge, leaderboard, และฟีเจอร์ใหม่ ๆ'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('สร้างกิจกรรมใหม่',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateActivityScreen(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // Tab Bar for Navigation
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF10B981),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF10B981),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              tabs: const [
                Tab(text: 'ทั้งหมด', icon: Icon(Icons.grid_view, size: 20)),
                Tab(text: 'ที่บันทึก', icon: Icon(Icons.bookmark, size: 20)),
                Tab(text: 'ของฉัน', icon: Icon(Icons.person, size: 20)),
              ],
            ),
          ),

          // Advanced Search & Filter Bar
          _buildSearchAndFilterBar(),

          // Main Content with TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All Activities
                _buildAllActivitiesTab(),

                // Tab 2: Bookmarked Activities
                _buildBookmarkedActivitiesTab(),

                // Tab 3: My Activities
                _buildMyActivitiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Premium Search & Filter Bar
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'ค้นหากิจกรรม...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF10B981),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'กำลังเปิด',
                  icon: Icons.check_circle,
                  isSelected: _showActiveOnly,
                  onTap: () {
                    setState(() {
                      _showActiveOnly = !_showActiveOnly;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'ที่บันทึกไว้',
                  icon: Icons.bookmark,
                  isSelected: false,
                  onTap: () {
                    // Navigate to bookmarked activities
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กิจกรรมที่บันทึกไว้'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildSortDropdown(),
                const SizedBox(width: 8),
                _buildProvinceDropdown(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      initialValue: _sortBy,
      onSelected: (value) {
        setState(() {
          _sortBy = value;
        });
      },
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              _getSortLabel(_sortBy),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade700),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'newest',
          child: Text('ใหม่สุด'),
        ),
        const PopupMenuItem(
          value: 'popular',
          child: Text('ยอดนิยม'),
        ),
        const PopupMenuItem(
          value: 'nearest',
          child: Text('ใกล้ฉัน'),
        ),
      ],
    );
  }

  Widget _buildProvinceDropdown() {
    final provinces = [
      'ทั้งหมด',
      'กรุงเทพมหานคร',
      'เชียงใหม่',
      'ภูเก็ต',
      'ขอนแก่น',
      'นครราชสีมา',
    ];

    return PopupMenuButton<String>(
      initialValue: _selectedProvince,
      onSelected: (value) {
        setState(() {
          _selectedProvince = value;
        });
      },
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              _selectedProvince,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade700),
          ],
        ),
      ),
      itemBuilder: (context) => provinces.map((province) {
        return PopupMenuItem(
          value: province,
          child: Text(province),
        );
      }).toList(),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'newest':
        return 'ใหม่สุด';
      case 'popular':
        return 'ยอดนิยม';
      case 'nearest':
        return 'ใกล้ฉัน';
      default:
        return 'เรียง';
    }
  }

  // Tab 1: All Activities Content
  Widget _buildAllActivitiesTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // Haptic feedback
        HapticFeedback.lightImpact();

        // Reload data
        await _loadLeaderboard();
        await _loadBookmarkedActivities();

        if (mounted) {
          setState(() {});
        }
      },
      color: const Color(0xFF10B981),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Onboarding Section
            Padding(
              padding: const EdgeInsets.only(
                  top: 18, left: 18, right: 18, bottom: 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('วิธีใช้งานโซนกิจกรรม'),
                        content: const Text(
                            '1. เข้าร่วมกิจกรรมเพื่อรับ badge และคะแนน\n2. แชร์ผลลัพธ์และไต่อันดับ leaderboard\n3. สร้างกิจกรรมใหม่เพื่อชุมชน'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ปิด'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info, color: AppColors.primaryTeal),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'แตะเพื่อดูวิธีใช้งานและสิทธิประโยชน์ของโซนกิจกรรมนี้!',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Hero Banner
            _buildHeroBanner(),

            // Real-time Leaderboard
            _buildLeaderboardSection(),

            // Featured Activities
            _buildFeaturedActivitiesSection(),

            // Statistics
            _buildStatisticsSection(),

            // Browse by Province
            _buildBrowseByProvinceSection(),

            // Activity Types
            _buildActivityTypesSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Tab 2: Bookmarked Activities with Pull-to-Refresh
  Widget _buildBookmarkedActivitiesTab() {
    if (_bookmarkedActivities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: 'ยังไม่มีกิจกรรมที่บันทึก',
        description:
            'บันทึกกิจกรรมที่สนใจเพื่อดูภายหลัง\nแตะไอคอนบุ๊กมาร์กเพื่อบันทึก',
        actionLabel: 'เรียกดูกิจกรรม',
        onActionPressed: () {
          HapticFeedback.selectionClick();
          _tabController.animateTo(0);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await _loadBookmarkedActivities();
        if (mounted) setState(() {});
      },
      color: const Color(0xFFFFA000),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .where(FieldPath.documentId,
                whereIn: _bookmarkedActivities.take(10).toList())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => _buildShimmerLoading(),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.bookmark_border,
              title: 'ไม่พบกิจกรรมที่บันทึก',
              description: 'กิจกรรมที่คุณบันทึกอาจถูกลบไปแล้ว',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              try {
                final activity = Activity.fromFirestore(docs[index]);
                return Hero(
                  tag: 'activity_${activity.id}',
                  child: _buildActivityListCard(activity),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  // Tab 3: My Activities with Pull-to-Refresh
  Widget _buildMyActivitiesTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: 'กรุณาเข้าสู่ระบบ',
        description: 'เข้าสู่ระบบเพื่อดูกิจกรรมของคุณ',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        if (mounted) setState(() {});
      },
      color: const Color(0xFF10B981),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .where('createdBy', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => _buildShimmerLoading(),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.add_circle_outline,
              title: 'ยังไม่มีกิจกรรมของคุณ',
              description:
                  'สร้างกิจกรรมใหม่เพื่อเชิญชวนคนอื่นๆ\nมาร่วมสร้างสังคมที่ยั่งยืนไปพร้อมกัน',
              actionLabel: 'สร้างกิจกรรมใหม่',
              onActionPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateActivityScreen(),
                  ),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              try {
                final activity = Activity.fromFirestore(docs[index]);
                return Hero(
                  tag: 'my_activity_${activity.id}',
                  child: _buildActivityListCard(activity),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: const Color(0xFF10B981).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.arrow_forward),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Shimmer Loading Effect
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Activity List Card for Tab 2 & 3
  Widget _buildActivityListCard(Activity activity,
      {bool isMyActivity = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to activity list
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityListScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  activity.province,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isMyActivity)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ของฉัน',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    if (!isMyActivity)
                      IconButton(
                        icon: Icon(
                          _bookmarkedActivities.contains(activity.id)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _bookmarkedActivities.contains(activity.id)
                              ? const Color(0xFFFFA000)
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                        onPressed: () => _toggleBookmark(activity.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (activity.isActive == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'เปิดรับสมัคร',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Extract sections as separate methods for cleaner code
  Widget _buildHeroBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF14B8A6), Color(0xFF10B981), Color(0xFF99F6E4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.15),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.volunteer_activism, size: 70, color: Colors.white),
                SizedBox(width: 18),
                Icon(Icons.emoji_events, size: 44, color: Colors.amberAccent),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'ร่วมสร้างโลกที่ยั่งยืน',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'เข้าร่วมกิจกรรมเพื่อสิ่งแวดล้อมและสังคม\nแชร์ผลลัพธ์ รับ badge และไต่อันดับ leaderboard',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF10B981),
                minimumSize: const Size(180, 44),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                elevation: 0,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              icon: const Icon(Icons.group_add, color: Color(0xFF10B981)),
              label: const Text('เข้าร่วมกิจกรรม'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedActivitiesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'กิจกรรมเด่น',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('activities')
                  .where('isFeatured', isEqualTo: true)
                  .where('isApproved', isEqualTo: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text('ยังไม่มีกิจกรรมเด่น',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, idx) {
                    try {
                      final activity = Activity.fromFirestore(docs[idx]);
                      return _buildFeaturedActivityCard(context, activity);
                    } catch (e) {
                      return Container(
                        width: 220,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: const Center(
                          child: Text('ข้อมูลกิจกรรมผิดพลาด',
                              style: TextStyle(color: Colors.red)),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .where('isApproved', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          int totalActivities = 0;
          int activeActivities = 0;
          int pendingActivities = 0;

          if (snapshot.hasData) {
            final activities = snapshot.data!.docs
                .map((doc) => Activity.fromFirestore(doc))
                .toList();

            totalActivities = activities.length;
            activeActivities =
                activities.where((a) => a.isActive == true).length;
            pendingActivities =
                activities.where((a) => a.isActive != true).length;
          }

          return Column(
            children: [
              const Text(
                'สถิติกิจกรรม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildStatCard('🌍', '$totalActivities', 'ทั้งหมด',
                      AppColors.primaryTeal),
                  buildStatCard('✅', '$activeActivities', 'กำลังเปิด',
                      const Color(0xFF10B981)),
                  buildStatCard('⏳', '$pendingActivities', 'รอเปิด',
                      const Color(0xFFF59E0B)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrowseByProvinceSection() {
    final provinces = [
      'กรุงเทพมหานคร',
      'เชียงใหม่',
      'ภูเก็ต',
      'ขอนแก่น',
      'นครราชสีมา',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'เลือกตามจังหวัด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provinces.map((p) => buildProvinceChip(p)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTypesSection() {
    final activityTypes = [
      {'name': 'ปลูกป่า', 'icon': '🌳', 'color': const Color(0xFF10B981)},
      {'name': 'ทำความสะอาด', 'icon': '🧹', 'color': const Color(0xFF0EA5E9)},
      {'name': 'รีไซเคิล', 'icon': '♻️', 'color': const Color(0xFF8B5CF6)},
      {'name': 'อนุรักษ์น้ำ', 'icon': '💧', 'color': const Color(0xFF06B6D4)},
      {'name': 'พลังงาน', 'icon': '⚡', 'color': const Color(0xFFF59E0B)},
      {'name': 'อื่นๆ', 'icon': '🌟', 'color': const Color(0xFFEC4899)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.category, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'ประเภทกิจกรรม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: activityTypes.length,
            itemBuilder: (context, index) {
              final type = activityTypes[index];
              return buildTypeCard(
                type['name'] as String,
                type['icon'] as String,
                type['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildStatCard(String emoji, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBrowseSection() {
    final popularProvinces = [
      'กรุงเทพมหานคร',
      'เชียงใหม่',
      'ภูเก็ต',
      'ขอนแก่น',
      'นครราชสีมา',
      'สงขลา'
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryTeal),
              SizedBox(width: 8),
              Text(
                'เลือกตามจังหวัด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularProvinces.map((province) {
              return buildProvinceChip(province);
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityListScreen(
                      title: 'เลือกจังหวัด',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('ดูทุกจังหวัด'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: const BorderSide(color: AppColors.primaryTeal),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTypeSection() {
    final activityTypes = [
      {'name': 'สิ่งแวดล้อม', 'icon': '🌱', 'color': Colors.green},
      {'name': 'สังคม', 'icon': '🤝', 'color': Colors.blue},
      {'name': 'การศึกษา', 'icon': '📚', 'color': Colors.orange},
      {'name': 'ชุมชน', 'icon': '🏘️', 'color': Colors.purple},
      {'name': 'อาสาสมัคร', 'icon': '💪', 'color': Colors.red},
      {'name': 'อื่นๆ', 'icon': '🌟', 'color': Colors.grey},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category, color: AppColors.primaryTeal),
              SizedBox(width: 8),
              Text(
                'เลือกตามประเภท',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: activityTypes.length,
            itemBuilder: (context, index) {
              final type = activityTypes[index];
              return buildTypeCard(
                type['name'] as String,
                type['icon'] as String,
                type['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildProvinceChip(String province) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityListScreen(
              province: province,
              title: 'กิจกรรมใน$province',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
        ),
        child: Text(
          province,
          style: const TextStyle(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget buildTypeCard(String name, String icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityListScreen(
                  activityType: name,
                  title: 'กิจกรรม$name',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
