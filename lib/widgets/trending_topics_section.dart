// lib/widgets/trending_topics_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';

/// Trending Topics & Hashtags Widget - แบบ Twitter/Instagram
class TrendingTopicsSection extends StatelessWidget {
  const TrendingTopicsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryTeal, AppColors.accentGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '🔥 กำลังฮิตในชุมชน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trending Hashtags Stream
          StreamBuilder<QuerySnapshot>(
            stream: _getTrendingHashtags(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildShimmerLoading();
              }

              final hashtagData = _processTrendingData(snapshot.data!.docs);

              if (hashtagData.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: List.generate(
                  hashtagData.length > 5 ? 5 : hashtagData.length,
                  (index) => _buildTrendingItem(
                    context,
                    index + 1,
                    hashtagData[index],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // View All Button
          InkWell(
            onTap: () {
              // Navigate to full trending page
              Navigator.pushNamed(context, '/trending_topics');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ดูทั้งหมด',
                    style: TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primaryTeal,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get trending hashtags from Firestore
  Stream<QuerySnapshot> _getTrendingHashtags() {
    // ดึงโพสต์ที่มี tags ในช่วง 7 วันล่าสุด
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return FirebaseFirestore.instance
        .collection('community_posts')
        .where('isActive', isEqualTo: true)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  /// Process trending data - count hashtags and sort by frequency
  List<Map<String, dynamic>> _processTrendingData(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, int> hashtagCount = {};
    final Map<String, int> hashtagEngagement = {};

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
          hashtagCount[cleanTag] = (hashtagCount[cleanTag] ?? 0) + 1;
          hashtagEngagement[cleanTag] =
              ((hashtagEngagement[cleanTag] ?? 0) + engagement).toInt();
        }
      }
    }

    // สร้าง list และเรียงตาม engagement score
    final trendingList = hashtagCount.entries.map((entry) {
      final tag = entry.key;
      final postCount = entry.value;
      final engagement = hashtagEngagement[tag] ?? 0;

      return {
        'tag': tag,
        'postCount': postCount,
        'engagement': engagement,
        'score': postCount * 10 + engagement, // Scoring algorithm
      };
    }).toList();

    trendingList
        .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return trendingList;
  }

  /// Build trending item card
  Widget _buildTrendingItem(
    BuildContext context,
    int rank,
    Map<String, dynamic> data,
  ) {
    final tag = data['tag'] as String;
    final postCount = data['postCount'] as int;
    final engagement = data['engagement'] as int;

    // Determine trend icon and color
    final trendColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey[400]
            : rank == 3
                ? Colors.brown[300]
                : AppColors.primaryTeal;

    return InkWell(
      onTap: () {
        // Navigate to hashtag feed
        Navigator.pushNamed(
          context,
          '/hashtag_feed',
          arguments: tag,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                rank <= 3 ? trendColor!.withOpacity(0.3) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: trendColor,
                shape: BoxShape.circle,
                boxShadow: [
                  if (rank <= 3)
                    BoxShadow(
                      color: trendColor!.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$postCount โพสต์',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatEngagement(engagement),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trending Arrow
            Icon(
              Icons.trending_up,
              color: trendColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีหัวข้อยอดนิยม',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
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
