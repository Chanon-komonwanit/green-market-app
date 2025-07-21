// -------------------- IMPORTS --------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:green_market/utils/constants.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/widgets/green_world_icon.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/green_activity.dart';
import 'package:green_market/models/green_investment.dart';
import 'package:green_market/screens/investment_hub_screen.dart';
import 'package:green_market/screens/sustainable_activities_hub_screen.dart';
import 'package:green_market/screens/community_forum_screen.dart';
import 'package:green_market/screens/feed_screen.dart';
import 'package:green_market/screens/eco_challenges_screen.dart';
import 'package:green_market/widgets/debug_panel.dart';
// -------------------- END IMPORTS --------------------

// --- Helper Methods for user stats ---
String getUserEcoLevel(double ecoCoins) {
  if (ecoCoins >= 1000) return 'Legend';
  if (ecoCoins >= 500) return 'Master';
  if (ecoCoins >= 200) return 'Hero';
  if (ecoCoins >= 50) return 'Friend';
  return 'Beginner';
}

String calculateCarbonOffset(double ecoCoins) {
  return (ecoCoins * 0.5).toStringAsFixed(1);
}

String getUserRank(double ecoCoins) {
  if (ecoCoins >= 1000) return '#1-50';
  if (ecoCoins >= 500) return '#51-200';
  if (ecoCoins >= 200) return '#201-500';
  if (ecoCoins >= 50) return '#501-1000';
  return '#1000+';
}

Map<String, dynamic>? getUserBadge(double ecoCoins) {
  if (ecoCoins >= 1000) {
    return {
      'label': 'Legend',
      'icon': Icons.verified,
      'color': Colors.amber[800],
    };
  } else if (ecoCoins >= 500) {
    return {
      'label': 'Master',
      'icon': Icons.star,
      'color': Colors.orange[700],
    };
  } else if (ecoCoins >= 200) {
    return {
      'label': 'Hero',
      'icon': Icons.military_tech,
      'color': Colors.blue[700],
    };
  } else if (ecoCoins >= 50) {
    return {
      'label': 'Friend',
      'icon': Icons.thumb_up,
      'color': Colors.green[700],
    };
  } else if (ecoCoins > 0) {
    return {
      'label': 'Beginner',
      'icon': Icons.emoji_nature,
      'color': Colors.grey[600],
    };
  }
  return null;
}

Widget buildStatItem(String value, String label) {
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

IconData getUpdateIcon(String type) {
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

// Main body widget for Green World Hub (top-level, stateless, receives builder functions)
class GreenWorldHubBody extends StatelessWidget {
  final dynamic currentUser;
  final Widget Function() buildHeader;
  final Widget Function(BuildContext) buildSocialActivitySection;
  final Widget Function(BuildContext) buildSustainableInvestmentSection;
  final Widget Function(dynamic) buildUserStatsCard;
  final Widget Function() buildNewsAndStatsSection;

  const GreenWorldHubBody({
    super.key,
    required this.currentUser,
    required this.buildHeader,
    required this.buildSocialActivitySection,
    required this.buildSustainableInvestmentSection,
    required this.buildUserStatsCard,
    required this.buildNewsAndStatsSection,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        buildHeader(),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: buildSocialActivitySection(context)),
                    const SizedBox(width: 18),
                    Expanded(child: buildSustainableInvestmentSection(context)),
                  ],
                )
              : Column(
                  children: [
                    buildSocialActivitySection(context),
                    buildSustainableInvestmentSection(context),
                  ],
                ),
        ),
        if (currentUser != null) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: buildUserStatsCard(currentUser),
          ),
        ],
        const SizedBox(height: 24),
        buildNewsAndStatsSection(),
        const DebugPanel(),
      ],
    );
  }
}

// --- Top-level class for Green World Hub Screen ---
class GreenWorldHubScreen extends StatefulWidget {
  const GreenWorldHubScreen({super.key});

  @override
  State<GreenWorldHubScreen> createState() => _GreenWorldHubScreenState();
}

