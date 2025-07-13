// lib/screens/investment_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/investment_summary.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/investment_project/my_investments_screen.dart';
import 'package:green_market/screens/investment_project/my_submitted_investment_projects_screen.dart';
import 'package:green_market/screens/investment_project_list_screen.dart';
import 'package:green_market/screens/submit_investment_project_screen.dart';
import 'package:green_market/screens/investment/p2p_lending_coming_soon_screen.dart';
import 'package:green_market/screens/investment/esg_funds_coming_soon_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/investment_project.dart';

import 'investment_project_detail_screen.dart';

class InvestmentHubScreen extends StatelessWidget {
  const InvestmentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'โซนลงทุนความยั่งยืน',
          style: AppTextStyles.title.copyWith(
            color: AppColors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryTeal.withAlpha((0.1 * 255).round()),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header Section
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF99F6E4),
                          Color(0xFFE0F2FE),
                          Colors.white
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryTeal,
                                AppColors.primaryGreen
                              ],
                            ),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.13),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            size: 54,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'ลงทุนเพื่ออนาคตที่ยั่งยืน',
                          style: AppTextStyles.title.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'สร้างผลตอบแทนพร้อมช่วยดูแลโลก\nเลือกรูปแบบการลงทุนที่เหมาะกับคุณ',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.modernGrey,
                            height: 1.5,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Investment Types Section
                _buildSectionTitle(context, 'รูปแบบการลงทุน',
                    icon: Icons.account_balance_wallet),
                const SizedBox(height: 16),

                // Investment Types with animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Column(
                    children: [
                      _buildInvestmentTypeCard(
                        context,
                        title: 'ระดมทุนโครงการ',
                        subtitle: 'ลงทุนในโครงการสีเขียวที่น่าสนใจ',
                        description:
                            'เลือกลงทุนในโครงการที่คุณเชื่อมั่น พร้อมติดตามผลตอบแทนและผลกระทบเชิงบวก',
                        icon: Icons.business_center,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        ),
                        isActive: true,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const InvestmentProjectListScreen())),
                      ),
                      const SizedBox(height: 16),
                      _buildInvestmentTypeCard(
                        context,
                        title: 'สนับสนุนธุรกิจสีเขียว',
                        subtitle: 'P2P Lending สำหรับ SME สีเขียว',
                        description:
                            'ให้กู้เงินกับธุรกิจขนาดเล็กที่เน้นความยั่งยืน รับดอกเบี้ยตอบแทนที่น่าสนใจ',
                        icon: Icons.handshake,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                        ),
                        isActive: false,
                        comingSoonText: 'เร็วๆ นี้',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const P2PLendingComingSoonScreen())),
                      ),
                      const SizedBox(height: 16),
                      _buildInvestmentTypeCard(
                        context,
                        title: 'กองทุน ESG',
                        subtitle: 'Environmental, Social & Governance',
                        description:
                            'ลงทุนในกองทุนที่คัดเลือกหุ้นจากบริษัทที่มีการดำเนินงานที่ยั่งยืน',
                        icon: Icons.pie_chart,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                        ),
                        isActive: false,
                        comingSoonText: 'เร็วๆ นี้',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ESGFundsComingSoonScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Project Summary Section (Only for active crowdfunding)
                _buildSectionTitle(context, 'ภาพรวมการระดมทุนโครงการ',
                    icon: Icons.insights_outlined),
                const SizedBox(height: 16),
                FutureBuilder<InvestmentSummary>(
                  future: firebaseService.getInvestmentProjectSummary(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                          child: Text('ไม่สามารถโหลดข้อมูลได้'));
                    }
                    final summary = snapshot.data!;
                    final totalProjects = summary.totalProjects;
                    final activeProjects = summary.activeProjects;
                    final totalRaised = summary.totalAmountRaised;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.08 * 255).round()),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
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
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Featured Projects Section
                _buildSectionTitle(context, 'โครงการแนะนำ',
                    icon: Icons.star_border_outlined),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: _buildFeaturedProjects(context, firebaseService),
                ),

                const SizedBox(height: 32),

                // User Actions Section
                if (userProvider.isLoggedIn) ...[
                  _buildSectionTitle(context, 'การจัดการของคุณ',
                      icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    context,
                    'การลงทุนของฉัน',
                    'ติดตามและจัดการการลงทุนที่คุณเข้าร่วม',
                    Icons.account_balance_wallet_outlined,
                    () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const MyInvestmentsScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    'โครงการที่ฉันเสนอ',
                    'ดูและจัดการโครงการที่คุณเป็นเจ้าของ',
                    Icons.assignment_ind_outlined,
                    () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            const MySubmittedInvestmentProjectsScreen())),
                  ),
                  const SizedBox(height: 12),
                ],

                // Submit Project Action
                _buildActionCard(
                  context,
                  'เสนอโครงการใหม่',
                  'ส่งโครงการของคุณเพื่อขอระดมทุน',
                  Icons.add_business_outlined,
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SubmitInvestmentProjectScreen())),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required bool isActive,
    String? comingSoonText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                              if (!isActive && comingSoonText != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange
                                        .withAlpha((0.2 * 255).round()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    comingSoonText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.modernGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.modernGrey,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.modernGrey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.modernGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primaryTeal, size: 24),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.05 * 255).round()),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryTeal, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.modernGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.modernGrey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProjects(
      BuildContext context, FirebaseService firebaseService) {
    return StreamBuilder<List<InvestmentProject>>(
      stream: firebaseService.getInvestmentProjects(
          isActive: true, sortBy: 'currentAmount', descending: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.05 * 255).round()),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'ไม่มีโครงการแนะนำในขณะนี้',
                style: TextStyle(
                  color: AppColors.modernGrey,
                  fontSize: 14,
                ),
              ),
            ),
          );
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
    );
  }

  Widget _buildProjectCard(BuildContext context, InvestmentProject project) {
    final currencyFormat =
        NumberFormat.compactCurrency(locale: 'th_TH', symbol: '฿');

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  InvestmentProjectDetailScreen(project: project),
            ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      project.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.background,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.modernGrey,
                          size: 40,
                        ),
                      ),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: project.fundingProgress,
                        borderRadius: BorderRadius.circular(5),
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ระดมทุนได้ ${currencyFormat.format(project.currentAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.modernGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
