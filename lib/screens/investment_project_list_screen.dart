// investment_project_list_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/investment_project.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/investment_project_detail_screen.dart';

// A helper extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class InvestmentProjectListScreen extends StatefulWidget {
  const InvestmentProjectListScreen({super.key});

  @override
  State<InvestmentProjectListScreen> createState() =>
      _InvestmentProjectListScreenState();
}

class _InvestmentProjectListScreenState
    extends State<InvestmentProjectListScreen> {
  String? _selectedSortBy = 'createdAt';
  bool _sortDescending = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('โครงการลงทุนเพื่อความยั่งยืน',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<String>(
                  value: _selectedSortBy,
                  hint: const Text('เรียงตาม'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSortBy = newValue;
                    });
                  },
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                        value: 'createdAt', child: Text('วันที่สร้าง')),
                    DropdownMenuItem(
                        value: 'endDate', child: Text('วันที่สิ้นสุด')),
                    DropdownMenuItem(
                        value: 'currentAmount', child: Text('ยอดลงทุน')),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_sortDescending
                      ? Icons.arrow_downward
                      : Icons.arrow_upward),
                  onPressed: () {
                    setState(() {
                      _sortDescending = !_sortDescending;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<InvestmentProject>>(
              stream: firebaseService.getInvestmentProjects(
                sortBy: _selectedSortBy,
                descending: _sortDescending,
                isActive: true,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(context, 'ไม่มีโครงการลงทุนในขณะนี้');
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
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, InvestmentProject project) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final progress = project.fundingProgress;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      elevation: 4,
      shadowColor: Colors.black.withAlpha((0.1 * 255).round()),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              height: 200,
              width: double.infinity,
              child: Image.network(
                project.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.colorScheme.surfaceContainer,
                  child: Icon(Icons.image_not_supported,
                      color: theme.colorScheme.onSurfaceVariant, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ระดมทุนได้ ${currencyFormat.format(project.currentAmount)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    'เป้าหมาย: ${currencyFormat.format(project.goalAmount)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.lightTeal.withAlpha((0.2 * 255).round()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    context,
                    Icons.trending_up,
                    'ผลตอบแทน ${project.formattedExpectedReturn}',
                  ),
                  _buildInfoChip(
                    context,
                    Icons.people_outline,
                    'N/A นักลงทุน',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
