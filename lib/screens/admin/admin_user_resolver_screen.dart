// lib/screens/admin/admin_user_resolver_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/admin_management_service.dart';
import 'package:green_market/utils/app_utils.dart';

class AdminUserResolverScreen extends StatefulWidget {
  const AdminUserResolverScreen({super.key});

  @override
  State<AdminUserResolverScreen> createState() =>
      _AdminUserResolverScreenState();
}

class _AdminUserResolverScreenState extends State<AdminUserResolverScreen> {
  final AdminManagementService _adminService = AdminManagementService();
  List<Map<String, dynamic>> _adminUsers = [];
  bool _isLoading = true;
  final String _problemEmail = 'heargofza1133@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadAdminUsers();
  }

  Future<void> _loadAdminUsers() async {
    try {
      final adminUsers = await _adminService.getAllAdminUsers();
      setState(() {
        _adminUsers = adminUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showAppSnackBar(context, 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e',
          isError: true);
    }
  }

  Future<void> _removeAdminRights(String email) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบสิทธิ์ Admin'),
        content: Text(
            'คุณต้องการลบสิทธิ์ Admin จาก $email หรือไม่?\n\nผู้ใช้จะยังคงสามารถใช้แอพได้ แต่จะไม่มีสิทธิ์ Admin'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('ลบสิทธิ์'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _adminService.removeAdminRights(email);
      if (success) {
        showAppSnackBar(context, 'ลบสิทธิ์ Admin สำเร็จ', isSuccess: true);
        _loadAdminUsers(); // Reload data
      } else {
        showAppSnackBar(context, 'ไม่สามารถลบสิทธิ์ Admin ได้', isError: true);
      }
    } catch (e) {
      showAppSnackBar(context, 'เกิดข้อผิดพลาด: $e', isError: true);
    }
  }

  Future<void> _convertToSeller(String email) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการเปลี่ยนเป็นผู้ขาย'),
        content: Text(
            'คุณต้องการเปลี่ยน $email จาก Admin เป็น Seller หรือไม่?\n\nผู้ใช้จะสามารถขายสินค้าได้ แต่ไม่มีสิทธิ์ Admin'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('เปลี่ยนเป็นผู้ขาย'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _adminService.convertAdminToSeller(email);
      if (success) {
        showAppSnackBar(context, 'เปลี่ยนเป็นผู้ขายสำเร็จ', isSuccess: true);
        _loadAdminUsers(); // Reload data
      } else {
        showAppSnackBar(context, 'ไม่สามารถเปลี่ยนเป็นผู้ขายได้',
            isError: true);
      }
    } catch (e) {
      showAppSnackBar(context, 'เกิดข้อผิดพลาด: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้ Admin'),
        backgroundColor: Colors.red.shade100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Problem alert
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'ปัญหาที่พบ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'อีเมล $_problemEmail ยังมีสิทธิ์ Admin อยู่ในระบบ'),
                          const SizedBox(height: 16),

                          // Quick action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _removeAdminRights(_problemEmail),
                                  icon: const Icon(Icons.remove_moderator),
                                  label: const Text('ลบสิทธิ์ Admin'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _convertToSeller(_problemEmail),
                                  icon: const Icon(Icons.store),
                                  label: const Text('เปลี่ยนเป็นผู้ขาย'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Admin users list
                  Text(
                    'ผู้ใช้ Admin ทั้งหมดในระบบ (${_adminUsers.length} คน)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_adminUsers.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'ไม่พบผู้ใช้ Admin ในระบบ',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._adminUsers.map((user) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user['email'] == _problemEmail
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: user['email'] == _problemEmail
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                            title: Text(
                              user['displayName'] ??
                                  user['email'] ??
                                  'ไม่มีชื่อ',
                              style: TextStyle(
                                fontWeight: user['email'] == _problemEmail
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('อีเมล: ${user['email'] ?? 'N/A'}'),
                                Text('แหล่งข้อมูล: ${user['source']}'),
                                if (user['email'] == _problemEmail)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ผู้ใช้ปัญหา',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'remove_admin':
                                    _removeAdminRights(user['email']);
                                    break;
                                  case 'convert_to_seller':
                                    _convertToSeller(user['email']);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'remove_admin',
                                  child: ListTile(
                                    leading: Icon(Icons.remove_moderator,
                                        color: Colors.orange),
                                    title: Text('ลบสิทธิ์ Admin'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'convert_to_seller',
                                  child: ListTile(
                                    leading:
                                        Icon(Icons.store, color: Colors.green),
                                    title: Text('เปลี่ยนเป็นผู้ขาย'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Instructions
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'คำแนะนำ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              '• การลบสิทธิ์ Admin จะไม่ลบผู้ใช้ออกจากระบบ'),
                          const Text(
                              '• ผู้ใช้จะยังคงสามารถใช้แอพได้แต่ไม่มีสิทธิ์ Admin'),
                          const Text(
                              '• หากต้องการลบผู้ใช้ทั้งหมด ต้องทำใน Firebase Console'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
