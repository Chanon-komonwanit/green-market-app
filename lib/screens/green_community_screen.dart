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

import '../utils/constants.dart';
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
      backgroundColor: const Color(0xFFF6FBF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FCFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A13B98A),
                      blurRadius: 18,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    FeedScreen(),
                    CommunityProfileScreen(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 68,
        width: 68,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF13B98A), Color(0xFF5EEAD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withOpacity(0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCommunityPostScreen(),
                ),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
            splashColor: AppColors.primaryTeal.withOpacity(0.18),
            highlightElevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Improved header with better contrast, more readable tab bar, and modern look
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF13B98A), Color(0xFF5EEAD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A13B98A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // โลโก้/ไอคอนเด่น (เปลี่ยนเป็นคนหลายคน, สไตล์เรียบ)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: Colors.white.withOpacity(0.93),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 18),
                  // ชื่อ/คำโปรย
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ชุมชนสีเขียว',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.6,
                            shadows: [
                              Shadow(
                                color: Color(0x3313B98A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'แชร์เรื่องราวดีๆ สู่สังคมสีเขียว',
                          style: TextStyle(
                            fontSize: 15.5,
                            color: Color(0xE6FFFFFF),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.22,
                            shadows: [
                              Shadow(
                                color: Color(0x2213B98A),
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action: Notification
                  _buildHeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CommunityNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 7),
                  // Action: Chat
                  _buildHeaderIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunityChatListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Tab Bar - improved for contrast and readability
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF6FBF9), Color(0xFFE0F2F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withOpacity(0.13),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: const Color(0xFF0D5C4B),
                  unselectedLabelColor: Colors.white.withOpacity(0.92),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17.5,
                    letterSpacing: 0.1,
                    shadows: [
                      Shadow(
                        color: Color(0x3313B98A),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.5,
                    letterSpacing: 0.1,
                    shadows: [
                      Shadow(
                        color: Color(0x2213B98A),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  tabs: const [
                    Tab(text: 'ฟีด'),
                    Tab(text: 'โปรไฟล์'),
                  ],
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.16),
                AppColors.primaryTeal.withOpacity(0.22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withOpacity(0.13),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppColors.primaryTeal.withOpacity(0.22),
              width: 1.3,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  // Widget _buildMyProfileTab() {
  //   return const CommunityProfileScreen();
  // }
// End of GreenCommunityScreen// End of GreenCommunityScreen
}
