// lib/utils/constants.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppColors {
  // === Modern Professional Color Palette (World-class Design) ===

  // --- Primary Palette (Teal/Emerald) ---
  // สีหลักสำหรับ Action, ปุ่ม, และส่วนที่ต้องการเน้น
  static const Color primaryTeal =
      Color(0xFF14B8A6); // Teal-500 - Modern & Professional
  static const Color primaryTealDark =
      Color(0xFF0F766E); // Teal-700 - For gradients or dark mode
  static const Color primaryTealLight =
      Color(0xFF99F6E4); // Teal-300 - Light accents
  static const Color emeraldPrimary = Color(0xFF10B981); // Emerald-500

  // --- Secondary Palette (Blue) ---
  // สีรองสำหรับสร้างมิติ หรือใช้ในส่วนเสริม
  static const Color infoBlue = Color(0xFF3B82F6); // Blue-500
  static const Color navyBlue = Color(0xFF1E3A8A); // Blue-800

  // --- Neutral & Utility Palette ---
  // สีกลางที่ใช้คุมโทนแอปทั้งหมด
  static const Color grayPrimary = Color(0xFF1F2937); // Gray-800 - Primary text
  static const Color graySecondary =
      Color(0xFF6B7280); // Gray-500 - Secondary text
  static const Color grayBorder = Color(0xFFE5E7EB); // Gray-200 - Borders

  // --- Surface Colors ---
  // สีสำหรับพื้นผิวต่างๆ เพื่อสร้าง Layer และความสะอาดตา
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF9FAFB); // Gray-50 (Off-white)
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // --- Status & Action Colors ---
  static const Color successGreen = Color(0xFF10B981); // Emerald-500
  static const Color warningAmber = Color(0xFFF59E0B); // Amber-500
  static const Color errorRed = Color(0xFFEF4444); // Red-500
  static const Color accent =
      Color(0xFF8B5CF6); // Violet-500 - For special actions

  // --- Gradients ---
  static const List<Color> gradientPrimary = [
    primaryTeal,
    emeraldPrimary,
  ];
  static const List<Color> gradientBlue = [
    infoBlue,
    navyBlue,
  ];

  // --- Dark Mode Palette (ตัวอย่าง) ---
  static const Color darkBackground = Color(0xFF0F172A); // Slate-900
  static const Color darkSurface = Color(0xFF1E293B); // Slate-800

  // === Legacy Support (เพื่อให้โค้ดเก่าไม่พัง) ===
  // แมพชื่อสีเก่าไปยังสีใหม่ในระบบ
  static const Color primaryGreen = primaryTeal;
  static const Color accentGreen = emeraldPrimary;
  static const Color primaryDarkGreen = primaryTealDark;
  static const Color lightTeal = primaryTealLight;
  static const Color veryLightTeal = primaryTealLight; // Fix for legacy code
  static const Color modernGrey = graySecondary;
  static const Color lightModernGrey = grayBorder;
  static const Color modernDarkGrey = grayPrimary; // Fix for legacy code
  static const Color darkModernGrey = grayPrimary; // Fix for legacy code
  static const Color darkGrey = grayPrimary; // Fix for legacy code
  static const Color lightGrey = grayBorder; // Fix for legacy code
  static const Color white = surfaceWhite;
  static const Color offWhite = surfaceGray;
  static const Color black = grayPrimary; // Fix for legacy code
  static const Color lightBeige = surfaceGray; // Fix for legacy code
  static const Color earthyBrown = graySecondary; // Fix for legacy code
  static const Color darkText = grayPrimary;
  static const Color lightText = graySecondary;
  static const Color background = surfaceGray;
  static const Color warningOrange = warningAmber;
  static const Color warningYellow = warningAmber;
  static const Color alertRed = errorRed;
  static const Color emeraldGreen = emeraldPrimary;
  static const Color modernBlue = infoBlue;
  static const Color deepBlue = navyBlue;
  static const Color peacockBlue = primaryTeal;
}

// Professional 4-level Eco Rating System (ระบบประเมินสินค้าเพื่อสิ่งแวดล้อม 4 ระดับ)
// ระดับสินค้าใหม่: เริ่มต้น 20-39%, มาตรฐาน 40-59%, พรีเมี่ยม 60-89%, Eco Hero 90%+
enum EcoLevel {
  basic, // ระดับเริ่มต้น (20-39%)
  standard, // ระดับมาตรฐาน (40-59%)
  premium, // ระดับพรีเมี่ยม (60-89%)
  hero // ระดับ Eco Hero (90-100%)
}

extension EcoLevelExtension on EcoLevel {
  String get name {
    switch (this) {
      case EcoLevel.basic:
        return 'เริ่มต้น';
      case EcoLevel.standard:
        return 'มาตรฐาน';
      case EcoLevel.premium:
        return 'พรีเมี่ยม';
      case EcoLevel.hero:
        return 'Eco Hero';
    }
  }

