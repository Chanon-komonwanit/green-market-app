// lib/screens/sustainable_activities_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import '../utils/constants.dart';
import 'create_activity_screen.dart';
import 'activity_list_screen.dart';
import 'admin_approve_activities_screen.dart';

class SustainableActivitiesHubScreen extends StatefulWidget {
  const SustainableActivitiesHubScreen({super.key});

  @override
  State<SustainableActivitiesHubScreen> createState() =>
      _SustainableActivitiesHubScreenState();
}

class _SustainableActivitiesHubScreenState
    extends State<SustainableActivitiesHubScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // ตรวจสอบสิทธิ์แอดมิน (สามารถปรับเปลี่ยนตามระบบที่ใช้)
      // ในตัวอย่างนี้ใช้ email admin หรือ UID เฉพาะ
      final adminEmails = ['admin@greenmarket.com', 'manager@greenmarket.com'];
      setState(() {
        _isAdmin = adminEmails.contains(user.email) || user.uid == 'admin_uid';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: const Text(
          'กิจกรรมเพื่อความยั่งยืน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isAdmin)
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.volunteer_activism,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ร่วมสร้างโลกที่ยั่งยืน',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'เข้าร่วมกิจกรรมเพื่อสิ่งแวดล้อมและสังคม\nหรือสร้างกิจกรรมของคุณเอง',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
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
                                child: _buildStatCard(
                                  '📊',
                                  totalActivities.toString(),
                                  'ทั้งหมด',
                                  AppColors.primaryTeal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  '🔥',
                                  activeActivities.toString(),
                                  'กำลังดำเนิน',
                                  Colors.orange,
                                ),
                              ),
                              if (_isAdmin) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
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
                        child: _buildActionCard(
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
                        child: _buildActionCard(
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
            _buildBrowseSection(),

            const SizedBox(height: 24),

            // Browse by Type
            _buildTypeSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String count, String label, Color color) {
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

  Widget _buildActionCard({
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

  Widget _buildBrowseSection() {
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
              return _buildProvinceChip(province);
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

  Widget _buildTypeSection() {
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
              return _buildTypeCard(
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

  Widget _buildProvinceChip(String province) {
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

  Widget _buildTypeCard(String name, String icon, Color color) {
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
