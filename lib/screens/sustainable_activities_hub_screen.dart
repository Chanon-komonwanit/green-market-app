// lib/screens/sustainable_activities_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart';

class SustainableActivitiesHubScreen extends StatelessWidget {
  const SustainableActivitiesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'กิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
          style: AppTextStyles.title.copyWith(
            color: AppColors.white,
            fontSize: 18,
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
                        Icons.volunteer_activism,
                        size: 64,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'กิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ร่วมสร้างผลกระทบเชิงบวกให้กับสังคม\nและสิ่งแวดล้อมรอบตัวเรา',
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
                // Coming Soon Section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.lightTeal,
                          AppColors.primaryGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.15 * 255).round()),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.construction,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'กำลังพัฒนา',
                          style: AppTextStyles.title.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ฟีเจอร์นี้กำลังอยู่ระหว่างการพัฒนา\nโปรดรอการอัปเดตในเร็วๆ นี้',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withAlpha((0.9 * 255).round()),
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'เร็วๆ นี้',
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                          'ฟีเจอร์นี้จะรวมกิจกรรมอนุรักษ์สิ่งแวดล้อม\nและกิจกรรมเพื่อสังคมต่างๆ',
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
}
