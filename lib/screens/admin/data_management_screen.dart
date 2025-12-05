// lib/screens/admin/data_management_screen.dart
//
// 🛠️ Data Management Screen - หน้าจัดการข้อมูล (Admin)
//
// ฟีเจอร์:
// - ดูสถิติ database
// - ทำความสะอาดข้อมูลเก่า
// - ตั้งค่า auto cleanup
// - ดู performance metrics

import 'package:flutter/material.dart';
import '../../services/data_cleanup_service.dart';
import '../../theme/app_colors.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final DataCleanupService _cleanupService = DataCleanupService();
  DatabaseStats? _stats;
  CleanupResult? _lastCleanup;
  bool _isLoading = false;
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _cleanupService.getDatabaseStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _performCleanup() async {
    final confirm = await _showConfirmDialog();
    if (confirm != true) return;

    setState(() => _isCleaning = true);

    try {
      final result = await _cleanupService.performFullCleanup();
      setState(() {
        _lastCleanup = result;
        _isCleaning = false;
      });

      if (result.success) {
        _showSuccess(
            'ทำความสะอาดเสร็จสิ้น: ลบข้อมูล ${result.totalDeleted} รายการ');
        _loadStats(); // Refresh stats
      } else {
        _showError('เกิดข้อผิดพลาด: ${result.error}');
      }
    } catch (e) {
      setState(() => _isCleaning = false);
      _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการทำความสะอาด'),
        content: const Text(
          'ระบบจะลบข้อมูลเก่าที่ไม่จำเป็น:\n\n'
          '• โพสต์เก่า (>90 วัน, engagement ต่ำ)\n'
          '• Notifications เก่า (>30 วัน)\n'
          '• Logs เก่า (>7 วัน)\n'
          '• Comments ของโพสต์ที่ถูกลบ\n\n'
          'ดำเนินการต่อหรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการข้อมูล'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildCleanupSection(),
                  if (_lastCleanup != null) ...[
                    const SizedBox(height: 24),
                    _buildLastCleanupSection(),
                  ],
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'สถิติฐานข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_stats != null) ...[
              _buildStatRow('โพสต์ทั้งหมด', _stats!.totalPosts),
              _buildStatRow(
                  'โพสต์ที่ใช้งาน', _stats!.activePosts, Colors.green),
              _buildStatRow(
                  'โพสต์ที่ไม่ใช้งาน', _stats!.inactivePosts, Colors.red),
              _buildStatRow('การแจ้งเตือน', _stats!.totalNotifications),
              _buildStatRow('ความคิดเห็น', _stats!.totalComments),
              _buildStatRow('ผู้ใช้', _stats!.totalUsers),
            ] else
              const Text('ไม่มีข้อมูล'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.cleaning_services, color: AppColors.warning),
                const SizedBox(width: 8),
                const Text(
                  'ทำความสะอาดข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'ลบข้อมูลเก่าที่ไม่จำเป็นเพื่อประหยัด storage และเพิ่มประสิทธิภาพ',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isCleaning ? null : _performCleanup,
              icon: _isCleaning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_sweep),
              label: Text(
                  _isCleaning ? 'กำลังทำความสะอาด...' : 'เริ่มทำความสะอาด'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastCleanupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.info),
                const SizedBox(width: 8),
                const Text(
                  'ผลลัพธ์ครั้งล่าสุด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatRow('โพสต์ที่ลบ', _lastCleanup!.postsDeleted),
            _buildStatRow(
                'การแจ้งเตือนที่ลบ', _lastCleanup!.notificationsDeleted),
            _buildStatRow('ความคิดเห็นที่ลบ', _lastCleanup!.commentsDeleted),
            _buildStatRow('Logs ที่ลบ', _lastCleanup!.logsDeleted),
            const Divider(),
            _buildStatRow(
              'รวมทั้งหมด',
              _lastCleanup!.totalDeleted,
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'ข้อมูลเพิ่มเติม',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• โพสต์เก่า (>90 วัน) ที่มี engagement ต่ำ (<5) จะถูกลบ\n'
              '• Notifications เก่า (>30 วัน) ที่อ่านแล้วจะถูกลบ\n'
              '• Logs เก่า (>7 วัน) จะถูกลบ\n'
              '• Comments ของโพสต์ที่ถูกลบจะถูกลบตาม\n'
              '• การลบเป็น "soft delete" สามารถกู้คืนได้ภายใน 30 วัน',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
