// lib/screens/admin/fix_permissions_screen.dart
import 'package:flutter/material.dart';
import '../../utils/fix_user_permissions.dart';

class FixPermissionsScreen extends StatefulWidget {
  const FixPermissionsScreen({super.key});

  @override
  State<FixPermissionsScreen> createState() => _FixPermissionsScreenState();
}

class _FixPermissionsScreenState extends State<FixPermissionsScreen> {
  bool _isProcessing = false;
  Map<String, dynamic> _results = {};
  String _reportText = '';
  final String _targetEmail = 'heargofza1133@gmail.com';

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    setState(() {
      _isProcessing = true;
      _reportText = 'กำลังตรวจสอบสิทธิ์ปัจจุบัน...';
    });

    try {
      final report =
          await FixUserPermissions.generatePermissionsReport(_targetEmail);
      setState(() {
        _reportText = report;
      });
    } catch (e) {
      setState(() {
        _reportText = 'เกิดข้อผิดพลาดในการตรวจสอบ: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _fixPermissions() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final results = await FixUserPermissions.fixHeargofzaPermissions();
      setState(() {
        _results = results;
      });

      if (results['status'] == 'SUCCESS') {
        // Refresh the report after fixing
        await _checkCurrentPermissions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ แก้ไขสิทธิ์ผู้ใช้สำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ เกิดข้อผิดพลาด: ${results['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขสิทธิ์ผู้ใช้'),
        backgroundColor: Colors.blue[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target User Info
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'ผู้ใช้เป้าหมาย',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'อีเมล: $_targetEmail\n'
                      'การดำเนินการ: เปลี่ยนจาก Admin เป็น Seller เท่านั้น\n'
                      '• ลบสิทธิ์ Admin (isAdmin = false)\n'
                      '• ให้สิทธิ์ Seller (isSeller = true)\n'
                      '• ลบออกจาก admins collection\n'
                      '• ตรวจสอบ/สร้างข้อมูลใน sellers collection',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Status Report
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'สถานะปัจจุบัน',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          if (_isProcessing)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _reportText,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Results (if any)
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: _results['status'] == 'SUCCESS'
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _results['status'] == 'SUCCESS'
                                ? Icons.check_circle
                                : Icons.error,
                            color: _results['status'] == 'SUCCESS'
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ผลการดำเนินการ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _results['status'] == 'SUCCESS'
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _results['message'] ??
                            _results['error'] ??
                            'ไม่มีข้อความ',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_results['status'] == 'SUCCESS') ...[
                        const SizedBox(height: 8),
                        Text(
                          'รายละเอียด:\n'
                          '• Users Collection: ${_results['users_updated'] ? "อัปเดตแล้ว" : "ไม่ได้อัปเดต"}\n'
                          '• Admin Removed: ${_results['admin_removed'] ? "ลบแล้ว" : "ไม่มีข้อมูล admin"}\n'
                          '• Seller: ${_results['seller_created'] ? "สร้างใหม่" : _results['seller_exists'] ? "มีอยู่แล้ว" : "ไม่ดำเนินการ"}',
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _isProcessing ? null : _checkCurrentPermissions,
            backgroundColor: Colors.blue,
            heroTag: "refresh",
            tooltip: 'ตรวจสอบสิทธิ์อีกครั้ง',
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: _isProcessing ? null : _fixPermissions,
            backgroundColor: _isProcessing ? Colors.grey : Colors.orange,
            heroTag: "fix",
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.build, color: Colors.white),
            label: Text(
              _isProcessing ? 'กำลังแก้ไข...' : 'แก้ไขสิทธิ์',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
