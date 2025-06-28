// lib/models/app_settings.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/theme_settings.dart';
import 'package:green_market/models/homepage_settings.dart';

class AppSettings {
  final String id;
  final String appName;
  final String contactEmail;
  final HomepageSettings homepageSettings;
  final ThemeSettings? themeSettings;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  AppSettings({
    required this.id,
    required this.appName,
    required this.contactEmail,
    required this.homepageSettings,
    this.themeSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] ?? 'app_settings',
      appName: map['appName'] ?? 'Green Market',
      contactEmail: map['contactEmail'] ?? 'contact@greenmarket.com',
      homepageSettings: HomepageSettings.fromMap(map['homepageSettings'] ??
          HomepageSettings.defaultSettings().toMap()),
      themeSettings: map['themeSettings'] != null
          ? ThemeSettings.fromMap(map['themeSettings'])
          : null,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (map['updatedAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appName': appName,
      'contactEmail': contactEmail,
      'homepageSettings': homepageSettings.toMap(),
      'themeSettings': themeSettings?.toMap(), // Use safe access
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppSettings copyWith(
      {String? id,
      String? appName,
      String? contactEmail,
      HomepageSettings? homepageSettings,
      ThemeSettings? themeSettings,
      Timestamp? createdAt,
      Timestamp? updatedAt}) {
    return AppSettings(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      contactEmail: contactEmail ?? this.contactEmail,
      homepageSettings: homepageSettings ?? this.homepageSettings,
      themeSettings: themeSettings ?? this.themeSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
