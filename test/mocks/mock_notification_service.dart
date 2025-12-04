// test/mocks/mock_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/app_notification.dart';
import 'package:green_market/services/notification_service.dart';
import 'package:rxdart/rxdart.dart';

/// Professional Mock NotificationService for testing
/// Provides complete notification functionality without Firebase/FCM dependencies
class MockNotificationService implements NotificationService {
  final BehaviorSubject<AppNotification?> _notificationController =
      BehaviorSubject<AppNotification?>();

  final List<AppNotification> _sentNotifications = [];
  bool _isInitialized = false;
  String? _fcmToken;
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Stream<AppNotification?> get notificationStream =>
      _notificationController.stream;

  @override
  Future<void> initialize() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock initialization error');
    }
    _isInitialized = true;
  }

  Future<String?> getToken() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock getToken error');
    }
    _fcmToken ??= 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
    return _fcmToken;
  }

  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    final notification = AppNotification(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'test_user',
      title: 'Test Notification',
      body: 'This is a test notification',
      type: NotificationType.promo,
      createdAt: Timestamp.now(),
    );

    _notificationController.add(notification);
    _sentNotifications.add(notification);
  }

  /// Add a custom notification for testing
  void addTestNotification(AppNotification notification) {
    _notificationController.add(notification);
    _sentNotifications.add(notification);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType? type,
  }) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock showLocalNotification error');
    }

    final notification = AppNotification(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'test_user',
      title: title,
      body: body,
      type: type ?? NotificationType.promo,
      createdAt: Timestamp.now(),
    );

    _notificationController.add(notification);
    _sentNotifications.add(notification);
  }

  Future<void> requestPermission() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock requestPermission error');
    }
    // Mock permission granted
  }

  Future<void> subscribeToTopic(String topic) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock subscribeToTopic error');
    }
    // Mock subscription
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock unsubscribeFromTopic error');
    }
    // Mock unsubscription
  }

  // Test helper methods
  List<AppNotification> getSentNotifications() =>
      List.unmodifiable(_sentNotifications);

  int getSentNotificationCount() => _sentNotifications.length;

  bool get isInitialized => _isInitialized;

  void reset() {
    _sentNotifications.clear();
    _isInitialized = false;
    _fcmToken = null;
    shouldThrowError = false;
    errorMessage = null;
  }

  @override
  void dispose() {
    _notificationController.close();
  }

  // Implement other methods with mock behavior
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error in ${invocation.memberName}');
    }
    return Future.value();
  }
}