class _GreenWorldHubScreenState extends State<GreenWorldHubScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        return Scaffold(
          backgroundColor: const Color(0xFFF6FBF9),
          body: SafeArea(
            child: GreenWorldHubBody(
              currentUser: currentUser,
              buildHeader: buildGreenWorldHeader,
              buildSocialActivitySection: buildSocialActivitySection,
              buildSustainableInvestmentSection:
                  buildSustainableInvestmentSection,
              buildUserStatsCard: buildUserStatsCard,
              buildNewsAndStatsSection: buildNewsAndStatsSection,
            ),
          ),
        );
      },
    );
  }

  // --- Widget Builders and Helpers ---
  Widget buildErrorCard(String message) {
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

  Widget buildGreenWorldHeader() {
    return Hero(
      tag: 'greenWorldHeader',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF43B48C), Color(0xFF4FC3F7), Color(0xFFE6F4F1)],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(32),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.95, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: const Text(
                  '🌱',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เปิดโลกสีเขียว',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.1,
                    shadows: const [
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'สร้างอนาคตที่ยั่งยืนไปด้วยกัน',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFeaturedActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1.0),
              duration: Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [Color(0xFF145A32), Color(0xFF43B48C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33145A32),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text('🌻', style: TextStyle(fontSize: 22)),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'กิจกรรมเด่น',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF145A32),
                letterSpacing: 0.8,
                shadows: const [
                  Shadow(
                    color: Color(0x22000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('activities')
              .where('featured', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Card(
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: const [
                      Icon(Icons.groups_rounded,
                          color: Color(0xFF059669), size: 40),
                      SizedBox(height: 12),
                      Text('ยังไม่มีข้อมูลกิจกรรมเด่น',
                          style: TextStyle(
                              fontSize: 17,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, idx) {
                final doc = docs[idx];
                final activity = doc.data() as Map<String, dynamic>;
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.groups_rounded,
                              color: Color(0xFF059669), size: 32),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(activity['title'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669))),
                              const SizedBox(height: 8),
                              Text(activity['description'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 14, color: Color(0xFF374151))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            showActivityDetails(context, activity, doc.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            minimumSize: const Size(90, 42),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          child: const Text('เข้าร่วม'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget buildUserStatsCard(dynamic user) {
    if (user == null) {
      return buildErrorCard('ไม่พบข้อมูลผู้ใช้');
    }
    final ecoCoins = user.ecoCoins ?? 0.0;
    final badge = getUserBadge(ecoCoins);
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: badge?['color'] ?? Colors.grey[300],
              child: Text('🦋',
                  style: TextStyle(
                      fontSize:
                          32)), // โปรไฟล์ผู้ใช้ (🦋 สื่อถึงการเปลี่ยนแปลง/สิ่งแวดล้อม)
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'ผู้ใช้',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text('Eco Coins: ${ecoCoins.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 14)),
                  Text('ระดับ: ${getUserEcoLevel(ecoCoins)}',
                      style: const TextStyle(fontSize: 14)),
                  Text('อันดับ: ${getUserRank(ecoCoins)}',
                      style: const TextStyle(fontSize: 14)),
                  Text(
                      'คาร์บอนที่ offset: ${calculateCarbonOffset(ecoCoins)} ตัน',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNewsAndStatsSection() {
    Widget buildCommunityStats() {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
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
                    Icons.groups_3_rounded,
                    color: Colors.white,
                    size: 28,
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
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                final userCount = snapshot.data?.docs.length ?? 0;
                Widget buildCommunityStatItem(IconData icon, Color iconColor,
                    String value, String label) {
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Text('🧑‍🤝‍🧑',
                            style: TextStyle(fontSize: 28, color: iconColor)),
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

                return Row(
                  children: [
                    Expanded(
                      child: buildCommunityStatItem(
                        Icons.groups_rounded,
                        Colors.amberAccent,
                        userCount.toString(),
                        'สมาชิก',
                      ),
                    ),
                    Expanded(
                      child: buildCommunityStatItem(
                        Icons.eco,
                        Colors.greenAccent,
                        '${(userCount * 2.5).toInt()}',
                        'กิจกรรมที่เสร็จ',
                      ),
                    ),
                    Expanded(
                      child: buildCommunityStatItem(
                        Icons.door_front_door,
                        Colors.lightBlueAccent,
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

    Widget buildLatestUpdates() {
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
              final updates = snapshot.data?.docs ?? [];
              Widget buildUpdateCard(Map<String, dynamic> update) {
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
                          getUpdateIcon(update['type'] ?? 'general'),
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
                        formatDate(update['createdAt']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                );
              }
              if (updates.isEmpty) {
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
                    children: const [
                      Icon(
                        Icons.update,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'ยังไม่มีอัปเดต',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ข่าวสารใหม่จะมาเร็วๆ นี้',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: updates
                    .map((doc) =>
                        buildUpdateCard(doc.data() as Map<String, dynamic>))
                    .toList(),
              );
            },
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCommunityStats(),
          const SizedBox(height: 24),
          buildLatestUpdates(),
        ],
      ),
    );
  }

  Widget buildSocialActivitySection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(isMobile ? 16 : 24, 24, isMobile ? 16 : 24, 10),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 5,
        shadowColor: const Color(0xFF059669).withOpacity(0.10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.volunteer_activism,
                        size: 22, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'กิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'ร่วมสร้างสังคมสีเขียวกับกิจกรรมดีๆ เพื่อโลกของเรา ช่วยเหลือสังคมและสิ่งแวดล้อมได้ทันที',
                style: TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'เข้าร่วมกิจกรรมเพื่อสร้างผลกระทบเชิงบวก',
                      child: ElevatedButton.icon(
                        onPressed: () => navigateToActivities(context),
                        icon: const Icon(Icons.groups_3_rounded, size: 24),
                        label: const Text('เข้าร่วมกิจกรรม'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF059669).withOpacity(0.2),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => navigateToActivities(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(
                          color: Color(0xFF059669), width: 1.5),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    child: const Text('ดูทั้งหมด'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              buildFeaturedActivities(),
              const SizedBox(height: 18),
              buildPersonalizedSuggestionSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSustainableInvestmentSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(isMobile ? 16 : 24, 24, isMobile ? 16 : 24, 10),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 5,
        shadowColor: const Color(0xFF1D4ED8).withOpacity(0.10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.trending_up,
                        size: 22, color: Color(0xFF1D4ED8)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'การลงทุนเพื่อความยั่งยืน',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'เปิดประตูสู่การลงทุนที่สร้างผลตอบแทนและโลกที่ดีขึ้น เลือกลงทุนในโปรเจกต์ยั่งยืนได้ทันที',
                style: TextStyle(fontSize: 15, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'เริ่มต้นลงทุนเพื่ออนาคตที่ยั่งยืน',
                      child: ElevatedButton.icon(
                        onPressed: () => navigateToInvestment(context),
                        icon: const Icon(Icons.door_front_door, size: 22),
                        label: const Text('เริ่มลงทุน'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF1D4ED8).withOpacity(0.2),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => navigateToInvestment(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D4ED8),
                      side: const BorderSide(
                          color: Color(0xFF1D4ED8), width: 1.5),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    child: const Text('ดูพอร์ต'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              buildPersonalizedSuggestionSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation Methods
  void navigateToActivities(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SustainableActivitiesHubScreen(),
      ),
    );
  }

  void navigateToInvestment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvestmentHubScreen(),
      ),
    );
  }

  // --- Build Personalized Suggestion Section ---
  Widget buildPersonalizedSuggestionSection() {
    return Card(
      color: Colors.teal[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('ข้อเสนอแนะสำหรับคุณ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
                'ลองเข้าร่วมกิจกรรมใหม่ ๆ เพื่อสะสม Eco Coins และยกระดับสู่ Legend!'),
          ],
        ),
      ),
    );
  }

  String formatDate(dynamic timestamp) {
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

  void showActivityDetails(
      BuildContext context, Map<String, dynamic> activity, String activityId) {
    // ...existing code for showing activity details dialog or page...
  }
} // <-- ปิดท้ายคลาส _GreenWorldHubScreenState
