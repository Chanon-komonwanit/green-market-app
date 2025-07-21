import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/services/notification_service.dart';
import 'package:green_market/models/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationService', () {
    test('notificationStream emits AppNotification', () async {
      final service = NotificationService();
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
      }));
      // เพิ่ม method ใน NotificationService สำหรับทดสอบเท่านั้น
      // หรือใช้ reflection/mock ในการทดสอบจริง
      // ตัวอย่าง: service.addTestNotification(notification);
    });
  });
}
