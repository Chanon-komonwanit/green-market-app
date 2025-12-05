// lib/screens/saved_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/community_post.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card_widget.dart';
import '../utils/constants.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserProvider>().currentUser?.id;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('โพสต์ที่บันทึก'),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.grayPrimary,
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bookmark, color: AppColors.primaryTeal),
            const SizedBox(width: 8),
            const Text('โพสต์ที่บันทึก'),
          ],
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.grayPrimary,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .where('savedBy', arrayContains: currentUserId)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data?.docs ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: AppColors.graySecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ยังไม่มีโพสต์ที่บันทึก',
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.graySecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'กดที่ไอคอน 🔖 เพื่อบันทึกโพสต์ที่คุณชอบ',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.graySecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index].data() as Map<String, dynamic>;
              final post = CommunityPost.fromMap(postData, posts[index].id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PostCardWidget(post: post),
              );
            },
          );
        },
      ),
    );
  }
}