  String get thaiName {
    switch (this) {
      case EcoLevel.basic:
        return 'เริ่มต้น';
      case EcoLevel.standard:
        return 'มาตรฐาน';
      case EcoLevel.premium:
        return 'พรีเมี่ยม';
      case EcoLevel.hero:
        return 'Eco Hero';
    }
  }

  String get fullName {
    switch (this) {
      case EcoLevel.basic:
        return 'ระดับเริ่มต้น';
      case EcoLevel.standard:
        return 'ระดับมาตรฐาน';
      case EcoLevel.premium:
        return 'ระดับพรีเมี่ยม';
      case EcoLevel.hero:
        return 'ระดับ Eco Hero';
    }
  }

  String get shortCode {
    switch (this) {
      case EcoLevel.basic:
        return '🌱 เริ่มต้น';
      case EcoLevel.standard:
        return '🌿 มาตรฐาน';
      case EcoLevel.premium:
        return '🏆 พรีเมี่ยม';
      case EcoLevel.hero:
        return '💎 Eco Hero';
    }
  }

  String get description {
    switch (this) {
      case EcoLevel.basic:
        return 'สินค้าระดับเริ่มต้นที่ผ่านการตรวจสอบคุณภาพเบื้องต้น';
      case EcoLevel.standard:
        return 'สินค้าระดับมาตรฐานที่เริ่มใส่ใจสิ่งแวดล้อม';
      case EcoLevel.premium:
        return 'สินค้าระดับพรีเมี่ยมที่มีคุณภาพสูงและเป็นมิตรกับสิ่งแวดล้อม';
      case EcoLevel.hero:
        return 'สินค้าระดับ Eco Hero ที่เป็นจุดสุดยอดของความยั่งยืนและนวัตกรรมสีเขียว';
    }
  }

  String get marketingDescription {
    switch (this) {
      case EcoLevel.basic:
        return 'เริ่มต้นเส้นทางสีเขียว';
      case EcoLevel.standard:
        return 'ตัวเลือกคุณภาพที่เชื่อถือได้';
      case EcoLevel.premium:
        return 'คุณภาพสูง เพื่อโลกที่ดีกว่า';
      case EcoLevel.hero:
        return 'จุดสุดยอดแห่งความเป็นเลิศ สำหรับผู้ที่ต้องการสิ่งที่ดีที่สุด';
    }
  }

  Color get color {
    switch (this) {
      case EcoLevel.basic:
        return AppColors.graySecondary;
      case EcoLevel.standard:
        return AppColors.primaryTeal;
      case EcoLevel.premium:
        return AppColors.warningAmber;
      case EcoLevel.hero:
        return AppColors.accent;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EcoLevel.basic:
        return AppColors.surfaceGray;
      case EcoLevel.standard:
        return AppColors.primaryTeal.withOpacity(0.1);
      case EcoLevel.premium:
        return AppColors.warningAmber.withOpacity(0.1);
      case EcoLevel.hero:
        return AppColors.accent.withOpacity(0.1);
    }
  }

  Color get gradientStart {
    switch (this) {
      case EcoLevel.basic:
        return AppColors.graySecondary;
      case EcoLevel.standard:
        return AppColors.primaryTeal;
      case EcoLevel.premium:
        return AppColors.warningAmber;
      case EcoLevel.hero:
        return AppColors.accent;
    }
  }

  Color get gradientEnd {
    switch (this) {
      case EcoLevel.basic:
        return AppColors.grayBorder;
      case EcoLevel.standard:
        return AppColors.emeraldPrimary;
      case EcoLevel.premium:
        return AppColors.warningAmber;
      case EcoLevel.hero:
        return AppColors.accent;
    }
  }

  IconData get icon {
    switch (this) {
      case EcoLevel.basic:
        return Icons.eco_outlined;
      case EcoLevel.standard:
        return Icons.verified_outlined;
      case EcoLevel.premium:
        return Icons.star_outlined;
      case EcoLevel.hero:
        return Icons.diamond_outlined;
    }
  }

  // Map eco score (20-100) to eco level (4-tier system) - ไม่มีสินค้าต่ำกว่า 20%
  static EcoLevel fromScore(int score) {
    if (score < 20) return EcoLevel.basic; // fallback สำหรับ edge case
    if (score < 40) return EcoLevel.basic; // 20-39%
    if (score < 60) return EcoLevel.standard; // 40-59%
    if (score < 90) return EcoLevel.premium; // 60-89%
    return EcoLevel.hero; // 90-100%
  }

