// lib/screens/hashtag_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/community_post.dart';
import 'package:green_market/widgets/post_card_widget.dart';
import 'package:green_market/utils/constants.dart';

/// Hashtag Feed Screen - แสดงโพสต์ที่มีแฮชแท็กเฉพาะ
/// แบบ Twitter/Instagram hashtag feed
class HashtagFeedScreen extends StatefulWidget {
  final String hashtag;

  const HashtagFeedScreen({super.key, required this.hashtag});

  @override
  State<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  String _selectedFilter = 'recent'; // recent, popular, week

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
        title: Text(
          '#${widget.hashtag}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats header
          _buildStatsHeader(),

          // Filter chips
          _buildFilterChips(),

          // Posts list
          Expanded(
            child: _buildPostsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Hashtag icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryTeal, AppColors.accentGreen],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tag,
              size: 32,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          // Post count
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_posts')
                .where('tags', arrayContains: widget.hashtag)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Column(
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Text(
                    'โพสต์',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Follow button (future feature)
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ฟีเจอร์ติดตามแฮชแท็กกำลังพัฒนา'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('ติดตามแฮชแท็ก'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: const BorderSide(color: AppColors.primaryTeal),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'ล่าสุด',
            value: 'recent',
            icon: Icons.access_time,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'ยอดนิยม',
            value: 'popular',
            icon: Icons.local_fire_department,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'สัปดาห์นี้',
            value: 'week',
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.primaryTeal, AppColors.accentGreen],
                )
              : null,
          color: isSelected ? null : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(20),
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
              size: 16,
              color: isSelected ? Colors.white : AppColors.graySecondary,
            ),
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

  Widget _buildPostsList() {
    Query query = FirebaseFirestore.instance
        .collection('community_posts')
        .where('tags', arrayContains: widget.hashtag)
        .where('isActive', isEqualTo: true);

    // Apply sorting based on filter
    switch (_selectedFilter) {
      case 'recent':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'popular':
        // Sort by likes count (requires composite index)
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'week':
        // Filter last 7 days
        final weekAgo = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)),
        );
        query = query
            .where('createdAt', isGreaterThan: weekAgo)
            .orderBy('createdAt', descending: true);
        break;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'เกิดข้อผิดพลาด',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'ยังไม่มีโพสต์',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เป็นคนแรกที่โพสต์ #${widget.hashtag}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        var posts = snapshot.data!.docs;

        // Client-side sorting for popular (since we can't have composite index yet)
        if (_selectedFilter == 'popular') {
          posts = posts.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              final aLikes = (aData['likes'] as List?)?.length ?? 0;
              final bLikes = (bData['likes'] as List?)?.length ?? 0;

              return bLikes.compareTo(aLikes);
            });
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index].data() as Map<String, dynamic>;
            final post = CommunityPost.fromMap(postData, posts[index].id);

            return PostCardWidget(
              post: post,
              onLike: () => setState(() {}),
            );
          },
        );
      },
    );
  }
}
