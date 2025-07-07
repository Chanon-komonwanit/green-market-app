// lib/utils/constants.dart

// lib/utils/constants.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppColors {
  // Alias for compatibility with old code
  static const Color darkModernGrey = grayPrimary;
  // === Modern Professional Color Palette (World-class Design) ===

  // --- Unified Modern Palette (World-class, Minimal, Professional) ---
  // Main Brand Colors
  static const Color primaryTeal = Color(0xFF13B98A); // Teal-500 (main)
  static const Color primaryTealDark = Color(0xFF0F766E); // Teal-700
  static const Color primaryTealLight = Color(0xFF5EEAD4); // Teal-300
  static const Color primaryTealSoft = Color(0xFFE0F7F1); // Teal-100

  static const Color emeraldPrimary = Color(0xFF10B981); // Emerald-500
  static const Color emeraldDark = Color(0xFF047857); // Emerald-700
  static const Color emeraldLight = Color(0xFF6EE7B7); // Emerald-300
  static const Color emeraldSoft = Color(0xFFD1FAE5); // Emerald-100

  // Blue/Peacock
  // (already defined below for compatibility)

  // Grays (Minimal, Clean)
  static const Color grayPrimary = Color(0xFF23272F); // Main text
  static const Color graySecondary = Color(0xFF6B7280); // Secondary text
  static const Color grayTertiary = Color(0xFFB0B8C1); // Tertiary text
  static const Color grayLight = Color(0xFFF4F7FA); // Light backgrounds
  static const Color grayBorder = Color(0xFFE5E7EB); // Borders

  // Surfaces
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceDarkCard = Color(0xFF334155);

  // Status Colors - Consistent with modern design
  static const Color successGreen = Color(0xFF059669); // Emerald-600
  static const Color warningOrange = Color(0xFFF59E42); // Orange-400 (NEW)
  static const Color warningYellow = Color(0xFFFACC15); // Yellow-400 (NEW)
  static const Color errorRed = Color(0xFFDC2626); // Red-600
  static const Color alertRed = Color(0xFFF87171); // Red-400 (NEW)
  static const Color infoBlue = Color(0xFF2563EB); // Blue-600

  // Modern Blue/Peacock/Emerald/Teal Palette for world-class look
  static const Color peacockBlue = Color(0xFF0E7490); // Peacock Blue
  static const Color modernBlue = Color(0xFF2563EB); // Modern Blue
  static const Color deepBlue = Color(0xFF1E40AF); // Deep Blue
  static const Color emeraldGreen = Color(0xFF10B981); // Emerald Green

  // Action Colors - Eye-catching but professional
  static const Color accent =
      Color(0xFF8B5CF6); // Violet-500 - For special actions
  static const Color accentLight = Color(0xFFC4B5FD); // Violet-300

  // Legacy/compatibility for old code
  static const Color modernDarkGrey = grayPrimary;
  static const Color darkGrey = grayPrimary;
  static const Color lightGrey = grayLight;
  static const Color lightBeige =
      Color(0xFFFFF8E1); // Soft beige for chat backgrounds
  static const Color earthyBrown =
      Color(0xFF8D6E63); // Earthy brown for accents

  // Background Gradients
  static const List<Color> gradientPrimary = [
    Color(0xFF14B8A6), // Teal-500
    Color(0xFF10B981), // Emerald-500
  ];

  static const List<Color> gradientSoft = [
    Color(0xFFECFDF5), // Emerald-50
    Color(0xFFF0FDFA), // Teal-50
  ];

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A); // Slate-900
  static const Color darkSurface = Color(0xFF1E293B); // Slate-800
  static const Color darkCard = Color(0xFF334155); // Slate-700
  static const Color darkBorder = Color(0xFF475569); // Slate-600

  // Legacy Support (mapped to new colors)
  static const Color primaryGreen = primaryTeal;
  static const Color accentGreen = emeraldPrimary;
  static const Color primaryDarkGreen = primaryTealDark;
  static const Color lightTeal = primaryTealLight;
  static const Color veryLightTeal = primaryTealSoft;
  static const Color modernGrey = graySecondary;
  static const Color lightModernGrey = grayBorder;
  static const Color white = surfaceWhite;
  static const Color offWhite = surfaceGray;
  static const Color black = grayPrimary;
  static const Color darkText = grayPrimary;
  static const Color lightText = graySecondary;
  static const Color background = surfaceGray;
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
        return const Color(0xFFC8E6C9); // เขียวอ่อนมาก
      case EcoLevel.standard:
        return const Color(0xFF2E7D32); // เขียวเข้มพอดี
      case EcoLevel.premium:
        return const Color(0xFFFFD700); // สีทอง
      case EcoLevel.hero:
        return const Color(0xFF6A1B9A); // สีเพชร/ไพลิน (ม่วงเข้ม)
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EcoLevel.basic:
        return const Color(0xFFF1F8E9); // เขียวอ่อนมากพื้นหลัง
      case EcoLevel.standard:
        return const Color(0xFFE8F5E9); // เขียวเข้มพื้นหลัง
      case EcoLevel.premium:
        return const Color(0xFFFFF8DC); // ทองอ่อน
      case EcoLevel.hero:
        return const Color(0xFFF3E5F5); // ม่วงเพชรอ่อนสวยหรู
    }
  }

  Color get gradientStart {
    switch (this) {
      case EcoLevel.basic:
        return const Color(0xFFDCEDC8); // เขียวอ่อนมากไล่โทน
      case EcoLevel.standard:
        return const Color(0xFF43A047); // เขียวเข้มไล่โทน
      case EcoLevel.premium:
        return const Color(0xFFFFE55C); // ทองสว่าง
      case EcoLevel.hero:
        return const Color(0xFF9C27B0); // เพชรไล่โทน
    }
  }

  Color get gradientEnd {
    switch (this) {
      case EcoLevel.basic:
        return const Color(0xFFC8E6C9); // เขียวอ่อนมาก
      case EcoLevel.standard:
        return const Color(0xFF2E7D32); // เขียวเข้ม
      case EcoLevel.premium:
        return const Color(0xFFFFD700); // ทอง
      case EcoLevel.hero:
        return const Color(0xFF6A1B9A); // เพชร/ไพลิน
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
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText, // เปลี่ยนเป็นสีที่อ่านง่าย
  );

  static const TextStyle headline = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText, // เปลี่ยนเป็นสีที่อ่านง่าย
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.lightText, // เปลี่ยนเป็นสีที่อ่านง่าย
  );

  static final TextStyle subtitleBold =
      subtitle.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkText);

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.lightText, // เปลี่ยนเป็นสีที่อ่านง่าย
  );

  static final TextStyle bodySmall = body.copyWith(fontSize: 14);

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
  );

  static const TextStyle link = TextStyle(
    fontSize: 16,
    color: AppColors.primaryTeal, // เปลี่ยนเป็นสีที่เด่นกว่า
    decoration: TextDecoration.underline,
  );

  static const TextStyle bodyBold = TextStyle(
      fontSize: 16, color: AppColors.darkText, fontWeight: FontWeight.bold);

  static const TextStyle caption =
      TextStyle(fontSize: 12, color: AppColors.lightText);

  static final TextStyle captionBold =
      caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkText);

  static final TextStyle bodyGreen =
      body.copyWith(color: AppColors.successGreen);

  static final TextStyle bodyYellow =
      body.copyWith(color: AppColors.warningYellow);

  static final TextStyle bodyRed = body.copyWith(color: AppColors.errorRed);

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
        return AppColors.warningYellow;
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
        return AppColors.lightTeal;
      case EcoCoinTransactionType.adminAdjustment:
        return AppColors.warningYellow;
      case EcoCoinTransactionType.earned:
        return AppColors.successGreen;
      case EcoCoinTransactionType.spent:
        return AppColors.errorRed;
      case EcoCoinTransactionType.bonus:
        return AppColors.warningYellow;
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
