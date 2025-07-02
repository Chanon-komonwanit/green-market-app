// lib/screens/sustainable_activity/my_organized_activities_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/sustainable_activity.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/screens/sustainable_activity/sustainable_activity_detail_screen.dart';
import 'package:green_market/screens/sustainable_activity/submit_sustainable_activity_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyOrganizedActivitiesScreen extends StatelessWidget {
  const MyOrganizedActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    final organizerId = userProvider
        .currentUser?.id; // Corrected: Use currentUser and correct property

    if (organizerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'กิจกรรมที่ฉันจัด',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบเพื่อดูกิจกรรมที่คุณจัด'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'กิจกรรมที่ฉันจัด',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: StreamBuilder<List<SustainableActivity>>(
        stream: firebaseService.getActivitiesByOrganizer(organizerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('คุณยังไม่ได้จัดกิจกรรมใดๆ'));
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

  Color _getSubmissionStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getSubmissionStatusDisplay(String status) {
    switch (status) {
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'pending':
        return 'รอดำเนินการ';
      case 'rejected':
        return 'ถูกปฏิเสธ';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Widget _buildActivityCard(
    BuildContext context,
    SustainableActivity activity,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          // Ensure imageUrl is not null
          // Use a placeholder if imageUrl is null or empty
          backgroundImage: NetworkImage(activity.imageUrl),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          // Ensure imageUrl is not null
          // Use a placeholder if imageUrl is null or empty
          child: activity.imageUrl.isNotEmpty
              ? null
              : const Icon(Icons.eco_outlined, color: Colors.white),
        ),
        title: Text(
          activity.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('จังหวัด: ${activity.province}'),
            Text(
              'เริ่ม: ${DateFormat('dd MMM yyyy').format(activity.startDate)}',
            ),
            Text(
              'สิ้นสุด: ${DateFormat('dd MMM yyyy').format(activity.endDate)}',
            ),
            Text(
              'สถานะ: ${_getSubmissionStatusDisplay(activity.submissionStatus)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getSubmissionStatusColor(activity.submissionStatus),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (activity.rejectionReason != null &&
                activity.rejectionReason!.isNotEmpty)
              Text(
                'เหตุผลการปฏิเสธ: ${activity.rejectionReason}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (activity.submissionStatus == 'pending' ||
                activity.submissionStatus == 'rejected')
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          SubmitSustainableActivityScreen(activity: activity),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        SustainableActivityDetailScreen(activity: activity),
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  SustainableActivityDetailScreen(activity: activity),
            ),
          );
        },
      ),
    );
  }
}
