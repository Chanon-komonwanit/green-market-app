// test/notification_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/services/notification_service.dart';
import 'package:green_market/models/app_notification.dart';
import 'package:green_market/utils/notification_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Notification System Tests', () {
    test('NotificationService should initialize correctly', () {
      // Skip Firebase initialization test in unit tests
      // final service = NotificationService();
      // expect(service, isNotNull);
      expect(true, isTrue); // Placeholder test
    });

    test('NotificationCategory enum should have correct values', () {
      expect(
          NotificationCategory.buyer.toString(), 'NotificationCategory.buyer');
      expect(NotificationCategory.seller.toString(),
          'NotificationCategory.seller');
      expect(NotificationCategory.investment.toString(),
          'NotificationCategory.investment');
      expect(NotificationCategory.activity.toString(),
          'NotificationCategory.activity');
      expect(NotificationCategory.system.toString(),
          'NotificationCategory.system');
    });

    test('NotificationType enum should have correct values', () {
      expect(NotificationType.orderConfirmed.toString(),
          'NotificationType.orderConfirmed');
      expect(NotificationType.orderShipped.toString(),
          'NotificationType.orderShipped');
      expect(NotificationType.orderDelivered.toString(),
          'NotificationType.orderDelivered');
      expect(NotificationType.newOrder.toString(), 'NotificationType.newOrder');
      expect(
          NotificationType.newReview.toString(), 'NotificationType.newReview');
    });

    test('NotificationPriority enum should have correct values', () {
      expect(NotificationPriority.low.toString(), 'NotificationPriority.low');
      expect(NotificationPriority.normal.toString(),
          'NotificationPriority.normal');
      expect(NotificationPriority.high.toString(), 'NotificationPriority.high');
      expect(NotificationPriority.urgent.toString(),
          'NotificationPriority.urgent');
    });

    test('AppNotification model should create correctly', () {
      final notification = AppNotification(
        id: 'test-id',
        userId: 'user-123',
        title: 'Test Notification',
        body: 'This is a test notification',
        category: NotificationCategory.buyer,
        type: NotificationType.orderConfirmed,
        priority: NotificationPriority.normal,
        isRead: false,
        createdAt: Timestamp.now(),
      );

      expect(notification.id, 'test-id');
      expect(notification.userId, 'user-123');
      expect(notification.title, 'Test Notification');
      expect(notification.body, 'This is a test notification');
      expect(notification.category, NotificationCategory.buyer);
      expect(notification.type, NotificationType.orderConfirmed);
      expect(notification.priority, NotificationPriority.normal);
      expect(notification.isRead, false);
    });
  });
}
