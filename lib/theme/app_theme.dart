// lib/theme/app_theme.dart - Theme ระดับโลกสำหรับ Green Market

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart' as colors;

class AppTheme {
  AppTheme._();

  /// Light Theme - ธีมหลักของแอพ
  static ThemeData get lightTheme {
    return ThemeData(
      // === COLOR SCHEME ===
      colorScheme: ColorScheme.light(
        primary: colors.AppColors.primary,
        onPrimary: colors.AppColors.white,
        secondary: colors.AppColors.secondary,
        onSecondary: colors.AppColors.white,
        tertiary: colors.AppColors.primaryLight,
        surface: colors.AppColors.white,
        onSurface: colors.AppColors.primaryTextColor,
        background: colors.AppColors.scaffoldBackgroundColor,
        onBackground: colors.AppColors.primaryTextColor,
        error: colors.AppColors.error,
        onError: colors.AppColors.white,
      ),

      // === BASIC COLORS ===
      primarySwatch:
          colors.AppColors.createMaterialColor(colors.AppColors.primary),
      scaffoldBackgroundColor: colors.AppColors.scaffoldBackgroundColor,
      canvasColor: colors.AppColors.white,
      cardColor: colors.AppColors.cardBackgroundColor,
      dividerColor: colors.AppColors.grayMediumLight,

      // === APP BAR THEME (Clean like Instagram) ===
      appBarTheme: AppBarTheme(
        backgroundColor: colors.AppColors.appBarBackgroundColor,
        foregroundColor: colors.AppColors.appBarTextColor,
        elevation: 0, // Flat design
        scrolledUnderElevation: 1, // Minimal elevation
        shadowColor: colors.AppColors.grayMedium.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Dark icons on white
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18, // Smaller, cleaner
          fontWeight: FontWeight.w600,
          color: colors.AppColors.appBarTextColor,
          fontFamily: 'Sarabun',
        ),
        iconTheme: IconThemeData(
          color: colors.AppColors.appBarIconColor,
          size: 22, // Smaller icons
        ),
        actionsIconTheme: IconThemeData(
          color: colors.AppColors.appBarIconColor,
          size: 22,
        ),
      ),

      // === ELEVATED BUTTON THEME (Modern CTA style) ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.AppColors.primaryButtonColor,
          foregroundColor: colors.AppColors.white,
          disabledBackgroundColor: colors.AppColors.primaryButtonDisabledColor,
          disabledForegroundColor: colors.AppColors.grayMedium,
          elevation: 0, // Flat design like Instagram
          shadowColor: Colors.transparent, // No shadows
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Instagram-style radius
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15, // Slightly smaller
            fontWeight: FontWeight.w600,
            fontFamily: 'Sarabun',
          ),
        ),
      ),

      // === OUTLINED BUTTON THEME (Clean Instagram style) ===
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.AppColors.secondaryButtonColor,
          foregroundColor: colors.AppColors.secondaryButtonTextColor,
          side: BorderSide(
            color: colors.AppColors.secondaryButtonBorderColor,
            width: 1, // Thinner border
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Sarabun',
          ),
        ),
      ),

      // === CARD THEME (Instagram-inspired clean cards) ===
      cardTheme: CardThemeData(
        color: colors.AppColors.cardBackgroundColor,
        shadowColor:
            colors.AppColors.grayMedium.withOpacity(0.06), // Very subtle
        elevation: 0, // Flat design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Consistent radius
          side: BorderSide(
            color: colors.AppColors.grayMediumLight,
            width: 0.5, // Subtle border
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // === INPUT DECORATION THEME ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.AppColors.inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.AppColors.inputBorderColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.AppColors.inputBorderColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.AppColors.inputFocusedBorderColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.AppColors.error,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: colors.AppColors.hintTextColor,
          fontSize: 16,
          fontFamily: 'Sarabun',
        ),
        labelStyle: TextStyle(
          color: colors.AppColors.primaryTextColor,
          fontSize: 16,
          fontFamily: 'Sarabun',
        ),
      ),

      // === BOTTOM NAVIGATION BAR THEME (Clean like modern apps) ===
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.AppColors.navBarBackgroundColor,
        selectedItemColor: colors.AppColors.navBarSelectedColor,
        unselectedItemColor: colors.AppColors.navBarUnselectedColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0, // Flat design
        selectedLabelStyle: const TextStyle(
          fontSize: 11, // Smaller labels
          fontWeight: FontWeight.w500, // Less bold
          fontFamily: 'Sarabun',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          fontFamily: 'Sarabun',
        ),
      ),

      // === TEXT THEME ===
      textTheme: TextTheme(
        // Headlines
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.3,
        ),

        // Titles
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.3,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.4,
        ),

        // Body Text
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: colors.AppColors.secondaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.5,
        ),

        // Labels
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.AppColors.primaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.AppColors.secondaryTextColor,
          fontFamily: 'Sarabun',
          height: 1.4,
        ),
      ),

      // === VISUAL DENSITY ===
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // === MATERIAL 3 ===
      useMaterial3: true,
    );
  }

  /// Dark Theme - สำหรับโหมดกลางคืน (ถ้าต้องการในอนาคต)
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.AppColors.grayDarkest,
      colorScheme: ColorScheme.dark(
        primary: colors.AppColors.primaryLight,
        onPrimary: colors.AppColors.grayDarkest,
        secondary: colors.AppColors.secondaryLight,
        onSecondary: colors.AppColors.grayDarkest,
        surface: colors.AppColors.grayDark,
        onSurface: colors.AppColors.white,
        background: colors.AppColors.grayDarkest,
        onBackground: colors.AppColors.white,
        error: colors.AppColors.error,
        onError: colors.AppColors.white,
      ),
    );
  }
}

/// Function to get the light theme
ThemeData getAppTheme() => AppTheme.lightTheme;

/// Legacy theme for backward compatibility
@Deprecated('Use AppTheme.lightTheme instead')
final ThemeData appTheme = AppTheme.lightTheme;
