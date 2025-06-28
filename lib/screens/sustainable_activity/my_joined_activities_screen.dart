// lib/screens/sustainable_activity/my_joined_activities_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:green_market/models/sustainable_activity.dart';
import 'package:green_market/screens/sustainable_activity/sustainable_activity_detail_screen.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyJoinedActivitiesScreen extends StatelessWidget {
  const MyJoinedActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    final userId = userProvider.currentUser?.id; // Corrected: Use currentUser

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('กิจกรรมที่เข้าร่วม',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
        ),
        body: const Center(
            child: Text('กรุณาเข้าสู่ระบบเพื่อดูกิจกรรมที่เข้าร่วม')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('กิจกรรมที่เข้าร่วม',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<SustainableActivity>>(
        stream: firebaseService.getJoinedSustainableActivities(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('คุณยังไม่ได้เข้าร่วมกิจกรรมใดๆ'));
          }

          final activities = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(context, activity);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(
      BuildContext context, SustainableActivity activity) {
    final theme = Theme.of(context);
    final daysLeft = activity.endDate.difference(DateTime.now()).inDays;
    final daysLeftText = daysLeft >= 0 ? '$daysLeft วัน' : 'สิ้นสุดแล้ว';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                SustainableActivityDetailScreen(activity: activity),
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 200, // Corrected: Already correct
                  width: double.infinity,
                  child: Image.network(
                    activity.imageUrl, // Ensure imageUrl is not null
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.surfaceContainer,
                      child: Icon(
                          Icons
                              .image_not_supported, // Corrected: Already correct
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 50),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Chip(
                    avatar: Icon(Icons.location_on_outlined,
                        size: 16,
                        color: theme.colorScheme.onSecondaryContainer),
                    label: Text(activity.province,
                        style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer)),
                    backgroundColor:
                        theme.colorScheme.secondaryContainer.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoIconText(
                        context,
                        Icons.calendar_today_outlined,
                        '${DateFormat('dd MMM', 'th').format(activity.startDate)} - ${DateFormat('dd MMM', 'th').format(activity.endDate)}',
                      ),
                      _buildInfoIconText(
                        context,
                        Icons.timer_outlined,
                        'เหลือ $daysLeftText',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIconText(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
