// lib/screens/admin/admin_activity_reports_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_market/models/activity_report.dart';
import 'package:green_market/models/app_notification.dart'; // Corrected import
import 'package:green_market/screens/sustainable_activity/sustainable_activity_detail_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminActivityReportsScreen extends StatefulWidget {
  const AdminActivityReportsScreen({super.key});

  @override
  State<AdminActivityReportsScreen> createState() =>
      _AdminActivityReportsScreenState();
}

class _AdminActivityReportsScreenState
    extends State<AdminActivityReportsScreen> {
  final TextEditingController _adminNotesController = TextEditingController();

  @override
  void dispose() {
    _adminNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('รายงานกิจกรรม',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firebaseService
            .getAllActivityReports(), // Assuming this method exists
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีรายงานกิจกรรมในขณะนี้'));
          }

          final reports = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getReportStatusColor(report['status'] ?? 'pending'),
                    child: Icon(Icons.flag, color: theme.colorScheme.onPrimary),
                  ),
                  title: Text(report['activityTitle'] ?? 'ไม่ระบุกิจกรรม',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    // Ensure reporterName is not null
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('รายงานโดย: ${report['reporterName'] ?? 'ไม่ระบุ'}'),
                      Text('เหตุผล: ${report['reason'] ?? 'ไม่ระบุ'}',
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (report['adminNotes'] != null &&
                          report['adminNotes'].toString().isNotEmpty)
                        Text('หมายเหตุแอดมิน: ${report['adminNotes']}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic)),
                      Text(
                          'สถานะ: ${_getReportStatusDisplay(report['status'] ?? 'pending')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: _getReportStatusColor(
                                  report['status'] ?? 'pending'))),
                      Text(
                          'วันที่: ${report['createdAt'] != null ? DateFormat('dd MMM yyyy HH:mm').format((report['createdAt'] as Timestamp).toDate()) : 'ไม่ระบุ'}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleReportAction(
                        context, firebaseService, report, value),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'view_activity',
                        child: Text('ดูรายละเอียดกิจกรรม'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit_report',
                        child: Text('แก้ไขสถานะ/หมายเหตุ'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'take_action',
                        child: Text('ดำเนินการ (เช่น ลบกิจกรรม)'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getReportStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blueGrey;
      case 'action_taken':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getReportStatusDisplay(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'reviewed':
        return 'ตรวจสอบแล้ว';
      case 'action_taken':
        return 'ดำเนินการแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  void _handleReportAction(
      BuildContext context,
      FirebaseService firebaseService,
      Map<String, dynamic> report,
      String action) async {
    if (action == 'view_activity') {
      final activity = await firebaseService.getSustainableActivityByIdAsMap(
          report['activityId'] ?? ''); // Assuming this method exists
      if (activity != null) {
        if (context.mounted) {
          // TODO: Create SustainableActivityDetailScreen that accepts Map
          // Navigator.of(context).push(MaterialPageRoute(
          //     builder: (ctx) =>
          //         SustainableActivityDetailScreen(activity: activity)));
          showAppSnackBar(context,
              'ดูรายละเอียดกิจกรรม: ${activity['title'] ?? 'ไม่ระบุ'}');
        }
      } else {
        if (context.mounted) {
          showAppSnackBar(context, 'ไม่พบกิจกรรมที่เกี่ยวข้อง', isError: true);
        }
      }
    } else if (action == 'edit_report') {
      _showEditReportDialog(context, firebaseService, report);
    } else if (action == 'take_action') {
      // Implement delete activity functionality
      _confirmAndDeleteActivity(context, firebaseService, report);
    }
  }

  void _showEditReportDialog(BuildContext context,
      FirebaseService firebaseService, Map<String, dynamic> report) {
    _adminNotesController.text = report['adminNotes'] ?? '';
    String selectedStatus = report['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            // Corrected: Already correct // Corrected: Already correct
            title: const Text('แก้ไขรายงานกิจกรรม'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Corrected: MainAxisSize.min
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Corrected: Already correct // Corrected: Already correct
                children: [
                  const Text('สถานะ:'),
                  DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: ['pending', 'reviewed', 'action_taken']
                        .map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(_getReportStatusDisplay(status)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatus = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _adminNotesController,
                    decoration: const InputDecoration(
                      labelText: 'หมายเหตุเพิ่มเติม',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await firebaseService.updateActivityReport(report['id'], {
                      'status': selectedStatus,
                      'adminNotes': _adminNotesController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    // Send notification to the user who reported
                    final notification = AppNotification(
                      // Corrected constructor call
                      id: firebaseService.generateNewDocId('notifications'),
                      userId: report['reporterId'] ?? '',
                      title: 'รายงานของคุณได้รับการอัปเดต',
                      body:
                          'สถานะรายงานกิจกรรม "${report['activityTitle'] ?? 'ไม่ระบุ'}" ของคุณได้เปลี่ยนเป็น "${_getReportStatusDisplay(selectedStatus)}"',
                      type: NotificationType.activityUpdate,
                      relatedId: report['activityId'] ?? '',
                      createdAt: Timestamp.now(),
                    );
                    await firebaseService.addNotification(notification);

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    showAppSnackBar(context, 'อัปเดตรายงานสำเร็จ',
                        isSuccess: true);
                  } catch (e) {
                    showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                        isError: true);
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _confirmAndDeleteActivity(BuildContext context,
      FirebaseService firebaseService, Map<String, dynamic> report) async {
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('ยืนยันการลบกิจกรรม'),
            content: Text(
                'คุณแน่ใจหรือไม่ว่าต้องการลบกิจกรรม "${report['activityTitle'] ?? 'ไม่ระบุ'}"? การดำเนินการนี้ไม่สามารถย้อนกลับได้'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('ลบกิจกรรม'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        // Fetch activity details to get organizerId
        final activity = await firebaseService.getSustainableActivityByIdAsMap(
            report['activityId'] ?? ''); // Assuming this method exists

        if (activity == null) {
          if (context.mounted) {
            showAppSnackBar(context, 'ไม่พบกิจกรรมที่เกี่ยวข้อง',
                isError: true);
          }
          return;
        }

        await firebaseService.deleteSustainableActivity(
            report['activityId'] ?? ''); // Assuming this method exists

        // Update the report status to 'action_taken'
        await firebaseService.updateActivityReport(report['id'] ?? '', {
          'status': 'action_taken',
          'adminNotes':
              '${report['adminNotes'] ?? ''}\n[Admin Action: Activity deleted due to report by ${report['reporterName'] ?? 'ไม่ระบุ'} on ${DateFormat('dd MMM yyyy HH:mm').format(Timestamp.now().toDate())}]',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send notification to the activity organizer
        final notification = AppNotification(
          // Corrected constructor call
          id: firebaseService.generateNewDocId('notifications'),
          userId: activity['organizerId'] ?? '',
          title: 'กิจกรรมของคุณถูกลบ',
          body:
              'กิจกรรม "${activity['title'] ?? 'ไม่ระบุ'}" ของคุณถูกลบเนื่องจากมีการรายงานปัญหา โปรดตรวจสอบรายงานในหน้าจัดการกิจกรรม',
          type: NotificationType.activityCancelled,
          relatedId: activity['id'] ?? '',
          createdAt: Timestamp.now(),
        );
        await firebaseService.addNotification(notification);

        if (context.mounted) {
          showAppSnackBar(context, 'กิจกรรมถูกลบและรายงานถูกอัปเดตสำเร็จ',
              isSuccess: true);
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(
              context, 'เกิดข้อผิดพลาดในการดำเนินการ: ${e.toString()}',
              isError: true);
        }
      }
    }
  }
}
