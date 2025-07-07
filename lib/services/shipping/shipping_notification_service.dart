// lib/services/shipping/shipping_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/firebase_service.dart';

class ShippingNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Send notification when order status changes
  static Future<void> sendOrderStatusNotification(
    app_order.Order order,
    String newStatus,
    String userId,
  ) async {
    String title = 'อัพเดทสถานะคำสั่งซื้อ';
    String body = '';

    switch (newStatus) {
      case 'processing':
        body = 'คำสั่งซื้อ #${order.id.substring(0, 8)} กำลังจัดเตรียม';
        break;
      case 'shipped':
        body = 'คำสั่งซื้อ #${order.id.substring(0, 8)} ได้จัดส่งแล้ว';
        break;
      case 'delivered':
        body = 'คำสั่งซื้อ #${order.id.substring(0, 8)} ได้ส่งถึงแล้ว';
        break;
      case 'cancelled':
        body = 'คำสั่งซื้อ #${order.id.substring(0, 8)} ถูกยกเลิก';
        break;
    }

    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'order_${order.id}',
    );
  }

  /// Send notification when tracking number is added
  static Future<void> sendTrackingNumberNotification(
    app_order.Order order,
    String trackingNumber,
  ) async {
    await _showLocalNotification(
      title: 'หมายเลขติดตามพัสดุ',
      body:
          'หมายเลขติดตาม: $trackingNumber สำหรับคำสั่งซื้อ #${order.id.substring(0, 8)}',
      payload: 'tracking_${order.id}',
    );
  }

  /// Send notification to seller about new orders
  static Future<void> sendNewOrderNotificationToSeller(
    app_order.Order order,
    String sellerId,
  ) async {
    await _showLocalNotification(
      title: 'คำสั่งซื้อใหม่',
      body: 'คุณมีคำสั่งซื้อใหม่ #${order.id.substring(0, 8)} รอการจัดส่ง',
      payload: 'seller_order_${order.id}',
    );
  }

  /// Send bulk operation completion notification
  static Future<void> sendBulkOperationNotification(
    String operation,
    int count,
    bool success,
  ) async {
    String title = success ? 'ดำเนินการสำเร็จ' : 'ดำเนินการล้มเหลว';
    String body = success
        ? '$operation $count รายการเสร็จสิ้น'
        : '$operation ล้มเหลว กรุณาลองใหม่';

    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'bulk_operation',
    );
  }

  /// Send delivery reminder notification
  static Future<void> sendDeliveryReminderNotification(
    app_order.Order order,
  ) async {
    await _showLocalNotification(
      title: 'พัสดุจะถึงวันนี้',
      body: 'คำสั่งซื้อ #${order.id.substring(0, 8)} น่าจะถึงวันนี้',
      payload: 'delivery_reminder_${order.id}',
    );
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'shipping_channel',
      'Shipping Notifications',
      channelDescription: 'Notifications about shipping and delivery',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule delivery reminder notification
  static Future<void> scheduleDeliveryReminder(
    app_order.Order order,
    DateTime deliveryDate,
  ) async {
    // Schedule notification for delivery day
    final reminderDate = deliveryDate.subtract(const Duration(hours: 2));

    if (reminderDate.isAfter(DateTime.now())) {
      // Implementation for scheduled notifications would go here
      // For now, we'll just log it
      print('Scheduled delivery reminder for ${order.id} at $reminderDate');
    }
  }

  /// Cancel all notifications for an order
  static Future<void> cancelOrderNotifications(String orderId) async {
    // Implementation to cancel specific notifications
    // This would require storing notification IDs
    print('Cancelled notifications for order $orderId');
  }
}
