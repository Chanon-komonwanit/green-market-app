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
        elevation: 2,
        title: Row(
          children: [
            Icon(Icons.eco, color: AppColors.primaryTeal, size: 28),
            const SizedBox(width: 8),
            Text('ชุมชนสีเขียว', style: AppTextStyles.headline.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: AppColors.primaryTeal, size: 18),
                  const SizedBox(width: 4),
                  Text('สมาชิก 1,234', style: AppTextStyles.captionBold.copyWith(color: AppColors.primaryTeal)),
                ],
              ),
            ),
          ],
        ),
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
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryTeal),
            tooltip: 'การแจ้งเตือน',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาโพสต์หรือเพื่อนในชุมชน...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.graySecondary),
                    filled: true,
                    fillColor: AppColors.surfaceGray,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {}, // TODO: implement search logic
                ),
              ),
              TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(colors: const [AppColors.primaryTeal, AppColors.emeraldPrimary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.graySecondary,
                labelStyle: AppTextStyles.bodyBold,
                tabs: const [
                  Tab(text: 'ฟีด'),
                  Tab(text: 'โปรไฟล์'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ฟีดโพสต์ + ปุ่มแชทใหม่
          Stack(
            children: [
              const FeedScreen(),
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton.extended(
                  heroTag: 'chat',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommunityChatListScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.infoBlue,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.forum_rounded),
                  label: const Text('แชทใหม่'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
              ),
            ],
          ),
          const CommunityProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'post',
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
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('สร้างโพสต์ใหม่'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
    );
