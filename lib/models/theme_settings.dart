// lib/models/theme_settings.dart
import 'package:flutter/material.dart'; // For Color

class ThemeSettings {
  final int primaryColor;
  final int secondaryColor;
  final int tertiaryColor;
  final bool useDarkTheme;
  final String? fontFamily;

  ThemeSettings({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.useDarkTheme,
    this.fontFamily,
  });

  // Static method to provide default settings
  static ThemeSettings defaultSettings() {
    return ThemeSettings(
      primaryColor: 0xFF4CAF50, // Default green
      secondaryColor: 0xFFFFC107, // Default amber
      tertiaryColor: 0xFF2196F3, // Default blue
      useDarkTheme: false,
      fontFamily: 'Sarabun', // Set Sarabun as the default font
    );
  }

  factory ThemeSettings.fromMap(Map<String, dynamic> map) {
    return ThemeSettings(
      primaryColor:
          map['primaryColor'] as int? ?? defaultSettings().primaryColor,
      secondaryColor:
          map['secondaryColor'] as int? ?? defaultSettings().secondaryColor,
      tertiaryColor:
          map['tertiaryColor'] as int? ?? defaultSettings().tertiaryColor,
      useDarkTheme: map['useDarkTheme'] as bool? ?? false,
      fontFamily: map['fontFamily'] as String? ?? defaultSettings().fontFamily,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'tertiaryColor': tertiaryColor,
      'useDarkTheme': useDarkTheme,
      'fontFamily': fontFamily,
    };
  }

  ThemeSettings copyWith({
    int? primaryColor,
    int? secondaryColor,
    int? tertiaryColor,
    bool? useDarkTheme,
    String? fontFamily,
  }) {
    return ThemeSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      tertiaryColor: tertiaryColor ?? this.tertiaryColor,
      useDarkTheme: useDarkTheme ?? this.useDarkTheme,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}
