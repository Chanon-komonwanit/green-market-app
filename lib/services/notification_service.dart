import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import '../models/app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final BehaviorSubject<AppNotification?> _notificationStream =
      BehaviorSubject<AppNotification?>();
  Stream<AppNotification?> get notificationStream => _notificationStream.stream;

  // Notification channels
  static const String _buyerChannelId = 'buyer_notifications';
  static const String _sellerChannelId = 'seller_notifications';
  static const String _investmentChannelId = 'investment_notifications';
  static const String _activityChannelId = 'activity_notifications';
  static const String _systemChannelId = 'system_notifications';

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInitialization =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitialization = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        _buyerChannelId,
        'การซื้อสินค้า',
        description: 'แจ้งเตือนเกี่ยวกับคำสั่งซื้อ การชำระเงิน และการจัดส่ง',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _sellerChannelId,
        'ร้านค้าของฉัน',
        description: 'แจ้งเตือนคำสั่งซื้อใหม่ รีวิว และยอดขาย',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _investmentChannelId,
        'การลงทุน',
        description: 'แจ้งเตือนโอกาสลงทุน ผลตอบแทน และอัปเดตพอร์ตโฟลิโอ',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _activityChannelId,
        'กิจกรรม',
        description: 'แจ้งเตือนกิจกรรมใหม่ การแจ้งเตือน และชุมชน',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        _systemChannelId,
        'ระบบ',
        description: 'แจ้งเตือนจากระบบ อัปเดต และประกาศ',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = _createNotificationFromRemoteMessage(message);
    if (notification != null) {
      _showLocalNotification(notification);
      _notificationStream.add(notification);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    final notification = _createNotificationFromRemoteMessage(message);
    if (notification != null) {
      _notificationStream.add(notification);
    }
  }

  AppNotification? _createNotificationFromRemoteMessage(RemoteMessage message) {
    if (message.data.isEmpty) return null;

    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: message.data['userId'] ?? '',
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: NotificationType.fromString(message.data['type'] ?? 'system'),
      relatedId: message.data['relatedId'],
      data: message.data,
      imageUrl: message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      actionUrl: message.data['actionUrl'],
      createdAt: Timestamp.now(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      _handleNotificationNavigation(response.payload!);
    }
  }

  void _handleNotificationNavigation(String payload) {
    print('Notification tapped with payload: $payload');
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    final channelId = _getChannelId(notification.category);
    final notificationId = notification.hashCode;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(notification.category),
      channelDescription: _getChannelDescription(notification.category),
      importance: _getImportance(notification.priority),
      priority: _getPriority(notification.priority),
      icon: _getIcon(notification.category),
      color: _getColor(notification.category),
      styleInformation: BigTextStyleInformation(notification.body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      notificationDetails,
      payload: notification.toMap().toString(),
    );
  }

  String _getChannelId(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.buyer:
        return _buyerChannelId;
      case NotificationCategory.seller:
        return _sellerChannelId;
      case NotificationCategory.investment:
        return _investmentChannelId;
      case NotificationCategory.activity:
        return _activityChannelId;
      case NotificationCategory.system:
        return _systemChannelId;
    }
  }

  String _getChannelName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.buyer:
        return 'การซื้อสินค้า';
      case NotificationCategory.seller:
        return 'ร้านค้าของฉัน';
      case NotificationCategory.investment:
        return 'การลงทุน';
      case NotificationCategory.activity:
        return 'กิจกรรม';
      case NotificationCategory.system:
        return 'ระบบ';
    }
  }

  String _getChannelDescription(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.buyer:
        return 'แจ้งเตือนเกี่ยวกับคำสั่งซื้อ การชำระเงิน และการจัดส่ง';
      case NotificationCategory.seller:
        return 'แจ้งเตือนคำสั่งซื้อใหม่ รีวิว และยอดขาย';
      case NotificationCategory.investment:
        return 'แจ้งเตือนโอกาสลงทุน ผลตอบแทน และอัปเดตพอร์ตโฟลิโอ';
      case NotificationCategory.activity:
        return 'แจ้งเตือนกิจกรรมใหม่ การแจ้งเตือน และชุมชน';
      case NotificationCategory.system:
        return 'แจ้งเตือนจากระบบ อัปเดต และประกาศ';
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  String _getIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.buyer:
        return '@mipmap/ic_launcher';
      case NotificationCategory.seller:
        return '@mipmap/ic_launcher';
      case NotificationCategory.investment:
        return '@mipmap/ic_launcher';
      case NotificationCategory.activity:
        return '@mipmap/ic_launcher';
      case NotificationCategory.system:
        return '@mipmap/ic_launcher';
    }
  }

  Color _getColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.buyer:
        return const Color(0xFF2196F3);
      case NotificationCategory.seller:
        return const Color(0xFF4CAF50);
      case NotificationCategory.investment:
        return const Color(0xFFFF9800);
      case NotificationCategory.activity:
        return const Color(0xFF9C27B0);
      case NotificationCategory.system:
        return const Color(0xFF607D8B);
    }
  }

  // Public methods สำหรับส่งการแจ้งเตือน
  Future<void> sendBuyerNotification({
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
      id: _generateId(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      category: NotificationCategory.buyer,
      priority: priority,
      relatedId: relatedId,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      createdAt: Timestamp.now(),
    );

    await _saveAndSendNotification(notification);
  }

  Future<void> sendSellerNotification({
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
      id: _generateId(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      category: NotificationCategory.seller,
      priority: priority,
      relatedId: relatedId,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      createdAt: Timestamp.now(),
    );

    await _saveAndSendNotification(notification);
  }

  Future<void> sendInvestmentNotification({
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
      id: _generateId(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      category: NotificationCategory.investment,
      priority: priority,
      relatedId: relatedId,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      createdAt: Timestamp.now(),
    );

    await _saveAndSendNotification(notification);
  }

  Future<void> sendActivityNotification({
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
      id: _generateId(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      category: NotificationCategory.activity,
      priority: priority,
      relatedId: relatedId,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      createdAt: Timestamp.now(),
    );

    await _saveAndSendNotification(notification);
  }

  Future<void> sendSystemNotification({
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
      id: _generateId(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      category: NotificationCategory.system,
      priority: priority,
      relatedId: relatedId,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      createdAt: Timestamp.now(),
    );

    await _saveAndSendNotification(notification);
  }

  // Helper methods
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random().nextInt(99999).toString().padLeft(5, '0');
    return 'notif_$timestamp$random';
  }

  Future<void> _saveAndSendNotification(AppNotification notification) async {
    try {
      // Save to Firestore
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // Show local notification
      await _showLocalNotification(notification);

      // Add to stream
      _notificationStream.add(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving/sending notification: $e');
      }
    }
  }

  // Additional utility methods
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user notifications: $e');
      }
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': Timestamp.now()});
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  // Additional methods สำหรับ UI components
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
      return 0;
    }
  }

  Future<int> getUnreadCountByCategory(
      String userId, NotificationCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.value)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count by category: $e');
      }
      return 0;
    }
  }

  Future<List<AppNotification>> getUserNotificationsByCategory(
      String userId, NotificationCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.value)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user notifications by category: $e');
      }
      return [];
    }
  }

  Stream<List<AppNotification>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .toList());
  }

  Stream<List<AppNotification>> getUserNotificationsByCategoryStream(
      String userId, NotificationCategory category) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .toList());
  }

  // Stream versions for real-time updates
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getUnreadCountByCategoryStream(
      String userId, NotificationCategory category) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category.value)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all as read: $e');
      }
    }
  }

  Future<void> archiveNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isArchived': true,
        'archivedAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error archiving notification: $e');
      }
    }
  }

  void dispose() {
    _notificationStream.close();
  }
}
