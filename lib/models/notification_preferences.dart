// lib/models/notification_preferences.dart
// Smart Notification Preferences - Shopee/TikTok style

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Notification Channel Preferences
class NotificationChannelPrefs {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool inAppNotifications;

  const NotificationChannelPrefs({
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
    this.inAppNotifications = true,
  });

  factory NotificationChannelPrefs.fromMap(Map<String, dynamic> map) {
    return NotificationChannelPrefs(
      pushNotifications: map['pushNotifications'] as bool? ?? true,
      emailNotifications: map['emailNotifications'] as bool? ?? false,
      smsNotifications: map['smsNotifications'] as bool? ?? false,
      inAppNotifications: map['inAppNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'inAppNotifications': inAppNotifications,
    };
  }

  NotificationChannelPrefs copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? inAppNotifications,
  }) {
    return NotificationChannelPrefs(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      inAppNotifications: inAppNotifications ?? this.inAppNotifications,
    );
  }
}

/// Category-specific Notification Settings
class CategoryNotificationSettings {
  final bool orderUpdates;
  final bool promotions;
  final bool newProducts;
  final bool priceAlerts;
  final bool socialActivity;
  final bool sellerMessages;
  final bool systemAnnouncements;
  final bool ecoRewards;
  final bool flashSales;

  const CategoryNotificationSettings({
    this.orderUpdates = true,
    this.promotions = true,
    this.newProducts = false,
    this.priceAlerts = true,
    this.socialActivity = false,
    this.sellerMessages = true,
    this.systemAnnouncements = true,
    this.ecoRewards = true,
    this.flashSales = true,
  });

  factory CategoryNotificationSettings.fromMap(Map<String, dynamic> map) {
    return CategoryNotificationSettings(
      orderUpdates: map['orderUpdates'] as bool? ?? true,
      promotions: map['promotions'] as bool? ?? true,
      newProducts: map['newProducts'] as bool? ?? false,
      priceAlerts: map['priceAlerts'] as bool? ?? true,
      socialActivity: map['socialActivity'] as bool? ?? false,
      sellerMessages: map['sellerMessages'] as bool? ?? true,
      systemAnnouncements: map['systemAnnouncements'] as bool? ?? true,
      ecoRewards: map['ecoRewards'] as bool? ?? true,
      flashSales: map['flashSales'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'newProducts': newProducts,
      'priceAlerts': priceAlerts,
      'socialActivity': socialActivity,
      'sellerMessages': sellerMessages,
      'systemAnnouncements': systemAnnouncements,
      'ecoRewards': ecoRewards,
      'flashSales': flashSales,
    };
  }

  CategoryNotificationSettings copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? newProducts,
    bool? priceAlerts,
    bool? socialActivity,
    bool? sellerMessages,
    bool? systemAnnouncements,
    bool? ecoRewards,
    bool? flashSales,
  }) {
    return CategoryNotificationSettings(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      newProducts: newProducts ?? this.newProducts,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      socialActivity: socialActivity ?? this.socialActivity,
      sellerMessages: sellerMessages ?? this.sellerMessages,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
      ecoRewards: ecoRewards ?? this.ecoRewards,
      flashSales: flashSales ?? this.flashSales,
    );
  }
}

/// Quiet Hours Configuration
class QuietHours {
  final bool enabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> enabledDays; // 0-6 (Sunday-Saturday)

  QuietHours({
    this.enabled = false,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? enabledDays,
  })  : startTime = startTime ?? const TimeOfDay(hour: 22, minute: 0),
        endTime = endTime ?? const TimeOfDay(hour: 8, minute: 0),
        enabledDays = enabledDays ?? List.generate(7, (index) => index);

