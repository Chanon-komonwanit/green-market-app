// lib/screens/eco_influence_screen.dart
// หน้าแสดงคะแนนอิทธิพลชุมชนสีเขียว (Eco Influence Score)
// แยกจาก Eco Coins - เฉพาะสำหรับชุมชนสีเขียว

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/eco_influence_service.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/eco_challenges_screen.dart';

class EcoInfluenceScreen extends StatefulWidget {
  const EcoInfluenceScreen({super.key});

  @override
  State<EcoInfluenceScreen> createState() => _EcoInfluenceScreenState();
}

class _EcoInfluenceScreenState extends State<EcoInfluenceScreen>
    with SingleTickerProviderStateMixin {
  final EcoInfluenceService _influenceService = EcoInfluenceService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF10B981),
              Color(0xFF059669),
              Color(0xFFF8FAF9),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(currentUser),
              const SizedBox(height: 16),
              // Tab Bar
              _buildTabBar(),
              const SizedBox(height: 20),
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyInfluenceTab(currentUser),
                    _buildLeaderboardTab(),
                    _buildViolationHistoryTab(currentUser),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppUser? currentUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '🌿 คะแนนอิทธิพลชุมชน',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'เป็นผู้นำการเปลี่ยนแปลง',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // แสดงอันดับปัจจุบัน
          if (currentUser != null)
            FutureBuilder<int>(
              future: _influenceService.getUserRank(currentUser.id),
              builder: (context, snapshot) {
                final rank = snapshot.data ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: const Color(0xFF10B981),
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(text: 'คะแนนของฉัน'),
          Tab(text: 'อันดับชุมชน'),
          Tab(text: 'ประวัติการละเมิด'),
        ],
      ),
    );
  }

  Widget _buildMyInfluenceTab(AppUser? currentUser) {
    if (currentUser == null) {
      return _buildLoginPrompt();
    }

    final score = currentUser.ecoInfluenceScore;
    final tier = _influenceService.getTier(score);
    final nextTierInfo = _influenceService.getNextTierInfo(score);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Score Card
        _buildScoreCard(currentUser, tier, nextTierInfo),
        const SizedBox(height: 20),
        // Breakdown
        _buildScoreBreakdown(currentUser),
        const SizedBox(height: 20),
        // Benefits
        _buildBenefitsCard(tier),
        const SizedBox(height: 20),
        // Quick Actions
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildScoreCard(
      AppUser user, EcoInfluenceTier tier, Map<String, dynamic> nextTierInfo) {
    final score = user.ecoInfluenceScore;
    final tierName = _influenceService.getTierName(tier);
    final tierIcon = _influenceService.getTierIcon(tier);
    final tierColor = Color(_influenceService.getTierColor(tier));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withOpacity(0.8),
            tierColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tier Badge
          Text(
            tierIcon,
            style: const TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 12),
          Text(
            tierName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toStringAsFixed(0)} คะแนน',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          // Progress to next tier
          if (nextTierInfo['hasNext'] == true) ...[
            const Divider(color: Colors.white30),
            const SizedBox(height: 12),
            Text(
              'ถัดไป: ${nextTierInfo['nextTierName']}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: nextTierInfo['progress'],
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'อีก ${nextTierInfo['remaining'].toStringAsFixed(0)} คะแนน',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ] else ...[
            const Divider(color: Colors.white30),
            const SizedBox(height: 12),
            const Text(
              '🏆 คุณอยู่ในระดับสูงสุดแล้ว!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดคะแนน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem(
            icon: Icons.people,
            title: 'ผู้ติดตาม',
            value: user.followersCount.toString(),
            weight: '20%',
            color: const Color(0xFF3B82F6),
          ),
          _buildBreakdownItem(
            icon: Icons.emoji_events,
            title: 'กิจกรรมสำเร็จ',
            value: user.challengesCompleted.toString(),
            weight: '45%',
            color: const Color(0xFFF59E0B),
          ),
          _buildBreakdownItem(
            icon: Icons.favorite,
            title: 'การมีส่วนร่วม',
            value: user.communityEngagement.toString(),
            weight: '20%',
            color: const Color(0xFFEF4444),
          ),
          _buildBreakdownItem(
            icon: Icons.shopping_bag,
            title: 'ซื้อสินค้า ECO',
            value: '฿${user.ecoProductsPurchased.toStringAsFixed(0)}',
            weight: '15%',
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required String title,
    required String value,
    required String weight,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              weight,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(EcoInfluenceTier tier) {
    final benefits = _influenceService.getTierBenefits(tier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'สิทธิพิเศษของคุณ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เพิ่มคะแนนของคุณ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              icon: Icons.emoji_events,
              title: 'ทำภารกิจ',
              subtitle: '+100 คะแนน',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EcoChallengesScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.post_add,
              title: 'สร้างโพสต์',
              subtitle: '+10 คะแนน',
              color: const Color(0xFF3B82F6),
              onTap: () {
                // Navigate to create post
              },
            ),
            _buildActionCard(
              icon: Icons.shopping_bag,
              title: 'ซื้อสินค้า ECO',
              subtitle: '+5/100฿',
              color: const Color(0xFF10B981),
              onTap: () {
                // Navigate to marketplace
              },
            ),
            _buildActionCard(
              icon: Icons.share,
              title: 'แชร์โพสต์',
              subtitle: '+15 คะแนน',
              color: const Color(0xFFEC4899),
              onTap: () {
                // Share post
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _influenceService.getTopInfluencers(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final user = AppUser.fromMap(userData, users[index].id);
            return _buildLeaderboardCard(user, index + 1);
          },
        );
      },
    );
  }

  Widget _buildLeaderboardCard(AppUser user, int rank) {
    final tier = _influenceService.getTier(user.ecoInfluenceScore);
    final tierIcon = _influenceService.getTierIcon(tier);
    final tierColor = Color(_influenceService.getTierColor(tier));

    Color? rankColor;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            rankColor != null ? Border.all(color: rankColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor ?? tierColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rankColor != null ? Colors.white : tierColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName ?? 'ไม่ระบุชื่อ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      tierIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.ecoInfluenceScore.toStringAsFixed(0)} คะแนน',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.login,
            size: 80,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          const Text(
            'กรุณาเข้าสู่ระบบ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'เพื่อดูคะแนนอิทธิพลของคุณ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// แท็บประวัติการละเมิด
  Widget _buildViolationHistoryTab(AppUser? currentUser) {
    if (currentUser == null) {
      return _buildLoginPrompt();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _influenceService.getPenaltyHistory(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final violations = snapshot.data ?? [];
        final penaltyPercentage = currentUser.penaltyPercentage;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Current Penalty Status Card
            _buildPenaltyStatusCard(penaltyPercentage, violations.length),
            const SizedBox(height: 20),

            // Violations List
            if (violations.isEmpty)
              _buildNoViolationsCard()
            else
              ...violations.map((violation) => _buildViolationCard(violation)),
          ],
        );
      },
    );
  }

  Widget _buildPenaltyStatusCard(double penaltyPercentage, int violationCount) {
    final isClean = penaltyPercentage == 0 && violationCount == 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClean
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [Colors.orange.shade400, Colors.red.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isClean
                ? const Color(0xFF10B981).withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isClean ? Icons.verified_user : Icons.warning_rounded,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            isClean ? 'สถานะดี ✨' : '⚠️ กำลังถูกหักคะแนน',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (!isClean) ...[
            Text(
              'หัก ${penaltyPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'จากคะแนนอิทธิพลทั้งหมด',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ตรวจพบการละเมิด $violationCount ครั้ง',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
            Text(
              'ไม่มีการละเมิดกฎชุมชน',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เก็บไว้นะ! 🌟',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoViolationsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'ยอดเยี่ยม!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'คุณเป็นสมาชิกที่ดีของชุมชน\nไม่มีประวัติการละเมิด',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationCard(Map<String, dynamic> violation) {
    final severity = violation['severity'] as String? ?? 'low';
    final issues =
        (violation['issues'] as List<dynamic>?)?.cast<String>() ?? [];
    final penaltyPercentage =
        (violation['penaltyPercentage'] as num?)?.toDouble() ?? 0.0;
    final timestamp = violation['timestamp'] as Timestamp?;

    Color severityColor;
    IconData severityIcon;
    String severityText;

    if (severity.contains('high')) {
      severityColor = Colors.red;
      severityIcon = Icons.dangerous;
      severityText = 'รุนแรง';
    } else if (severity.contains('medium')) {
      severityColor = Colors.orange;
      severityIcon = Icons.warning;
      severityText = 'ปานกลาง';
    } else {
      severityColor = Colors.yellow.shade700;
      severityIcon = Icons.info;
      severityText = 'เล็กน้อย';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.3), width: 2),
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
              Icon(severityIcon, color: severityColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'ระดับ: $severityText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-${penaltyPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...issues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        issue,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (timestamp != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}
