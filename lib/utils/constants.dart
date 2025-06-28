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
}

// Professional 5-level Eco Rating System
enum EcoLevel {
  basic, // ระดับเริ่มต้น (0-19%)
  standard, // ระดับมาตรฐาน (20-39%)
  premium, // ระดับพรีเมียม (40-59%)
  hero, // ระดับฮีโร่ (60-79%)
  platinum // ระดับแพลตตินั่มฮีโร่ (80-100%)
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
      case EcoLevel.hero:
        return 'ฮีโร่';
      case EcoLevel.platinum:
        return 'แพลตตินั่มฮีโร่';
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
      case EcoLevel.hero:
        return 'ระดับฮีโร่';
      case EcoLevel.platinum:
        return 'ระดับแพลตตินั่มฮีโร่';
    }
  }

  String get shortCode {
    switch (this) {
      case EcoLevel.basic:
        return '🌱 เริ่มต้น';
      case EcoLevel.standard:
        return '⭐ มาตรฐาน';
      case EcoLevel.premium:
        return '🏆 พรีเมียม';
      case EcoLevel.hero:
        return '� ฮีโร่';
      case EcoLevel.platinum:
        return '💎 แพลตตินั่มฮีโร่';
    }
  }

  String get description {
    switch (this) {
      case EcoLevel.basic:
        return 'สินค้าระดับเริ่มต้นที่ผ่านการตรวจสอบคุณภาพ';
      case EcoLevel.standard:
        return 'สินค้าระดับมาตรฐานที่เริ่มใส่ใจสิ่งแวดล้อม';
      case EcoLevel.premium:
        return 'สินค้าระดับพรีเมียมที่มีคุณภาพสูงและเป็นมิตรกับสิ่งแวดล้อม';
      case EcoLevel.hero:
        return 'สินค้าระดับฮีโร่ที่ช่วยรักษาโลกอย่างเป็นรูปธรรม';
      case EcoLevel.platinum:
        return 'สินค้าระดับแพลตตินั่มฮีโร่ที่เป็นจุดสุดยอดของความยั่งยืน';
    }
  }

  String get marketingDescription {
    switch (this) {
      case EcoLevel.basic:
        return 'เริ่มต้นเส้นทางสีเขียว';
      case EcoLevel.standard:
        return 'ตัวเลือกมาตรฐานที่เชื่อถือได้';
      case EcoLevel.premium:
        return 'คุณภาพพรีเมียม เพื่อโลกที่ดีกว่า';
      case EcoLevel.hero:
        return 'เป็นฮีโร่ช่วยโลก ด้วยการเลือกซื้อที่ถูกต้อง';
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
      case EcoLevel.hero:
        return const Color(0xFFFF9800); // Orange
      case EcoLevel.platinum:
        return const Color(0xFFFFD700); // Gold
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
      case EcoLevel.hero:
        return const Color(0xFFFFF3E0);
      case EcoLevel.platinum:
        return const Color(0xFFFFFDE7);
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
      case EcoLevel.hero:
        return const Color(0xFFFFB74D);
      case EcoLevel.platinum:
        return const Color(0xFFFFD54F);
    }
  }

  Color get gradientEnd {
    switch (this) {
      case EcoLevel.basic:
        return const Color(0xFF4CAF50);
      case EcoLevel.standard:
        return const Color(0xFF1976D2);
      case EcoLevel.premium:
        return const Color(0xFF7B1FA2);
      case EcoLevel.hero:
        return const Color(0xFFE65100);
      case EcoLevel.platinum:
        return const Color(0xFFFF8F00);
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
      case EcoLevel.hero:
        return Icons.shield_outlined;
      case EcoLevel.platinum:
        return Icons.diamond_outlined;
    }
  }

  // Map eco score (0-100) to eco level
  static EcoLevel fromScore(int score) {
    if (score < 20) return EcoLevel.basic;
    if (score < 40) return EcoLevel.standard;
    if (score < 60) return EcoLevel.premium;
    if (score < 80) return EcoLevel.hero;
    return EcoLevel.platinum;
  }

  // Get percentage range for display
  String get scoreRange {
    switch (this) {
      case EcoLevel.basic:
        return '0-19%';
      case EcoLevel.standard:
        return '20-39%';
      case EcoLevel.premium:
        return '40-59%';
      case EcoLevel.hero:
        return '60-79%';
      case EcoLevel.platinum:
        return '80-100%';
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
      case EcoLevel.platinum:
        return 5;
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

// Product listing constants
class ProductConstants {
  static const List<String> categories = [
    'อาหารและเครื่องดื่ม',
    'เสื้อผ้าและแฟชั่น',
    'ของใช้ในบ้าน',
    'สุขภาพและความงาม',
    'อิเล็กทรอนิกส์',
    'กีฬาและนันทนาการ',
    'หนังสือและสื่อการเรียน',
    'ของเล่นและเกม',
    'สวนและพืชผล',
    'อื่นๆ',
  ];

  static const List<String> conditions = [
    'ใหม่',
    'เหมือนใหม่',
    'ใช้แล้วดี',
    'ใช้แล้วปกติ',
    'ต้องซ่อม',
  ];

  static const Map<String, IconData> categoryIcons = {
    'อาหารและเครื่องดื่ม': Icons.restaurant,
    'เสื้อผ้าและแฟชั่น': Icons.checkroom,
    'ของใช้ในบ้าน': Icons.home,
    'สุขภาพและความงาม': Icons.spa,
    'อิเล็กทรอนิกส์': Icons.devices,
    'กีฬาและนันทนาการ': Icons.sports,
    'หนังสือและสื่อการเรียน': Icons.book,
    'ของเล่นและเกม': Icons.toys,
    'สวนและพืชผล': Icons.local_florist,
    'อื่นๆ': Icons.category,
  };
}

// Status constants
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  shipped,
  delivered,
  cancelled,
  returned
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'รอการยืนยัน';
      case OrderStatus.confirmed:
        return 'ยืนยันแล้ว';
      case OrderStatus.preparing:
        return 'กำลังเตรียม';
      case OrderStatus.shipped:
        return 'จัดส่งแล้ว';
      case OrderStatus.delivered:
        return 'ส่งแล้ว';
      case OrderStatus.cancelled:
        return 'ยกเลิก';
      case OrderStatus.returned:
        return 'คืนสินค้า';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.indigo;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returned:
        return Colors.grey;
    }
  }
}

