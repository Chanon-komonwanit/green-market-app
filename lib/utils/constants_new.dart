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

// Professional 4-level Eco Rating System
enum EcoLevel {
  bronze, // ระดับบรอนซ์ (0-24%)
  silver, // ระดับซิลเวอร์ (25-49%)
  gold, // ระดับโกลด์ (50-74%)
  platinum // ระดับแพลตตินั่ม (75-100%)
}

extension EcoLevelExtension on EcoLevel {
  String get name {
    switch (this) {
      case EcoLevel.bronze:
        return 'บรอนซ์';
      case EcoLevel.silver:
        return 'ซิลเวอร์';
      case EcoLevel.gold:
        return 'โกลด์';
      case EcoLevel.platinum:
        return 'แพลตตินั่ม';
    }
  }

  String get fullName {
    switch (this) {
      case EcoLevel.bronze:
        return 'ระดับบรอนซ์';
      case EcoLevel.silver:
        return 'ระดับซิลเวอร์';
      case EcoLevel.gold:
        return 'ระดับโกลด์';
      case EcoLevel.platinum:
        return 'ระดับแพลตตินั่ม';
    }
  }

  String get shortCode {
    switch (this) {
      case EcoLevel.bronze:
        return '🥉 บรอนซ์';
      case EcoLevel.silver:
        return '🥈 ซิลเวอร์';
      case EcoLevel.gold:
        return '🥇 โกลด์';
      case EcoLevel.platinum:
        return '💎 แพลตตินั่ม';
    }
  }

  String get description {
    switch (this) {
      case EcoLevel.bronze:
        return 'สินค้าระดับบรอนซ์ที่ผ่านการตรวจสอบคุณภาพเบื้องต้น';
      case EcoLevel.silver:
        return 'สินค้าระดับซิลเวอร์ที่เริ่มใส่ใจสิ่งแวดล้อม';
      case EcoLevel.gold:
        return 'สินค้าระดับโกลด์ที่มีคุณภาพสูงและเป็นมิตรกับสิ่งแวดล้อม';
      case EcoLevel.platinum:
        return 'สินค้าระดับแพลตตินั่มที่เป็นจุดสุดยอดของความยั่งยืน';
    }
  }

  String get marketingDescription {
    switch (this) {
      case EcoLevel.bronze:
        return 'เริ่มต้นเส้นทางสีเขียว';
      case EcoLevel.silver:
        return 'ตัวเลือกคุณภาพที่เชื่อถือได้';
      case EcoLevel.gold:
        return 'คุณภาพสูง เพื่อโลกที่ดีกว่า';
      case EcoLevel.platinum:
        return 'จุดสุดยอดแห่งความเป็นเลิศ สำหรับผู้ที่ต้องการสิ่งที่ดีที่สุด';
    }
  }

  Color get color {
    switch (this) {
      case EcoLevel.bronze:
        return const Color(0xFFCD7F32); // Bronze
      case EcoLevel.silver:
        return const Color(0xFF9E9E9E); // Silver
      case EcoLevel.gold:
        return const Color(0xFFFFD700); // Gold
      case EcoLevel.platinum:
        return const Color(0xFF6A5ACD); // Platinum (SlateBlue)
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EcoLevel.bronze:
        return const Color(0xFFFFF8E1);
      case EcoLevel.silver:
        return const Color(0xFFF5F5F5);
      case EcoLevel.gold:
        return const Color(0xFFFFFDE7);
      case EcoLevel.platinum:
        return const Color(0xFFF8F8FF);
    }
  }

  Color get gradientStart {
    switch (this) {
      case EcoLevel.bronze:
        return const Color(0xFFD2691E);
      case EcoLevel.silver:
        return const Color(0xFFBDBDBD);
      case EcoLevel.gold:
        return const Color(0xFFFFD54F);
      case EcoLevel.platinum:
        return const Color(0xFF8A7BE8);
    }
  }

  Color get gradientEnd {
    switch (this) {
      case EcoLevel.bronze:
        return const Color(0xFFCD7F32);
      case EcoLevel.silver:
        return const Color(0xFF9E9E9E);
      case EcoLevel.gold:
        return const Color(0xFFFF8F00);
      case EcoLevel.platinum:
        return const Color(0xFF6A5ACD);
    }
  }

  IconData get icon {
    switch (this) {
      case EcoLevel.bronze:
        return Icons.eco_outlined;
      case EcoLevel.silver:
        return Icons.verified_outlined;
      case EcoLevel.gold:
        return Icons.star_border;
      case EcoLevel.platinum:
        return Icons.diamond_outlined;
    }
  }

  // Map eco score (0-100) to eco level
  static EcoLevel fromScore(int score) {
    if (score < 25) return EcoLevel.bronze;
    if (score < 50) return EcoLevel.silver;
    if (score < 75) return EcoLevel.gold;
    return EcoLevel.platinum;
  }

  // Get percentage range for display
  String get scoreRange {
    switch (this) {
      case EcoLevel.bronze:
        return '0-24%';
      case EcoLevel.silver:
        return '25-49%';
      case EcoLevel.gold:
        return '50-74%';
      case EcoLevel.platinum:
        return '75-100%';
    }
  }

  // Get priority for sorting (higher number = higher priority)
  int get priority {
    switch (this) {
      case EcoLevel.bronze:
        return 1;
      case EcoLevel.silver:
        return 2;
      case EcoLevel.gold:
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
