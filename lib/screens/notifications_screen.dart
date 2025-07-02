// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/app_notification.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/screens/investment_project_detail_screen.dart'; // NEW: Import
import 'package:green_market/screens/sustainable_activity/sustainable_activity_detail_screen.dart'; // NEW: Import
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    final userId = userProvider.currentUser?.id; // Use currentUser.id

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('การแจ้งเตือน',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
        ),
        body: const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูการแจ้งเตือน')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('การแจ้งเตือน',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await firebaseService.markAllNotificationsAsRead(userId);
                showAppSnackBar(context, 'ทำเครื่องหมายว่าอ่านแล้วทั้งหมด',
                    isSuccess: true);
              } catch (e) {
                showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                    isError: true);
              }
            },
            child: Text('ทำเครื่องหมายว่าอ่านแล้วทั้งหมด',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: firebaseService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, // Corrected: Already correct
                      color: theme.colorScheme.onSurface
                          .withAlpha((0.4 * 255).round())), // Use withAlpha
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีการแจ้งเตือนในขณะนี้',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withAlpha((0.6 * 255).round()), // Use withAlpha
                    ), // Corrected: Already correct
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                color: notification.isRead
                    ? theme.cardColor
                    // ignore: deprecated_member_use
                    : theme.colorScheme.primaryContainer.withOpacity(0.1),
                child: ListTile(
                  leading: Icon(
                    notification.isRead
                        ? Icons.notifications_none // Corrected: Already correct
                        : Icons
                            .notifications_active, // Corrected: Already correct
                    color: notification.isRead
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                  ),
                  title: Text(
                    notification.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      // Corrected: Already correct
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme
                            .textTheme.bodyMedium, // Corrected: Already correct
                      ),
                      Text(
                        DateFormat('dd MMM yyyy HH:mm')
                            .format(notification.createdAt.toDate()),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!notification.isRead) {
                      await firebaseService
                          .markNotificationAsRead(notification.id);
                    }
                    // Optionally navigate to related content based on notification.type and notification.relatedId
                    if (notification.type ==
                            NotificationType.investmentApproved ||
                        notification.type ==
                            NotificationType.investmentRejected) {
                      // Corrected: Already correct
                      final project = await firebaseService
                          .getInvestmentProjectById(notification.relatedId!);
                      if (context.mounted && project != null) {
                        Navigator.of(context).push(MaterialPageRoute(
                          // Ensure project is not null before passing
                          // If project is null, InvestmentProjectDetailScreen will crash
                          builder: (ctx) =>
                              InvestmentProjectDetailScreen(project: project),
                        ));
                      } else if (context.mounted) {
                        showAppSnackBar(context, 'ไม่พบโครงการที่เกี่ยวข้อง',
                            isError: true);
                      }
                    } else if (notification.type ==
                            NotificationType.activityApproved ||
                        notification.type ==
                            NotificationType.activityRejected ||
                        notification.type ==
                            NotificationType.activityCancelled) {
                      // Corrected: Already correct
                      final activity = await firebaseService
                          .getSustainableActivityById(notification.relatedId!);
                      if (context.mounted && activity != null) {
                        Navigator.of(context).push(MaterialPageRoute(
                          // Ensure activity is not null before passing
                          // If activity is null, SustainableActivityDetailScreen will crash
                          builder: (ctx) => SustainableActivityDetailScreen(
                              activity: activity),
                        ));
                      } else if (context.mounted) {
                        showAppSnackBar(context, 'ไม่พบกิจกรรมที่เกี่ยวข้อง',
                            isError: true);
                      }
                    } else {
                      showAppSnackBar(
                          context, 'แจ้งเตือน: ${notification.title}');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
