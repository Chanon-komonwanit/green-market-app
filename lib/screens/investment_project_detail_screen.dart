// lib/screens/investment_project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/models/investment_project.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase User
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/investment_opportunity_detail_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/project_question.dart'; // Import ProjectQuestion
import 'package:green_market/models/project_update.dart'; // Import ProjectUpdate
import 'package:green_market/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:green_market/utils/constants.dart'; // Import for kAdminEmail

class InvestmentProjectDetailScreen extends StatefulWidget {
  final InvestmentProject project;

  const InvestmentProjectDetailScreen({super.key, required this.project});

  @override
  State<InvestmentProjectDetailScreen> createState() =>
      _InvestmentProjectDetailScreenState();
}

class _InvestmentProjectDetailScreenState
    extends State<InvestmentProjectDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return _InvestmentProjectDetailScreenContent(
        project: widget.project, user: userProvider.currentUser);
  }
}

class _InvestmentProjectDetailScreenContent extends StatefulWidget {
  final InvestmentProject project;
  final AppUser? user;

  const _InvestmentProjectDetailScreenContent(
      {required this.project, this.user});

  @override
  State<_InvestmentProjectDetailScreenContent> createState() =>
      _InvestmentProjectDetailScreenContentState();
}

class _InvestmentProjectDetailScreenContentState
    extends State<_InvestmentProjectDetailScreenContent> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _updateTitleController = TextEditingController();
  final TextEditingController _updateContentController =
      TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    _updateTitleController.dispose();
    _updateContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final progress = (widget.project.goalAmount > 0)
        ? (widget.project.currentAmount / widget.project.goalAmount)
            .clamp(0.0, 1.0)
        : 0.0;
    final daysLeft = widget.project.endDate.difference(DateTime.now()).inDays;

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.savings_outlined),
          label: const Text('ร่วมลงทุน'),
          onPressed: widget.project.submissionStatus ==
                      ProjectSubmissionStatus.approved &&
                  widget.project.currentAmount < widget.project.goalAmount &&
                  widget.project.isActive
              ? () => _showInvestmentDialog(context)
              : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: widget.project.submissionStatus ==
                          ProjectSubmissionStatus.approved &&
                      widget.project.currentAmount <
                          widget.project.goalAmount &&
                      widget.project.isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.project.title,
                style: const TextStyle(
                  shadows: [
                    Shadow(blurRadius: 8.0, color: Colors.black54),
                  ],
                ),
              ),
              background: Image.network(
                widget.project.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child:
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text('โดย: ${widget.project.projectOwnerName}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProgressCard(context, progress, currencyFormat),
                  const SizedBox(height: 16),
                  _buildInfoChips(context, daysLeft),
                  const Divider(height: 32),
                  _buildDetailSection(
                      context, 'เกี่ยวกับโครงการ', widget.project.description),
                  const SizedBox(height: 24),
                  _buildQATabs(context),
                  const SizedBox(height: 24),
                  _buildUpdatesSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      BuildContext context, double progress, NumberFormat currencyFormat) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ระดมทุนได้', style: theme.textTheme.bodyLarge),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '฿${currencyFormat.format(widget.project.currentAmount)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
                Text(
                  'เป้าหมาย: ฿${currencyFormat.format(widget.project.goalAmount)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChips(BuildContext context, int daysLeft) {
    String daysLeftText;
    if (daysLeft > 0) {
      daysLeftText = '$daysLeft วัน';
    } else if (daysLeft == 0) {
      daysLeftText = 'วันสุดท้าย';
    } else {
      daysLeftText = 'สิ้นสุดแล้ว';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoChip(
            context,
            'ผลตอบแทน',
            '${widget.project.expectedReturnRate.toStringAsFixed(1)}%',
            Icons.trending_up),
        _buildInfoChip(context, 'ความเสี่ยง',
            widget.project.riskLevel.name.capitalize(), Icons.shield_outlined),
        _buildInfoChip(context, 'สิ้นสุด', daysLeftText, Icons.timer_outlined),
      ],
    );
  }

  Widget _buildInfoChip(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDetailSection(
      BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(content, style: theme.textTheme.bodyLarge),
      ],
    );
  }

  void _showInvestmentDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    if (userProvider.currentUser == null) {
      showAppSnackBar(context, 'กรุณาเข้าสู่ระบบเพื่อร่วมลงทุน', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ร่วมลงทุนในโครงการ'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.project.title,
                    style: Theme.of(dialogContext).textTheme.titleMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'จำนวนเงิน (บาท)',
                    prefixText: '฿ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกจำนวนเงิน';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'จำนวนเงินต้องมากกว่า 0';
                    }
                    final remaining = widget.project.goalAmount -
                        widget.project.currentAmount;
                    if (amount > remaining) {
                      return 'จำนวนเงินลงทุนเกินกว่าที่ต้องการ (${remaining.toStringAsFixed(2)} บาท)';
                    }
                    return null;
                  },
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
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  try {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) => const Center(
                              child: CircularProgressIndicator(),
                            ));

                    await firebaseService.investInProject(
                      widget.project.id,
                      userProvider.currentUser!.id,
                      amount,
                    );

                    if (context.mounted) Navigator.of(context).pop();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }

                    showAppSnackBar(context, 'ลงทุนสำเร็จ!', isSuccess: true);
                  } catch (e) {
                    if (context.mounted) Navigator.of(context).pop();
                    showAppSnackBar(
                        dialogContext, 'เกิดข้อผิดพลาด: ${e.toString()}',
                        isError: true);
                  }
                }
              },
              child: const Text('ยืนยันการลงทุน'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQATabs(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('คำถาม-คำตอบ', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (widget.user != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'ถามคำถามเกี่ยวกับโครงการ...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: () async {
                    if (_questionController.text.trim().isNotEmpty) {
                      final userProvider =
                          Provider.of<UserProvider>(context, listen: false);
                      final firebaseService =
                          Provider.of<FirebaseService>(context, listen: false);
                      if (userProvider.currentUser != null) {
                        try {
                          await firebaseService.addProjectQuestion({
                            'projectId': widget.project.id,
                            'userId': userProvider.currentUser!.id,
                            'userName': userProvider.currentUser!.displayName ??
                                userProvider.currentUser!.email,
                            'question': _questionController.text.trim(),
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          showAppSnackBar(context, 'ส่งคำถามสำเร็จ!',
                              isSuccess: true);
                          _questionController.clear();
                        } catch (e) {
                          showAppSnackBar(context,
                              'เกิดข้อผิดพลาดในการส่งคำถาม: ${e.toString()}',
                              isError: true);
                        }
                      } else {
                        showAppSnackBar(
                            context, 'กรุณาเข้าสู่ระบบเพื่อส่งคำถาม',
                            isError: true);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Provider.of<FirebaseService>(context, listen: false)
              .getProjectQuestions(widget.project.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'ยังไม่มีคำถามสำหรับโครงการนี้',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            final questions = snapshot.data!;
            return Card(
              margin: EdgeInsets.zero,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final qa = questions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q: ${qa['question']}',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                            'โดย ${qa['userName']} เมื่อ ${qa['timestamp'] != null ? DateFormat('dd MMM yyyy').format((qa['timestamp'] as Timestamp).toDate()) : 'N/A'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        if (qa['answer'] != null &&
                            qa['answer'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('A: ${qa['answer']}',
                              style: theme.textTheme.bodyMedium),
                          Text(
                              'โดยแอดมิน เมื่อ ${qa['answeredAt'] != null ? DateFormat('dd MMM yyyy').format((qa['answeredAt'] as Timestamp).toDate()) : 'N/A'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ] else if (widget.user?.email == kAdminEmail ||
                            widget.user?.id == widget.project.projectOwnerId)
                          TextButton(
                            onPressed: () => _showAnswerDialog(
                                context, qa['id'], qa['question']),
                            child: const Text('ตอบคำถาม'),
                          ),
                        if (index < questions.length - 1) const Divider(),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAnswerDialog(
      BuildContext context, String questionId, String question) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    // final userProvider = Provider.of<UserProvider>(context, listen: false);
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ตอบคำถาม'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('คำถาม: $question',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'คำตอบของคุณ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (answerController.text.trim().isNotEmpty) {
                  try {
                    await firebaseService.answerProjectQuestion(
                      questionId,
                      answerController.text.trim(),
                    );
                    showAppSnackBar(context, 'ตอบคำถามสำเร็จ!',
                        isSuccess: true);
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    showAppSnackBar(
                        context, 'เกิดข้อผิดพลาดในการตอบคำถาม: ${e.toString()}',
                        isError: true);
                  }
                }
              },
              child: const Text('ส่งคำตอบ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpdatesSection(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('การอัปเดตโครงการ', style: theme.textTheme.titleLarge),
            if (userProvider.currentUser?.email == kAdminEmail ||
                userProvider.currentUser?.id == widget.project.projectOwnerId)
              TextButton(
                onPressed: () => _showAddUpdateDialog(context),
                child: const Text('เพิ่มการอัปเดต'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: firebaseService.getProjectUpdates(widget.project.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'ยังไม่มีการอัปเดตสำหรับโครงการนี้',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            final updates = snapshot.data!;
            return Card(
              margin: EdgeInsets.zero,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: updates.length,
                itemBuilder: (context, index) {
                  final update = updates[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(update['title'] ?? '',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(update['content'] ?? '',
                            style: theme.textTheme.bodyMedium),
                        Text(
                            'โดย ${update['userName'] ?? 'ไม่ระบุ'} เมื่อ ${update['timestamp'] != null ? DateFormat('dd MMM yyyy').format((update['timestamp'] as Timestamp).toDate()) : 'N/A'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        if (index < updates.length - 1) const Divider(),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddUpdateDialog(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    _updateTitleController.clear();
    _updateContentController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('เพิ่มการอัปเดตโครงการ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _updateTitleController,
                decoration: const InputDecoration(
                  labelText: 'หัวข้อการอัปเดต',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _updateContentController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดการอัปเดต',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_updateTitleController.text.trim().isNotEmpty &&
                    _updateContentController.text.trim().isNotEmpty) {
                  try {
                    await firebaseService.addProjectUpdate({
                      'projectId': widget.project.id,
                      'title': _updateTitleController.text.trim(),
                      'content': _updateContentController.text.trim(),
                      'userId': userProvider.currentUser!.id,
                      'userName': userProvider.currentUser!.displayName ??
                          userProvider.currentUser!.email,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    showAppSnackBar(context, 'เพิ่มการอัปเดตสำเร็จ!',
                        isSuccess: true);
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    showAppSnackBar(context,
                        'เกิดข้อผิดพลาดในการเพิ่มการอัปเดต: ${e.toString()}',
                        isError: true);
                  }
                }
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        );
      },
    );
  }
}
