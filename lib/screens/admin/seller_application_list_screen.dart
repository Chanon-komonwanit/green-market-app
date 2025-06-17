// lib/screens/admin/seller_application_list_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class SellerApplicationListScreen extends StatefulWidget {
  const SellerApplicationListScreen({super.key});

  @override
  State<SellerApplicationListScreen> createState() =>
      _SellerApplicationListScreenState();
}

class _SellerApplicationListScreenState
    extends State<SellerApplicationListScreen> {
  Future<void> _approveApplication(String userId) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      await firebaseService.approveSellerApplication(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('อนุมัติคำขอเป็นผู้ขายเรียบร้อยแล้ว'),
              backgroundColor: AppColors.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการอนุมัติ: ${e.toString()}'),
              backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Future<void> _rejectApplicationDialog(String userId) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    String? rejectionReason;

    final bool? confirmReject = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ปฏิเสธคำขอเป็นผู้ขาย'),
          content: TextField(
            onChanged: (value) {
              rejectionReason = value;
            },
            decoration: const InputDecoration(
              hintText: 'ระบุเหตุผลการปฏิเสธ (ไม่บังคับ)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
              child: const Text('ยืนยันการปฏิเสธ'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmReject == true) {
      try {
        await firebaseService.rejectSellerApplication(userId,
            reason: rejectionReason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ปฏิเสธคำขอเป็นผู้ขายเรียบร้อยแล้ว'),
                backgroundColor: AppColors.warningOrange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('เกิดข้อผิดพลาดในการปฏิเสธ: ${e.toString()}'),
                backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.getPendingSellerApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                  style: AppTextStyles.body));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('ไม่มีคำขอเปิดร้านที่รอการอนุมัติ',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.modernGrey)));
        }

        final applications = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final appData = applications[index];
            final userId = appData['uid'] as String? ?? 'N/A';
            final email = appData['email'] as String? ?? 'ไม่มีข้อมูลอีเมล';
            final timestamp =
                appData['sellerApplicationTimestamp'] as Timestamp?;
            final requestDate = timestamp != null
                ? DateFormat('dd MMM yyyy, HH:mm', 'th')
                    .format(timestamp.toDate())
                : 'ไม่มีข้อมูลวันที่';

            return Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
              elevation: 1.5,
              child: ListTile(
                title: Text(email,
                    style: AppTextStyles.subtitle
                        .copyWith(color: AppColors.primaryDarkGreen)),
                subtitle: Text('วันที่ส่งคำขอ: $requestDate\nUID: $userId',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.modernGrey)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline,
                          color: AppColors.primaryGreen),
                      onPressed: () => _approveApplication(userId),
                      tooltip: 'อนุมัติ',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.errorRed),
                      onPressed: () => _rejectApplicationDialog(userId),
                      tooltip: 'ปฏิเสธ',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
