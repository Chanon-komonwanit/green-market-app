// lib/screens/sustainable_activities_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import '../utils/constants.dart';
import 'create_activity_screen.dart';
import 'activity_list_screen.dart';
import 'admin_approve_activities_screen.dart';
import 'activity_notifications_screen.dart';

class SustainableActivitiesHubScreen extends StatefulWidget {
  const SustainableActivitiesHubScreen({super.key});

  @override
  State<SustainableActivitiesHubScreen> createState() =>
      _SustainableActivitiesHubScreenState();
}

class _SustainableActivitiesHubScreenState
    extends State<SustainableActivitiesHubScreen> {
  bool isAdmin = false;

  // Leaderboard/Badge Section (World-class, expandable)
  Widget _buildLeaderboardSection() {
    final List<Map<String, dynamic>> leaders = [
      {'name': 'คุณรักษ์โลก', 'points': 1200, 'badge': '🥇'},
      {'name': 'GreenHero', 'points': 950, 'badge': '🥈'},
      {'name': 'EcoStar', 'points': 800, 'badge': '🥉'},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Leaderboard & Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...leaders.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(l['badge'] as String,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Text('${l['points']} pts',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFeaturedActivityCard(BuildContext context, Activity activity) {
    final String title =
        (activity.title.isNotEmpty) ? activity.title : 'กิจกรรมไม่ระบุชื่อ';
    final String desc =
        (activity.description.isNotEmpty) ? activity.description : '-';
    final String province =
        (activity.province.isNotEmpty) ? activity.province : '-';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityListScreen(
                title: title,
              ),
            ),
          );
        },
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.teal.withOpacity(0.13)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.teal, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      province,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activity.isActive == true)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('เปิดรับสมัคร',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF10B981))),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    checkAdminRole();
  }

  Future<void> checkAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // ตรวจสอบสิทธิ์แอดมิน (สามารถปรับเปลี่ยนตามระบบที่ใช้)
      // ในตัวอย่างนี้ใช้ email admin หรือ UID เฉพาะ
      final adminEmails = ['admin@greenmarket.com', 'manager@greenmarket.com'];
      setState(() {
        isAdmin = adminEmails.contains(user.email) || user.uid == 'admin_uid';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.groups, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'กิจกรรมเพื่อความยั่งยืน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ปุ่มแจ้งเตือนกิจกรรม
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'การแจ้งเตือนกิจกรรม',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityNotificationsScreen(),
                ),
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminApproveActivitiesScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'เกี่ยวกับกิจกรรม',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('กิจกรรมเพื่อความยั่งยืน'),
                  content: const Text(
                      'เข้าร่วมกิจกรรมเพื่อสังคมและสิ่งแวดล้อม พร้อมระบบ badge, leaderboard, และฟีเจอร์ใหม่ ๆ'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('สร้างกิจกรรมใหม่',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateActivityScreen(),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Onboarding/Tooltip Section
            Padding(
              padding: const EdgeInsets.only(
                  top: 18, left: 18, right: 18, bottom: 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('วิธีใช้งานโซนกิจกรรม'),
                        content: const Text(
                            '1. เข้าร่วมกิจกรรมเพื่อรับ badge และคะแนน\n2. แชร์ผลลัพธ์และไต่อันดับ leaderboard\n3. สร้างกิจกรรมใหม่เพื่อชุมชน'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ปิด'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info, color: AppColors.primaryTeal),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'แตะเพื่อดูวิธีใช้งานและสิทธิประโยชน์ของโซนกิจกรรมนี้!',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Header Banner with world-class animation and CTA
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF14B8A6),
                      Color(0xFF10B981),
                      Color(0xFF99F6E4)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.15),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.volunteer_activism,
                            size: 70, color: Colors.white),
                        SizedBox(width: 18),
                        Icon(Icons.emoji_events,
                            size: 44, color: Colors.amberAccent),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ร่วมสร้างโลกที่ยั่งยืน',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'เข้าร่วมกิจกรรมเพื่อสิ่งแวดล้อมและสังคม\nแชร์ผลลัพธ์ รับ badge และไต่อันดับ leaderboard',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF10B981),
                        minimumSize: Size(180, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        elevation: 0,
                        textStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      icon: Icon(Icons.group_add, color: Color(0xFF10B981)),
                      label: const Text('เข้าร่วมกิจกรรม'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActivityListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Featured Activities Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.star, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text(
                        'กิจกรรมเด่น',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 170,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('activities')
                          .where('isFeatured', isEqualTo: true)
                          .where('isApproved', isEqualTo: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Text('ยังไม่มีกิจกรรมเด่น',
                                style: TextStyle(color: Colors.grey)),
                          );
                        }
                        // ป้องกันกรณี docs ไม่ใช่ List<DocumentSnapshot<Map<String, dynamic>>> ที่ถูกต้อง
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, idx) {
                            try {
                              final activity =
                                  Activity.fromFirestore(docs[idx]);
                              return _buildFeaturedActivityCard(
                                  context, activity);
                            } catch (e) {
                              return Container(
                                width: 220,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.2)),
                                ),
                                child: const Center(
                                  child: Text('ข้อมูลกิจกรรมผิดพลาด',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Statistics Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('activities')
                    .where('isApproved', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  int totalActivities = 0;
                  int activeActivities = 0;
                  int pendingActivities = 0;

                  if (snapshot.hasData) {
                    final activities = snapshot.data!.docs
                        .map((doc) => Activity.fromFirestore(doc))
                        .toList();

                    totalActivities = activities.length;
                    activeActivities =
                        activities.where((a) => a.isActive).length;
                  }

                  // นับกิจกรรมที่รออนุมัติ
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('activities')
                        .where('isApproved', isEqualTo: false)
                        .snapshots(),
                    builder: (context, pendingSnapshot) {
                      if (pendingSnapshot.hasData) {
                        pendingActivities = pendingSnapshot.data!.docs.length;
                      }

                      return Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.analytics,
                                  color: AppColors.primaryTeal),
                              SizedBox(width: 8),
                              Text(
                                'สถิติกิจกรรม',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: buildStatCard(
                                  '📊',
                                  totalActivities.toString(),
                                  'ทั้งหมด',
                                  AppColors.primaryTeal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildStatCard(
                                  '🔥',
                                  activeActivities.toString(),
                                  'กำลังดำเนิน',
                                  Colors.orange,
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: buildStatCard(
                                    '⏳',
                                    pendingActivities.toString(),
                                    'รออนุมัติ',
                                    Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Leaderboard & Badges Section
            _buildLeaderboardSection(),

            // Quick Actions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'การดำเนินการ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildActionCard(
                          title: 'สร้างกิจกรรม',
                          subtitle: 'เริ่มต้นกิจกรรมใหม่',
                          icon: Icons.add_circle,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreateActivityScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildActionCard(
                          title: 'ดูกิจกรรม',
                          subtitle: 'ค้นหาและเข้าร่วม',
                          icon: Icons.search,
                          color: AppColors.primaryTeal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ActivityListScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Browse by Province
            buildBrowseSection(),

            const SizedBox(height: 24),

            // Browse by Type
            buildTypeSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget buildStatCard(String emoji, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBrowseSection() {
    final popularProvinces = [
      'กรุงเทพมหานคร',
      'เชียงใหม่',
      'ภูเก็ต',
      'ขอนแก่น',
      'นครราชสีมา',
      'สงขลา'
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryTeal),
              SizedBox(width: 8),
              Text(
                'เลือกตามจังหวัด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularProvinces.map((province) {
              return buildProvinceChip(province);
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityListScreen(
                      title: 'เลือกจังหวัด',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('ดูทุกจังหวัด'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: const BorderSide(color: AppColors.primaryTeal),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTypeSection() {
    final activityTypes = [
      {'name': 'สิ่งแวดล้อม', 'icon': '🌱', 'color': Colors.green},
      {'name': 'สังคม', 'icon': '🤝', 'color': Colors.blue},
      {'name': 'การศึกษา', 'icon': '📚', 'color': Colors.orange},
      {'name': 'ชุมชน', 'icon': '🏘️', 'color': Colors.purple},
      {'name': 'อาสาสมัคร', 'icon': '💪', 'color': Colors.red},
      {'name': 'อื่นๆ', 'icon': '🌟', 'color': Colors.grey},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category, color: AppColors.primaryTeal),
              SizedBox(width: 8),
              Text(
                'เลือกตามประเภท',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: activityTypes.length,
            itemBuilder: (context, index) {
              final type = activityTypes[index];
              return buildTypeCard(
                type['name'] as String,
                type['icon'] as String,
                type['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildProvinceChip(String province) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityListScreen(
              province: province,
              title: 'กิจกรรมใน$province',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
        ),
        child: Text(
          province,
          style: const TextStyle(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget buildTypeCard(String name, String icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityListScreen(
                  activityType: name,
                  title: 'กิจกรรม$name',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
