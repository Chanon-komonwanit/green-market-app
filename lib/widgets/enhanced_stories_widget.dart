// lib/widgets/enhanced_stories_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';

/// Enhanced Stories Widget - แบบ Instagram Stories
/// พร้อม Stickers, Filters, และ Highlights
class EnhancedStoriesWidget extends StatelessWidget {
  final String currentUserId;

  const EnhancedStoriesWidget({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('expiresAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          final stories = snapshot.data?.docs ?? [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: stories.length + 1, // +1 for "Add Story"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryButton(context);
              }

              final story = stories[index - 1].data() as Map<String, dynamic>;
              final storyId = stories[index - 1].id;

              return _buildStoryAvatar(
                context,
                storyId,
                story,
                index - 1,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/create_story');
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[200]!,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'เพิ่ม Story',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(
    BuildContext context,
    String storyId,
    Map<String, dynamic> story,
    int index,
  ) {
    final userName = story['userName'] ?? 'User';
    final userPhoto = story['userPhoto'];
    final isViewed = _isStoryViewed(storyId, currentUserId);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/view_story',
          arguments: {
            'storyId': storyId,
            'story': story,
          },
        );
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[300]!],
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFFF58529),
                          Color(0xFFDD2A7B),
                          Color(0xFF8134AF),
                          Color(0xFF515BD4),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: userPhoto != null
                      ? Image.network(
                          userPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(userName);
                          },
                        )
                      : _buildDefaultAvatar(userName),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: TextStyle(
                fontSize: 12,
                color: isViewed ? Colors.grey : Colors.black87,
                fontWeight: isViewed ? FontWeight.normal : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String userName) {
    return Container(
      color: AppColors.primaryTeal,
      child: Center(
        child: Text(
          userName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _isStoryViewed(String storyId, String userId) {
    // TODO: Check if user has viewed this story
    return false;
  }
}
