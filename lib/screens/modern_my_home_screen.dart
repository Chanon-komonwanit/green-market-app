// lib/screens/modern_my_home_screen.dart
// 🏠 Modern My Home Screen - Shopee/TikTok/Lazada Style
// ออกแบบใหม่ทั้งหมดตามมาตรฐาน E-commerce ชั้นนำ

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart';
import 'cart_screen.dart';
import 'edit_profile_screen.dart';
import 'user/enhanced_edit_profile_screen.dart';
import 'orders_screen.dart';
import 'profile/my_coupons_screen.dart';
import 'customer_shipping_dashboard_screen.dart';
import 'seller/complete_modern_seller_dashboard.dart';
import 'seller/seller_application_form_screen.dart';
import 'eco_rewards_screen.dart';
import 'wishlist_screen.dart';

import '../providers/cart_provider_enhanced.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';

/// 🏠 Modern My Home Screen - E-commerce Style Profile Page
/// - Profile header with avatar, name, membership tier
/// - Quick stats (orders, wishlist, following)
/// - Menu grid (orders, wallet, vouchers, wishlist, etc.)
/// - Order tracking section
/// - Eco coins & rewards
class ModernMyHomeScreen extends StatefulWidget {
  const ModernMyHomeScreen({super.key});

  @override
  State<ModernMyHomeScreen> createState() => _ModernMyHomeScreenState();
}

