// lib/screens/green_community_screen.dart
import 'package:flutter/material.dart';
import '../screens/create_community_post_screen.dart';
import '../screens/community_profile_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/community_notifications_screen.dart';
import '../screens/community_chat_list_screen.dart';
import '../utils/constants.dart';

class GreenCommunityScreen extends StatefulWidget {
  const GreenCommunityScreen({super.key});

  @override
  State<GreenCommunityScreen> createState() => _GreenCommunityScreenState();
}

class _GreenCommunityScreenState extends State<GreenCommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        title: Text('ชุมชนสีเขียว', style: AppTextStyles.headline),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityNotificationsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.graySecondary,
            ),
            tooltip: 'การแจ้งเตือน',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityChatListScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.graySecondary,
            ),
            tooltip: 'ข้อความ',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryTeal,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.graySecondary,
          labelStyle: AppTextStyles.bodyBold,
          tabs: const [
            Tab(text: 'ฟีด'),
            Tab(text: 'โปรไฟล์'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FeedScreen(),
          CommunityProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCommunityPostScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
