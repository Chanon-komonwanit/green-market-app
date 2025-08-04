// lib/theme/app_colors.dart - ระบบสีใหม่สำหรับ Green Market

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor

  // === PRIMARY GREEN PALETTE (Inspired by Instagram & Modern Apps) ===
  static const Color primaryDarkest =
      Color(0xFF0F5132); // เขียวเข้มสุด - minimal use only
  static const Color primaryDark =
      Color(0xFF198754); // เขียวเข้ม - important CTAs
  static const Color primary =
      Color(0xFF20C997); // เขียวมิ้นท์หลัก - brand color
  static const Color primaryMedium =
      Color(0xFF6EDAA6); // เขียวกลาง - hover states
  static const Color primaryLight =
      Color(0xFFB3E5D1); // เขียวอ่อน - subtle highlights
  static const Color primaryLightest =
      Color(0xFFF0FDF4); // เขียวอ่อนสุด - card backgrounds

  // === SECONDARY BLUE PALETTE (Minimal & Clean) ===
  static const Color secondaryDark =
      Color(0xFF0369A1); // น้ำเงินเข้ม - info elements
  static const Color secondary = Color(0xFF0EA5E9); // ฟ้าใส - accent color
  static const Color secondaryLight =
      Color(0xFFBAE6FD); // ฟ้าอ่อน - subtle accents
  static const Color secondaryLightest =
      Color(0xFFF0F9FF); // ฟ้าอ่อนสุด - notification bg

  // === NEUTRAL PALETTE (Instagram-inspired clean whites) ===
  static const Color white = Color(0xFFFFFFFF); // ขาวบริสุทธิ์ - main surface
  static const Color grayLightest =
      Color(0xFFFAFAFA); // เทาอ่อนสุด - background
  static const Color grayLight = Color(0xFFF9F9F9); // เทาอ่อน - card container
  static const Color grayMediumLight =
      Color(0xFFE5E7EB); // เทากลางอ่อน - borders minimal
  static const Color grayMedium =
      Color(0xFF9CA3AF); // เทากลาง - placeholder text
  static const Color grayDark = Color(0xFF374151); // เทาเข้ม - secondary text
  static const Color grayDarkest =
      Color(0xFF111827); // เทาเข้มสุด - primary text

  // === SEMANTIC COLORS (Refined & Modern) ===
  static const Color success =
      Color(0xFF10B981); // เขียวสำเร็จ - modern success
  static const Color warning = Color(0xFFF59E0B); // ส้มเหลือง - warning
  static const Color error = Color(0xFFEF4444); // แดงโมเดิล - error
  static const Color info = Color(0xFF3B82F6); // ฟ้าสดใส - info

  // === GRADIENTS (Subtle & Professional) ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryMedium], // Simplified 2-color gradient
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight], // Subtle blue gradient
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, grayLightest], // Very subtle background
  );

  // === SHADOWS (Instagram-inspired minimal) ===
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: grayMedium.withOpacity(0.08), // More subtle
          blurRadius: 12, // Softer blur
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: grayMedium.withOpacity(0.06), // Very subtle like Instagram
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: primary.withOpacity(0.15), // Minimal elevation
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // === BUTTON COLORS (Instagram/Facebook inspired) ===

  /// Primary Buttons - สีเขียวสำหรับ CTA สำคัญ
  static Color get primaryButtonColor => primary;
  static Color get primaryButtonHoverColor => primaryDark;
  static Color get primaryButtonDisabledColor => grayMediumLight;

  /// Secondary Buttons - สีขาวขอบเขียว (Instagram style)
  static Color get secondaryButtonColor => white;
  static Color get secondaryButtonBorderColor => primary;
  static Color get secondaryButtonTextColor => primary;

  /// Text Colors - Clean & Readable
  static Color get primaryTextColor => grayDarkest;
  static Color get secondaryTextColor => grayDark;
  static Color get hintTextColor => grayMedium;

  /// Background Colors - Instagram inspired
  static Color get scaffoldBackgroundColor =>
      white; // Pure white like Instagram
  static Color get cardBackgroundColor => white;
  static Color get sectionBackgroundColor =>
      grayLightest; // Very subtle section

  /// Icon Colors - Minimal & Clean
  static Color get primaryIconColor => grayDarkest; // Strong icons
  static Color get secondaryIconColor => grayMedium; // Subtle icons
  static Color get accentIconColor => primary; // Accent icons

  // === UI COMPONENT COLORS (Modern App Style) ===

  /// AppBar - Clean gradient like modern apps
  static Color get appBarBackgroundColor => white; // Clean white header
  static Color get appBarTextColor => grayDarkest;
  static Color get appBarIconColor => grayDarkest;

  /// Navigation - Minimal like Instagram
  static Color get navBarBackgroundColor => white;
  static Color get navBarSelectedColor => grayDarkest; // Strong selection
  static Color get navBarUnselectedColor => grayMedium;

  /// Input Fields - Clean borders
  static Color get inputFillColor => grayLight;
  static Color get inputBorderColor => grayMediumLight;
  static Color get inputFocusedBorderColor => primary;

  /// ตรวจสอบว่าสีเป็น light หรือ dark
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// สร้างสี opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// สร้าง Material Color สำหรับ Theme
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      swatch[(i + 1) * 100] = Color.fromRGBO(r, g, b, strengths[i]);
    }
    return MaterialColor(color.value, swatch);
  }
}
