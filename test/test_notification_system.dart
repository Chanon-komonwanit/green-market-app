// test/test_notification_system.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/models/app_notification.dart';
import 'package:green_market/utils/notification_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Notification System Tests', () {
    test('Test Order Notification Creation', () async {
      // Test order confirmation notification
      await NotificationHelper.orderConfirmed(
        userId: 'test_user_123',
        orderId: 'ORDER_001',
        orderTotal: '1,250.00',
        productNames: ['มะม่วงอินทผลัม', 'กล้วยหอมทอง'],
      );

      print('✅ Order confirmation notification sent successfully');
    });

    test('Test Seller Notification Creation', () async {
      // Test new order notification for seller
      await NotificationHelper.newOrder(
        sellerId: 'seller_456',
        orderId: 'ORDER_001',
        customerName: 'จิรายุ ใจดี',
        orderTotal: '650.00',
        products: [
          {'name': 'มะม่วงอินทผลัม', 'quantity': 2, 'price': 325.0},
        ],
      );

      print('✅ New order notification for seller sent successfully');
    });

    test('Test Investment Notification Creation', () async {
      // Test investment opportunity notification
      await NotificationHelper.investmentOpportunity(
        userId: 'investor_789',
        opportunityId: 'INV_001',
        title: 'โครงการปลูกข้าวอินทรีย์',
        description: 'โครงการเกษตรอินทรีย์ที่มีศักยภาพสูง',
        expectedReturn: '12%',
        riskLevel: 'ปานกลาง',
        minimumInvestment: '50,000',
      );

      print('✅ Investment notification sent successfully');
    });

    test('Test Activity Notification Creation', () async {
      // Test new activity notification
      await NotificationHelper.newActivity(
        userId: 'user_101',
        activityId: 'ACT_001',
        activityName: 'กิจกรรมเก็บขยะชายหาด',
        description: 'ร่วมกันดูแลสิ่งแวดล้อม',
        date: '15 มกราคม 2568',
        location: 'หาดป่าตอง จังหวัดภูเก็ต',
      );

      print('✅ Activity notification sent successfully');
    });

    test('Test System Notification Creation', () async {
      // Test app update notification
      await NotificationHelper.appUpdate(
        userId: 'user_001',
        version: '2.0.0',
        features: 'เพิ่มฟีเจอร์ใหม่และปรับปรุงประสิทธิภาพ',
        isRequired: false,
      );

      print('✅ System notification sent successfully');
    });

    test('Test Notification Categories and Types', () {
      // Test all notification categories
      final categories = NotificationCategory.values;
      print('Available notification categories: ${categories.length}');
      for (var category in categories) {
        print('- ${category.value}');
      }

      // Test all notification types
      final types = NotificationType.values;
      print('Available notification types: ${types.length}');
      for (var type in types) {
        print('- ${type.value}');
      }

      expect(categories.length, greaterThan(0));
      expect(types.length, greaterThan(0));
    });

    test('Test Notification Model', () {
      final notification = AppNotification(
        id: 'test_001',
        userId: 'user_123',
        title: 'Test Notification',
        body: 'This is a test notification',
        category: NotificationCategory.buyer,
        type: NotificationType.orderConfirmed,
        priority: NotificationPriority.high,
        createdAt: Timestamp.now(),
        isRead: false,
      );

      expect(notification.id, equals('test_001'));
      expect(notification.userId, equals('user_123'));
      expect(notification.category, equals(NotificationCategory.buyer));
      expect(notification.type, equals(NotificationType.orderConfirmed));
      expect(notification.priority, equals(NotificationPriority.high));
      expect(notification.isRead, isFalse);

      print('✅ Notification model validation passed');
    });
  });
}
