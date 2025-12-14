import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/sustainable_activities_hub_screen.dart';
import 'package:green_market/screens/investment_hub_screen.dart';
import 'package:green_market/screens/carbon_credit_trading_screen.dart';
import 'package:green_market/screens/knowledge_base_screen.dart';
import 'package:green_market/screens/unified_notifications_screen.dart';

/// Green World Hub - Modern Sustainable Platform
/// 4 Core Features: Activities, Investment, Carbon Credit, Knowledge Base
class GreenWorldHubScreen extends StatefulWidget {
  const GreenWorldHubScreen({super.key});

  @override
  State<GreenWorldHubScreen> createState() => _GreenWorldHubScreenState();
}

class _GreenWorldHubScreenState extends State<GreenWorldHubScreen> {
  int _totalUnreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Real-time listener for notifications
    FirebaseFirestore.instance
        .collection('investment_notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((investmentSnapshot) {
      FirebaseFirestore.instance
          .collection('activity_notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .listen((activitySnapshot) {
        if (mounted) {
          setState(() {
            _totalUnreadNotifications =
                investmentSnapshot.docs.length + activitySnapshot.docs.length;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              _buildHeader(context),

              const SizedBox(height: 24),

              // 4 Main Feature Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildFeatureCard(
                      context: context,
                      title: 'กิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
                      description: 'ร่วมสร้างสังคมสีเขียวกับกิจกรรมดีๆ',
                      icon: Icons.volunteer_activism,
                      color: const Color(0xFF059669),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      onTap: () => _navigateToActivities(context),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      context: context,
                      title: 'การลงทุนเพื่อความยั่งยืน',
                      description: 'เปิดประตูสู่การลงทุนที่สร้างผลตอบแทน',
                      icon: Icons.trending_up,
                      color: const Color(0xFF1D4ED8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                      ),
                      onTap: () => _navigateToInvestment(context),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      context: context,
                      title: 'ซื้อขายคาร์บอนเครดิต',
                      description: 'ชดเชยการปล่อยก๊าซเรือนกระจก',
                      icon: Icons.eco,
                      color: const Color(0xFF0891B2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                      ),
                      badge: 'เร็วๆ นี้',
                      onTap: () => _navigateToCarbonCredit(context),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      context: context,
                      title: 'คลังความรู้',
                      description: 'ศูนย์รวมความรู้และแนวทางสำหรับผู้เริ่มต้น',
                      icon: Icons.menu_book,
                      color: const Color(0xFFF59E0B),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      ),
                      badge: 'เร็วๆ นี้',
                      onTap: () => _navigateToKnowledgeBase(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // User Stats Section (if logged in)
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.currentUser;
                  if (user != null) {
                    return _buildUserStatsCard(user);
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Premium Header with Enhanced Design
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF047857),
            Color(0xFF059669),
            Color(0xFF10B981),
            Color(0xFF34D399),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Title & Notifications
          Row(
            children: [
              // Eco Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.public,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              // Title Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Green World Hub',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'แพลตฟอร์มสร้างสรรค์โลกยั่งยืน',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Unified Notification Button
              _buildUnifiedNotificationButton(context),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('กิจกรรม', '28+', Icons.eco_rounded),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildQuickStat('โครงการ', '15+', Icons.trending_up_rounded),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildQuickStat('สมาชิก', '1.2K', Icons.people_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Unified Notification Button with Badge Count
  Widget _buildUnifiedNotificationButton(BuildContext context) {
    return Tooltip(
      message: 'การแจ้งเตือนทั้งหมด',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UnifiedNotificationsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 24),
                // Real-time Badge Count
                if (_totalUnreadNotifications > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        _totalUnreadNotifications > 99
                            ? '99+'
                            : '$_totalUnreadNotifications',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Premium Feature Card with Modern Design
  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEC4899),
                                    Color(0xFFF43F5E)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Premium User Stats Card
  Widget _buildUserStatsCard(dynamic user) {
    final ecoCoins = user.ecoCoins ?? 0.0;
    final influenceScore = user.ecoInfluenceScore ?? 0.0;
    final level = _getUserLevel(ecoCoins);
    final rank = _getUserRank(ecoCoins);
    final co2Offset = (ecoCoins * 0.5).toStringAsFixed(1);
    final influenceTier = _getInfluenceTier(influenceScore);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF047857),
              Color(0xFF059669),
              Color(0xFF10B981),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              left: -25,
              bottom: -25,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.displayName?.substring(0, 1).toUpperCase() ??
                                '👤',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'ผู้ใช้',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                level,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Stats Grid - 2x2 Modern Layout
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Row 1
                        Row(
                          children: [
                            _buildStatItem(
                              icon: Icons.eco_rounded,
                              value: '${ecoCoins.toStringAsFixed(0)}',
                              label: 'Eco Coins',
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                            _buildStatItem(
                              icon: Icons.stars_rounded,
                              value: '${influenceScore.toStringAsFixed(0)}',
                              label: 'Green Score',
                              badge: influenceTier,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Row 2
                        Row(
                          children: [
                            _buildStatItem(
                              icon: Icons.emoji_events_rounded,
                              value: rank,
                              label: 'อันดับ',
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                            _buildStatItem(
                              icon: Icons.cloud_outlined,
                              value: co2Offset,
                              label: 'CO₂ Saved',
                              unit: 'ตัน',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    String? unit,
    String? badge,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Navigation Methods
  void _navigateToActivities(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SustainableActivitiesHubScreen(),
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

  void _navigateToCarbonCredit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CarbonCreditTradingScreen(),
      ),
    );
  }

  void _navigateToKnowledgeBase(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KnowledgeBaseScreen(),
      ),
    );
  }

  // Helper Methods
  String _getUserLevel(double ecoCoins) {
    if (ecoCoins >= 1000) return 'Legend 🏆';
    if (ecoCoins >= 500) return 'Master ⭐';
    if (ecoCoins >= 200) return 'Hero 🎖️';
    if (ecoCoins >= 50) return 'Friend 👍';
    return 'Beginner 🌱';
  }

  String _getUserRank(double ecoCoins) {
    if (ecoCoins >= 1000) return '#1-50';
    if (ecoCoins >= 500) return '#51-200';
    if (ecoCoins >= 200) return '#201-500';
    if (ecoCoins >= 50) return '#501-1000';
    return '#1000+';
  }

  String _getInfluenceTier(double score) {
    if (score >= 80) return '🌟 Legend';
    if (score >= 60) return '⭐ Expert';
    if (score >= 40) return '🎖️ Active';
    if (score >= 20) return '👍 Member';
    return '🌱 Starter';
  }
}
