// d:/Development/green_market/lib/screens/admin/admin_user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/services/firebase_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  bool? _filterIsAdmin;
  bool? _filterIsSeller;
  bool? _filterIsSuspended;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  List<AppUser> _filterUsers(List<AppUser> allUsers) {
    return allUsers.where((user) {
      final String displayName = user.displayName ?? user.email;
      final String email = user.email;
      final String uid = user.id;

      final bool searchMatch = _searchQuery.isEmpty ||
          displayName.toLowerCase().contains(_searchQuery) ||
          email.toLowerCase().contains(_searchQuery) ||
          uid.toLowerCase().contains(_searchQuery);

      final bool isAdmin = user.isAdmin;
      final bool isSeller = user.isSeller;
      final bool isSuspended = user.isSuspended;

      final bool adminFilterMatch =
          _filterIsAdmin == null || _filterIsAdmin == isAdmin;
      final bool sellerFilterMatch =
          _filterIsSeller == null || _filterIsSeller == isSeller;
      final bool suspendedFilterMatch =
          _filterIsSuspended == null || _filterIsSuspended == isSuspended;

      return searchMatch &&
          adminFilterMatch &&
          sellerFilterMatch &&
          suspendedFilterMatch;
    }).toList();
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('แอดมิน'),
            selected: _filterIsAdmin == true,
            onSelected: (selected) {
              setState(() {
                _filterIsAdmin = selected ? true : null;
              });
            },
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('ผู้ขาย'),
            selected: _filterIsSeller == true,
            onSelected: (selected) {
              setState(() {
                _filterIsSeller = selected ? true : null;
              });
            },
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('ระงับ'),
            selected: _filterIsSuspended == true,
            onSelected: (selected) {
              setState(() {
                _filterIsSuspended = selected ? true : null;
              });
            },
            selectedColor: theme.colorScheme.errorContainer,
            checkmarkColor: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          if (_filterIsAdmin != null ||
              _filterIsSeller != null ||
              _filterIsSuspended != null)
            ActionChip(
              label: const Text('ล้างตัวกรอง'),
              onPressed: () {
                setState(() {
                  _filterIsAdmin = null;
                  _filterIsSeller = null;
                  _filterIsSuspended = null;
                });
              },
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              labelStyle: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              avatar: Icon(Icons.clear,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการผู้ใช้',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาผู้ใช้ (ชื่อ, อีเมล, UID)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          _buildFilterChips(context),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: firebaseService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('ไม่พบผู้ใช้ในระบบ'));
                }

                final users =
                    _filterUsers(snapshot.data!); // Apply filters here

                if (users.isEmpty) {
                  return const Center(
                      child: Text('ไม่พบผู้ใช้ที่ตรงกับตัวกรอง/การค้นหา'));
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(8.0), // Corrected: Already correct
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final bool isSuspended = user.isSuspended;
                    final bool isAdmin = user.isAdmin;
                    final bool isSeller = user.isSeller;
                    final String userEmail = user.email;
                    final String displayName = user.displayName ?? userEmail;
                    final String uid = user.id;
                    final DateTime createdAt = user.createdAt.toDate();

                    final bool isPrimaryAdmin =
                        userEmail.toLowerCase() == kAdminEmail.toLowerCase();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSuspended
                              ? Colors.red.shade100
                              : theme.colorScheme.primary
                                  .withAlpha((0.1 * 255).round()),
                          child: Icon(
                            isSuspended
                                ? Icons.person_off_outlined
                                : Icons.person,
                            color: isSuspended
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSuspended ? Colors.red : null)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userEmail, style: theme.textTheme.bodySmall),
                            Text('UID: ${uid.substring(0, 8)}...',
                                style: theme.textTheme
                                    .bodySmall), // Corrected: Already correct
                            Text(
                                'เข้าร่วม: ${DateFormat('dd MMM yyyy').format(createdAt)}',
                                style: theme.textTheme.bodySmall),
                            Wrap(
                              spacing: 6.0,
                              children: [
                                if (isAdmin)
                                  Chip(
                                      label: const Text('แอดมิน'),
                                      backgroundColor: Colors.blue.shade100),
                                if (isSeller)
                                  Chip(
                                      label: const Text('ผู้ขาย'),
                                      backgroundColor: Colors.green.shade100),
                                if (isSuspended)
                                  Chip(
                                      label: const Text('ระงับ'),
                                      backgroundColor: Colors.red.shade100),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleUserAction(context,
                              firebaseService, user, value, isPrimaryAdmin),
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'toggle_suspend',
                              enabled: !isPrimaryAdmin,
                              child: Text(
                                  isSuspended ? 'ยกเลิกระงับ' : 'ระงับผู้ใช้'),
                            ),
                            PopupMenuItem<String>(
                              value: 'toggle_admin',
                              enabled: !isPrimaryAdmin,
                              child: Text(isAdmin
                                  ? 'ลบสิทธิ์แอดมิน'
                                  : 'ให้สิทธิ์แอดมิน'),
                            ),
                            PopupMenuItem<String>(
                              value: 'toggle_seller',
                              enabled: !isPrimaryAdmin,
                              child: Text(isSeller
                                  ? 'ลบสิทธิ์ผู้ขาย'
                                  : 'ให้สิทธิ์ผู้ขาย'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(BuildContext context, FirebaseService firebaseService,
      AppUser user, String action, bool isPrimaryAdmin) async {
    final String uid = user.id;
    try {
      if (isPrimaryAdmin) {
        showAppSnackBar(context, 'ไม่สามารถแก้ไขบัญชีแอดมินหลักได้',
            isError: true);
        return;
      }

      switch (action) {
        case 'toggle_suspend':
          final bool currentStatus = user.isSuspended;
          await firebaseService.updateUserRolesAndStatus(
              userId: uid,
              isSuspended: !currentStatus,
              rejectionReason: currentStatus ? null : 'ระงับโดยแอดมิน');
          showAppSnackBar(context,
              '${currentStatus ? 'ยกเลิกระงับ' : 'ระงับ'}ผู้ใช้ ${user.displayName ?? user.email} สำเร็จ',
              isSuccess: true);
          break;
        case 'toggle_admin':
          final bool currentStatus = user.isAdmin;
          await firebaseService.updateUserRolesAndStatus(
              userId: uid, isAdmin: !currentStatus);
          showAppSnackBar(context,
              '${currentStatus ? 'ลบสิทธิ์แอดมิน' : 'ให้สิทธิ์แอดมิน'}แก่ ${user.displayName ?? user.email} สำเร็จ',
              isSuccess: true);
          break;
        case 'toggle_seller':
          final bool currentStatus = user.isSeller;
          await firebaseService.updateUserRolesAndStatus(
              userId: uid, isSeller: !currentStatus);
          showAppSnackBar(context,
              '${currentStatus ? 'ลบสิทธิ์ผู้ขาย' : 'ให้สิทธิ์ผู้ขาย'}แก่ ${user.displayName ?? user.email} สำเร็จ',
              isSuccess: true);
          break;
      }
    } catch (e) {
      firebaseService.logger.e('Error performing user action: $e');
      showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
          isError: true);
    }
  }
}
