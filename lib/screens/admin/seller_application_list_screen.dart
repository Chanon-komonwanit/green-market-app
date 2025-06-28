// lib/screens/admin/seller_application_list_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminSellerApplicationScreen extends StatelessWidget {
  const AdminSellerApplicationScreen({super.key});

  void _approveApplication(
      BuildContext context, FirebaseService firebaseService, String uid) async {
    try {
      await firebaseService.approveSellerApplication(uid);
      showAppSnackBar(context, 'อนุมัติคำขอผู้ขายสำเร็จ', isSuccess: true);
    } catch (e) {
      showAppSnackBar(context, 'เกิดข้อผิดพลาดในการอนุมัติ: ${e.toString()}',
          isError: true);
    }
  }

  void _rejectApplication(
      BuildContext context, FirebaseService firebaseService, String uid) async {
    TextEditingController reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ปฏิเสธคำขอผู้ขาย'),
          content: TextField(
            controller: reasonController,
            decoration:
                const InputDecoration(labelText: 'เหตุผลในการปฏิเสธ (ถ้ามี)'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await firebaseService.rejectSellerApplication(
                    uid,
                    reasonController.text.trim(),
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  showAppSnackBar(context, 'ปฏิเสธคำขอผู้ขายสำเร็จ',
                      isSuccess: true);
                } catch (e) {
                  showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
                      isError: true);
                }
              },
              child: const Text('ปฏิเสธ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('คำขอเป็นผู้ขาย',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: firebaseService.getPendingSellerApplicationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('ไม่มีคำขอเป็นผู้ขายที่รอการอนุมัติ'));
          }

          final applications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final String uid = application.id;
              final String email = application.email;
              final String displayName = application.displayName ?? email;
              final DateTime? timestamp =
                  application.sellerApplicationTimestamp?.toDate();

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person_add_alt_1,
                        color: theme.colorScheme.primary),
                  ),
                  title: Text(displayName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('อีเมล: $email'),
                      Text('UID: ${uid.substring(0, 8)}...'),
                      if (timestamp != null)
                        Text(
                            'ส่งคำขอเมื่อ: ${DateFormat('dd MMM yyyy HH:mm').format(timestamp)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        onPressed: () =>
                            _approveApplication(context, firebaseService, uid),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.red),
                        onPressed: () =>
                            _rejectApplication(context, firebaseService, uid),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