  // Get percentage range for display
  String get scoreRange {
    switch (this) {
      case EcoLevel.basic:
        return '20-39%';
      case EcoLevel.standard:
        return '40-59%';
      case EcoLevel.premium:
        return '60-89%';
      case EcoLevel.hero:
        return '90-100%';
    }
  }

  // Get priority for sorting (higher number = higher priority)
  int get priority {
    switch (this) {
      case EcoLevel.basic:
        return 1;
      case EcoLevel.standard:
        return 2;
      case EcoLevel.premium:
        return 3;
      case EcoLevel.hero:
        return 4;
    }
  }
}

class AppConstants {
  static const String appName = 'Green Market';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.greenmarket.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheTimeout = Duration(hours: 1);

  // Images
  static const double maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxProductNameLength = 100;
  static const int maxDescriptionLength = 1000;
}

// Theme constants
class AppTheme {
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double padding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Font sizes
  static const double headingFontSize = 24.0;
  static const double titleFontSize = 20.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;
  static const double smallFontSize = 12.0;
}

// App Text Styles
class AppTextStyles {
  // ใช้สำหรับหัวข้อใหญ่ที่สุดในหน้า หรือ Hero text
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.grayPrimary,
    letterSpacing: -0.5,
  );

  // ใช้สำหรับหัวข้อของ Section หรือ AppBar
  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.grayPrimary,
  );

  // ใช้สำหรับหัวข้อย่อย หรือชื่อรายการ
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.grayPrimary,
  );

  // ใช้สำหรับเนื้อหาหลัก
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.graySecondary,
    height: 1.5, // เพิ่มระยะห่างระหว่างบรรทัดเพื่อให้อ่านง่าย
  );

  static final TextStyle bodyBold =
      body.copyWith(fontWeight: FontWeight.w600, color: AppColors.grayPrimary);
  static final TextStyle subtitleBold = subtitle.copyWith(
      fontWeight: FontWeight.bold, color: AppColors.grayPrimary);
  static final TextStyle bodySmall = body.copyWith(fontSize: 14);

  // ใช้สำหรับแสดงราคา
  static const TextStyle price = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
  );

  // ใช้สำหรับลิงก์
  static const TextStyle link = TextStyle(
    fontSize: 16,
    color: AppColors.infoBlue,
    fontWeight: FontWeight.w600,
  );

  // ใช้สำหรับข้อความขนาดเล็ก เช่นคำอธิบายใต้ภาพ
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.graySecondary,
  );
  static final TextStyle captionBold = caption.copyWith(
      fontWeight: FontWeight.w600, color: AppColors.grayPrimary);

  // ใช้สำหรับข้อความบนปุ่ม
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

// Risk Level for investment projects
enum RiskLevel {
  low,
  medium,
  high,
}

extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'ความเสี่ยงต่ำ';
      case RiskLevel.medium:
        return 'ความเสี่ยงปานกลาง';
      case RiskLevel.high:
        return 'ความเสี่ยงสูง';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return AppColors.successGreen;
      case RiskLevel.medium:
        return AppColors.warningAmber;
      case RiskLevel.high:
        return AppColors.errorRed;
    }
  }
}

// EcoCoin related enums and classes
enum EcoCoinTransactionType {
  purchase,
  sale,
  reward,
  activity,
  adminAdjustment,
  earned,
  spent,
  bonus,
}

extension EcoCoinTransactionTypeExtension on EcoCoinTransactionType {
  String get displayName {
    switch (this) {
      case EcoCoinTransactionType.purchase:
        return 'ซื้อสินค้า';
      case EcoCoinTransactionType.sale:
        return 'ขายสินค้า';
      case EcoCoinTransactionType.reward:
        return 'รางวัล';
      case EcoCoinTransactionType.activity:
        return 'กิจกรรม';
      case EcoCoinTransactionType.adminAdjustment:
        return 'ปรับปรุงโดยแอดมิน';
      case EcoCoinTransactionType.earned:
        return 'ได้รับ';
      case EcoCoinTransactionType.spent:
        return 'ใช้จ่าย';
      case EcoCoinTransactionType.bonus:
        return 'โบนัส';
    }
  }

  Color get color {
    switch (this) {
      case EcoCoinTransactionType.purchase:
        return AppColors.errorRed;
      case EcoCoinTransactionType.sale:
        return AppColors.successGreen;
      case EcoCoinTransactionType.reward:
        return AppColors.primaryTeal;
      case EcoCoinTransactionType.activity:
        return AppColors.primaryTealLight;
      case EcoCoinTransactionType.adminAdjustment:
        return AppColors.warningAmber;
      case EcoCoinTransactionType.earned:
        return AppColors.successGreen;
      case EcoCoinTransactionType.spent:
        return AppColors.errorRed;
      case EcoCoinTransactionType.bonus:
        return AppColors.warningAmber;
    }
  }

