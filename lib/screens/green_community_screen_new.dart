// lib/screens/green_community_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community_post.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card_widget.dart';
import '../screens/create_community_post_screen.dart';
import '../screens/community_profile_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/community_notifications_screen.dart';
import '../screens/community_chat_list_screen.dart';
import '../utils/community_sample_data.dart';

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
      body: Column(
        children: [
          // Header กับ Tab Bar
          _buildHeader(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const FeedScreen(), // ใช้ FeedScreen แทน
                _buildMyProfileTab(),
              ],
            ),
          ),
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
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ส่วนหัว
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ชุมชนสีเขียว',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'เชื่อมต่อและแบ่งปันร่วมกัน',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notifications Button
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CommunityNotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  // Chat Button
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
                      Icons.chat,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(text: 'ฟีด'),
                Tab(text: 'โปรไฟล์'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProfileTab() {
    return const CommunityProfileScreen();
  }
}
