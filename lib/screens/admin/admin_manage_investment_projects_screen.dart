// lib/screens/admin/admin_manage_investment_projects_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/investment_project.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:green_market/models/app_notification.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminManageInvestmentProjectsScreen extends StatefulWidget {
  const AdminManageInvestmentProjectsScreen({super.key});

  @override
  State<AdminManageInvestmentProjectsScreen> createState() =>
      _AdminManageInvestmentProjectsScreenState();
}

class _AdminManageInvestmentProjectsScreenState
    extends State<AdminManageInvestmentProjectsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการโครงการลงทุน',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<InvestmentProject>>(
        stream: firebaseService.getAllInvestmentProjectsForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีโครงการลงทุนในระบบ'));
          }

          final projects = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  // Ensure imageUrl is not null
                  // Use a placeholder if imageUrl is null or empty
                  leading: project.imageUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(project.imageUrl),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        )
                      : CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.business_center_outlined,
                              color: Colors.white),
                        ),
                  title: Text(project.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'เป้าหมาย: ฿${NumberFormat("#,##0").format(project.goalAmount)}'),
                      Text(
                          'ระดมทุนได้: ฿${NumberFormat("#,##0").format(project.currentAmount)}'),
                      Text('ผู้เสนอ: ${project.projectOwnerName}'),
                      Text(
                        'สถานะการส่ง: ${project.submissionStatus}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getSubmissionStatusColor(
                              project.submissionStatus as String),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (project.rejectionReason != null &&
                          project.rejectionReason!.isNotEmpty)
                        Text(
                          'เหตุผลการปฏิเสธ: ${project.rejectionReason}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.red),
                        ),
                      Text(
                        'สถานะ: ${project.isActive ? 'เปิดใช้งาน' : 'พักชั่วคราว'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: project.isActive ? Colors.green : Colors.grey,
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
                            _showProjectDialog(context, project: project),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outlined,
                            color: Colors.red),
                        onPressed: () => _deleteProject(
                            context, firebaseService, project.id),
                      ),
                      // ignore: unrelated_type_equality_checks
                      if (project.submissionStatus == 'pending')
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'approve') {
                              _approveProject(
                                  context, firebaseService, project.id);
                            } else if (value == 'reject') {
                              _rejectProject(
                                  context, firebaseService, project.id);
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
                            _toggleProjectActiveStatus(context, firebaseService,
                                project.id, project.isActive);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'toggle_active',
                            child: Text(project.isActive
                                ? 'พักโครงการ'
                                : 'เปิดใช้งานโครงการ'),
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
        onPressed: () => _showProjectDialog(context),
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

  void _approveProject(BuildContext context, FirebaseService firebaseService,
      String projectId) async {
    try {
      final project = await firebaseService.getInvestmentProjectById(projectId);
      if (project == null) {
        showAppSnackBar(context, 'ไม่พบโครงการที่ต้องการอนุมัติ',
            isError: true);
        return;
      }

      await FirebaseService.approveInvestmentProject(projectId);

      final notification = AppNotification(
        id: firebaseService.generateNewDocId('notifications'),
        userId: project.projectOwnerId,
        title: 'โครงการลงทุนของคุณได้รับการอนุมัติ',
        body:
            'โครงการ "${project.title}" ของคุณได้รับการอนุมัติแล้ว และจะแสดงในแอปพลิเคชัน',
        type: NotificationType.investmentApproved,
        relatedId: projectId,
        createdAt: Timestamp.now(),
      );
      await firebaseService.addNotification(notification);
      showAppSnackBar(context, 'อนุมัติโครงการสำเร็จ', isSuccess: true);
    } catch (e) {
      showAppSnackBar(context, 'เกิดข้อผิดพลาดในการอนุมัติ: ${e.toString()}',
          isError: true);
    }
  }

  void _toggleProjectActiveStatus(
      BuildContext context,
      FirebaseService firebaseService,
      String projectId,
      bool currentStatus) async {
    try {
      await firebaseService.toggleInvestmentProjectActiveStatus(
          projectId, !currentStatus);
      showAppSnackBar(
        context,
        currentStatus ? 'พักโครงการสำเร็จ' : 'เปิดใช้งานโครงการสำเร็จ',
        isSuccess: true,
      );
    } catch (e) {
      showAppSnackBar(
        context,
        'เกิดข้อผิดพลาดในการ${currentStatus ? 'พัก' : 'เปิดใช้งาน'}โครงการ: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _rejectProject(BuildContext context, FirebaseService firebaseService,
      String projectId) async {
    TextEditingController reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ปฏิเสธโครงการ'),
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
                  final project =
                      await firebaseService.getInvestmentProjectById(projectId);
                  if (project == null) {
                    showAppSnackBar(context, 'ไม่พบโครงการที่ต้องการปฏิเสธ',
                        isError: true);
                    return;
                  }

                  await firebaseService.rejectInvestmentProject(
                      projectId, reasonController.text.trim());

                  final notification = AppNotification(
                    id: firebaseService.generateNewDocId('notifications'),
                    userId: project.projectOwnerId,
                    title: 'โครงการลงทุนของคุณถูกปฏิเสธ',
                    body:
                        'โครงการ "${project.title}" ของคุณถูกปฏิเสธด้วยเหตุผล: ${reasonController.text.trim()}',
                    type: NotificationType.investmentRejected,
                    relatedId: projectId,
                    createdAt: Timestamp.now(),
                  );
                  await firebaseService.addNotification(notification);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  showAppSnackBar(context, 'ปฏิเสธโครงการสำเร็จ',
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

  void _deleteProject(BuildContext context, FirebaseService firebaseService,
      String projectId) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบโครงการนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseService.deleteInvestmentProject(projectId);
                showAppSnackBar(context, 'ลบโครงการสำเร็จ', isSuccess: true);
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

  void _showProjectDialog(BuildContext context, {InvestmentProject? project}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: project?.title ?? '');
    final descriptionController =
        TextEditingController(text: project?.description ?? '');
    final imageUrlController =
        TextEditingController(text: project?.imageUrl ?? '');
    final targetAmountController =
        TextEditingController(text: project?.goalAmount.toString() ?? '');
    final expectedReturnRateController = TextEditingController(
        text: project?.expectedReturnRate.toString() ?? '');

    String? selectedRiskLevel = (project?.riskLevel ?? 'Medium') as String?;
    DateTime? selectedStartDate = project?.startDate;
    DateTime? selectedEndDate = project?.endDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(project == null ? 'เพิ่มโครงการใหม่' : 'แก้ไขโครงการ'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                        controller: titleController,
                        decoration:
                            buildInputDecoration(context, 'ชื่อโครงการ'),
                        validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: descriptionController,
                        decoration:
                            buildInputDecoration(context, 'คำอธิบายโครงการ'),
                        maxLines: 3,
                        validator: (v) =>
                            v!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: imageUrlController,
                        decoration: buildInputDecoration(context, 'URL รูปภาพ'),
                        keyboardType: TextInputType.url,
                        validator: (v) =>
                            v!.isEmpty ? 'กรุณากรอก URL รูปภาพ' : null),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: targetAmountController,
                        decoration:
                            buildInputDecoration(context, 'จำนวนเงินเป้าหมาย'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ||
                                double.tryParse(v) == null ||
                                double.parse(v) <= 0
                            ? 'กรุณากรอกจำนวนเงินเป้าหมายที่ถูกต้อง'
                            : null),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: expectedReturnRateController,
                        decoration: buildInputDecoration(
                            context, 'อัตราผลตอบแทนที่คาดหวัง (%)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ||
                                double.tryParse(v) == null ||
                                double.parse(v) <= 0
                            ? 'กรุณากรอกอัตราผลตอบแทนที่ถูกต้อง'
                            : null),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRiskLevel,
                      decoration:
                          buildInputDecoration(context, 'ระดับความเสี่ยง'),
                      items: const ['Low', 'Medium', 'High']
                          .map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRiskLevel = newValue;
                        });
                      },
                      validator: (v) =>
                          v == null ? 'กรุณาเลือกระดับความเสี่ยง' : null,
                    ),
                    const SizedBox(height: 10),
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
                    final updatedProject = InvestmentProject(
                      id: project?.id ??
                          firebaseService
                              .generateNewDocId('investment_projects'),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      imageUrl: imageUrlController.text.trim(),
                      goalAmount: double.parse(targetAmountController.text),
                      currentAmount: project?.currentAmount ?? 0.0,
                      startDate: selectedStartDate!,
                      endDate: selectedEndDate!,
                      projectOwnerId: project?.projectOwnerId ?? '',
                      projectOwnerName: project?.projectOwnerName ?? '',
                      expectedReturnRate:
                          double.parse(expectedReturnRateController.text),
                      riskLevel: RiskLevel.values
                          .firstWhere((e) => e.name == selectedRiskLevel),
                      submissionStatus: project?.submissionStatus ??
                          ProjectSubmissionStatus.pending,
                      isActive: project?.isActive ?? true,
                    );

                    if (project == null) {
                      await FirebaseService.addInvestmentProject(
                          updatedProject);
                      showAppSnackBar(context, 'เพิ่มโครงการสำเร็จ',
                          isSuccess: true);
                    } else {
                      await FirebaseService.updateInvestmentProject(
                          updatedProject);
                      showAppSnackBar(context, 'แก้ไขโครงการสำเร็จ',
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
