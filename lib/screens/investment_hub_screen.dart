// lib/screens/investment_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/investment_summary.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/investment_project/my_investments_screen.dart';
import 'package:green_market/screens/investment_project/my_submitted_investment_projects_screen.dart';
import 'package:green_market/screens/investment_project_list_screen.dart';
import 'package:green_market/screens/submit_investment_project_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/investment_project.dart';

import 'investment_project_detail_screen.dart';

class InvestmentHubScreen extends StatelessWidget {
  const InvestmentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('ศูนย์รวมการลงทุน',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'ภาพรวมการลงทุน',
                icon: Icons.insights_outlined),
            const SizedBox(height: 8),
            FutureBuilder<InvestmentSummary>(
              future: firebaseService.getInvestmentProjectSummary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('ไม่สามารถโหลดข้อมูลได้'));
                }
                final summary = snapshot.data!;
                final totalProjects = summary.totalProjects;
                final activeProjects = summary.activeProjects;
                final totalRaised = summary.totalAmountRaised;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(context, 'โครงการทั้งหมด',
                        totalProjects.toString(), Colors.blue),
                    _buildSummaryItem(context, 'โครงการที่เปิดอยู่',
                        activeProjects.toString(), Colors.green),
                    _buildSummaryItem(
                        context,
                        'ระดมทุนแล้ว',
                        '฿${NumberFormat.compact().format(totalRaised)}',
                        Colors.purple),
                  ],
                );
              },
            ),
            const Divider(height: 32),
            _buildSectionTitle(context, 'โครงการแนะนำ',
                icon: Icons.star_border_outlined),
            const SizedBox(height: 8),
            _buildFeaturedProjects(context, firebaseService),
            const Divider(height: 32),
            _buildSectionTitle(context, 'การดำเนินการ',
                icon: Icons.menu_outlined),
            const SizedBox(height: 8),
            _buildActionCard(
              context,
              'ดูโครงการทั้งหมด',
              'ค้นหาและเลือกลงทุนในโครงการที่น่าสนใจ',
              Icons.explore_outlined,
              () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const InvestmentProjectListScreen())),
            ),
            _buildActionCard(
              context,
              'เสนอโครงการของคุณ',
              'ส่งโครงการเพื่อขอระดมทุนจากนักลงทุน',
              Icons.add_business_outlined,
              () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SubmitInvestmentProjectScreen())),
            ),
            if (userProvider.isLoggedIn) ...[
              _buildActionCard(
                context,
                'การลงทุนของฉัน',
                'ติดตามและจัดการการลงทุนที่คุณเข้าร่วม',
                Icons.account_balance_wallet_outlined,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MyInvestmentsScreen())),
              ),
              _buildActionCard(
                context,
                'โครงการที่ฉันเสนอ',
                'ดูและจัดการโครงการที่คุณเป็นเจ้าของ',
                Icons.assignment_ind_outlined,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        const MySubmittedInvestmentProjectsScreen())),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String title, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {IconData? icon}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Text(title, style: theme.textTheme.titleLarge),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary, size: 30),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFeaturedProjects(
      BuildContext context, FirebaseService firebaseService) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<List<InvestmentProject>>(
        stream: firebaseService.getInvestmentProjects(
            isActive: true, sortBy: 'currentAmount', descending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีโครงการแนะนำในขณะนี้'));
          }
          final projects = snapshot.data!.take(5).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return _buildProjectCard(context, projects[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, InvestmentProject project) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.compactCurrency(locale: 'th_TH', symbol: '฿');

    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(right: 12.0),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  InvestmentProjectDetailScreen(project: project),
            ));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.network(
                  project.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.surfaceContainer,
                    child: Icon(Icons.image_not_supported,
                        color: theme.colorScheme.onSurfaceVariant, size: 40),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: project.fundingProgress,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ระดมทุนได้ ${currencyFormat.format(project.currentAmount)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
