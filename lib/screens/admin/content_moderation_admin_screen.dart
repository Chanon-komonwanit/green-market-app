// lib/screens/admin/content_moderation_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/content_moderation_service.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';

/// Admin Screen สำหรับจัดการ Content Moderation
/// รวม: รายงานเนื้อหา, ผู้ใช้ที่ถูกระงับ, และตั้งค่า
class ContentModerationAdminScreen extends StatefulWidget {
  const ContentModerationAdminScreen({super.key});

  @override
  State<ContentModerationAdminScreen> createState() =>
      _ContentModerationAdminScreenState();
}

class _ContentModerationAdminScreenState
    extends State<ContentModerationAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _moderationService = ContentModerationService();

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
      appBar: AppBar(
        title: const Text('จัดการเนื้อหา'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.report), text: 'รายงาน'),
            Tab(icon: Icon(Icons.block), text: 'ผู้ใช้ถูกระงับ'),
            Tab(icon: Icon(Icons.settings), text: 'ตั้งค่า'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildSuspendedUsersTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  /// Tab: รายงานเนื้อหา
  Widget _buildReportsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _moderationService.getPendingReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('ไม่มีรายงานที่รอตรวจสอบ'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report);
          },
        );
      },
    );
  }

  /// Card: รายการรายงาน
  Widget _buildReportCard(Map<String, dynamic> report) {
    final contentType = report['contentType'] ?? 'unknown';
    final reason = report['reason'] ?? 'ไม่ระบุ';
    final reportedBy = report['reportedBy'] ?? 'ไม่ระบุ';
    final createdAt = report['createdAt'] as Timestamp?;

    IconData icon;
    Color color;
    switch (contentType) {
      case 'post':
        icon = Icons.article;
        color = Colors.blue;
        break;
      case 'comment':
        icon = Icons.comment;
        color = Colors.orange;
        break;
      case 'message':
        icon = Icons.message;
        color = Colors.purple;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          'รายงาน${_getContentTypeName(contentType)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('เหตุผล: $reason'),
            Text(
              'โดย: $reportedBy • ${_formatDate(createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Content ID: ${report['contentId']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _dismissReport(report['id']),
                      icon: const Icon(Icons.close),
                      label: const Text('ยกเลิก'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _takeAction(report),
                      icon: const Icon(Icons.gavel),
                      label: const Text('ดำเนินการ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab: ผู้ใช้ที่ถูกระงับ
  Widget _buildSuspendedUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isSuspended', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('ไม่มีผู้ใช้ที่ถูกระงับ'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            return _buildSuspendedUserCard(userId, user);
          },
        );
      },
    );
  }

  /// Card: ผู้ใช้ที่ถูกระงับ
  Widget _buildSuspendedUserCard(String userId, Map<String, dynamic> user) {
    final displayName = user['displayName'] ?? user['email'] ?? 'ไม่ระบุชื่อ';
    final suspendedAt = user['suspendedAt'] as Timestamp?;
    final suspendedUntil = user['suspendedUntil'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
          child: user['photoUrl'] == null
              ? Text(displayName[0].toUpperCase())
              : null,
        ),
        title: Text(displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ระงับเมื่อ: ${_formatDate(suspendedAt)}'),
            if (suspendedUntil != null)
              Text(
                'ถึงวันที่: ${_formatDate(suspendedUntil)}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'unsuspend') {
              await _unsuspendUser(userId);
            } else if (value == 'extend') {
              await _extendSuspension(userId);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'unsuspend',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('ยกเลิกการระงับ'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'extend',
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('ขยายระยะเวลา'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab: ตั้งค่า
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingSection(
          title: 'คำหยาบคาย',
          subtitle: 'ระบบตรวจจับคำหยาบอัตโนมัติ',
          icon: Icons.speaker_notes_off,
          onTap: () => _showBadWordsDialog(),
        ),
        _buildSettingSection(
          title: 'Spam Detection',
          subtitle: 'ตรวจจับเนื้อหาสแปม',
          icon: Icons.shield,
          onTap: () => _showSpamSettingsDialog(),
        ),
        _buildSettingSection(
          title: 'URL ต้องสงสัย',
          subtitle: 'ตรวจจับลิงก์ที่ต้องสงสัย',
          icon: Icons.link_off,
          onTap: () => _showUrlPatternsDialog(),
        ),
        const Divider(height: 32),
        _buildSettingSection(
          title: 'ระยะเวลาระงับเริ่มต้น',
          subtitle: '7 วัน',
          icon: Icons.schedule,
          onTap: () => _showSuspensionDurationDialog(),
        ),
        _buildSettingSection(
          title: 'จำนวนโพสต์ต่อชั่วโมง',
          subtitle: 'จำกัดไว้ที่ 10 โพสต์',
          icon: Icons.speed,
          onTap: () => _showRateLimitDialog(),
        ),
      ],
    );
  }

  Widget _buildSettingSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// ฟังก์ชันจัดการ
  String _getContentTypeName(String type) {
    switch (type) {
      case 'post':
        return 'โพสต์';
      case 'comment':
        return 'ความคิดเห็น';
      case 'message':
        return 'ข้อความ';
      default:
        return 'เนื้อหา';
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่ระบุ';
    return DateFormat('d MMM yyyy, HH:mm').format(timestamp.toDate());
  }

  Future<void> _dismissReport(String reportId) async {
    try {
      await _moderationService.updateReportStatus(reportId, 'dismissed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยกเลิกรายงานสำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _takeAction(Map<String, dynamic> report) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ดำเนินการ'),
        content: const Text('เลือกการดำเนินการกับเนื้อหานี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('ลบเนื้อหา'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'suspend'),
            child: const Text('ระงับผู้ใช้'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );

    if (result == 'suspend') {
      await _showSuspendUserDialog(report);
    } else if (result == 'delete') {
      await _deleteContent(report);
    }
  }

  Future<void> _showSuspendUserDialog(Map<String, dynamic> report) async {
    // ดึงข้อมูลเจ้าของเนื้อหา
    final contentId = report['contentId'];
    String? userId;

    // ค้นหา userId จากเนื้อหา
    try {
      if (report['contentType'] == 'post') {
        final doc = await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(contentId)
            .get();
        userId = doc.data()?['userId'];
      }
    } catch (e) {
      debugPrint('Error finding userId: $e');
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้')),
      );
      return;
    }

    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ระงับผู้ใช้'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลือกระยะเวลาการระงับ'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('1 วัน'),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              title: const Text('7 วัน'),
              onTap: () => Navigator.pop(context, 7),
            ),
            ListTile(
              title: const Text('30 วัน'),
              onTap: () => Navigator.pop(context, 30),
            ),
            ListTile(
              title: const Text('ถาวร'),
              onTap: () => Navigator.pop(context, 36500), // 100 years
            ),
          ],
        ),
      ),
    );

    if (days != null) {
      try {
        await _moderationService.suspendUser(userId, days);
        await _moderationService.updateReportStatus(
            report['id'], 'action_taken');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ระงับผู้ใช้เป็นเวลา $days วัน')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteContent(Map<String, dynamic> report) async {
    try {
      final contentType = report['contentType'];
      final contentId = report['contentId'];

      String collection;
      switch (contentType) {
        case 'post':
          collection = 'community_posts';
          break;
        case 'comment':
          collection = 'comments';
          break;
        default:
          throw Exception('Unsupported content type');
      }

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(contentId)
          .delete();
      await _moderationService.updateReportStatus(report['id'], 'action_taken');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบเนื้อหาสำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _unsuspendUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isSuspended': false,
        'suspendedUntil': FieldValue.delete(),
        'suspendedAt': FieldValue.delete(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยกเลิกการระงับสำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _extendSuspension(String userId) async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ขยายระยะเวลาระงับ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('+ 7 วัน'),
              onTap: () => Navigator.pop(context, 7),
            ),
            ListTile(
              title: const Text('+ 30 วัน'),
              onTap: () => Navigator.pop(context, 30),
            ),
          ],
        ),
      ),
    );

    if (days != null) {
      try {
        await _moderationService.suspendUser(userId, days);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ขยายระยะเวลาระงับ $days วันเพิ่ม')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }

  void _showBadWordsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('คำหยาบคาย'),
        content: const SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ระบบมีการตรวจจับคำหยาบอัตโนมัติ'),
              SizedBox(height: 8),
              Text('รวมถึงคำหยาบภาษาไทยและอังกฤษ'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showSpamSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('การตั้งค่า Spam Detection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('คำสำคัญที่บ่งบอกถึง spam:'),
            SizedBox(height: 8),
            Text('ระบบตรวจจับเนื้อหาสแปมอัตโนมัติ'),
            SizedBox(height: 16),
            Text('จำนวนโพสต์สูงสุดต่อชั่วโมง:'),
            Text('10 โพสต์', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showUrlPatternsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL ต้องสงสัย'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• bit.ly'),
            Text('• tinyurl.com'),
            Text('• goo.gl'),
            Text('• ow.ly'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showSuspensionDurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ระยะเวลาระงับเริ่มต้น'),
        content:
            const Text('ตั้งค่าระยะเวลาระงับเริ่มต้นเมื่อพบเนื้อหาไม่เหมาะสม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showRateLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Limiting'),
        content: const Text('จำกัดจำนวนการโพสต์เพื่อป้องกัน spam'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}
