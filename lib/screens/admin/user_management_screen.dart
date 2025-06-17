// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // TODO: Implement functions for editing roles, suspending users, etc.
  void _editUserRole(String userId, String currentRole) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'TODO: Implement edit role for $userId (current: $currentRole)')),
    );
  }

  void _suspendUser(String userId, bool isCurrentlySuspended) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('TODO: Implement suspend/unsuspend user $userId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.getAllUsers(),
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
              child: Text('ไม่พบข้อมูลผู้ใช้ในระบบ',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.modernGrey)));
        }

        final users = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index];
            final userId = userData['uid'] as String? ?? 'N/A';
            final email = userData['email'] as String? ?? 'ไม่มีอีเมล';
            final displayName =
                userData['displayName'] as String? ?? 'ไม่มีชื่อแสดง';
            final bool isAdmin = userData['isAdmin'] as bool? ?? false;
            final bool isSeller = userData['isSeller'] as bool? ?? false;
            final String sellerStatus =
                userData['sellerApplicationStatus'] as String? ?? 'none';
            final Timestamp? createdAtTimestamp =
                userData['createdAt'] as Timestamp?;
            final String createdAt = createdAtTimestamp != null
                ? DateFormat('dd MMM yyyy', 'th')
                    .format(createdAtTimestamp.toDate())
                : 'ไม่ระบุ';

            String role = 'ผู้ซื้อ';
            if (isAdmin) {
              role = 'แอดมิน';
            } else if (isSeller) {
              role = 'ผู้ขาย ($sellerStatus)';
            }

            return Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
              elevation: 1.5,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin
                      ? AppColors.primaryTeal
                      : (isSeller
                          ? AppColors.accentGreen
                          : AppColors.lightModernGrey),
                  foregroundColor: AppColors.white,
                  child: Icon(isAdmin
                      ? Icons.admin_panel_settings_outlined
                      : (isSeller
                          ? Icons.store_outlined
                          : Icons.person_outline)),
                ),
                title: Text(displayName,
                    style: AppTextStyles.subtitle
                        .copyWith(color: AppColors.primaryDarkGreen)),
                subtitle: Text(
                  'Email: $email\nRole: $role\nสมัครเมื่อ: $createdAt',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.modernGrey),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit_role') {
                      _editUserRole(userId, role);
                    } else if (value == 'suspend') {
                      // TODO: Check current suspension status to pass to _suspendUser
                      _suspendUser(userId, false);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit_role',
                      child: Text('แก้ไข Role/สถานะ'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'suspend',
                      child: Text('ระงับ/ยกเลิกระงับผู้ใช้'),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.modernDarkGrey),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
