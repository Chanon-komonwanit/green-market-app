// lib/utils/constants.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  static const Color accentGreen =
      lightTeal; // Map old accentGreen to new lightTeal

  // Additional legacy colors needed by the app
  static const Color primaryDarkGreen = Color(0xFF00695C); // Darker Teal
  static const Color modernDarkGrey = Color(0xFF424242);
  static const Color warningOrange = Colors.orangeAccent;
  static const Color lightGrey =
      lightModernGrey; // Map old lightGrey to new lightModernGrey
  static const Color darkGrey =
      modernGrey; // Map old darkGrey to new modernGrey
  static const Color lightBeige =
      veryLightTeal; // Map old lightBeige to new veryLightTeal
  static const Color background = offWhite; // สีพื้นหลังหลัก

  // เพิ่มสีที่ขาดหายไป
  static const Color lightGreen = Color(0xFF8BC34A);
}

// Professional 4-level Eco Rating System (ระบบประเมินสินค้าเพื่อสิ่งแวดล้อม 4 ระดับ)
enum EcoLevel {
  basic, // ระดับเริ่มต้น (0-24%)
  standard, // ระดับมาตรฐาน (25-49%)
  premium, // ระดับพรีเมียม (50-74%)
  platinum // ระดับแพลตตินั่ม (75-100%)
}

extension EcoLevelExtension on EcoLevel {
  String get name {
    switch (this) {
      case EcoLevel.basic:
        return 'เริ่มต้น';
      case EcoLevel.standard:
        return 'มาตรฐาน';
      case EcoLevel.premium:
        return 'พรีเมียม';
      case EcoLevel.platinum:
        return 'แพลตตินั่ม';
    }
  }

  String get fullName {
    switch (this) {
      case EcoLevel.basic:
        return 'ระดับเริ่มต้น';
      case EcoLevel.standard:
        return 'ระดับมาตรฐาน';
      case EcoLevel.premium:
        return 'ระดับพรีเมียม';
      case EcoLevel.platinum:
        return 'ระดับแพลตตินั่ม';
    }
  }

  String get shortCode {
    switch (this) {
      case EcoLevel.basic:
        return '🌱 เริ่มต้น';
      case EcoLevel.standard:
        return '🌿 มาตรฐาน';
      case EcoLevel.premium:
        return '⭐ พรีเมียม';
      case EcoLevel.platinum:
        return '💎 แพลตตินั่ม';
    }
  }

  String get description {
    switch (this) {
      case EcoLevel.basic:
        return 'สินค้าระดับเริ่มต้นที่ผ่านการตรวจสอบคุณภาพเบื้องต้น';
      case EcoLevel.standard:
        return 'สินค้าระดับมาตรฐานที่เริ่มใส่ใจสิ่งแวดล้อม';
      case EcoLevel.premium:
        return 'สินค้าระดับพรีเมียมที่มีคุณภาพสูงและเป็นมิตรกับสิ่งแวดล้อม';
      case EcoLevel.platinum:
        return 'สินค้าระดับแพลตตินั่มที่เป็นจุดสุดยอดของความยั่งยืนและนวัตกรรมสีเขียว';
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
      case EcoLevel.platinum:
        return 'จุดสุดยอดแห่งความเป็นเลิศ สำหรับผู้ที่ต้องการสิ่งที่ดีที่สุด';
    }
  }

  Color get color {
    switch (this) {
      case EcoLevel.basic:
        return const Color(0xFF4CAF50); // Green
      case EcoLevel.standard:
        return const Color(0xFF2196F3); // Blue
      case EcoLevel.premium:
        return const Color(0xFF9C27B0); // Purple
      case EcoLevel.platinum:
        return const Color(0xFFFF9800); // Orange (combining hero and platinum)
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EcoLevel.basic:
        return const Color(0xFFE8F5E8);
      case EcoLevel.standard:
        return const Color(0xFFE3F2FD);
      case EcoLevel.premium:
        return const Color(0xFFF3E5F5);
      case EcoLevel.platinum:
        return const Color(0xFFFFF3E0);
    }
  }

  Color get gradientStart {
    switch (this) {
      case EcoLevel.basic:
        return const Color(0xFF66BB6A);
      case EcoLevel.standard:
        return const Color(0xFF42A5F5);
      case EcoLevel.premium:
        return const Color(0xFFAB47BC);
      case EcoLevel.platinum:
        return const Color(0xFFFFB74D);
    }
  }

  Color get gradientEnd {
    switch (this) {
      case EcoLevel.basic:
        return const Color(0xFF4CAF50);
      case EcoLevel.standard:
        return const Color(0xFF2196F3);
      case EcoLevel.premium:
        return const Color(0xFF9C27B0);
      case EcoLevel.platinum:
        return const Color(0xFFFF9800);
    }
  }

  IconData get icon {
    switch (this) {
      case EcoLevel.basic:
        return Icons.eco_outlined;
      case EcoLevel.standard:
        return Icons.verified_outlined;
      case EcoLevel.premium:
        return Icons.star_border;
      case EcoLevel.platinum:
        return Icons.diamond_outlined;
    }
  }

  // Map eco score (0-100) to eco level (4-tier system)
  static EcoLevel fromScore(int score) {
    if (score < 25) return EcoLevel.basic;
    if (score < 50) return EcoLevel.standard;
    if (score < 75) return EcoLevel.premium;
    return EcoLevel.platinum;
  }

  // Get percentage range for display
  String get scoreRange {
    switch (this) {
      case EcoLevel.basic:
        return '0-24%';
      case EcoLevel.standard:
        return '25-49%';
      case EcoLevel.premium:
        return '50-74%';
      case EcoLevel.platinum:
        return '75-100%';
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
      case EcoLevel.platinum:
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
    color: AppColors.primaryTeal,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.modernGrey,
  );

  static final TextStyle subtitleBold = subtitle.copyWith(
      fontWeight: FontWeight.bold, color: AppColors.primaryDarkGreen);

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.modernGrey,
  );

  static final TextStyle bodySmall = body.copyWith(fontSize: 14);

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
  );

  static const TextStyle link = TextStyle(
    fontSize: 16,
    color: AppColors.lightTeal,
    decoration: TextDecoration.underline,
  );

  static const TextStyle bodyBold = TextStyle(
      fontSize: 16, color: AppColors.modernGrey, fontWeight: FontWeight.bold);

  static const TextStyle caption =
      TextStyle(fontSize: 12, color: AppColors.modernGrey);

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
