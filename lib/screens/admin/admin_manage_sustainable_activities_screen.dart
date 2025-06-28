// lib/screens/admin/admin_manage_sustainable_activities_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/sustainable_activity.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:green_market/models/app_notification.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminManageSustainableActivitiesScreen extends StatefulWidget {
  const AdminManageSustainableActivitiesScreen({super.key});

  @override
  State<AdminManageSustainableActivitiesScreen> createState() =>
      _AdminManageSustainableActivitiesScreenState();
}

class _AdminManageSustainableActivitiesScreenState
    extends State<AdminManageSustainableActivitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการกิจกรรมความยั่งยืน',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<SustainableActivity>>(
        stream: firebaseService.getAllSustainableActivitiesForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีกิจกรรมความยั่งยืน'));
          }

          final activities = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  // Corrected: Already correct // Corrected: Already correct // Corrected: Already correct
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(activity.imageUrl),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  title: Text(activity.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.description, maxLines: 2),
                      Text('จังหวัด: ${activity.province}'),
                      Text(
                          'เริ่ม: ${DateFormat('dd MMM yyyy').format(activity.startDate)}'),
                      Text(
                          'สิ้นสุด: ${DateFormat('dd MMM yyyy').format(activity.endDate)}'),
                      Text('ผู้จัด: ${activity.organizerName}'),
                      Text(
                        'สถานะการส่ง: ${activity.submissionStatus}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getSubmissionStatusColor(
                              activity.submissionStatus),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () =>
                            _showActivityDialog(context, activity: activity),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outlined,
                            color: Colors.red),
                        onPressed: () => _deleteActivity(
                            context, firebaseService, activity.id),
                      ),
                      if (activity.submissionStatus ==
                          'pending') // Show approve/reject for pending projects
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'approve') {
                              _approveActivity(
                                  context, firebaseService, activity.id);
                            } else if (value == 'reject') {
                              _rejectActivity(
                                  context, firebaseService, activity.id);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'approve',
                              child: Text('อนุมัติ'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'reject',
                              child: Text('ปฏิเสธ'),
                            ),
                          ],
                        ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'toggle_active') {
                            _toggleActivityActiveStatus(
                                context,
                                firebaseService,
                                activity.id,
                                activity.isActive);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'approve',
                            child: Text('อนุมัติ'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'reject',
                            child: Text('ปฏิเสธ'),
                          ),
                          PopupMenuItem<String>(
                            value: 'toggle_active',
                            child: Text(activity.isActive
                                ? 'พักกิจกรรม'
                                : 'เปิดใช้งานกิจกรรม'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActivityDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getSubmissionStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _approveActivity(BuildContext context, FirebaseService firebaseService,
      String activityId) async {
    try {
      // Update the activity status directly
      final updateData = {
        'submissionStatus': 'approved',
        'rejectionReason': null,
        'updatedAt': Timestamp.now(),
      };
      await firebaseService.updateSustainableActivityByData(
          activityId, updateData);

      // Fetch activity data for notification
      final activityDoc =
          await firebaseService.getSustainableActivityById(activityId);
      if (activityDoc != null) {
        // Send notification to the organizer
        final notification = AppNotification(
          id: firebaseService.generateNewDocId('notifications'),
          userId: activityDoc.organizerId,
          title: 'กิจกรรมของคุณได้รับการอนุมัติ',
          body:
              'กิจกรรม "${activityDoc.title}" ของคุณได้รับการอนุมัติแล้ว และจะแสดงในแอปพลิเคชัน',
          type: 'activity_approved',
          relatedId: activityId,
          createdAt: Timestamp.now(),
        );
        await firebaseService.addNotification(notification);
      }

      showAppSnackBar(context, 'อนุมัติกิจกรรมสำเร็จ', isSuccess: true);
    } catch (e) {
      showAppSnackBar(context, 'เกิดข้อผิดพลาดในการอนุมัติ: ${e.toString()}',
          isError: true);
    }
  }

  void _toggleActivityActiveStatus(
      BuildContext context,
      FirebaseService firebaseService,
      String activityId,
      bool currentStatus) async {
    try {
      await firebaseService.toggleActivityActiveStatus(
          activityId, !currentStatus);
      showAppSnackBar(
        context,
        currentStatus ? 'พักกิจกรรมสำเร็จ' : 'เปิดใช้งานกิจกรรมสำเร็จ',
        isSuccess: true,
      );
    } catch (e) {
      showAppSnackBar(
        context,
        'เกิดข้อผิดพลาดในการ${currentStatus ? 'พัก' : 'เปิดใช้งาน'}กิจกรรม: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _rejectActivity(BuildContext context, FirebaseService firebaseService,
      String activityId) async {
    TextEditingController reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ปฏิเสธกิจกรรม'),
          content: TextField(
            controller: reasonController,
            decoration:
                const InputDecoration(labelText: 'เหตุผลในการปฏิเสธ (จำเป็น)'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  showAppSnackBar(context, 'กรุณากรอกเหตุผลในการปฏิเสธ',
                      isError: true);
                  return;
                }
                try {
                  // Update the activity status directly
                  final updateData = {
                    'submissionStatus': 'rejected',
                    'rejectionReason': reasonController.text.trim(),
                    'updatedAt': Timestamp.now(),
                  };
                  await firebaseService.updateSustainableActivityByData(
                      activityId, updateData);

                  // Fetch activity data for notification
                  final activityDoc = await firebaseService
                      .getSustainableActivityById(activityId);
                  if (activityDoc != null) {
                    // Send notification to the organizer
                    final notification = AppNotification(
                      id: firebaseService.generateNewDocId('notifications'),
                      userId: activityDoc.organizerId,
                      title: 'กิจกรรมของคุณถูกปฏิเสธ',
                      body:
                          'กิจกรรม "${activityDoc.title}" ของคุณถูกปฏิเสธด้วยเหตุผล: ${reasonController.text.trim()}',
                      type: 'activity_rejected',
                      relatedId: activityId,
                      createdAt: Timestamp.now(),
                    );
                    await firebaseService.addNotification(notification);
                  }

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  showAppSnackBar(context, 'ปฏิเสธกิจกรรมสำเร็จ',
                      isSuccess: true);
                } catch (e) {
                  showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                      isError: true);
                }
              },
              child: const Text('ปฏิเสธ'),
            ),
          ],
        );
      },
    );
  }

  void _deleteActivity(BuildContext context, FirebaseService firebaseService,
      String activityId) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบกิจกรรมนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await firebaseService.deleteSustainableActivity(activityId);
                showAppSnackBar(context, 'ลบกิจกรรมสำเร็จ', isSuccess: true);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                    isError: true);
              }
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _showActivityDialog(BuildContext context,
      {SustainableActivity? activity}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: activity?.title ?? '');
    final descriptionController =
        TextEditingController(text: activity?.description ?? '');
    final provinceController =
        TextEditingController(text: activity?.province ?? '');
    final imageUrlController =
        TextEditingController(text: activity?.imageUrl ?? '');
    final contactInfoController =
        TextEditingController(text: activity?.contactInfo ?? '');

    DateTime? selectedStartDate = activity?.startDate;
    DateTime? selectedEndDate = activity?.endDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(activity == null ? 'เพิ่มกิจกรรมใหม่' : 'แก้ไขกิจกรรม'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                        controller: titleController,
                        decoration:
                            buildInputDecoration(context, 'ชื่อกิจกรรม'),
                        validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: descriptionController,
                        decoration:
                            buildInputDecoration(context, 'คำอธิบายกิจกรรม'),
                        maxLines: 3,
                        validator: (v) =>
                            v!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: provinceController,
                        decoration: buildInputDecoration(context, 'จังหวัด'),
                        validator: (v) =>
                            v!.isEmpty ? 'กรุณากรอกจังหวัด' : null),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: imageUrlController,
                        decoration: buildInputDecoration(context, 'URL รูปภาพ'),
                        keyboardType: TextInputType.url,
                        validator: (v) =>
                            v!.isEmpty ? 'กรุณากรอก URL รูปภาพ' : null),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: contactInfoController,
                        decoration:
                            buildInputDecoration(context, 'ข้อมูลติดต่อ'),
                        validator: (v) =>
                            v!.isEmpty ? 'กรุณากรอกข้อมูลติดต่อ' : null),
                    const SizedBox(height: 10), // Corrected: Already correct
                    _buildDatePicker(
                      context,
                      'วันที่เริ่มต้น',
                      selectedStartDate,
                      (date) => setState(() => selectedStartDate = date),
                    ),
                    const SizedBox(height: 10),
                    _buildDatePicker(
                      context,
                      'วันที่สิ้นสุด',
                      selectedEndDate,
                      (date) => setState(() => selectedEndDate = date),
                      minDate: selectedStartDate,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (selectedStartDate == null || selectedEndDate == null) {
                    showAppSnackBar(
                        context, 'กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด',
                        isError: true);
                    return;
                  }
                  if (selectedEndDate!.isBefore(selectedStartDate!)) {
                    showAppSnackBar(
                        context, 'วันที่สิ้นสุดต้องอยู่หลังวันที่เริ่มต้น',
                        isError: true);
                    return;
                  }

                  final firebaseService =
                      Provider.of<FirebaseService>(context, listen: false);
                  try {
                    final updatedActivity = SustainableActivity(
                      id: activity?.id ??
                          firebaseService
                              .generateNewDocId('sustainable_activities'),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      province: provinceController.text.trim(),
                      startDate: selectedStartDate!,
                      endDate: selectedEndDate!,
                      imageUrl: imageUrlController.text.trim(),
                      contactInfo: contactInfoController.text.trim(),
                      location: '', // Corrected: Added location
                      organizerId: activity?.organizerId ??
                          '', // Preserve original organizer
                      organizerName: activity?.organizerName ??
                          '', // Preserve original organizer
                      submissionStatus: activity?.submissionStatus ?? 'pending',
                      createdAt: activity?.createdAt ??
                          Timestamp
                              .now(), // Preserve original or set current time
                    );

                    if (activity == null) {
                      await firebaseService
                          .addSustainableActivity(updatedActivity);
                      showAppSnackBar(context, 'เพิ่มกิจกรรมสำเร็จ',
                          isSuccess: true);
                    } else {
                      await firebaseService
                          .updateSustainableActivity(updatedActivity);
                      showAppSnackBar(context, 'แก้ไขกิจกรรมสำเร็จ',
                          isSuccess: true);
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
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

  Widget _buildDatePicker(BuildContext context, String label,
      DateTime? selectedDate, Function(DateTime?) onDateSelected,
      {DateTime? minDate}) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: minDate ?? DateTime(2020),
          lastDate: DateTime(2101),
        );
        onDateSelected(pickedDate);
      },
      child: InputDecorator(
        decoration: buildInputDecoration(context, label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate != null
                  ? DateFormat('dd MMMM yyyy').format(selectedDate)
                  : 'เลือกวันที่',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
