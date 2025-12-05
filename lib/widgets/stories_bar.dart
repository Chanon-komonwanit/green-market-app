// lib/widgets/stories_bar.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/story.dart';
import '../utils/constants.dart';
import '../providers/user_provider.dart';
import 'story_viewer.dart';

class StoriesBar extends StatelessWidget {
  final String currentUserId;

  const StoriesBar({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('isActive', isEqualTo: true)
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('expiresAt', descending: false)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stories = snapshot.data!.docs
              .map((doc) =>
                  Story.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          // Group stories by user
          final Map<String, List<Story>> userStories = {};
          for (var story in stories) {
            if (!userStories.containsKey(story.userId)) {
              userStories[story.userId] = [];
            }
            userStories[story.userId]!.add(story);
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: userStories.length + 1, // +1 for "Add Story"
            itemBuilder: (context, index) {
              // First item: Add your story
              if (index == 0) {
                return _buildAddStoryCircle(context);
              }

              final userId = userStories.keys.elementAt(index - 1);
              final storiesForUser = userStories[userId]!;
              final hasUnviewed =
                  storiesForUser.any((s) => !s.isViewedBy(currentUserId));

              return _buildStoryCircle(
                context,
                storiesForUser.first,
                hasUnviewed,
                () => _viewStories(context, storiesForUser),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStoryCircle(BuildContext context) {
    return GestureDetector(
      onTap: () => _createStory(context),
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primaryTeal, AppColors.emeraldPrimary],
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'สร้าง Story',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCircle(
    BuildContext context,
    Story story,
    bool hasUnviewed,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryTeal,
                          AppColors.emeraldPrimary
                        ],
                      )
                    : null,
                border: hasUnviewed
                    ? null
                    : Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: story.userPhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(story.userPhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: story.userPhotoUrl == null
                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.userName,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createStory(BuildContext context) async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // Show dialog with caption input
    final caption = await showDialog<String>(
      context: context,
      builder: (context) => const _StoryCreationDialog(),
    );

    if (caption == null) return; // User cancelled

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );

    try {
      // Upload image to Storage
      final storageRef = FirebaseStorage.instance.ref().child(
          'stories/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(File(image.path));
      final imageUrl = await storageRef.getDownloadURL();

      // Create story document
      final story = Story(
        id: '',
        userId: user.id,
        userName: user.displayName ?? 'ผู้ใช้',
        userPhotoUrl: user.photoUrl,
        mediaUrl: imageUrl,
        mediaType: 'image',
        caption: caption.isNotEmpty ? caption : null,
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      );

      await FirebaseFirestore.instance.collection('stories').add(story.toMap());

      // Close loading
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ เพิ่ม Story สำเร็จ!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      // Close loading
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _viewStories(BuildContext context, List<Story> stories) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryViewer(
          stories: stories,
          onStoryViewed: (storyId) => _markStoryAsViewed(storyId),
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _markStoryAsViewed(String storyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .update({
        'viewedBy': FieldValue.arrayUnion([currentUserId]),
      });
    } catch (e) {
      debugPrint('Error marking story as viewed: $e');
    }
  }
}

class _StoryCreationDialog extends StatefulWidget {
  const _StoryCreationDialog();

  @override
  State<_StoryCreationDialog> createState() => _StoryCreationDialogState();
}

class _StoryCreationDialogState extends State<_StoryCreationDialog> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      title: const Text('สร้าง Story'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'เพิ่มคำบรรยาย (ถ้ามี)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide:
                    const BorderSide(color: AppColors.primaryTeal, width: 2),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('ยกเลิก', style: AppTextStyles.body),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _captionController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
          child: const Text('เผยแพร่'),
        ),
      ],
    );
  }
}
