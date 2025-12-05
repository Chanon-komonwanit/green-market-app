// lib/screens/community_leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../screens/community_profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// Enhanced Community Leaderboard Screen
/// แสดง ranking ผู้ใช้แบบ Weekly/Monthly/All-time
/// พร้อม category: Posts, Eco Coins, Activities
class CommunityLeaderboardScreen extends StatefulWidget {
  const CommunityLeaderboardScreen({super.key});

  @override
  State<CommunityLeaderboardScreen> createState() =>
      _CommunityLeaderboardScreenState();
}

class _CommunityLeaderboardScreenState extends State<CommunityLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Time period: weekly, monthly, all-time
  String _timePeriod = 'weekly';

  // Category: posts, ecoCoins, activities
  String _category = 'ecoCoins';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_timePeriod) {
      case 'weekly':
        return now.subtract(Duration(days: now.weekday - 1)); // Start of week
      case 'monthly':
        return DateTime(now.year, now.month, 1); // Start of month
      case 'all-time':
      default:
        return DateTime(2020, 1, 1); // App launch date
    }
  }

  Stream<List<LeaderboardEntry>> _getLeaderboardStream() {
    final startDate = _getStartDate();

    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
      List<LeaderboardEntry> entries = [];

      for (var doc in snapshot.docs) {
        try {
          final userData = doc.data();
          final userId = doc.id;

          // Calculate score based on category
          int score = 0;
          int streak = 0;

          switch (_category) {
            case 'posts':
              // Count posts in time period
              final postsSnapshot = await FirebaseFirestore.instance
                  .collection('community_posts')
                  .where('userId', isEqualTo: userId)
                  .where('createdAt', isGreaterThanOrEqualTo: startDate)
                  .where('isActive', isEqualTo: true)
                  .get();
              score = postsSnapshot.docs.length;
              break;

            case 'ecoCoins':
              score = userData['ecoCoins'] ?? 0;
              break;

            case 'activities':
              // Count activity participations
              final activitiesSnapshot = await FirebaseFirestore.instance
                  .collection('activity_participants')
                  .where('userId', isEqualTo: userId)
                  .where('joinedAt', isGreaterThanOrEqualTo: startDate)
                  .get();
              score = activitiesSnapshot.docs.length;
              break;
          }

          // Calculate streak (consecutive days with posts)
          streak = await _calculateStreak(userId);

          if (score > 0) {
            entries.add(LeaderboardEntry(
              userId: userId,
              displayName: userData['displayName'] ?? 'Unknown',
              photoUrl: userData['photoUrl'],
              score: score,
              streak: streak,
            ));
          }
        } catch (e) {
          debugPrint('Error processing user ${doc.id}: $e');
        }
      }

      // Sort by score descending
      entries.sort((a, b) => b.score.compareTo(a.score));

      // Add rank
      for (int i = 0; i < entries.length; i++) {
        entries[i].rank = i + 1;
      }

      return entries.take(50).toList(); // Top 50
    });
  }

  Future<int> _calculateStreak(String userId) async {
    try {
      final now = DateTime.now();
      int streak = 0;
      DateTime checkDate = DateTime(now.year, now.month, now.day);

      // Check last 30 days
      for (int i = 0; i < 30; i++) {
        final startOfDay = checkDate;
        final endOfDay = checkDate.add(const Duration(days: 1));

        final snapshot = await FirebaseFirestore.instance
            .collection('community_posts')
            .where('userId', isEqualTo: userId)
            .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
            .where('createdAt', isLessThan: endOfDay)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          streak++;
        } else {
          // Streak broken
          break;
        }

        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      return streak;
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }

  String _getCategoryLabel() {
    switch (_category) {
      case 'posts':
        return 'โพสต์';
      case 'ecoCoins':
        return 'เหรียญอีโค';
      case 'activities':
        return 'กิจกรรม';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserProvider>().currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 กระดานผู้นำ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Time Period Tabs
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  setState(() {
                    switch (index) {
                      case 0:
                        _timePeriod = 'weekly';
                        break;
                      case 1:
                        _timePeriod = 'monthly';
                        break;
                      case 2:
                        _timePeriod = 'all-time';
                        break;
                    }
                  });
                },
                tabs: const [
                  Tab(text: 'สัปดาห์'),
                  Tab(text: 'เดือน'),
                  Tab(text: 'ตลอดกาล'),
                ],
              ),

              // Category Selector
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryButton('ecoCoins', '🪙 เหรียญ'),
                    _buildCategoryButton('posts', '📝 โพสต์'),
                    _buildCategoryButton('activities', '🎯 กิจกรรม'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<LeaderboardEntry>>(
        stream: _getLeaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                ],
              ),
            );
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 64, color: AppColors.graySecondary),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีข้อมูลกระดานผู้นำ',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.graySecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เริ่มโพสต์หรือทำกิจกรรมเพื่อขึ้นอันดับ!',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrentUser = entry.userId == currentUserId;

              return _buildLeaderboardCard(entry, isCurrentUser);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryButton(String category, String label) {
    final isSelected = _category == category;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _category = category;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? AppColors.primaryTeal : AppColors.surfaceGray,
        foregroundColor: isSelected ? Colors.white : AppColors.grayPrimary,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, bool isCurrentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentUser ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser
            ? BorderSide(color: AppColors.primaryTeal, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CommunityProfileScreen(userId: entry.userId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank Badge
              _buildRankBadge(entry.rank),

              const SizedBox(width: 16),

              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundImage: entry.photoUrl != null
                    ? CachedNetworkImageProvider(entry.photoUrl!)
                    : null,
                child: entry.photoUrl == null
                    ? Text(
                        entry.displayName.isNotEmpty
                            ? entry.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.displayName,
                            style: AppTextStyles.bodyBold.copyWith(
                              color:
                                  isCurrentUser ? AppColors.primaryTeal : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.person,
                              size: 16, color: AppColors.primaryTeal),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.emoji_events,
                            size: 14, color: AppColors.warningAmber),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.score} ${_getCategoryLabel()}',
                          style: AppTextStyles.caption,
                        ),
                        if (entry.streak > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.local_fire_department,
                              size: 14, color: AppColors.errorRed),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.streak} วัน',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.errorRed),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    Color textColor;
    String rankText;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Gold
      textColor = Colors.white;
      rankText = '🥇';
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Silver
      textColor = Colors.white;
      rankText = '🥈';
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // Bronze
      textColor = Colors.white;
      rankText = '🥉';
    } else {
      badgeColor = AppColors.surfaceGray;
      textColor = AppColors.grayPrimary;
      rankText = '#$rank';
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: badgeColor.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          rankText,
          style: TextStyle(
            fontSize: rank <= 3 ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// Leaderboard Entry Model
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int score;
  final int streak;
  int rank;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.score,
    required this.streak,
    this.rank = 0,
  });
}
