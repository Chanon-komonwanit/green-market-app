// lib/screens/green_community_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import '../utils/constants.dart';
// import '../utils/app_text_styles.dart' as app_text_styles;
import 'create_community_post_screen.dart';
import 'feed_screen.dart';
import 'community_profile_screen.dart';
import 'community_notifications_screen.dart';
import 'community_chat_list_screen.dart';
import '../widgets/community_quick_actions.dart';
import 'eco_challenges_screen.dart';

class GreenCommunityScreen extends StatefulWidget {
  const GreenCommunityScreen({super.key});

  @override
  State<GreenCommunityScreen> createState() => _GreenCommunityScreenState();
}

class _GreenCommunityScreenState extends State<GreenCommunityScreen>
    with SingleTickerProviderStateMixin {
  String _searchKeyword = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        backgroundColor: AppColors.white,
        elevation: 2,
        title: Row(
          children: [
            Icon(Icons.eco, color: AppColors.primaryTeal, size: 28),
            SizedBox(width: 8),
            Text(
              'ชุมชนสีเขียว',
              style: AppTextStyles.headline.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            // Real-time member count from Firebase
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                final memberCount = snapshot.data?.docs.length ?? 0;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        color: AppColors.primaryTeal,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'สมาชิก ${memberCount.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            )}',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EcoChallengesScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.emoji_events,
              color: AppColors.primaryTeal,
            ),
            tooltip: 'Eco Challenges',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityNotificationsScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.primaryTeal,
            ),
            tooltip: 'การแจ้งเตือน',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาโพสต์หรือเพื่อนในชุมชน...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.graySecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceGray,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchKeyword = value.trim();
                    });
                  },
                ),
              ),
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  // Tab index handled by TabController
                },
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryTeal, AppColors.emeraldPrimary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.graySecondary,
                labelStyle: AppTextStyles.bodyBold,
                tabs: [
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
          FeedScreen(searchKeyword: _searchKeyword),
          CommunityProfileScreen(hideCreatePostButton: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_post',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateCommunityPostScreen(),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}
