// lib/screens/trending_topics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/modern_animations.dart';

/// Full Trending Topics Screen - แสดงหัวข้อยอดนิยมทั้งหมด
class TrendingTopicsScreen extends StatefulWidget {
  const TrendingTopicsScreen({super.key});

  @override
  State<TrendingTopicsScreen> createState() => _TrendingTopicsScreenState();
}

class _TrendingTopicsScreenState extends State<TrendingTopicsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🔥 กำลังฮิต',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                // Period selection handled by TabController
              },
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryTeal, AppColors.accentGreen],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: '24 ชม.'),
                Tab(text: '7 วัน'),
                Tab(text: '30 วัน'),
                Tab(text: 'ทั้งหมด'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendingList('24h'),
          _buildTrendingList('7days'),
          _buildTrendingList('30days'),
          _buildTrendingList('alltime'),
        ],
      ),
    );
  }

  Widget _buildTrendingList(String period) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTrendingStream(period),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final trendingData = _processTrendingData(snapshot.data!.docs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trendingData.length,
          itemBuilder: (context, index) {
            return FadeInAnimation(
              delay: Duration(milliseconds: index * 50),
              child: _buildTrendingCard(
                context,
                index + 1,
                trendingData[index],
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getTrendingStream(String period) {
    DateTime startDate;

    switch (period) {
      case '24h':
        startDate = DateTime.now().subtract(const Duration(hours: 24));
        break;
      case '7days':
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case '30days':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case 'alltime':
      default:
        startDate = DateTime(2020); // Far past date
        break;
    }

    return FirebaseFirestore.instance
        .collection('community_posts')
        .where('isActive', isEqualTo: true)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots();
  }

  List<Map<String, dynamic>> _processTrendingData(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, Map<String, dynamic>> hashtagData = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final tags = List<String>.from(data['tags'] ?? []);
      final likes = (data['likes'] as List?)?.length ?? 0;
      final comments = data['commentCount'] ?? 0;
      final shares = data['shareCount'] ?? 0;

      final engagement = likes + (comments * 2) + (shares * 3);

      for (final tag in tags) {
        final cleanTag = tag.toLowerCase().trim();
        if (cleanTag.isNotEmpty) {
          if (!hashtagData.containsKey(cleanTag)) {
            hashtagData[cleanTag] = {
              'tag': cleanTag,
              'postCount': 0,
              'totalEngagement': 0,
              'recentPosts': <String>[],
            };
          }

          hashtagData[cleanTag]!['postCount'] =
              (hashtagData[cleanTag]!['postCount'] as int) + 1;
          hashtagData[cleanTag]!['totalEngagement'] =
              (hashtagData[cleanTag]!['totalEngagement'] as int) + engagement;

          // Store recent post IDs (max 3)
          final recentPosts =
              hashtagData[cleanTag]!['recentPosts'] as List<String>;
          if (recentPosts.length < 3) {
            recentPosts.add(doc.id);
          }
        }
      }
    }

    // Convert to list and sort
    final trendingList = hashtagData.values.toList();
    trendingList.sort((a, b) {
      final scoreA =
          (a['postCount'] as int) * 10 + (a['totalEngagement'] as int);
      final scoreB =
          (b['postCount'] as int) * 10 + (b['totalEngagement'] as int);
      return scoreB.compareTo(scoreA);
    });

    return trendingList;
  }

  Widget _buildTrendingCard(
    BuildContext context,
    int rank,
    Map<String, dynamic> data,
  ) {
    final tag = data['tag'] as String;
    final postCount = data['postCount'] as int;
    final engagement = data['totalEngagement'] as int;

    final trendColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey[400]
            : rank == 3
                ? Colors.brown[300]
                : AppColors.primaryTeal;

    final isTopThree = rank <= 3;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/hashtag_feed',
          arguments: tag,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isTopThree
              ? Border.all(color: trendColor!.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isTopThree
                    ? LinearGradient(
                        colors: [trendColor!, trendColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [AppColors.primaryTeal, AppColors.accentGreen],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  if (isTopThree)
                    BoxShadow(
                      color: trendColor!.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Center(
                child: isTopThree
                    ? Text(
                        rank == 1
                            ? '🥇'
                            : rank == 2
                                ? '🥈'
                                : '🥉',
                        style: const TextStyle(fontSize: 24),
                      )
                    : Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Hashtag Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '#',
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.article_outlined,
                        '$postCount โพสต์',
                        AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.favorite,
                        _formatEngagement(engagement),
                        Colors.red[400]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primaryTeal,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีหัวข้อยอดนิยม',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ลองเปลี่ยนช่วงเวลาดูสิ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEngagement(int engagement) {
    if (engagement >= 1000000) {
      return '${(engagement / 1000000).toStringAsFixed(1)}M';
    } else if (engagement >= 1000) {
      return '${(engagement / 1000).toStringAsFixed(1)}K';
    }
    return '$engagement';
  }
}
