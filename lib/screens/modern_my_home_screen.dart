// lib/screens/modern_my_home_screen.dart
import 'package:flutter/material.dart';
import 'my_home_screen_notification_tab.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/chat_screen.dart';
import 'package:green_market/screens/cart_screen.dart';
import 'package:green_market/screens/edit_profile_screen.dart';
import 'package:green_market/screens/user/enhanced_edit_profile_screen.dart';
import 'package:green_market/widgets/eco_coins_widget.dart';
import 'package:green_market/widgets/modern_home_header.dart';
import 'package:green_market/widgets/modern_card.dart';
import 'package:green_market/widgets/modern_button.dart';
import 'package:green_market/screens/notifications_center_screen.dart';
import 'package:green_market/providers/cart_provider_enhanced.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/services/order_service.dart';
import 'package:green_market/models/order.dart' as order_model;
import 'package:green_market/models/product.dart';
import 'package:green_market/models/cart_item.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/screens/orders_screen.dart';
import 'package:green_market/screens/customer_shipping_dashboard_screen.dart';
import 'package:green_market/screens/seller/seller_dashboard_screen.dart';
import 'package:green_market/screens/seller/seller_application_form_screen.dart';
import 'package:green_market/widgets/smart_eco_hero_tab.dart';
import 'package:green_market/screens/eco_rewards_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/theme/app_colors.dart' as colors;

class ModernMyHomeScreen extends StatefulWidget {
  const ModernMyHomeScreen({super.key});

  @override
  State<ModernMyHomeScreen> createState() => _ModernMyHomeScreenState();
}

