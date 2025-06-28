// lib/models/homepage_settings.dart
import 'package:flutter/material.dart';

class HomepageSettings {
  final String heroImageUrl;
  final String heroTitle;
  final String heroSubtitle;

  HomepageSettings({
    required this.heroImageUrl,
    required this.heroTitle,
    required this.heroSubtitle,
  });

  // A default factory constructor for when no settings are found in Firestore
  factory HomepageSettings.defaultSettings() {
    return HomepageSettings(
      heroImageUrl:
          'https://firebasestorage.googleapis.com/v0/b/green-market-551f7.appspot.com/o/app_settings%2Fdefault_banner.jpg?alt=media&token=18f82917-9f23-4933-958b-a79a11391458', // A default placeholder image URL from Firebase Storage
      heroTitle: 'ยินดีต้อนรับสู่ Green Market',
      heroSubtitle: 'เลือกซื้อสินค้าเพื่อโลกและชุมชนที่ยั่งยืน',
    );
  }

  // Factory constructor to create HomepageSettings from a map (from Firestore)
  factory HomepageSettings.fromMap(Map<String, dynamic> map) {
    return HomepageSettings(
      heroImageUrl: map['heroImageUrl'] as String? ??
          HomepageSettings.defaultSettings().heroImageUrl,
      heroTitle: map['heroTitle'] as String? ??
          HomepageSettings.defaultSettings().heroTitle,
      heroSubtitle: map['heroSubtitle'] as String? ??
          HomepageSettings.defaultSettings().heroSubtitle,
    );
  }

  // Method to convert HomepageSettings object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'heroImageUrl': heroImageUrl,
      'heroTitle': heroTitle,
      'heroSubtitle': heroSubtitle,
    };
  }
}
