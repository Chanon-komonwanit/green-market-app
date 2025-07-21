import 'package:flutter/material.dart';

/// Utility สำหรับจัดการธีมของแอป เช่น primaryColor, secondaryColor, dark/light mode
class ThemeUtils {
  static ThemeData getLightTheme({Color? primaryColor}) {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor ?? Colors.teal,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData getDarkTheme({Color? primaryColor}) {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor ?? Colors.teal,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }

  /// ฟังก์ชันช่วยเปลี่ยนธีมตาม darkMode
  static ThemeData getTheme(bool isDarkMode, {Color? primaryColor}) {
    return isDarkMode
        ? getDarkTheme(primaryColor: primaryColor)
        : getLightTheme(primaryColor: primaryColor);
  }
}