  factory QuietHours.fromMap(Map<String, dynamic> map) {
    return QuietHours(
      enabled: map['enabled'] as bool? ?? false,
      startTime: map['startTime'] != null
          ? TimeOfDay(
              hour: map['startTime']['hour'] as int,
              minute: map['startTime']['minute'] as int,
            )
          : const TimeOfDay(hour: 22, minute: 0),
      endTime: map['endTime'] != null
          ? TimeOfDay(
              hour: map['endTime']['hour'] as int,
              minute: map['endTime']['minute'] as int,
            )
          : const TimeOfDay(hour: 8, minute: 0),
      enabledDays: List<int>.from(
          map['enabledDays'] ?? List.generate(7, (index) => index)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'startTime': {
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': {
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
      'enabledDays': enabledDays,
    };
  }

  bool isInQuietHours(DateTime dateTime) {
    if (!enabled) return false;
    if (!enabledDays.contains(dateTime.weekday % 7)) return false;

    final now = TimeOfDay.fromDateTime(dateTime);
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes < endMinutes) {
      // Same day range (e.g., 09:00 - 17:00)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight range (e.g., 22:00 - 08:00)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  QuietHours copyWith({
    bool? enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? enabledDays,
  }) {
    return QuietHours(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      enabledDays: enabledDays ?? this.enabledDays,
    );
  }
}

/// Notification Frequency Settings
class NotificationFrequencySettings {
  final int maxPerDay;
  final int maxPerHour;
  final bool bundleMode; // Group notifications together
  final Duration bundleInterval; // How often to send bundles

  NotificationFrequencySettings({
    this.maxPerDay = 20,
    this.maxPerHour = 5,
    this.bundleMode = false,
    this.bundleInterval = const Duration(hours: 2),
  });

  factory NotificationFrequencySettings.fromMap(Map<String, dynamic> map) {
    return NotificationFrequencySettings(
      maxPerDay: map['maxPerDay'] as int? ?? 20,
      maxPerHour: map['maxPerHour'] as int? ?? 5,
      bundleMode: map['bundleMode'] as bool? ?? false,
      bundleInterval: Duration(
        minutes: map['bundleIntervalMinutes'] as int? ?? 120,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxPerDay': maxPerDay,
      'maxPerHour': maxPerHour,
      'bundleMode': bundleMode,
      'bundleIntervalMinutes': bundleInterval.inMinutes,
    };
  }

  NotificationFrequencySettings copyWith({
    int? maxPerDay,
    int? maxPerHour,
    bool? bundleMode,
    Duration? bundleInterval,
  }) {
    return NotificationFrequencySettings(
      maxPerDay: maxPerDay ?? this.maxPerDay,
      maxPerHour: maxPerHour ?? this.maxPerHour,
      bundleMode: bundleMode ?? this.bundleMode,
      bundleInterval: bundleInterval ?? this.bundleInterval,
    );
  }
}

/// Main Notification Preferences Model
class NotificationPreferences {
  final String userId;
  final NotificationChannelPrefs channels;
  final CategoryNotificationSettings categories;
  final QuietHours quietHours;
  final NotificationFrequencySettings frequency;
  final bool smartTiming; // AI-powered optimal timing
  final DateTime lastUpdated;

  NotificationPreferences({
    required this.userId,
    NotificationChannelPrefs? channels,
    CategoryNotificationSettings? categories,
    QuietHours? quietHours,
    NotificationFrequencySettings? frequency,
    this.smartTiming = true,
    DateTime? lastUpdated,
  })  : channels = channels ?? const NotificationChannelPrefs(),
        categories = categories ?? const CategoryNotificationSettings(),
        quietHours = quietHours ?? QuietHours(),
        frequency = frequency ?? NotificationFrequencySettings(),
        lastUpdated = lastUpdated ?? DateTime.now();

