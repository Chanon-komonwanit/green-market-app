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
    final autoDetected = report['autoDetected'] as bool? ?? false;
    final severity = report['severity'] as String?;
    final imageUrls = (report['imageUrls'] as List<dynamic>?)?.cast<String>();
    final videoUrl = report['videoUrl'] as String?;
    final contentPreview = report['contentPreview'] as String?;

    IconData icon;
    Color color;
    switch (contentType) {
      case 'post':
      case 'community_post':
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
        title: Row(
          children: [
            Text(
              'รายงาน${_getContentTypeName(contentType)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (autoDetected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🤖 ตรวจจับอัตโนมัติ',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('เหตุผล: $reason'),
            if (severity != null)
              Text(
                'ระดับ: ${_getSeverityText(severity)}',
                style:
                    TextStyle(fontSize: 12, color: _getSeverityColor(severity)),
              ),
            Text(
              'โดย: ${autoDetected ? "ระบบ" : reportedBy} • ${_formatDate(createdAt)}',
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
                const SizedBox(height: 8),

                // แสดง Content Preview
                if (contentPreview != null) ...[
                  const Divider(),
                  const Text('เนื้อหา:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      contentPreview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // แสดงรูปภาพ
                if (imageUrls != null && imageUrls.isNotEmpty) ...[
                  const Divider(),
                  const Text('รูปภาพ:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // แสดงวิดีโอ
                if (videoUrl != null) ...[
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.videocam, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'วิดีโอ: $videoUrl',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 8),
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

  String _getSeverityText(String severity) {
    if (severity.contains('high')) return 'รุนแรง';
    if (severity.contains('medium')) return 'ปานกลาง';
    if (severity.contains('low')) return 'เล็กน้อย';
    return 'ไม่ระบุ';
  }

  Color _getSeverityColor(String severity) {
    if (severity.contains('high')) return Colors.red;
    if (severity.contains('medium')) return Colors.orange;
    if (severity.contains('low')) return Colors.yellow.shade700;
    return Colors.grey;
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
            onPressed: () => Navigator.pop(context, 'hide'),
            child: const Text('ซ่อนเนื้อหา',
                style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('ลบเนื้อหา', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'suspend'),
            child: const Text('ระงับผู้ใช้',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
    } else if (result == 'hide') {
      await _hideContent(report);
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
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text(
            'คุณแน่ใจหรือไม่ว่าต้องการลบเนื้อหานี้?\n\nการลบจะไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final contentType = report['contentType'];
      final contentId = report['contentId'];

      // ใช้ service method ที่มี error handling ดีกว่า
      await _moderationService.deleteContent(
        contentId: contentId,
        contentType: contentType,
        reason: report['reason'] ?? 'รายงานโดยผู้ใช้',
      );

      await _moderationService.updateReportStatus(report['id'], 'action_taken');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ลบเนื้อหาสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _hideContent(Map<String, dynamic> report) async {
    try {
      final contentType = report['contentType'];
      final contentId = report['contentId'];

      await _moderationService.hideContent(
        contentId: contentId,
        contentType: contentType,
        reason: report['reason'] ?? 'รายงานโดยผู้ใช้',
      );

      await _moderationService.updateReportStatus(report['id'], 'action_taken');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👁️ ซ่อนเนื้อหาสำเร็จ'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e')),
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
