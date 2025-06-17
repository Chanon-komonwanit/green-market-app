// lib/utils/constants.dart
// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';

class AppColors {
  // Peacock Green / Teal Tones
  static const Color primaryTeal = Color(0xFF008080); // สีเขียวหางนกยูงหลัก
  static const Color lightTeal =
      Color(0xFF4DB6AC); // สีเขียวหางนกยูงอ่อน (สำหรับ Accent)
  static const Color veryLightTeal = Color(
      0xFFB2DFDB); // สีเขียวหางนกยูงอ่อนมาก (สำหรับพื้นหลังหรือส่วนประกอบรอง)

  // Modern Grey Tones
  static const Color modernGrey = Color(0xFF757575); // เทาโมเดิร์น
  static const Color lightModernGrey = Color(0xFFBDBDBD); // เทาโมเดิร์นอ่อน

  // Earthy Accent Tones
  static const Color earthyBrown = Color(0xFFA1887F); // สีน้ำตาลเอิร์ธโทนอ่อน
  static const Color lightEarthyBeige = Color(0xFFD7CCC8); // สีเบจเอิร์ธโทน

  static const Color white = Colors.white;
  static const Color offWhite = Color(0xFFFAFAFA); // สีขาวนวล
  static const Color black = Colors.black;
  static const Color errorRed = Color(0xFFE57373); // แดงอ่อนสำหรับ Error
  static const Color warningYellow = Colors.amber;
  static const Color successGreen =
      Color(0xFF81C784); // เขียวสำหรับ Success (อาจใช้ lightTeal แทนได้)

  // Legacy (can be phased out or mapped to new theme)
  static const Color primaryGreen =
      primaryTeal; // Map old primaryGreen to new primaryTeal
  static const Color accentGreen = lightTeal;
  static const Color darkGrey = modernGrey;
  static const Color lightGrey = lightModernGrey;
  static const Color lightBeige = veryLightTeal;

  static const Color modernDarkGrey = Color(0xFF424242);

  static const Color primaryDarkGreen = Color(0xFF00695C); // Darker Teal

  static const Color warningOrange = Colors.orangeAccent; // Example Orange
}

class AppTextStyles {
  // Consider defining a base font family for the app in main.dart Theme
  // static const String baseFontFamily = 'Nunito'; // Example

  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    // fontFamily: baseFontFamily,
    color: AppColors.primaryTeal, // ใช้สีหลักใหม่
  );
  static const TextStyle headline = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    // fontFamily: baseFontFamily,
    color: AppColors.primaryTeal,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    // fontFamily: baseFontFamily,
    color: AppColors.modernGrey,
  );
  static final TextStyle subtitleBold = subtitle.copyWith(
      fontWeight: FontWeight.bold, color: AppColors.primaryDarkGreen);

  static const TextStyle body = TextStyle(
    fontSize: 16,
    /*fontFamily: baseFontFamily,*/ color: AppColors.modernGrey,
  );
  static final TextStyle bodySmall = body.copyWith(fontSize: 14);

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    // fontFamily: baseFontFamily,
    color: AppColors.primaryTeal,
  );

  static const TextStyle link = TextStyle(
    fontSize: 16,
    // fontFamily: baseFontFamily,
    color: AppColors.lightTeal, // ใช้สีอ่อนลงสำหรับลิงก์
    decoration: TextDecoration.underline,
  );

  static const TextStyle bodyBold = TextStyle(
      fontSize: 16,
      // fontFamily: baseFontFamily,
      color: AppColors.modernGrey, // Changed from darkGrey
      fontWeight: FontWeight.bold);
  static const TextStyle caption = TextStyle(
      fontSize: 12,
      /*fontFamily: baseFontFamily,*/ color: AppColors.modernGrey);
  static final TextStyle captionBold =
      caption.copyWith(fontWeight: FontWeight.bold);

  static final TextStyle bodyGreen =
      body.copyWith(color: AppColors.successGreen);

  static final TextStyle bodyYellow =
      body.copyWith(color: AppColors.warningYellow);

  static final TextStyle bodyRed = body.copyWith(color: AppColors.errorRed);

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    // fontFamily: baseFontFamily,
    color: AppColors.white, // Default button text color
  );
}

enum EcoLevel {
  starter, // 10-34%
  moderate, // 35-69%
  hero, // 70-100%
}

extension EcoLevelExtension on EcoLevel {
  String get name {
    switch (this) {
      case EcoLevel.starter:
        return 'ระดับรักษ์โลก: เบื้องต้น';
      case EcoLevel.moderate:
        return 'ระดับรักษ์โลก: ปานกลาง';
      case EcoLevel.hero:
        return 'ระดับรักษ์โลก: ขั้นสูง';
    }
  }

  String get englishName {
    switch (this) {
      case EcoLevel.starter:
        return 'Eco Starter';
      case EcoLevel.moderate:
        return 'Eco Smart';
      case EcoLevel.hero:
        return 'Eco Hero';
    }
  }

  String get shortCode {
    switch (this) {
      case EcoLevel.starter:
        return '🌱 Eco Starter 😠';
      case EcoLevel.moderate:
        return '🌿 Eco Smart 😊';
      case EcoLevel.hero:
        return '🌳 Eco Hero 😄';
    }
  }

  IconData get icon {
    switch (this) {
      case EcoLevel.starter:
        return Icons.spa_outlined;
      case EcoLevel.moderate:
        return Icons.eco_rounded;
      case EcoLevel.hero:
        return Icons.verified_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EcoLevel.starter:
        return const Color.fromARGB(
            255, 22, 106, 3); // หรือสีส้มที่เข้ากับธีม Teal
      case EcoLevel.moderate:
        return AppColors.lightTeal; // ใช้สี lightTeal
      case EcoLevel.hero:
        return AppColors.primaryTeal; // ใช้สี primaryTeal
    }
  }

  static EcoLevel fromScore(int score) {
    if (score >= 70) {
      return EcoLevel.hero;
    } else if (score >= 35) {
      return EcoLevel.moderate;
    } else {
      return EcoLevel.starter;
    }
  }
}

// Admin Configuration
const String kAdminEmail = 'chanonkomonwanit@gmail.com';
