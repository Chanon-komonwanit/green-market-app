import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../models/app_notification.dart';
import '../providers/user_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('กรุณาเข้าสู่ระบบ')),
      );
    }
    final NotificationService notificationService = NotificationService();
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งเตือน')),
      body: StreamBuilder<List<AppNotification>>(
        stream: notificationService.getUserNotificationsStream(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีแจ้งเตือนใหม่'));
          }
          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                leading: n.imageUrl != null
                    ? Image.network(n.imageUrl!,
                        width: 40, height: 40, fit: BoxFit.cover)
                    : const Icon(Icons.notifications),
                title: Text(n.title),
                subtitle: Text(n.body),
                trailing: n.isRead
                    ? null
                    : const Icon(Icons.fiber_new, color: Colors.red),
                onTap: () {
                  // TODO: handle notification action (deep link, etc.)
                },
              );
            },
          );
        },
      ),
    );
  }
}
