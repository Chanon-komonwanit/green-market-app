// lib/models/dynamic_app_config.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DynamicAppConfig {
  final String id;
  final String appName;
  final String appTagline;
  final String logoUrl;
  final String faviconUrl;
  final String heroImageUrl;
  final String heroTitle;
  final String heroSubtitle;

  // Color Scheme
  final int primaryColorValue;
  final int secondaryColorValue;
  final int accentColorValue;
  final int backgroundColorValue;
  final int surfaceColorValue;
  final int errorColorValue;
  final int successColorValue;
  final int warningColorValue;
  final int infoColorValue;

  // Typography
  final String primaryFontFamily;
  final String secondaryFontFamily;
  final double baseFontSize;
  final double titleFontSize;
  final double headingFontSize;
  final double captionFontSize;

  // Layout Settings
  final double borderRadius;
  final double cardElevation;
  final double buttonHeight;
  final double inputHeight;
  final double spacing;
  final double padding;

  // Feature Toggles
  final bool enableDarkMode;
  final bool enableNotifications;
  final bool enableChat;
  final bool enableInvestments;
  final bool enableSustainableActivities;
  final bool enableReviews;
  final bool enablePromotions;
  final bool enableMultiLanguage;

  // Business Settings
  final double defaultShippingFee;
  final double minimumOrderAmount;
  final int maxCartItems;
  final int productApprovalDays;
  final double platformCommissionRate;

  // Contact & Social
  final String supportEmail;
  final String supportPhone;
  final String companyAddress;
  final String facebookUrl;
  final String lineUrl;
  final String instagramUrl;
  final String twitterUrl;

  // Text Content
  final Map<String, String> staticTexts;
  final Map<String, String> errorMessages;
  final Map<String, String> successMessages;
  final Map<String, String> labels;
  final Map<String, String> placeholders;
  final Map<String, String> buttonTexts;

  // Images & Icons
  final Map<String, String> images;
  final Map<String, String> icons;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  DynamicAppConfig({
    required this.id,
    required this.appName,
    required this.appTagline,
    required this.logoUrl,
    required this.faviconUrl,
    required this.heroImageUrl,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.primaryColorValue,
    required this.secondaryColorValue,
    required this.accentColorValue,
    required this.backgroundColorValue,
    required this.surfaceColorValue,
    required this.errorColorValue,
    required this.successColorValue,
    required this.warningColorValue,
    required this.infoColorValue,
    required this.primaryFontFamily,
    required this.secondaryFontFamily,
    required this.baseFontSize,
    required this.titleFontSize,
    required this.headingFontSize,
    required this.captionFontSize,
    required this.borderRadius,
    required this.cardElevation,
    required this.buttonHeight,
    required this.inputHeight,
    required this.spacing,
    required this.padding,
    required this.enableDarkMode,
    required this.enableNotifications,
    required this.enableChat,
    required this.enableInvestments,
    required this.enableSustainableActivities,
    required this.enableReviews,
    required this.enablePromotions,
    required this.enableMultiLanguage,
    required this.defaultShippingFee,
    required this.minimumOrderAmount,
    required this.maxCartItems,
    required this.productApprovalDays,
    required this.platformCommissionRate,
    required this.supportEmail,
    required this.supportPhone,
    required this.companyAddress,
    required this.facebookUrl,
    required this.lineUrl,
    required this.instagramUrl,
    required this.twitterUrl,
    required this.staticTexts,
    required this.errorMessages,
    required this.successMessages,
    required this.labels,
    required this.placeholders,
    required this.buttonTexts,
    required this.images,
    required this.icons,
    required this.createdAt,
    required this.updatedAt,
  });

  // Color getters
  Color get primaryColor => Color(primaryColorValue);
  Color get secondaryColor => Color(secondaryColorValue);
  Color get accentColor => Color(accentColorValue);
  Color get backgroundColor => Color(backgroundColorValue);
  Color get surfaceColor => Color(surfaceColorValue);
  Color get errorColor => Color(errorColorValue);
  Color get successColor => Color(successColorValue);
  Color get warningColor => Color(warningColorValue);
  Color get infoColor => Color(infoColorValue);

  // Helper method to parse timestamp from different formats
  static Timestamp? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Timestamp) return value;
      if (value is int) {
        // Assume it's milliseconds since epoch
        return Timestamp.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        final intValue = int.parse(value);
        return Timestamp.fromMillisecondsSinceEpoch(intValue);
      }
    } catch (e) {
      print(
          'Error parsing timestamp: $e, value: $value, type: ${value.runtimeType}');
      // Return null instead of throwing error
      return null;
    }

    return null;
  }

  factory DynamicAppConfig.fromMap(Map<String, dynamic> map) {
    return DynamicAppConfig(
      id: map['id'] as String? ?? '',
      appName: map['appName'] as String? ?? 'Green Market',
      appTagline: map['appTagline'] as String? ?? 'ตลาดเกษตรเพื่อความยั่งยืน',
      logoUrl: map['logoUrl'] as String? ?? '',
      faviconUrl: map['faviconUrl'] as String? ?? '',
      heroImageUrl: map['heroImageUrl'] as String? ?? '',
      heroTitle: map['heroTitle'] as String? ?? 'ยินดีต้อนรับสู่ Green Market',
      heroSubtitle: map['heroSubtitle'] as String? ??
          'ตลาดออนไลน์เพื่อเกษตรกรและผู้บริโภคที่ใส่ใจสิ่งแวดล้อม',
      primaryColorValue: map['primaryColorValue'] as int? ?? 0xFF4CAF50,
      secondaryColorValue: map['secondaryColorValue'] as int? ?? 0xFFFF9800,
      accentColorValue: map['accentColorValue'] as int? ?? 0xFF2196F3,
      backgroundColorValue: map['backgroundColorValue'] as int? ?? 0xFFF5F5F5,
      surfaceColorValue: map['surfaceColorValue'] as int? ?? 0xFFFFFFFF,
      errorColorValue: map['errorColorValue'] as int? ?? 0xFFF44336,
      successColorValue: map['successColorValue'] as int? ?? 0xFF4CAF50,
      warningColorValue: map['warningColorValue'] as int? ?? 0xFFFF9800,
      infoColorValue: map['infoColorValue'] as int? ?? 0xFF2196F3,
      primaryFontFamily: map['primaryFontFamily'] as String? ?? 'Sarabun',
      secondaryFontFamily: map['secondaryFontFamily'] as String? ?? 'Sarabun',
      baseFontSize: (map['baseFontSize'] as num?)?.toDouble() ?? 14.0,
      titleFontSize: (map['titleFontSize'] as num?)?.toDouble() ?? 20.0,
      headingFontSize: (map['headingFontSize'] as num?)?.toDouble() ?? 24.0,
      captionFontSize: (map['captionFontSize'] as num?)?.toDouble() ?? 12.0,
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 8.0,
      cardElevation: (map['cardElevation'] as num?)?.toDouble() ?? 2.0,
      buttonHeight: (map['buttonHeight'] as num?)?.toDouble() ?? 48.0,
      inputHeight: (map['inputHeight'] as num?)?.toDouble() ?? 56.0,
      spacing: (map['spacing'] as num?)?.toDouble() ?? 16.0,
      padding: (map['padding'] as num?)?.toDouble() ?? 16.0,
      enableDarkMode: map['enableDarkMode'] as bool? ?? true,
      enableNotifications: map['enableNotifications'] as bool? ?? true,
      enableChat: map['enableChat'] as bool? ?? true,
      enableInvestments: map['enableInvestments'] as bool? ?? true,
      enableSustainableActivities:
          map['enableSustainableActivities'] as bool? ?? true,
      enableReviews: map['enableReviews'] as bool? ?? true,
      enablePromotions: map['enablePromotions'] as bool? ?? true,
      enableMultiLanguage: map['enableMultiLanguage'] as bool? ?? false,
      defaultShippingFee:
          (map['defaultShippingFee'] as num?)?.toDouble() ?? 50.0,
      minimumOrderAmount:
          (map['minimumOrderAmount'] as num?)?.toDouble() ?? 100.0,
      maxCartItems: map['maxCartItems'] as int? ?? 50,
      productApprovalDays: map['productApprovalDays'] as int? ?? 7,
      platformCommissionRate:
          (map['platformCommissionRate'] as num?)?.toDouble() ?? 0.05,
      supportEmail: map['supportEmail'] as String? ?? 'support@greenmarket.com',
      supportPhone: map['supportPhone'] as String? ?? '02-xxx-xxxx',
      companyAddress: map['companyAddress'] as String? ?? 'Bangkok, Thailand',
      facebookUrl: map['facebookUrl'] as String? ?? '',
      lineUrl: map['lineUrl'] as String? ?? '',
      instagramUrl: map['instagramUrl'] as String? ?? '',
      twitterUrl: map['twitterUrl'] as String? ?? '',
      staticTexts: Map<String, String>.from(map['staticTexts'] as Map? ?? {}),
      errorMessages:
          Map<String, String>.from(map['errorMessages'] as Map? ?? {}),
      successMessages:
          Map<String, String>.from(map['successMessages'] as Map? ?? {}),
      labels: Map<String, String>.from(map['labels'] as Map? ?? {}),
      placeholders: Map<String, String>.from(map['placeholders'] as Map? ?? {}),
      buttonTexts: Map<String, String>.from(map['buttonTexts'] as Map? ?? {}),
      images: Map<String, String>.from(map['images'] as Map? ?? {}),
      icons: Map<String, String>.from(map['icons'] as Map? ?? {}),
      createdAt: _parseTimestamp(map['createdAt']) ?? Timestamp.now(),
      updatedAt: _parseTimestamp(map['updatedAt']) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appName': appName,
      'appTagline': appTagline,
      'logoUrl': logoUrl,
      'faviconUrl': faviconUrl,
      'heroImageUrl': heroImageUrl,
      'heroTitle': heroTitle,
      'heroSubtitle': heroSubtitle,
      'primaryColorValue': primaryColorValue,
      'secondaryColorValue': secondaryColorValue,
      'accentColorValue': accentColorValue,
      'backgroundColorValue': backgroundColorValue,
      'surfaceColorValue': surfaceColorValue,
      'errorColorValue': errorColorValue,
      'successColorValue': successColorValue,
      'warningColorValue': warningColorValue,
      'infoColorValue': infoColorValue,
      'primaryFontFamily': primaryFontFamily,
      'secondaryFontFamily': secondaryFontFamily,
      'baseFontSize': baseFontSize,
      'titleFontSize': titleFontSize,
      'headingFontSize': headingFontSize,
      'captionFontSize': captionFontSize,
      'borderRadius': borderRadius,
      'cardElevation': cardElevation,
      'buttonHeight': buttonHeight,
      'inputHeight': inputHeight,
      'spacing': spacing,
      'padding': padding,
      'enableDarkMode': enableDarkMode,
      'enableNotifications': enableNotifications,
      'enableChat': enableChat,
      'enableInvestments': enableInvestments,
      'enableSustainableActivities': enableSustainableActivities,
      'enableReviews': enableReviews,
      'enablePromotions': enablePromotions,
      'enableMultiLanguage': enableMultiLanguage,
      'defaultShippingFee': defaultShippingFee,
      'minimumOrderAmount': minimumOrderAmount,
      'maxCartItems': maxCartItems,
      'productApprovalDays': productApprovalDays,
      'platformCommissionRate': platformCommissionRate,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'companyAddress': companyAddress,
      'facebookUrl': facebookUrl,
      'lineUrl': lineUrl,
      'instagramUrl': instagramUrl,
      'twitterUrl': twitterUrl,
      'staticTexts': staticTexts,
      'errorMessages': errorMessages,
      'successMessages': successMessages,
      'labels': labels,
      'placeholders': placeholders,
      'buttonTexts': buttonTexts,
      'images': images,
      'icons': icons,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  DynamicAppConfig copyWith({
    String? id,
    String? appName,
    String? appTagline,
    String? logoUrl,
    String? faviconUrl,
    String? heroImageUrl,
    String? heroTitle,
    String? heroSubtitle,
    int? primaryColorValue,
    int? secondaryColorValue,
    int? accentColorValue,
    int? backgroundColorValue,
    int? surfaceColorValue,
    int? errorColorValue,
    int? successColorValue,
    int? warningColorValue,
    int? infoColorValue,
    String? primaryFontFamily,
    String? secondaryFontFamily,
    double? baseFontSize,
    double? titleFontSize,
    double? headingFontSize,
    double? captionFontSize,
    double? borderRadius,
    double? cardElevation,
    double? buttonHeight,
    double? inputHeight,
    double? spacing,
    double? padding,
    bool? enableDarkMode,
    bool? enableNotifications,
    bool? enableChat,
    bool? enableInvestments,
    bool? enableSustainableActivities,
    bool? enableReviews,
    bool? enablePromotions,
    bool? enableMultiLanguage,
    double? defaultShippingFee,
    double? minimumOrderAmount,
    int? maxCartItems,
    int? productApprovalDays,
    double? platformCommissionRate,
    String? supportEmail,
    String? supportPhone,
    String? companyAddress,
    String? facebookUrl,
    String? lineUrl,
    String? instagramUrl,
    String? twitterUrl,
    Map<String, String>? staticTexts,
    Map<String, String>? errorMessages,
    Map<String, String>? successMessages,
    Map<String, String>? labels,
    Map<String, String>? placeholders,
    Map<String, String>? buttonTexts,
    Map<String, String>? images,
    Map<String, String>? icons,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return DynamicAppConfig(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      appTagline: appTagline ?? this.appTagline,
      logoUrl: logoUrl ?? this.logoUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      heroTitle: heroTitle ?? this.heroTitle,
      heroSubtitle: heroSubtitle ?? this.heroSubtitle,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      surfaceColorValue: surfaceColorValue ?? this.surfaceColorValue,
      errorColorValue: errorColorValue ?? this.errorColorValue,
      successColorValue: successColorValue ?? this.successColorValue,
      warningColorValue: warningColorValue ?? this.warningColorValue,
      infoColorValue: infoColorValue ?? this.infoColorValue,
      primaryFontFamily: primaryFontFamily ?? this.primaryFontFamily,
      secondaryFontFamily: secondaryFontFamily ?? this.secondaryFontFamily,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      headingFontSize: headingFontSize ?? this.headingFontSize,
      captionFontSize: captionFontSize ?? this.captionFontSize,
      borderRadius: borderRadius ?? this.borderRadius,
      cardElevation: cardElevation ?? this.cardElevation,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      inputHeight: inputHeight ?? this.inputHeight,
      spacing: spacing ?? this.spacing,
      padding: padding ?? this.padding,
      enableDarkMode: enableDarkMode ?? this.enableDarkMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableChat: enableChat ?? this.enableChat,
      enableInvestments: enableInvestments ?? this.enableInvestments,
      enableSustainableActivities:
          enableSustainableActivities ?? this.enableSustainableActivities,
      enableReviews: enableReviews ?? this.enableReviews,
      enablePromotions: enablePromotions ?? this.enablePromotions,
      enableMultiLanguage: enableMultiLanguage ?? this.enableMultiLanguage,
      defaultShippingFee: defaultShippingFee ?? this.defaultShippingFee,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      maxCartItems: maxCartItems ?? this.maxCartItems,
      productApprovalDays: productApprovalDays ?? this.productApprovalDays,
      platformCommissionRate:
          platformCommissionRate ?? this.platformCommissionRate,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      companyAddress: companyAddress ?? this.companyAddress,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      lineUrl: lineUrl ?? this.lineUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      staticTexts: staticTexts ?? this.staticTexts,
      errorMessages: errorMessages ?? this.errorMessages,
      successMessages: successMessages ?? this.successMessages,
      labels: labels ?? this.labels,
      placeholders: placeholders ?? this.placeholders,
      buttonTexts: buttonTexts ?? this.buttonTexts,
      images: images ?? this.images,
      icons: icons ?? this.icons,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DynamicAppConfig defaultConfig() {
    return DynamicAppConfig(
      id: 'default',
      appName: 'Green Market',
      appTagline: 'ตลาดเกษตรเพื่อความยั่งยืน',
      logoUrl: '',
      faviconUrl: '',
      heroImageUrl: '',
      heroTitle: 'ยินดีต้อนรับสู่ Green Market',
      heroSubtitle: 'ตลาดออนไลน์เพื่อเกษตรกรและผู้บริโภคที่ใส่ใจสิ่งแวดล้อม',
      primaryColorValue: 0xFF4CAF50,
      secondaryColorValue: 0xFFFF9800,
      accentColorValue: 0xFF2196F3,
      backgroundColorValue: 0xFFF5F5F5,
      surfaceColorValue: 0xFFFFFFFF,
      errorColorValue: 0xFFF44336,
      successColorValue: 0xFF4CAF50,
      warningColorValue: 0xFFFF9800,
      infoColorValue: 0xFF2196F3,
      primaryFontFamily: 'Sarabun',
      secondaryFontFamily: 'Sarabun',
      baseFontSize: 14.0,
      titleFontSize: 20.0,
      headingFontSize: 24.0,
      captionFontSize: 12.0,
      borderRadius: 8.0,
      cardElevation: 2.0,
      buttonHeight: 48.0,
      inputHeight: 56.0,
      spacing: 16.0,
      padding: 16.0,
      enableDarkMode: true,
      enableNotifications: true,
      enableChat: true,
      enableInvestments: true,
      enableSustainableActivities: true,
      enableReviews: true,
      enablePromotions: true,
      enableMultiLanguage: false,
      defaultShippingFee: 50.0,
      minimumOrderAmount: 100.0,
      maxCartItems: 50,
      productApprovalDays: 7,
      platformCommissionRate: 0.05,
      supportEmail: 'support@greenmarket.com',
      supportPhone: '02-xxx-xxxx',
      companyAddress: 'Bangkok, Thailand',
      facebookUrl: '',
      lineUrl: '',
      instagramUrl: '',
      twitterUrl: '',
      staticTexts: {},
      errorMessages: {},
      successMessages: {},
      labels: {},
      placeholders: {},
      buttonTexts: {},
      images: {},
      icons: {},
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }
}