class _ModernMyHomeScreenState extends State<ModernMyHomeScreen> {
  int _pendingOrdersCount = 0;
  int _wishlistCount = 0;
  int _notificationsCount = 0;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (_isLoadingStats) return;
    setState(() => _isLoadingStats = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingStats = false);
        return;
      }

      // Load pending orders count with limit
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'processing', 'shipped'])
          .limit(100)
          .get();

      // Load wishlist count with limit
      final wishlistSnapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('userId', isEqualTo: user.uid)
          .limit(100)
          .get();

      // Load notifications count with limit
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .limit(99)
          .get();

      if (mounted) {
        setState(() {
          _pendingOrdersCount = ordersSnapshot.docs.length;
          _wishlistCount = wishlistSnapshot.docs.length;
          _notificationsCount = notificationsSnapshot.docs.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูลได้ กรุณาลองใหม่'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Helper method สำหรับ card shadow
  List<BoxShadow> _defaultCardShadow() {
    return [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Profile Header (Shopee/TikTok Style)
          _buildProfileHeader(),

          // Quick Stats
          SliverToBoxAdapter(child: _buildQuickStats()),

          // Eco Coins Card
          SliverToBoxAdapter(child: _buildEcoCoinsCard()),

          // My Orders Section
          SliverToBoxAdapter(child: _buildMyOrdersSection()),

          // Menu Grid
          SliverToBoxAdapter(child: _buildMenuGrid()),

          // Seller Section (if applicable)
          SliverToBoxAdapter(child: _buildSellerSection()),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // === Profile Header (Shopee/TikTok Style) ===
  Widget _buildProfileHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final isLoggedIn = currentUser != null;

        return SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: const Color(0xFF059669),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      Tooltip(
                        message: 'แก้ไขโปรไฟล์',
                        child: InkWell(
                          onTap: () {
                            if (isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EnhancedEditProfileScreen(),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: currentUser?.photoUrl != null
                                  ? Image.network(
                                      currentUser!.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildDefaultAvatar(),
                                    )
                                  : _buildDefaultAvatar(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name & Membership
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoggedIn
                                  ? currentUser.displayName ?? 'ผู้ใช้'
                                  : 'เข้าสู่ระบบ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isLoggedIn) ...[
                              _buildMembershipBadge(currentUser),
                              const SizedBox(height: 4),
                              Text(
                                currentUser.email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Settings Button
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white, size: 28),
                        tooltip: 'ตั้งค่า',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            // Notifications Badge
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 28),
                  tooltip: 'การแจ้งเตือน',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _notificationsCount > 0
                              ? 'คุณมีการแจ้งเตือน $_notificationsCount รายการ'
                              : 'ไม่มีการแจ้งเตือนใหม่',
                        ),
                        action: _notificationsCount > 0
                            ? SnackBarAction(
                                label: 'ดู',
                                textColor: Colors.white,
                                onPressed: () {
                                  // Navigate to notifications screen when available
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
                if (_notificationsCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _notificationsCount > 99
                            ? '99+'
                            : _notificationsCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white,
      child: const Icon(Icons.person, size: 40, color: Color(0xFF059669)),
    );
  }

  Widget _buildMembershipBadge(currentUser) {
    final ecoCoins = currentUser.ecoCoins ?? 0;
    String tier = 'สมาชิกทั่วไป';
    Color tierColor = Colors.white70;

    if (ecoCoins >= 10000) {
      tier = '👑 Diamond';
      tierColor = const Color(0xFFB9F2FF);
    } else if (ecoCoins >= 5000) {
      tier = '🥇 Gold';
      tierColor = const Color(0xFFFFD700);
    } else if (ecoCoins >= 1000) {
      tier = '🥈 Silver';
      tierColor = const Color(0xFFC0C0C0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor, width: 1.5),
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: tierColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // === Quick Stats ===
  Widget _buildQuickStats() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _defaultCardShadow(),
          ),
          child: Row(
            children: [
              _buildStatItem(
                icon: Icons.shopping_bag_outlined,
                label: 'ออเดอร์',
                value: _pendingOrdersCount.toString(),
                color: const Color(0xFFFF6B6B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                ),
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.favorite_border,
                label: 'รายการโปรด',
                value: _wishlistCount.toString(),
                color: const Color(0xFFFF69B4),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WishlistScreen()),
                ),
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.eco_outlined,
                label: 'Eco Coins',
                value: currentUser?.ecoCoins.toInt().toString() ?? '0',
                color: const Color(0xFF059669),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EcoRewardsScreen()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Colors.grey[200],
    );
  }

  // === Eco Coins Card ===
  Widget _buildEcoCoinsCard() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final ecoCoins = currentUser?.ecoCoins ?? 0;
        final equivalentBaht = ecoCoins * 0.01;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EcoRewardsScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFFFFA500),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🪙 Eco Coins ของฉัน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ecoCoins.toInt()} เหรียญ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'มูลค่า ≈ ฿${equivalentBaht.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // === My Orders Section ===
  Widget _buildMyOrdersSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _defaultCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      color: Color(0xFF059669), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'คำสั่งซื้อของฉัน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrdersScreen()),
                  );
                },
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderStatusItem(
                icon: Icons.payment,
                label: 'รอชำระเงิน',
                count: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrdersScreen()),
                  );
                },
              ),
              _buildOrderStatusItem(
                icon: Icons.inventory_2_outlined,
                label: 'รอจัดส่ง',
                count: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrdersScreen()),
                  );
                },
              ),
              _buildOrderStatusItem(
                icon: Icons.local_shipping_outlined,
                label: 'กำลังจัดส่ง',
                count: _pendingOrdersCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrdersScreen()),
                  );
                },
              ),
              _buildOrderStatusItem(
                icon: Icons.rate_review_outlined,
                label: 'รีวิว',
                count: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrdersScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusItem({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF059669), size: 28),
              ),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // === Menu Grid (Shopee/Lazada Style) ===
  Widget _buildMenuGrid() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _defaultCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.apps, color: Color(0xFF059669), size: 24),
              SizedBox(width: 8),
              Text(
                'เครื่องมือ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              _buildMenuItem(
                icon: Icons.favorite_border,
                label: 'รายการโปรด',
                color: const Color(0xFFFF69B4),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WishlistScreen()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.discount_outlined,
                label: 'คูปอง',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyCouponsScreen()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.local_shipping_outlined,
                label: 'การจัดส่ง',
                color: const Color(0xFF0891B2),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const CustomerShippingDashboardScreen()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.chat_bubble_outline,
                label: 'แชท',
                color: const Color(0xFF059669),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณาเลือกสินค้าเพื่อเริ่มแชทกับผู้ขาย'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.shopping_cart_outlined,
                label: 'ตะกร้า',
                color: const Color(0xFFFF6B6B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.eco_outlined,
                label: 'Eco Rewards',
                color: const Color(0xFF059669),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EcoRewardsScreen()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'กระเป๋าเงิน',
                color: const Color(0xFFFFA500),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ฟีเจอร์กระเป๋าเงินกำลังพัฒนา'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                label: 'ตั้งค่า',
                color: const Color(0xFF6B7280),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // === Seller Section ===
  Widget _buildSellerSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final isSeller = currentUser?.isSeller ?? false;

        if (!isSeller) {
          // Show "Become Seller" card
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SellerApplicationFormScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: Color(0xFF059669),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎯 เปิดร้านค้ากับเรา',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'สมัครเป็นผู้ขายและเริ่มต้นธุรกิจของคุณ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Show Seller Dashboard Button
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CompleteModernSellerDashboard(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard,
                        color: Color(0xFF7C3AED),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 แดชบอร์ดผู้ขาย',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'จัดการร้านค้า สินค้า และคำสั่งซื้อ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
