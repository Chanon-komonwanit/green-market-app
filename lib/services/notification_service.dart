// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  static const channelId = "123";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        selectNotificationSubject.add(response.payload!);
      }
    });
  }

  Future<void> showNotification(
      int id, String title, String body, String payload) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      'Green Market Channel',
      channelDescription:
          'This channel is used for important notifications.', // Corrected: Added channelDescription
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(id, title, body, notificationDetails, payload: payload);
  }

  void dispose() {
    selectNotificationSubject.close();
  }
}
