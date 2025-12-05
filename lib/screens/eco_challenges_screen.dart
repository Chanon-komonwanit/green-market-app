// lib/screens/eco_challenges_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/services/eco_influence_service.dart';

class EcoChallengesScreen extends StatefulWidget {
  const EcoChallengesScreen({super.key});

  @override
  State<EcoChallengesScreen> createState() => _EcoChallengesScreenState();
}

class _EcoChallengesScreenState extends State<EcoChallengesScreen>
    with TickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF8B5CF6),
              Color(0xFFF8FAF9),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏆 ความท้าทาย Eco',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'ท้าทายตัวเองเพื่อสิ่งแวดล้อม',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tab Bar
              Container(
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
                  labelColor: const Color(0xFF7C3AED),
                  unselectedLabelColor: Colors.white,
                  tabs: const [
                    Tab(text: 'ใหม่'),
                    Tab(text: 'ของฉัน'),
                    Tab(text: 'เสร็จแล้ว'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvailableChallenges(),
                    _buildMyChallenges(),
                    _buildCompletedChallenges(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableChallenges() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eco_challenges')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorCard('เกิดข้อผิดพลาดในการโหลดข้อมูล');
        }

        final challenges = snapshot.data?.docs ?? [];

        if (challenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emoji_events,
            title: 'ยังไม่มีความท้าทาย',
            subtitle: 'ความท้าทายใหม่จะมาเร็วๆ นี้',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index].data() as Map<String, dynamic>;
            return _buildChallengeCard(challenge, challenges[index].id);
          },
        );
      },
    );
  }

  Widget _buildMyChallenges() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: 'กรุณาเข้าสู่ระบบ',
        subtitle: 'เพื่อดูความท้าทายของคุณ',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_challenges')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'in_progress')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        final myChallenges = snapshot.data?.docs ?? [];

        if (myChallenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment,
            title: 'คุณยังไม่มีความท้าทายที่กำลังดำเนินการ',
            subtitle: 'เลือกความท้าทายใหม่จากแท็บ "ใหม่"',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: myChallenges.length,
          itemBuilder: (context, index) {
            final userChallenge =
                myChallenges[index].data() as Map<String, dynamic>;
            return _buildMyChallengeCard(userChallenge, myChallenges[index].id);
          },
        );
      },
    );
  }

  Widget _buildCompletedChallenges() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: 'กรุณาเข้าสู่ระบบ',
        subtitle: 'เพื่อดูความท้าทายที่เสร็จแล้ว',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_challenges')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        final completedChallenges = snapshot.data?.docs ?? [];

        if (completedChallenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emoji_events,
            title: 'คุณยังไม่มีความท้าทายที่เสร็จ',
            subtitle: 'เริ่มต้นความท้าทายแรกของคุณกันเลย!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: completedChallenges.length,
          itemBuilder: (context, index) {
            final userChallenge =
                completedChallenges[index].data() as Map<String, dynamic>;
            return _buildCompletedChallengeCard(userChallenge);
          },
        );
      },
    );
  }

  Widget _buildChallengeCard(
      Map<String, dynamic> challenge, String challengeId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getChallengeEmoji(challenge['category'] ?? ''),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge['title'] ?? 'ความท้าทาย',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge['description'] ?? '',
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChallengeInfo(
                Icons.schedule,
                '${challenge['duration'] ?? 7} วัน',
              ),
              const SizedBox(width: 16),
              _buildChallengeInfo(
                Icons.star,
                '${challenge['reward'] ?? 50} เหรียญ',
              ),
              const SizedBox(width: 16),
              _buildChallengeInfo(
                Icons.trending_up,
                _getDifficultyText(challenge['difficulty'] ?? 'medium'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _acceptChallenge(challengeId, challenge),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'รับความท้าทาย',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyChallengeCard(
      Map<String, dynamic> userChallenge, String userChallengeId) {
    final progress = userChallenge['progress'] ?? 0;
    final target = userChallenge['target'] ?? 1;
    final progressPercentage = (progress / target * 100).clamp(0, 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getChallengeEmoji(userChallenge['category'] ?? ''),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userChallenge['title'] ?? 'ความท้าทาย',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ความคืบหน้า: $progress/$target',
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
          const SizedBox(height: 16),
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: progressPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progressPercentage.toInt()}% เสร็จสิ้น',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _updateProgress(userChallengeId, progress + 1, target),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('อัปเดตความคืบหน้า'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _abandonChallenge(userChallengeId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedChallengeCard(Map<String, dynamic> userChallenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userChallenge['title'] ?? 'ความท้าทาย',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เสร็จสิ้นเมื่อ ${_formatDate(userChallenge['completedAt'])}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+${userChallenge['reward'] ?? 50} เหรียญ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.all(20),
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

  void _acceptChallenge(
      String challengeId, Map<String, dynamic> challenge) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('user_challenges').add({
        'userId': currentUser.uid,
        'challengeId': challengeId,
        'title': challenge['title'],
        'description': challenge['description'],
        'category': challenge['category'],
        'target': challenge['target'] ?? 1,
        'progress': 0,
        'reward': challenge['reward'] ?? 50,
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รับความท้าทายสำเร็จ!')),
      );

      // Switch to "My Challenges" tab
      _tabController.animateTo(1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _updateProgress(
      String userChallengeId, int newProgress, int target) async {
    try {
      final isCompleted = newProgress >= target;

      await FirebaseFirestore.instance
          .collection('user_challenges')
          .doc(userChallengeId)
          .update({
        'progress': newProgress,
        'status': isCompleted ? 'completed' : 'in_progress',
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      });

      if (isCompleted) {
        // Award Influence Score
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userChallengeDoc = await FirebaseFirestore.instance
              .collection('user_challenges')
              .doc(userChallengeId)
              .get();

          if (userChallengeDoc.exists) {
            final challengeData =
                userChallengeDoc.data() as Map<String, dynamic>;
            final difficulty = challengeData['difficulty'] ?? 'medium';

            // Award influence points through service
            final influenceService = EcoInfluenceService();
            await influenceService.awardChallengePoints(
                currentUser.uid, difficulty);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🎉 ยินดีด้วย! คุณทำความท้าทายสำเร็จแล้ว')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตความคืบหน้าแล้ว')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _abandonChallenge(String userChallengeId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกความท้าทาย'),
        content: const Text('คุณแน่ใจหรือไม่ที่จะยกเลิกความท้าทายนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('user_challenges')
            .doc(userChallengeId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยกเลิกความท้าทายแล้ว')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  String _getChallengeEmoji(String category) {
    switch (category) {
      case 'recycling':
        return '♻️';
      case 'energy':
        return '⚡';
      case 'transport':
        return '🚲';
      case 'water':
        return '💧';
      case 'waste':
        return '🗑️';
      case 'education':
        return '📚';
      case 'community':
        return '🤝';
      default:
        return '🌱';
    }
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'ง่าย';
      case 'medium':
        return 'ปานกลาง';
      case 'hard':
        return 'ยาก';
      default:
        return 'ปานกลาง';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'ไม่ระบุ';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        return 'ไม่ระบุ';
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
      return 'ไม่ระบุ';
    }
  }
}
