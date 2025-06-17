// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/screens/auth/login_screen.dart';
import 'package:green_market/providers/user_provider.dart'; // Import UserProvider
import 'package:green_market/screens/admin_panel_screen.dart';
import 'package:green_market/screens/seller/seller_dashboard_screen.dart';
import 'package:green_market/screens/user/become_seller_screen.dart';
import 'package:green_market/screens/sustainable_investment_screen.dart'; // Import investment screen
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Assuming UserProfileScreen is for editing, if not, remove or adjust.
// If this screen (profile_screen.dart) IS the user's own profile editing screen,
// then the navigation to UserProfileScreen in _buildGeneralOptions might be redundant
// or should be to a more specific "Edit Details" screen.
// For now, I'll assume UserProfileScreen is a separate editing screen.
import 'package:green_market/screens/user_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // User data is now primarily managed by UserProvider,
    // which is listened to by AuthWrapper.
    // If specific refresh logic is needed here, it can be added.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Example: Force a refresh if needed, though UserProvider should handle this.
      // Provider.of<UserProvider>(context, listen: false).refreshUserData();
    });
  }

  Future<void> _fetchUserData() async {
    // This method can be used for manual refresh via RefreshIndicator
    // It will re-trigger UserProvider's loading logic if necessary.
    await Provider.of<UserProvider>(context, listen: false).refreshUserData();
  }

  void _navigateToBecomeSellerScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BecomeSellerScreen()),
    ).then((_) =>
        _fetchUserData()); // Refresh data after returning, UserProvider will update
  }

  void _navigateToSellerDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellerDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser; // Get user from UserProvider

    if (userProvider.isLoading && userProvider.userData == null) {
      // Show loading if UserProvider is loading and has no data yet
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal));
    }
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('กรุณาเข้าสู่ระบบ'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false);
              },
              child: const Text('ไปหน้าเข้าสู่ระบบ'),
            )
          ],
        ),
      );
    }

    // Use data from UserProvider
    final bool isSeller = userProvider.userData?['isSeller'] == true;
    final bool isAdmin = userProvider.isAdmin; // Use getter from UserProvider
    final String? currentDisplayName =
        userProvider.userData?['displayName'] ?? user.email;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: AppColors.primaryTeal,
        child: ListView(
          children: <Widget>[
            _buildProfileHeader(
                user, currentDisplayName), // Use currentDisplayName
            _buildInvestmentSection(
                context), // New dedicated section for investment
            const SizedBox(height: 16), // Spacing before role-specific actions
            _buildRoleSpecificActions(
                isAdmin, isSeller), // Role-specific actions
            const Divider(height: 30, thickness: 1),
            _buildGeneralOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user, String? displayName) {
    return Padding(
      // Added Padding for better spacing
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            // ignore: deprecated_member_use
            backgroundColor: AppColors.lightTeal.withOpacity(0.5),
            child: Icon(Icons.person, size: 50, color: AppColors.primaryTeal),
            // TODO: Add user profile image if available
          ),
          const SizedBox(height: 16),
          Text('สวัสดี, ${displayName ?? user.email ?? 'ผู้ใช้งาน'}!',
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.primaryDarkGreen)),
          Text(user.email ?? '',
              style: AppTextStyles.body.copyWith(color: AppColors.modernGrey)),
        ],
      ),
    );
  }

  Widget _buildInvestmentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const SustainableInvestmentScreen(),
          ));
        },
        borderRadius: BorderRadius.circular(12), // For splash effect
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                // ignore: deprecated_member_use
                AppColors.primaryGreen.withOpacity(0.8),
                // ignore: deprecated_member_use
                AppColors.primaryTeal.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppColors.primaryTeal.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: AppColors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การลงทุนความยั่งยืน',
                      style: AppTextStyles.subtitleBold
                          .copyWith(color: AppColors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'สร้างผลตอบแทนพร้อมสร้างโลกที่ดีกว่า',
                      style: AppTextStyles.bodySmall
                          // ignore: deprecated_member_use
                          .copyWith(color: AppColors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificActions(bool isAdmin, bool isSeller) {
    return Column(
      children: <Widget>[
        if (isAdmin)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined,
                color: AppColors.primaryTeal),
            title: Text('แผงควบคุมผู้ดูแลระบบ', style: AppTextStyles.bodyBold),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen()));
            },
          ),
        if (isAdmin && isSeller) const Divider(),
        if (isSeller)
          ListTile(
            leading: const Icon(Icons.storefront, color: AppColors.primaryTeal),
            title: Text('จัดการร้านค้าของฉัน', style: AppTextStyles.bodyBold),
            onTap: _navigateToSellerDashboard,
          )
        else if (!isAdmin) // Show "Become Seller" only if not admin and not already a seller
          ListTile(
            leading: const Icon(Icons.add_business_outlined,
                color: AppColors.primaryTeal),
            title: Text('ร่วมเป็นผู้ขายกับเรา', style: AppTextStyles.bodyBold),
            onTap: _navigateToBecomeSellerScreen,
          ),
      ],
    );
  }

  Widget _buildGeneralOptions(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading:
              const Icon(Icons.edit_outlined, color: AppColors.primaryTeal),
          title: Text('แก้ไขโปรไฟล์', style: AppTextStyles.bodyBold),
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ))
                .then((_) => _fetchUserData());
          },
        ),
        // Add other general options here if needed
      ],
    );
  }
}
