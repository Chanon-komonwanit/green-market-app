// lib/providers/notification_preferences_provider.dart
// Smart Notification Preferences Provider
// จัดการการตั้งค่าการแจ้งเตือนอัจฉริยะ

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/notification_preferences.dart';
import '../services/smart_notification_service.dart';
import 'dart:async';

class NotificationPreferencesProvider extends ChangeNotifier {
  final SmartNotificationService _smartService = SmartNotificationService();

  // ==================== STATE ====================

  NotificationPreferences? _preferences;
  NotificationAnalytics? _analytics;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Real-time streams
  StreamSubscription? _notificationsSub;
  StreamSubscription? _unreadCountSub;

  int _unreadCount = 0;

  // ==================== GETTERS ====================

  NotificationPreferences? get preferences => _preferences;
  NotificationAnalytics? get analytics => _analytics;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  int get unreadCount => _unreadCount;

  // Channel preferences
  bool get pushEnabled => _preferences?.channels.pushNotifications ?? true;
  bool get emailEnabled => _preferences?.channels.emailNotifications ?? false;
  bool get smsEnabled => _preferences?.channels.smsNotifications ?? false;
  bool get inAppEnabled => _preferences?.channels.inAppNotifications ?? true;

  // Category preferences
  CategoryNotificationSettings? get categorySettings =>
      _preferences?.categories;

  // Quiet hours
  bool get hasQuietHours => _preferences?.quietHours != null;
  QuietHours? get quietHours => _preferences?.quietHours;
  bool get isCurrentlyInQuietHours =>
      _preferences?.quietHours.isInQuietHours(DateTime.now()) ?? false;

  // Frequency settings
  int get maxNotificationsPerDay => _preferences?.frequency.maxPerDay ?? 20;
  int get maxNotificationsPerHour => _preferences?.frequency.maxPerHour ?? 5;
  bool get bundleNotifications => _preferences?.frequency.bundleMode ?? false;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    await loadPreferences();
    _startListeningToStreams();
  }

  void _startListeningToStreams() {
    // Listen to unread count
    _unreadCountSub = _smartService.getUnreadCountStream().listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Unread count stream error: $error');
      },
    );
  }

  // ==================== PREFERENCES MANAGEMENT ====================

  /// Load user preferences
  Future<void> loadPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _preferences = await _smartService.getPreferences();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load preferences: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update full preferences
  Future<bool> updatePreferences(NotificationPreferences newPreferences) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _smartService.updatePreferences(newPreferences);
      _preferences = newPreferences;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save preferences: $e';
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ==================== CHANNEL SETTINGS ====================

  Future<void> setPushEnabled(bool enabled) async {
    if (_preferences == null) return;

    final updated = NotificationPreferences(
      userId: _preferences!.userId,
      channels: NotificationChannelPrefs(
        pushNotifications: enabled,
        emailNotifications: _preferences!.channels.emailNotifications,
        smsNotifications: _preferences!.channels.smsNotifications,
        inAppNotifications: _preferences!.channels.inAppNotifications,
      ),
      categories: _preferences!.categories,
      quietHours: _preferences!.quietHours,
      frequency: _preferences!.frequency,
    );

    await updatePreferences(updated);
  }

  Future<void> setEmailEnabled(bool enabled) async {
    if (_preferences == null) return;

    final updated = NotificationPreferences(
      userId: _preferences!.userId,
      channels: NotificationChannelPrefs(
        pushNotifications: _preferences!.channels.pushNotifications,
        emailNotifications: enabled,
        smsNotifications: _preferences!.channels.smsNotifications,
        inAppNotifications: _preferences!.channels.inAppNotifications,
      ),
      categories: _preferences!.categories,
      quietHours: _preferences!.quietHours,
      frequency: _preferences!.frequency,
    );
    await updatePreferences(updated);
  }

  // ==================== CATEGORY SETTINGS ====================

  Future<void> setCategoryEnabled(String category, bool enabled) async {
    if (_preferences == null) return;

    final currentSettings = _preferences!.categories.toMap();
    currentSettings[category] = enabled;

    final updated = NotificationPreferences(
      userId: _preferences!.userId,
      channels: _preferences!.channels,
      categories: CategoryNotificationSettings.fromMap(currentSettings),
      quietHours: _preferences!.quietHours,
      frequency: _preferences!.frequency,
    );

    await updatePreferences(updated);
  }

  // ==================== QUIET HOURS ====================

  Future<void> setQuietHours({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    List<int>? enabledDays,
  }) async {
    if (_preferences == null) return;

    final quietHours = QuietHours(
      enabled: true,
      startTime: startTime,
      endTime: endTime,
      enabledDays: enabledDays,
    );
    final updated = NotificationPreferences(
      userId: _preferences!.userId,
      channels: _preferences!.channels,
      categories: _preferences!.categories,
      quietHours: quietHours,
      frequency: _preferences!.frequency,
    );

    await updatePreferences(updated);
  }

  Future<void> removeQuietHours() async {
    if (_preferences == null) return;

    final updated = NotificationPreferences(
      userId: _preferences!.userId,
      channels: _preferences!.channels,
      categories: _preferences!.categories,
      quietHours: null,
      frequency: _preferences!.frequency,
    );

    await updatePreferences(updated);
  }

  // ==================== FREQUENCY SETTINGS ====================

  Future<void> setFrequencyLimits({
    int? maxPerDay,
    int? maxPerHour,
    bool? bundleNotifications,
  }) async {
    if (_preferences == null) return;

    final updated = NotificationPreferences(
      userId: _preferences!.userId,
      channels: _preferences!.channels,
      categories: _preferences!.categories,
      quietHours: _preferences!.quietHours,
      frequency: NotificationFrequencySettings(
        maxPerDay: maxPerDay ?? _preferences!.frequency.maxPerDay,
        maxPerHour: maxPerHour ?? _preferences!.frequency.maxPerHour,
        bundleMode: bundleNotifications ?? _preferences!.frequency.bundleMode,
      ),
    );

    await updatePreferences(updated);
  }

  // ==================== NOTIFICATION ACTIONS ====================

  Future<void> markAsRead(String notificationId) async {
    try {
      await _smartService.markAsRead(notificationId);
    } catch (e) {
      debugPrint('Mark as read failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _smartService.markAllAsRead();
    } catch (e) {
      debugPrint('Mark all as read failed: $e');
    }
  }

  Future<void> trackNotificationClicked(String notificationId) async {
    try {
      await _smartService.trackNotificationClicked(notificationId);
    } catch (e) {
      debugPrint('Track click failed: $e');
    }
  }

  // ==================== UTILITY ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();
    super.dispose();
  }
}
