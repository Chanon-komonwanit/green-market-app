// lib/screens/green_community_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community_post.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card_widget.dart';
import '../screens/create_community_post_screen.dart';
import '../screens/community_profile_screen.dart';
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
              children: [_buildFeedTab(), _buildMyProfileTab()],
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
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'แบ่งปันไอเดียเพื่อโลกที่ยั่งยืน',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // ปุ่มโปรไฟล์
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final user = userProvider.currentUser;
                      return GestureDetector(
                        onTap: () {
                          if (user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CommunityProfileScreen(userId: user.id),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'ฟีดข่าว', icon: Icon(Icons.feed, size: 20)),
                  Tab(
                    text: 'โปรไฟล์ของฉัน',
                    icon: Icon(Icons.person, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.value(
          CommunitySampleData.getSamplePosts(),
        ), // ใช้ sample data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ไม่สามารถโหลดข้อมูลได้',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return _buildEmptyFeedState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            color: const Color(0xFF2E7D32),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index];
                final post = CommunityPost.fromMap(postData, postData['id']);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: PostCardWidget(
                    post: post,
                    onTap: () {
                      // TODO: Navigate to post detail
                    },
                    onLike: () {
                      // TODO: Toggle like
                    },
                    onComment: () {
                      // TODO: Open comments
                    },
                    onShare: () {
                      // TODO: Share post
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyProfileTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) {
          return const Center(child: Text('กรุณาเข้าสู่ระบบ'));
        }

        return CommunityProfileScreen(userId: user.id);
      },
    );
  }

  Widget _buildEmptyFeedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, size: 60, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 24),
            const Text(
              'ยังไม่มีโพสต์ในชุมชน',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เป็นคนแรกที่แบ่งปันเรื่องราวดีๆ\nเพื่อสิ่งแวดล้อมกันเถอะ!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCommunityPostScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'สร้างโพสต์แรก',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
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
      ),
    );
  }
}