// Investment project level constants
class InvestmentLevel {
  static const List<Map<String, dynamic>> levels = [
    {
      'name': 'Beginner',
      'minAmount': 1000,
      'maxAmount': 50000,
      'color': AppColors.primaryTeal,
      'icon': Icons.eco_outlined,
      'description': 'เหมาะสำหรับผู้เริ่มต้นลงทุนด้านสิ่งแวดล้อม',
    },
    {
      'name': 'Intermediate',
      'minAmount': 50001,
      'maxAmount': 200000,
      'color': AppColors.primaryTeal,
      'icon': Icons.eco,
      'description': 'สำหรับนักลงทุนที่มีประสบการณ์ปานกลาง',
    },
    {
      'name': 'Advanced',
      'minAmount': 200001,
      'maxAmount': 1000000,
      'color': AppColors.primaryTeal,
      'icon': Icons.emoji_events,
      'description': 'สำหรับนักลงทุนระดับสูงที่ต้องการผลตอบแทนสูง',
    },
  ];
}

// App Text Styles
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
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }
}

// Admin Configuration
const String kAdminEmail =
    'admin@greenmarket.com'; // Add email here to manage admin

// Eco Coins System Configuration
class EcoCoinsConfig {
  // Coin earning rates
  static const int coinsPerPurchase = 10; // เหลียญต่อการซื้อ 100 บาท
  static const int coinsPer100Baht = 10;
  static const int coinsForReview = 5; // เหลียญสำหรับการรีวิว
  static const int coinsForEcoProduct =
      20; // เหลียญเพิ่มเติมสำหรับสินค้าเป็นมิตรกับสิ่งแวดล้อม
  static const int dailyLoginCoins = 2; // เหลียญเช็คอินรายวัน
  static const int weeklyLoginBonus = 15; // โบนัสเช็คอินครบ 7 วัน

  // Special eco activities coins
  static const int coinsForRecycling = 30; // เหลียญสำหรับการรีไซเคิล
  static const int coinsForCarbonOffset = 50; // เหลียญสำหรับการชดเชยคาร์บอน
  static const int coinsForTreePlanting = 100; // เหลียญสำหรับการปลูกต้นไม้

