// d:/Development/green_market/lib/screens/investment_project/my_submitted_investment_projects_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/investment_project.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/investment_project_detail_screen.dart';
import 'package:green_market/screens/submit_investment_project_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MySubmittedInvestmentProjectsScreen extends StatelessWidget {
  const MySubmittedInvestmentProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    final ownerId = userProvider.currentUser?.id;

    if (ownerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('โครงการที่ฉันเสนอ',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
        ),
        body: const Center(
            child: Text('กรุณาเข้าสู่ระบบเพื่อดูโครงการที่คุณเสนอ')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('โครงการที่ฉันเสนอ',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SubmitInvestmentProjectScreen(),
              ));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<InvestmentProject>>(
        stream: firebaseService.getProjectsByProjectOwner(ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('คุณยังไม่ได้เสนอโครงการใดๆ'));
          }

          final projects = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectCard(context, project);
            },
          );
        },
      ),
    );
  }

  // --- CORRECTED: Accepts ProjectSubmissionStatus enum ---
  Color _getSubmissionStatusColor(ProjectSubmissionStatus status) {
    switch (status) {
      case ProjectSubmissionStatus.approved:
        return Colors.green;
      case ProjectSubmissionStatus.pending:
        return Colors.orange;
      case ProjectSubmissionStatus.rejected:
        return Colors.red;
    }
  }

  // --- CORRECTED: Accepts ProjectSubmissionStatus enum ---
  String _getSubmissionStatusDisplay(ProjectSubmissionStatus status) {
    switch (status) {
      case ProjectSubmissionStatus.approved:
        return 'อนุมัติแล้ว';
      case ProjectSubmissionStatus.pending:
        return 'รอดำเนินการ';
      case ProjectSubmissionStatus.rejected:
        return 'ถูกปฏิเสธ';
    }
  }

  Widget _buildProjectCard(BuildContext context, InvestmentProject project) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final progress = project.fundingProgress;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          // --- CORRECTED: Moved properties before child ---
          backgroundImage: NetworkImage(project.imageUrl),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: project.imageUrl.isNotEmpty
              ? null
              : const Icon(Icons.business_center_outlined, color: Colors.white),
        ),
        title: Text(project.title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'ระดมทุนได้ ฿${currencyFormat.format(project.currentAmount)} จากเป้าหมาย ฿${currencyFormat.format(project.goalAmount)}',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: 4),
            Text(
              // --- CORRECTED: Pass enum directly ---
              'สถานะ: ${_getSubmissionStatusDisplay(project.submissionStatus)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getSubmissionStatusColor(project.submissionStatus),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (project.rejectionReason != null &&
                project.rejectionReason!.isNotEmpty)
              Text(
                'เหตุผลการปฏิเสธ: ${project.rejectionReason}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- CORRECTED: Compare with enum values ---
            if (project.submissionStatus == ProjectSubmissionStatus.pending ||
                project.submissionStatus == ProjectSubmissionStatus.rejected)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SubmitInvestmentProjectScreen(project: project),
                  ));
                },
              ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      InvestmentProjectDetailScreen(project: project),
                ));
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                InvestmentProjectDetailScreen(project: project),
          ));
        },
      ),
    );
  }
}