class _ModernMyHomeScreenState extends State<ModernMyHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // ลดเหลือ 2 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // สร้าง Header สไตล์ Clean & Modern (Instagram inspired)
  Widget _buildModernHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        return Container(
          decoration: BoxDecoration(
            color: colors.AppColors.white, // Clean white background
            boxShadow: [
              BoxShadow(
                color: colors.AppColors.grayMedium.withOpacity(0.08),
                blurRadius: 1,
                offset: const Offset(0, 1), // Very subtle shadow
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // แถวบน: อวตาร + ข้อมูลผู้ใช้ + การแจ้งเตือน
                  Row(
                    children: [
                      // Avatar และข้อมูลผู้ใช้
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EnhancedEditProfileScreen(),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.AppColors.grayMediumLight,
                                    width: 1,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 24, // Smaller avatar
                                  backgroundColor:
                                      colors.AppColors.grayLightest,
                                  backgroundImage: currentUser?.photoUrl != null
                                      ? NetworkImage(currentUser!.photoUrl!)
                                      : null,
                                  child: currentUser?.photoUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: 24,
                                          color: colors.AppColors.grayMedium,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'สวัสดี, ${currentUser?.displayName ?? 'ผู้ใช้'}!',
                                    style: TextStyle(
                                      color: colors.AppColors.grayDarkest,
                                      fontSize: 16, // Smaller, cleaner
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.eco,
                                        color: colors.AppColors.primary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${currentUser?.ecoCoins.floor() ?? 0} เหรียญ',
                                        style: TextStyle(
                                          color: colors.AppColors.grayDark,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (currentUser?.isAdmin == true ||
                                          currentUser?.isSeller == true) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'VIP',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ปุ่มแจ้งเตือนและตะกร้า (Clean Instagram style)
                      Row(
                        children: [
                          _buildHeaderIconButton(
                            icon: Icons
                                .notifications_none, // Clean notification icon
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsCenterScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(width: 8),
                          Consumer<CartProviderEnhanced>(
                            builder: (context, cartProvider, child) {
                              return _buildHeaderIconButton(
                                icon: Icons.shopping_cart_outlined,
                                badgeCount: cartProvider.itemCount,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CartScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // แถว Quick Actions สไตล์ Shopee
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.shopping_bag_outlined,
                          label: 'ออเดอร์ของฉัน',
                          color: const Color(0xFF4CAF50),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const OrdersScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.monetization_on,
                          label: 'Eco Coins',
                          color: const Color(0xFFFFD700),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const EcoRewardsScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.local_shipping_outlined,
                          label: 'ติดตามพัสดุ',
                          color: const Color(0xFF2196F3),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CustomerShippingDashboardScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick Shopping Actions
                  _buildShoppingActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, // Smaller like Instagram
        height: 40,
        decoration: BoxDecoration(
          color: colors.AppColors.white, // Clean white background
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.AppColors.grayMediumLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.AppColors.grayMedium.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: colors.AppColors.grayDarkest, // Dark icon on white
                size: 20, // Smaller icon
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colors.AppColors.error, // Use theme error color
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$badgeCount',
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
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16), // More padding
        decoration: BoxDecoration(
          color: colors.AppColors.white, // Pure white
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.AppColors.grayMediumLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.AppColors.grayMedium.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Bigger icon container
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Subtle color background
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22), // Bigger icon
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.AppColors.grayDarkest, // Dark text on white
                fontSize: 12, // Slightly bigger
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Allow 2 lines
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // สร้าง Shopping Actions สำหรับการซื้อขายจริง
  Widget _buildShoppingActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.AppColors.grayMediumLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.AppColors.grayMedium.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'การซื้อขายของฉัน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.AppColors.grayDarkest,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildShoppingActionCard(
                  icon: Icons.add_business,
                  label: 'ขายสินค้า',
                  color: colors.AppColors.primary,
                  onTap: () =>
                      Navigator.pushNamed(context, '/seller-dashboard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShoppingActionCard(
                  icon: Icons.search,
                  label: 'ค้นหาสินค้า',
                  color: colors.AppColors.secondary,
                  onTap: () => Navigator.pushNamed(context, '/search'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShoppingActionCard(
                  icon: Icons.favorite_outline,
                  label: 'รายการโปรด',
                  color: colors.AppColors.error,
                  onTap: () => Navigator.pushNamed(context, '/wishlist'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShoppingActionCard(
                  icon: Icons.history,
                  label: 'ซื้อซ้ำ',
                  color: const Color(0xFF9C27B0),
                  onTap: () => Navigator.pushNamed(context, '/reorder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.AppColors.grayDarkest,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colors.AppColors.grayMedium,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // สร้าง Category Grid สไตล์ Amazon/Lazada
  // สร้าง Recent Orders Section
  Widget _buildRecentOrders() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.AppColors.grayMediumLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.AppColors.grayMedium.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'คำสั่งซื้อล่าสุด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.AppColors.grayDarkest,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                ),
                child: Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    color: colors.AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Recent orders will be loaded from Firebase here
          StreamBuilder<List<order_model.Order>>(
            stream: OrderService()
                .getUserOrders(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: colors.AppColors.grayMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ยังไม่มีคำสั่งซื้อ',
                        style: TextStyle(
                          color: colors.AppColors.grayMedium,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.AppColors.primary,
                          foregroundColor: colors.AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('เริ่มช้อปปิ้ง'),
                      ),
                    ],
                  ),
                );
              }

              // แสดงเฉพาะ 3 คำสั่งซื้อล่าสุด
              final recentOrders = snapshot.data!.take(3).toList();

              return Column(
                children: recentOrders
                    .map((order) => _buildOrderItem(order))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(order_model.Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.AppColors.grayLightest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.AppColors.grayMediumLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              color: colors.AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'คำสั่งซื้อ #${order.id.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.AppColors.grayDarkest,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '฿${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colors.AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getOrderStatusColor(order.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getOrderStatusText(order.status),
              style: TextStyle(
                color: _getOrderStatusColor(order.status),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'confirmed':
        return colors.AppColors.primary;
      case 'shipped':
        return colors.AppColors.secondary;
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return colors.AppColors.error;
      default:
        return colors.AppColors.grayMedium;
    }
  }

  String _getOrderStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'confirmed':
        return 'ยืนยันแล้ว';
      case 'shipped':
        return 'จัดส่งแล้ว';
      case 'delivered':
        return 'ส่งแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  // สร้าง Banner สไตล์ Shopee
  Widget _buildPromotionalBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/home'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.AppColors.primary, colors.AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.AppColors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.AppColors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🛍️ เริ่มช้อปปิ้ง',
                    style: TextStyle(
                      color: colors.AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ค้นพบสินค้าเพื่อสิ่งแวดล้อม',
                    style: TextStyle(
                      color: colors.AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ไปเลย',
                      style: TextStyle(
                        color: colors.AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header สไตล์ใหม่
          _buildModernHeader(),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: colors.AppColors.primary, // ใช้สีใหม่
              unselectedLabelColor: colors.AppColors.grayMedium,
              indicatorColor: colors.AppColors.primary,
              indicatorWeight: 2, // บางลง
              tabs: const [
                Tab(
                  icon: Icon(Icons.home_outlined, size: 20), // Outlined icon
                  text: 'หน้าหลัก',
                ),
                Tab(
                  icon: Icon(Icons.notifications_outlined, size: 20),
                  text: 'แจ้งเตือน',
                ),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // หน้าหลัก
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildPromotionalBanner(),

                      const SizedBox(height: 16),

                      // Recent Orders Section
                      _buildRecentOrders(),

                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'สินค้าแนะนำ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'ดูทั้งหมด',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // สินค้าแนะนำ (ใช้ Stream builder)
                            StreamBuilder<List<Product>>(
                              stream:
                                  FirebaseService().getAllProductsForAdmin(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text('ไม่มีสินค้าแนะนำ'),
                                  );
                                }

                                // แสดงเฉพาะ 10 สินค้าแรก
                                final featuredProducts =
                                    snapshot.data!.take(10).toList();

                                return SizedBox(
                                  height: 240,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: featuredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = featuredProducts[index];
                                      return Container(
                                        width: 160,
                                        margin: EdgeInsets.only(
                                          right: index ==
                                                  featuredProducts.length - 1
                                              ? 0
                                              : 12,
                                        ),
                                        child: ProductCard(product: product),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 100), // เว้นพื้นที่ให้ bottom navigation
                    ],
                  ),
                ),

                // Tab แจ้งเตือน (สร้างเนื้อหาใหม่)
                Container(
                  color: Colors.grey[50],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'ไม่มีการแจ้งเตือนใหม่',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