  // Redemption rates
  static const int coinsToDiscount1Baht = 10; // 10 เหลียญ = ส่วนลด 1 บาท
  static const int minCoinsForRedemption = 100; // เหลียรขั้นต่ำสำหรับแลก
  static const int maxDiscountPercent = 50; // ส่วนลดสูงสุด 50%

  // Level system
  static const List<EcoCoinTier> tiers = [
    EcoCoinTier(
      name: 'Green Starter',
      minCoins: 0,
      maxCoins: 999,
      multiplier: 1.0,
      color: Colors.green,
      icon: Icons.eco_outlined,
      benefits: ['เก็บเหลียญพื้นฐาน', 'ส่วนลดพิเศษ 5%'],
    ),
    EcoCoinTier(
      name: 'Eco Warrior',
      minCoins: 1000,
      maxCoins: 4999,
      multiplier: 1.2,
      color: Colors.teal,
      icon: Icons.eco,
      benefits: ['เหลียญเพิ่ม 20%', 'ส่วนลดพิเศษ 10%', 'ฟรีค่าจัดส่ง'],
    ),
    EcoCoinTier(
      name: 'Planet Protector',
      minCoins: 5000,
      maxCoins: 19999,
      multiplier: 1.5,
      color: Colors.amber,
      icon: Icons.star,
      benefits: [
        'เหลียญเพิ่ม 50%',
        'ส่วนลดพิเศษ 15%',
        'สินค้าพิเศษ',
        'ข้ามคิวรีวิว'
      ],
    ),
    EcoCoinTier(
      name: 'Earth Guardian',
      minCoins: 20000,
      maxCoins: 999999,
      multiplier: 2.0,
      color: Colors.purple,
      icon: Icons.emoji_events,
      benefits: [
        'เหลียญเพิ่ม 100%',
        'ส่วนลดพิเศษ 25%',
        'สินค้าจำกัด',
        'บริการ VIP'
      ],
    ),
  ];
}

// Eco Coin Tier Model
class EcoCoinTier {
  final String name;
  final int minCoins;
  final int maxCoins;
  final double multiplier;
  final Color color;
  final IconData icon;
  final List<String> benefits;

  const EcoCoinTier({
    required this.name,
    required this.minCoins,
    required this.maxCoins,
    required this.multiplier,
    required this.color,
    required this.icon,
    required this.benefits,
  });

  // Check if user coins fall within this tier
  bool isInTier(int userCoins) {
    return userCoins >= minCoins && userCoins <= maxCoins;
  }

  // Get next tier
  static EcoCoinTier? getNextTier(int currentCoins) {
    for (var tier in EcoCoinsConfig.tiers) {
      if (currentCoins < tier.minCoins) {
        return tier;
      }
    }
    return null; // Already at highest tier
  }

  // Get current tier
  static EcoCoinTier getCurrentTier(int userCoins) {
    for (var tier in EcoCoinsConfig.tiers.reversed) {
      if (tier.isInTier(userCoins)) {
        return tier;
      }
    }
    return EcoCoinsConfig.tiers.first; // Default to first tier
  }
}

// Eco Coins Transaction Types
enum EcoCoinTransactionType {
  earned,
  spent,
  expired,
  bonus,
}

extension EcoCoinTransactionTypeExtension on EcoCoinTransactionType {
  String get displayName {
    switch (this) {
      case EcoCoinTransactionType.earned:
        return 'ได้รับเหลียญ';
      case EcoCoinTransactionType.spent:
        return 'ใช้เหลียญ';
      case EcoCoinTransactionType.expired:
        return 'เหลียญหมดอายุ';
      case EcoCoinTransactionType.bonus:
        return 'โบนัสเหลียญ';
    }
  }

  Color get color {
    switch (this) {
      case EcoCoinTransactionType.earned:
        return Colors.green;
      case EcoCoinTransactionType.spent:
        return Colors.orange;
      case EcoCoinTransactionType.expired:
        return Colors.red;
      case EcoCoinTransactionType.bonus:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case EcoCoinTransactionType.earned:
        return Icons.add_circle;
      case EcoCoinTransactionType.spent:
        return Icons.remove_circle;
      case EcoCoinTransactionType.expired:
        return Icons.schedule;
      case EcoCoinTransactionType.bonus:
        return Icons.card_giftcard;
    }
  }
}