  IconData get icon {
    switch (this) {
      case EcoCoinTransactionType.purchase:
        return Icons.shopping_cart;
      case EcoCoinTransactionType.sale:
        return Icons.sell;
      case EcoCoinTransactionType.reward:
        return Icons.emoji_events;
      case EcoCoinTransactionType.activity:
        return Icons.eco;
      case EcoCoinTransactionType.adminAdjustment:
        return Icons.admin_panel_settings;
      case EcoCoinTransactionType.earned:
        return Icons.add_circle;
      case EcoCoinTransactionType.spent:
        return Icons.remove_circle;
      case EcoCoinTransactionType.bonus:
        return Icons.card_giftcard;
    }
  }
}

enum EcoCoinTier {
  bronze,
  silver,
  gold,
  platinum,
}

extension EcoCoinTierExtension on EcoCoinTier {
  String get displayName {
    switch (this) {
      case EcoCoinTier.bronze:
        return 'บรอนซ์';
      case EcoCoinTier.silver:
        return 'ซิลเวอร์';
      case EcoCoinTier.gold:
        return 'โกลด์';
      case EcoCoinTier.platinum:
        return 'แพลตตินั่ม';
    }
  }

  int get minCoins {
    switch (this) {
      case EcoCoinTier.bronze:
        return 0;
      case EcoCoinTier.silver:
        return 1000;
      case EcoCoinTier.gold:
        return 5000;
      case EcoCoinTier.platinum:
        return 15000;
    }
  }

  int get maxCoins {
    switch (this) {
      case EcoCoinTier.bronze:
        return 999;
      case EcoCoinTier.silver:
        return 4999;
      case EcoCoinTier.gold:
        return 14999;
      case EcoCoinTier.platinum:
        return 999999; // No upper limit for platinum
    }
  }

  Color get color {
    switch (this) {
      case EcoCoinTier.bronze:
        return const Color(0xFFCD7F32);
      case EcoCoinTier.silver:
        return const Color(0xFF9E9E9E);
      case EcoCoinTier.gold:
        return const Color(0xFFFFD700);
      case EcoCoinTier.platinum:
        return const Color(0xFF6A5ACD);
    }
  }

  IconData get icon {
    switch (this) {
      case EcoCoinTier.bronze:
        return Icons.eco_outlined;
      case EcoCoinTier.silver:
        return Icons.verified_outlined;
      case EcoCoinTier.gold:
        return Icons.star_border;
      case EcoCoinTier.platinum:
        return Icons.diamond_outlined;
    }
  }

  double get multiplier {
    switch (this) {
      case EcoCoinTier.bronze:
        return 1.0;
      case EcoCoinTier.silver:
        return 1.2;
      case EcoCoinTier.gold:
        return 1.5;
      case EcoCoinTier.platinum:
        return 2.0;
    }
  }

  static EcoCoinTier getCurrentTier(int coins) {
    if (coins >= EcoCoinTier.platinum.minCoins) return EcoCoinTier.platinum;
    if (coins >= EcoCoinTier.gold.minCoins) return EcoCoinTier.gold;
    if (coins >= EcoCoinTier.silver.minCoins) return EcoCoinTier.silver;
    return EcoCoinTier.bronze;
  }

  EcoCoinTier? getNextTier() {
    switch (this) {
      case EcoCoinTier.bronze:
        return EcoCoinTier.silver;
      case EcoCoinTier.silver:
        return EcoCoinTier.gold;
      case EcoCoinTier.gold:
        return EcoCoinTier.platinum;
      case EcoCoinTier.platinum:
        return null; // Already at the highest tier
    }
  }
}

// EcoCoins Configuration
class EcoCoinsConfig {
  static const int purchaseReward = 10;
  static const int reviewReward = 50;
  static const int activityReward = 25;
  static const int dailyLoginReward = 5;
  static const int coinsPer100Baht = 10;
  static const int coinsForReview = 50;
  static const int dailyLoginCoins = 5;

  static const List<Map<String, dynamic>> tiers = [
    {
      'name': 'บรอนซ์',
      'minCoins': 0,
      'maxCoins': 999,
      'multiplier': 1.0,
      'color': 0xFFCD7F32,
    },
    {
      'name': 'ซิลเวอร์',
      'minCoins': 1000,
      'maxCoins': 4999,
      'multiplier': 1.2,
      'color': 0xFF9E9E9E,
    },
    {
      'name': 'โกลด์',
      'minCoins': 5000,
      'maxCoins': 14999,
      'multiplier': 1.5,
      'color': 0xFFFFD700,
    },
    {
      'name': 'แพลตตินั่ม',
      'minCoins': 15000,
      'maxCoins': 999999,
      'multiplier': 2.0,
      'color': 0xFF6A5ACD,
    }
  ];
}

// Admin email constant
const String kAdminEmail = 'admin@greenmarket.com';