  factory NotificationPreferences.fromMap(
      Map<String, dynamic> map, String userId) {
    return NotificationPreferences(
      userId: userId,
      channels: map['channels'] != null
          ? NotificationChannelPrefs.fromMap(map['channels'])
          : const NotificationChannelPrefs(),
      categories: map['categories'] != null
          ? CategoryNotificationSettings.fromMap(map['categories'])
          : const CategoryNotificationSettings(),
      quietHours: map['quietHours'] != null
          ? QuietHours.fromMap(map['quietHours'])
          : QuietHours(),
      frequency: map['frequency'] != null
          ? NotificationFrequencySettings.fromMap(map['frequency'])
          : NotificationFrequencySettings(),
      smartTiming: map['smartTiming'] as bool? ?? true,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'channels': channels.toMap(),
      'categories': categories.toMap(),
      'quietHours': quietHours.toMap(),
      'frequency': frequency.toMap(),
      'smartTiming': smartTiming,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Check if notification should be sent now
  bool shouldSendNotification(String category, DateTime now) {
    // Check quiet hours
    if (quietHours.isInQuietHours(now)) return false;

    // Check channel preferences
    if (!channels.pushNotifications) return false;

    // Check category preferences
    switch (category) {
      case 'orderUpdates':
        return categories.orderUpdates;
      case 'promotions':
        return categories.promotions;
      case 'newProducts':
        return categories.newProducts;
      case 'priceAlerts':
        return categories.priceAlerts;
      case 'socialActivity':
        return categories.socialActivity;
      case 'sellerMessages':
        return categories.sellerMessages;
      case 'systemAnnouncements':
        return categories.systemAnnouncements;
      case 'ecoRewards':
        return categories.ecoRewards;
      case 'flashSales':
        return categories.flashSales;
      default:
        return true;
    }
  }

  NotificationPreferences copyWith({
    NotificationChannelPrefs? channels,
    CategoryNotificationSettings? categories,
    QuietHours? quietHours,
    NotificationFrequencySettings? frequency,
    bool? smartTiming,
  }) {
    return NotificationPreferences(
      userId: userId,
      channels: channels ?? this.channels,
      categories: categories ?? this.categories,
      quietHours: quietHours ?? this.quietHours,
      frequency: frequency ?? this.frequency,
      smartTiming: smartTiming ?? this.smartTiming,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Notification Analytics
class NotificationAnalytics {
  final String userId;
  final int totalSent;
  final int totalRead;
  final int totalClicked;
  final Map<String, int> categoryStats;
  final Map<int, int> hourlyActivity; // Hour of day (0-23) -> activity count
  final DateTime lastAnalyzed;

  NotificationAnalytics({
    required this.userId,
    this.totalSent = 0,
    this.totalRead = 0,
    this.totalClicked = 0,
    Map<String, int>? categoryStats,
    Map<int, int>? hourlyActivity,
    DateTime? lastAnalyzed,
  })  : categoryStats = categoryStats ?? {},
        hourlyActivity = hourlyActivity ?? {},
        lastAnalyzed = lastAnalyzed ?? DateTime.now();

  factory NotificationAnalytics.fromMap(
      Map<String, dynamic> map, String userId) {
    return NotificationAnalytics(
      userId: userId,
      totalSent: map['totalSent'] as int? ?? 0,
      totalRead: map['totalRead'] as int? ?? 0,
      totalClicked: map['totalClicked'] as int? ?? 0,
      categoryStats: Map<String, int>.from(map['categoryStats'] ?? {}),
      hourlyActivity: Map<int, int>.from(
        (map['hourlyActivity'] as Map<dynamic, dynamic>? ?? {}).map(
          (k, v) => MapEntry(int.parse(k.toString()), v as int),
        ),
      ),
      lastAnalyzed: map['lastAnalyzed'] != null
          ? (map['lastAnalyzed'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalSent': totalSent,
      'totalRead': totalRead,
      'totalClicked': totalClicked,
      'categoryStats': categoryStats,
      'hourlyActivity': hourlyActivity,
      'lastAnalyzed': Timestamp.fromDate(lastAnalyzed),
    };
  }

  double get readRate => totalSent > 0 ? totalRead / totalSent : 0;
  double get clickRate => totalSent > 0 ? totalClicked / totalSent : 0;

  /// Get optimal send time based on user activity
  int get optimalHour {
    if (hourlyActivity.isEmpty) return 10; // Default to 10 AM

    return hourlyActivity.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
