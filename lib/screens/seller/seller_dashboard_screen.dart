// lib/screens/seller/seller_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Modern App Bar with Seller Profile
              _buildModernAppBar(),

              // Shop Statistics Section
              SliverToBoxAdapter(child: _buildShopStatistics()),

              // Quick Actions Section
              SliverToBoxAdapter(child: _buildQuickActions()),

              // Recent Activities Section
              SliverToBoxAdapter(child: _buildRecentActivities()),

              // Performance Analytics
              SliverToBoxAdapter(child: _buildPerformanceAnalytics()),

              // Bottom Padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF43A047),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/pattern.png',
                    repeat: ImageRepeat.repeat,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final user = userProvider.currentUser;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Seller Avatar
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.white,
                                  backgroundImage: user?.photoUrl != null
                                      ? NetworkImage(user!.photoUrl!)
                                      : null,
                                  child: user?.photoUrl == null
                                      ? Icon(
                                          Icons.store_outlined,
                                          size: 35,
                                          color: const Color(0xFF2E7D32),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.displayName ??
                                          'ร้านค้า Green Market',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'ผู้ขายที่ได้รับการยืนยัน',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Settings Button
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ShopSettingsScreen(),
                                    ),
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Shop Performance Summary
                          Row(
                            children: [
                              _buildPerformanceCard(
                                  'สินค้าทั้งหมด', '25', Icons.inventory_2),
                              const SizedBox(width: 12),
                              _buildPerformanceCard(
                                  'ยอดขายวันนี้', '₿1.2K', Icons.trending_up),
                              const SizedBox(width: 12),
                              _buildPerformanceCard(
                                  'คำสั่งซื้อใหม่', '8', Icons.shopping_cart),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopStatistics() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'สถิติร้านค้า',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('ดูรายละเอียด'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'ยอดขายรวม',
                    '฿45,230',
                    '+12.5%',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'คำสั่งซื้อ',
                    '156',
                    '+8.2%',
                    Colors.blue,
                    Icons.shopping_bag_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'ลูกค้าใหม่',
                    '23',
                    '+15.3%',
                    Colors.purple,
                    Icons.person_add_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'คะแนนรีวิว',
                    '4.8',
                    '+0.2',
                    Colors.orange,
                    Icons.star_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String change,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickAction(
        icon: Icons.add_circle_outline,
        title: 'เพิ่มสินค้าใหม่',
        subtitle: 'เพิ่มสินค้าใหม่เข้าสู่ร้านค้า',
        color: const Color(0xFF2E7D32),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductScreen()),
        ),
      ),
      QuickAction(
        icon: Icons.inventory_2_outlined,
        title: 'จัดการสินค้า',
        subtitle: 'ดู แก้ไข และจัดการสินค้า',
        color: const Color(0xFF1976D2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyProductsScreen()),
        ),
      ),
      QuickAction(
        icon: Icons.receipt_long_outlined,
        title: 'คำสั่งซื้อ',
        subtitle: 'ดูและจัดการคำสั่งซื้อ',
        color: const Color(0xFFE91E63),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SellerOrdersScreen()),
        ),
      ),
      QuickAction(
        icon: Icons.rate_review_outlined,
        title: 'รีวิวลูกค้า',
        subtitle: 'ดูและตอบกลับรีวิว',
        color: const Color(0xFFFF9800),
        onTap: () => _showComingSoon(),
      ),
      QuickAction(
        icon: Icons.campaign_outlined,
        title: 'โปรโมชัน',
        subtitle: 'สร้างและจัดการโปรโมชัน',
        color: const Color(0xFF9C27B0),
        onTap: () => _showComingSoon(),
      ),
      QuickAction(
        icon: Icons.analytics_outlined,
        title: 'รายงานขาย',
        subtitle: 'ดูสถิติและรายงาน',
        color: const Color(0xFF00BCD4),
        onTap: () => _showComingSoon(),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFFEC407A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'การกระทำด่วน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildQuickActionCard(action);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: action.color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                action.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              action.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: action.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action.subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'กิจกรรมล่าสุด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('ดูทั้งหมด'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._buildActivityList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityList() {
    final activities = [
      ActivityItem(
        icon: Icons.shopping_cart_outlined,
        title: 'คำสั่งซื้อใหม่ #1234',
        subtitle: 'ลูกค้าสั่งซื้อ "เสื้อผ้าออแกนิค" จำนวน 2 ชิ้น',
        time: '5 นาทีที่แล้ว',
        color: Colors.green,
      ),
      ActivityItem(
        icon: Icons.star_outline,
        title: 'รีวิวใหม่ ⭐⭐⭐⭐⭐',
        subtitle: 'ลูกค้าให้รีวิว 5 ดาวสำหรับ "กระเป๋าผ้าใบ"',
        time: '1 ชั่วโมงที่แล้ว',
        color: Colors.orange,
      ),
      ActivityItem(
        icon: Icons.inventory_2_outlined,
        title: 'สินค้าหมดสต็อก',
        subtitle: '"รองเท้าผ้าใบรีไซเคิล" เหลือสต็อกน้อย',
        time: '3 ชั่วโมงที่แล้ว',
        color: Colors.red,
      ),
    ];

    return activities.map((activity) => _buildActivityItem(activity)).toList();
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activity.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activity.color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.time,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalytics() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'วิเคราะห์ประสิทธิภาพ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF9C27B0).withOpacity(0.1),
                    const Color(0xFFBA68C8).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 40,
                      color: Color(0xFF9C27B0),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'กราฟแสดงยอดขายรายวัน',
                      style: TextStyle(
                        color: Color(0xFF9C27B0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'คลิกเพื่อดูรายละเอียด',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductScreen()),
        );
      },
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text(
        'เพิ่มสินค้า',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 8,
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}
