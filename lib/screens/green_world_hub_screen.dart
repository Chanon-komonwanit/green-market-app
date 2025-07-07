// lib/screens/green_world_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/green_activity.dart';
import 'package:green_market/models/green_investment.dart';
import 'package:green_market/screens/investment_hub_screen.dart';
import 'package:green_market/screens/sustainable_activities_hub_screen.dart';
import 'package:green_market/screens/community_forum_screen.dart';
import 'package:green_market/screens/feed_screen.dart';
import 'package:green_market/screens/eco_challenges_screen.dart';
import 'package:green_market/widgets/debug_panel.dart';

class GreenWorldHubScreen extends StatefulWidget {
  const GreenWorldHubScreen({super.key});

  @override
  State<GreenWorldHubScreen> createState() => _GreenWorldHubScreenState();
}

class _GreenWorldHubScreenState extends State<GreenWorldHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF059669),
                  Color(0xFF10B981),
                  Color(0xFFF8FAF9),
                ],
                stops: [0.0, 0.3, 1.0],
              ),
            ),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: CustomScrollView(
                        slivers: [
                          // Enhanced App Bar
                          SliverAppBar(
                            expandedHeight: 200,
                            floating: false,
                            pinned: true,
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            flexibleSpace: FlexibleSpaceBar(
                              background: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF059669),
                                      Color(0xFF10B981),
                                      Color(0xFF34D399),
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Animated Background Elements
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: TweenAnimationBuilder<double>(
                                        duration: const Duration(seconds: 3),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Transform.rotate(
                                            angle: value * 2 * 3.14159,
                                            child: Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white
                                                    .withOpacity(0.1),
                                              ),
                                              child: const Icon(
                                                Icons.eco,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Main Content
                                    Positioned(
                                      bottom: 30,
                                      left: 20,
                                      right: 20,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.public,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '🌍 ชุมชนสีเขียว',
                                                      style: TextStyle(
                                                        fontSize: 28,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white,
                                                        letterSpacing: 1.2,
                                                        shadows: [
                                                          Shadow(
                                                            color: Color(
                                                                0x40000000),
                                                            blurRadius: 4,
                                                            offset:
                                                                Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Green Community Hub',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'เชื่อมต่อ แบ่งปัน และสร้างผลกระทบเชิงบวกร่วมกัน',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Main Content
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // User Stats Card
                                  if (currentUser != null)
                                    _buildUserStatsCard(currentUser),
                                  const SizedBox(height: 20),

                                  // Quick Actions Grid
                                  _buildQuickActionsGrid(context),
                                  const SizedBox(height: 30),

                                  // Featured Activities
                                  _buildFeaturedActivities(),
                                  const SizedBox(height: 30),

                                  // Community Stats
                                  _buildCommunityStats(),
                                  const SizedBox(height: 30),
                                  // Latest Updates
                                  _buildLatestUpdates(),
                                  const SizedBox(height: 30),

                                  // Debug Panel (Development Only)
                                  const DebugPanel(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserStatsCard(dynamic currentUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Color(0xFFFFD700),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB8860B),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดี ${currentUser.displayName ?? "สมาชิก"}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Eco Level: ${_getUserEcoLevel(currentUser.ecoCoins ?? 0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '🪙 ${(currentUser.ecoCoins ?? 0).toStringAsFixed(1)}',
                  'Eco Coins',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  '🌱 ${_calculateCarbonOffset(currentUser.ecoCoins ?? 0)}',
                  'CO₂ Offset (kg)',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  '🏆 ${_getUserRank(currentUser.ecoCoins ?? 0)}',
                  'Rank',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Quick Actions Grid
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การกระทำด่วน',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildQuickActionCard(
              icon: Icons.forum,
              title: 'ฟีดชุมชน',
              subtitle: 'ดูโพสต์และแบ่งปัน',
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              ),
              onTap: () => _navigateToFeed(context),
            ),
            _buildQuickActionCard(
              icon: Icons.emoji_events,
              title: 'ความท้าทาย',
              subtitle: 'ลองท้าทายตัวเอง',
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              ),
              onTap: () => _navigateToChallenges(context),
            ),
            _buildQuickActionCard(
              icon: Icons.trending_up,
              title: 'การลงทุน',
              subtitle: 'ลงทุนเพื่อสิ่งแวดล้อม',
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              onTap: () => _navigateToInvestment(context),
            ),
            _buildQuickActionCard(
              icon: Icons.volunteer_activism,
              title: 'กิจกรรม',
              subtitle: 'ร่วมกิจกรรมสีเขียว',
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              onTap: () => _navigateToActivities(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Featured Activities
  Widget _buildFeaturedActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'กิจกรรมแนะนำ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _navigateToActivities(context),
              child: const Text(
                'ดูทั้งหมด',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('green_activities')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorCard('เกิดข้อผิดพลาดในการโหลดกิจกรรม');
            }

            final activities = snapshot.data?.docs ?? [];

            if (activities.isEmpty) {
              return _buildEmptyStateCard(
                icon: Icons.eco,
                title: 'ยังไม่มีกิจกรรม',
                subtitle: 'กิจกรรมใหม่จะมาเร็วๆ นี้',
              );
            }

            return Column(
              children: activities
                  .map((doc) => _buildActivityCard(
                      doc.data() as Map<String, dynamic>, doc.id))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, String activityId) {
    return InkWell(
      onTap: () => _showActivityDetails(activity, activityId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF059669).withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'] ?? 'กิจกรรมสีเขียว',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['description'] ?? 'รายละเอียดกิจกรรม',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(activity['startDate']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.people,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${activity['participantCount'] ?? 0} คน',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activity['ecoCoinsReward'] ?? 0} เหรียญ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Community Stats
  Widget _buildCommunityStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'สถิติชุมชน',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              final userCount = snapshot.data?.docs.length ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: _buildCommunityStatItem(
                      '👥',
                      userCount.toString(),
                      'สมาชิก',
                    ),
                  ),
                  Expanded(
                    child: _buildCommunityStatItem(
                      '🌱',
                      '${(userCount * 2.5).toInt()}',
                      'กิจกรรมที่เสร็จ',
                    ),
                  ),
                  Expanded(
                    child: _buildCommunityStatItem(
                      '🌍',
                      '${(userCount * 15.7).toStringAsFixed(1)} ตัน',
                      'CO₂ ที่ลดได้',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Latest Updates
  Widget _buildLatestUpdates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'อัปเดตล่าสุด',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_updates')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                ),
              );
            }

            final updates = snapshot.data?.docs ?? [];

            if (updates.isEmpty) {
              return _buildEmptyStateCard(
                icon: Icons.update,
                title: 'ยังไม่มีอัปเดต',
                subtitle: 'ข่าวสารใหม่จะมาเร็วๆ นี้',
              );
            }

            return Column(
              children: updates
                  .map((doc) =>
                      _buildUpdateCard(doc.data() as Map<String, dynamic>))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getUpdateIcon(update['type'] ?? 'general'),
              color: const Color(0xFF059669),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update['title'] ?? 'อัปเดต',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  update['description'] ?? 'รายละเอียด',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatDate(update['createdAt']),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation Methods
  void _navigateToFeed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeedScreen(),
      ),
    );
  }

  void _navigateToChallenges(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EcoChallengesScreen(),
      ),
    );
  }

  void _navigateToInvestment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvestmentHubScreen(),
      ),
    );
  }

  void _navigateToActivities(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SustainableActivitiesHubScreen(),
      ),
    );
  }

  // Helper Methods
  String _getUserEcoLevel(double ecoCoins) {
    if (ecoCoins >= 1000) return 'Legend';
    if (ecoCoins >= 500) return 'Master';
    if (ecoCoins >= 200) return 'Hero';
    if (ecoCoins >= 50) return 'Friend';
    return 'Beginner';
  }

  String _calculateCarbonOffset(double ecoCoins) {
    return (ecoCoins * 0.5).toStringAsFixed(1);
  }

  String _getUserRank(double ecoCoins) {
    if (ecoCoins >= 1000) return '#1-50';
    if (ecoCoins >= 500) return '#51-200';
    if (ecoCoins >= 200) return '#201-500';
    if (ecoCoins >= 50) return '#501-1000';
    return '#1000+';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'วันที่ไม่ระบุ';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'วันที่ไม่ระบุ';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} วันที่แล้ว';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ชั่วโมงที่แล้ว';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} นาทีที่แล้ว';
      } else {
        return 'เมื่อสักครู่';
      }
    } catch (e) {
      return 'วันที่ไม่ระบุ';
    }
  }

  IconData _getUpdateIcon(String type) {
    switch (type) {
      case 'activity':
        return Icons.eco;
      case 'investment':
        return Icons.trending_up;
      case 'challenge':
        return Icons.emoji_events;
      case 'community':
        return Icons.forum;
      default:
        return Icons.info;
    }
  }

  void _showActivityDetails(Map<String, dynamic> activity, String activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.eco, color: Color(0xFF059669)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity['title'] ?? 'กิจกรรมสีเขียว',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity['description'] ?? 'รายละเอียดกิจกรรม',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'เริ่ม: ${_formatDate(activity['startDate'])}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'ผู้เข้าร่วม: ${activity['participantCount'] ?? 0}/${activity['maxParticipants'] ?? 0}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.stars, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  'รางวัล: ${activity['ecoCoinsReward'] ?? 0} เหรียญ',
                  style: const TextStyle(fontSize: 14, color: Colors.amber),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinActivity(activityId, activity);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('เข้าร่วม'),
          ),
        ],
      ),
    );
  }

  void _joinActivity(String activityId, Map<String, dynamic> activity) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')),
      );
      return;
    }

    try {
      // Check if user already joined
      final existingParticipant = await FirebaseFirestore.instance
          .collection('activity_participants')
          .where('activityId', isEqualTo: activityId)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (existingParticipant.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณได้เข้าร่วมกิจกรรมนี้แล้ว')),
        );
        return;
      }

      // Add participant
      await FirebaseFirestore.instance.collection('activity_participants').add({
        'activityId': activityId,
        'userId': currentUser.uid,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'joined',
      });

      // Update participant count
      await FirebaseFirestore.instance
          .collection('green_activities')
          .doc(activityId)
          .update({
        'participantCount': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เข้าร่วมกิจกรรมสำเร็จ!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // Helper Methods
}
