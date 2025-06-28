// lib/screens/admin/admin_activity_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/activity_review.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/sustainable_activity.dart'; // Ensure this import is present
import 'package:green_market/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActivityReviewsScreen extends StatelessWidget {
  const AdminActivityReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการรีวิวกิจกรรม',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firebaseService.getAllActivityReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีรีวิวกิจกรรมในระบบ'));
          }

          final reviews = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.star, color: theme.colorScheme.primary),
                  ),
                  title: Text(review['userName'] ?? 'ไม่ระบุผู้ใช้',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: FutureBuilder<Map<String, dynamic>?>(
                    // Ensure activityTitle is not null
                    future: firebaseService.getSustainableActivityByIdAsMap(
                        review['activityId'] ?? ''),
                    builder: (context, activitySnapshot) {
                      String activityTitle = 'กำลังโหลด...';
                      if (activitySnapshot.connectionState ==
                              ConnectionState.done &&
                          activitySnapshot.hasData) {
                        activityTitle =
                            activitySnapshot.data!['title'] ?? 'ไม่ระบุ';
                      } else if (activitySnapshot.hasError) {
                        activityTitle = 'ไม่พบกิจกรรม';
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('กิจกรรม: $activityTitle'),
                          Row(
                            children: List.generate(
                                5,
                                (i) => Icon(
                                      i < (review['rating'] ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    )),
                          ),
                          Text(review['comment'] ?? '',
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(
                              'เมื่อ: ${review['createdAt'] != null ? DateFormat('dd MMM yyyy HH:mm').format((review['createdAt'] as Timestamp).toDate()) : 'ไม่ระบุ'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      );
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outlined, color: Colors.red),
                    onPressed: () => _deleteReview(
                        context, firebaseService, review['id'] ?? ''),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteReview(BuildContext context, FirebaseService firebaseService,
      String reviewId) async {
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('ยืนยันการลบรีวิว'),
            content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรีวิวนี้?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('ยกเลิก')),
              ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('ลบ')),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await firebaseService.deleteActivityReview(reviewId);
        showAppSnackBar(context, 'ลบรีวิวสำเร็จ', isSuccess: true);
      } catch (e) {
        showAppSnackBar(context, 'เกิดข้อผิดพลาดในการลบ: ${e.toString()}',
            isError: true);
      }
    }
  }
}
