// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/providers/theme_provider.dart';
import 'package:green_market/screens/admin/admin_dashboard_screen.dart';
import 'package:green_market/screens/seller/complete_modern_seller_dashboard.dart';
import 'package:green_market/screens/user/become_seller_screen.dart';
import 'package:green_market/screens/user/enhanced_edit_profile_screen.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changeProfilePicture(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

    try {
      final XFile? image =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        await userProvider.updateUserProfilePicture(image);
        if (context.mounted) {
          showAppSnackBar(context, 'Profile picture updated successfully!',
              isSuccess: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
            context, 'Failed to update profile picture: ${e.toString()}',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (userProvider.isLoading && currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentUser == null) {
      return const Center(child: Text('User not found. Please log in again.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('โปรไฟล์'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // รูปโปรไฟล์
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: currentUser.photoUrl != null
                        ? NetworkImage(currentUser.photoUrl!)
                        : null,
                    child: currentUser.photoUrl == null
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  InkWell(
                    onTap: () => _changeProfilePicture(context),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child:
                          Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              currentUser.displayName ?? 'N/A',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            Text(
              currentUser.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            const SizedBox(height: 32),
            // --- Menu Options ---
            _buildProfileMenu(context, userProvider, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context, UserProvider userProvider,
      AuthProvider authProvider) {
    final currentUser = userProvider.currentUser!;

    return Column(
      children: [
        _buildMenuTile(
          context: context,
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const EnhancedEditProfileScreen(),
            ));
          },
        ),
        if (currentUser.isAdmin)
          _buildMenuTile(
            context: context,
            icon: Icons.admin_panel_settings_outlined,
            title: 'แผงควบคุมแอดมิน',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminDashboardScreen(),
              ));
            },
          )
        else if (currentUser.isSeller)
          _buildMenuTile(
            context: context,
            icon: Icons.store_outlined,
            title: 'แดชบอร์ดร้านค้า (Complete Modern)',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CompleteModernSellerDashboard(),
              ));
            },
          ),

        _buildMenuTile(
          context: context,
          icon: Icons.history_outlined,
          title: 'ประวัติการสั่งซื้อ',
          onTap: () {
            showAppSnackBar(context, 'ฟีเจอร์ประวัติการสั่งซื้อจะมาเร็วๆ นี้!');
          },
        ),

        // เมนูสำหรับสมัครเป็นผู้ขาย (ใช้ getter ใหม่จาก UserProvider)
        if (userProvider.canApplyToBecomeSeller)
          _buildMenuTile(
            context: context,
            icon: Icons.storefront_outlined,
            title: 'สมัครเป็นผู้ขาย',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const BecomeSellerScreen(),
              ));
            },
          ),
        if (userProvider.isSellerApplicationPending)
          _buildMenuTile(
            context: context,
            icon: Icons.hourglass_top_outlined,
            title: 'รอการอนุมัติเป็นผู้ขาย',
            subtitle: 'กำลังรอการพิจารณาจากแอดมิน',
            onTap: () {},
            trailing: Icon(Icons.schedule,
                color: Theme.of(context).colorScheme.secondary),
          ),
        if (userProvider.isSellerApplicationRejected)
          _buildMenuTile(
            context: context,
            icon: Icons.cancel_outlined,
            title: 'คำขอเป็นผู้ขายถูกปฏิเสธ',
            subtitle: currentUser.rejectionReason ?? 'ไม่ได้ระบุเหตุผล',
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              // สามารถสมัครใหม่ได้
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const BecomeSellerScreen(),
              ));
            },
          ),
        const Divider(height: 32),
        _buildMenuTile(
          context: context,
          icon: Icons.logout,
          title: 'ออกจากระบบ',
          color: Theme.of(context).colorScheme.error,
          onTap: () async {
            final bool? confirmLogout = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    'ยืนยันการออกจากระบบ',
                    style: AppTextStyles.subtitle.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  content: Text(
                    'คุณต้องการออกจากระบบหรือไม่?',
                    style: AppTextStyles.body,
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text(
                        'ยกเลิก',
                        style: AppTextStyles.body.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: Text(
                        'ออกจากระบบ',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                );
              },
            );
            if (confirmLogout == true) {
              await authProvider.signOut();
            }
          },
        ),

        // Theme Toggle
      ],
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    String? subtitle,
    Widget? trailing,
  }) {
    final Widget trailingWidget =
        trailing ?? const Icon(Icons.arrow_forward_ios, size: 16);
    return ListTile(
      leading:
          Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(title,
          style: AppTextStyles.body.copyWith(
              color: color ?? Theme.of(context).colorScheme.onBackground)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: AppTextStyles.body.copyWith(
                  color: Theme.of(context).colorScheme.outline, fontSize: 12))
          : null,
      trailing: trailingWidget,
      onTap: onTap,
    );
  }
}
