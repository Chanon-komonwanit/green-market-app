// lib/screens/green_world_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/investment_hub_screen.dart';
import 'package:green_market/screens/sustainable_activities_hub_screen.dart';

class GreenWorldHubScreen extends StatelessWidget {
  const GreenWorldHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'เปิดโลกสีเขียว',
          style: AppTextStyles.title.copyWith(
            color: AppColors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGreen.withAlpha((0.1 * 255).round()),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
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
                      Icon(
                        Icons.eco,
                        size: 64,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'เปิดโลกสีเขียว',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'สำรวจโอกาสในการลงทุนที่ยั่งยืน\nและเข้าร่วมกิจกรรมเพื่อสิ่งแวดล้อม',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.modernGrey,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Two Main Features
                Expanded(
                  child: Column(
                    children: [
                      // Investment Section
                      Expanded(
                        child: _buildFeatureCard(
                          context: context,
                          title: 'ลงทุนความยั่งยืน',
                          subtitle: 'สร้างผลตอบแทนพร้อมดูแลโลก',
                          description:
                              'ลงทุนในโครงการที่เป็นมิตรกับสิ่งแวดล้อม\nและสร้างผลตอบแทนที่ยั่งยืน',
                          icon: Icons.trending_up,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.primaryTeal,
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InvestmentHubScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Activities Section
                      Expanded(
                        child: _buildFeatureCard(
                          context: context,
                          title: 'กิจกรรมเพื่อสังคม',
                          subtitle: 'ร่วมเป็นส่วนหนึ่งของการเปลี่ยนแปลง',
                          description:
                              'เข้าร่วมกิจกรรมอนุรักษ์สิ่งแวดล้อม\nและสร้างผลกระทบเชิงบวกให้สังคม',
                          icon: Icons.volunteer_activism,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.lightTeal,
                              AppColors.primaryGreen,
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SustainableActivitiesHubScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Footer Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withAlpha((0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ทั้งสองฟีเจอร์นี้เป็นส่วนเสริมของแพลตฟอร์ม\nเพื่อส่งเสริมการใช้ชีวิตที่เป็นมิตรกับสิ่งแวดล้อม',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.modernGrey,
                            height: 1.4,
                          ),
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

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.15 * 255).round()),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha((0.2 * 255).round()),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.3 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withAlpha((0.8 * 255).round()),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.title.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTextStyles.bodyBold.copyWith(
                  color: Colors.white.withAlpha((0.9 * 255).round()),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withAlpha((0.8 * 255).round()),
                    height: 1.3,
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
