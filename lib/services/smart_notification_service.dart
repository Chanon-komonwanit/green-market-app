// lib/services/smart_notification_service.dart
// Smart Notification Service with AI-powered timing and preferences
// ขยายความสามารถจาก NotificationService เดิม

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_notification.dart';
import '../models/notification_preferences.dart';
import 'notification_service.dart';

class SmartNotificationService {
  static final SmartNotificationService _instance =
      SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== PREFERENCES MANAGEMENT ====================

  /// Get user's notification preferences
  Future<NotificationPreferences> getPreferences() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore
        .collection('notification_preferences')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      return _createDefaultPreferences(user.uid);
    }

    return NotificationPreferences.fromMap(doc.data()!, user.uid);
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('notification_preferences')
        .doc(user.uid)
        .set(preferences.toMap(), SetOptions(merge: true));
  }

  /// Create default preferences for new user
  Future<NotificationPreferences> _createDefaultPreferences(
      String userId) async {
    final preferences = NotificationPreferences(userId: userId);
    await _firestore
        .collection('notification_preferences')
        .doc(userId)
        .set(preferences.toMap());
    return preferences;
  }

  // ==================== SMART SENDING ====================

  /// Send notification with smart timing
  Future<void> sendSmartNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    // Get user preferences
    final prefs = await getPreferences();

    // Get category from type
    final category = type.category.value;

    // Check if should send
    final now = DateTime.now();
    if (!prefs.shouldSendNotification(category, now)) {
      print('Notification blocked by user preferences');
      return;
    }

    // Check frequency limits
    if (!(await _checkFrequencyLimits(userId, prefs.frequency))) {
      print('Notification blocked by frequency limits');
      if (prefs.frequency.bundleMode) {
        await _addToPendingBundle(userId, title, body, type);
      }
      return;
    }

    // Optimize send time if smart timing enabled
    if (prefs.smartTiming && priority == NotificationPriority.normal) {
      final optimalTime = await _getOptimalSendTime(userId);
      if (optimalTime != null && optimalTime.isAfter(now)) {
        await _scheduleNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          scheduledFor: optimalTime,
          relatedId: relatedId,
          data: data,
          imageUrl: imageUrl,
          actionUrl: actionUrl,
        );
        return;
      }
    }

    // Send immediately
    await _sendNotificationNow(
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      priority: priority,
    );

    // Track analytics
    await _trackNotificationSent(userId, category);
  }

  /// Check if within frequency limits
  Future<bool> _checkFrequencyLimits(
    String userId,
    NotificationFrequencySettings frequency,
  ) async {
    final now = DateTime.now();

    // Check hourly limit
    final hourStart = DateTime(now.year, now.month, now.day, now.hour);
    final hourCount = await _getNotificationCount(
      userId,
      hourStart,
      now,
    );
    if (hourCount >= frequency.maxPerHour) return false;

    // Check daily limit
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayCount = await _getNotificationCount(
      userId,
      dayStart,
      now,
    );
    if (dayCount >= frequency.maxPerDay) return false;

    return true;
  }

  /// Get notification count in time range
  Future<int> _getNotificationCount(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get optimal send time based on user activity
  Future<DateTime?> _getOptimalSendTime(String userId) async {
    final analyticsDoc =
        await _firestore.collection('notification_analytics').doc(userId).get();

    if (!analyticsDoc.exists) return null;

    final analytics =
        NotificationAnalytics.fromMap(analyticsDoc.data()!, userId);
    final optimalHour = analytics.optimalHour;

    final now = DateTime.now();
    var optimalTime = DateTime(
      now.year,
      now.month,
      now.day,
      optimalHour,
    );

    // If optimal time already passed, schedule for tomorrow
    if (optimalTime.isBefore(now)) {
      optimalTime = optimalTime.add(const Duration(days: 1));
    }

    return optimalTime;
  }

  /// Schedule notification for later
  Future<void> _scheduleNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required DateTime scheduledFor,
    String? relatedId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) async {
    await _firestore.collection('scheduled_notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'relatedId': relatedId,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send notification immediately
  Future<void> _sendNotificationNow({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final notification = AppNotification(
      id: _firestore.collection('notifications').doc().id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      data: data ?? {},
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      priority: priority,
      createdAt: Timestamp.now(),
    );

    // Save to Firestore
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());

    // Send push notification via FCM
    await _sendPushNotification(userId, notification);
  }

  /// Send push notification via FCM
  Future<void> _sendPushNotification(
    String userId,
    AppNotification notification,
  ) async {
    // Get user's FCM token
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;

    if (fcmToken == null) return;

    // Send via FCM (would use Firebase Admin SDK in production)
    // For now, just log
    print('Would send push to token: $fcmToken');
  }

  /// Add notification to pending bundle
  Future<void> _addToPendingBundle(
    String userId,
    String title,
    String body,
    NotificationType type,
  ) async {
    await _firestore.collection('notification_bundles').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'addedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  /// Track notification sent for analytics
  Future<void> _trackNotificationSent(String userId, String category) async {
    final analyticsRef =
        _firestore.collection('notification_analytics').doc(userId);

    await analyticsRef.set({
      'userId': userId,
      'totalSent': FieldValue.increment(1),
      'categoryStats.$category': FieldValue.increment(1),
      'hourlyActivity.${DateTime.now().hour}': FieldValue.increment(1),
      'lastAnalyzed': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==================== NOTIFICATION ACTIONS ====================

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });

    // Track for analytics
    await _trackNotificationRead(user.uid);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Track notification read
  Future<void> _trackNotificationRead(String userId) async {
    await _firestore.collection('notification_analytics').doc(userId).set({
      'totalRead': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Track notification clicked
  Future<void> trackNotificationClicked(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('notifications').doc(notificationId).update({
      'isClicked': true,
      'clickedAt': FieldValue.serverTimestamp(),
    });

    // Track for analytics
    await _firestore.collection('notification_analytics').doc(user.uid).set({
      'totalClicked': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ==================== STREAMS ====================

  /// Get notifications stream
  Stream<List<AppNotification>> getNotificationsStream({
    int limit = 50,
    bool unreadOnly = false,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return AppNotification.fromMap(data);
        }).toList());
  }

  /// Get unread count
  Stream<int> getUnreadCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
