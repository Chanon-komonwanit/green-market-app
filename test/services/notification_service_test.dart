import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/models/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../mocks/mock_notification_service.dart';

void main() {
  group('NotificationService', () {
    late MockNotificationService service;

    setUp(() {
      service = MockNotificationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initialization should succeed', () async {
      await service.initialize();
      expect(service.isInitialized, true);
    });

    test('notificationStream emits AppNotification', () async {
      await service.initialize();

      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'Test',
        body: 'Hello',
        createdAt: Timestamp.now(),
        type: NotificationType.promo,
      );

      service.notificationStream.listen(expectAsync1((notif) {
        expect(notif, isA<AppNotification>());
        expect(notif?.title, notification.title);
        expect(notif?.body, notification.body);
      }));

      service.addTestNotification(notification);
    });

    test('showLocalNotification should emit notification', () async {
      await service.initialize();

      service.notificationStream.listen(expectAsync1((notif) {
        expect(notif, isNotNull);
        expect(notif?.title, 'Test Title');
        expect(notif?.body, 'Test Body');
      }));

      await service.showLocalNotification(
        title: 'Test Title',
        body: 'Test Body',
        type: NotificationType.promo,
      );
    });

    test('getToken should return mock FCM token', () async {
      final token = await service.getToken();
      expect(token, isNotNull);
      expect(token, startsWith('mock_fcm_token_'));
    });

    test('should track sent notifications', () async {
      await service.initialize();

      expect(service.getSentNotificationCount(), 0);

      await service.showLocalNotification(
        title: 'Test 1',
        body: 'Body 1',
      );

      await service.showLocalNotification(
        title: 'Test 2',
        body: 'Body 2',
      );

      expect(service.getSentNotificationCount(), 2);
      final notifications = service.getSentNotifications();
      expect(notifications[0].title, 'Test 1');
      expect(notifications[1].title, 'Test 2');
    });

    test('should handle errors when configured', () async {
      service.shouldThrowError = true;
      service.errorMessage = 'Test error';

      expect(
        () => service.initialize(),
        throwsException,
      );
    });
  });
}
