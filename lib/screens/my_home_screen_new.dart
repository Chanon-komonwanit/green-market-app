import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/chat_screen.dart';
import 'package:green_market/screens/cart_screen.dart';
import 'package:green_market/screens/edit_profile_screen.dart';
import 'package:green_market/widgets/eco_coins_widget.dart';
import 'package:green_market/screens/notifications_center_screen.dart';
import 'package:green_market/providers/cart_provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/order.dart' as app_order;

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // ตลาด และ My Home
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: const Color(0xFFF3FBF4),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F5E9), Color(0xFFF3FBF4)],
              ),
            ),
            child: Column(
              children: [
                // Modern User Info Header
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _UserInfoHeaderModern(),
                ),
                const SizedBox(height: 8),

                // Enhanced Eco Coins Zone
                _EcoCoinsSection(),
                const SizedBox(height: 8),

                // Modern Quick Actions
                _QuickActionsModern(),
                const SizedBox(height: 8),

                // Modern Tab Bar
                modernTabBar(),
                const SizedBox(height: 4),

                // TabBarView - ตลาด และ My Home
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      marketTab(),
                      myHomeTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return errorScreen(error: e.toString());
    }
  }

  Widget modernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF666666),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorWeight: 0,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(
            text: 'ตลาด',
            icon: Icon(Icons.store_outlined, size: 22),
          ),
          Tab(
            text: 'My Home',
            icon: Icon(Icons.home_outlined, size: 22),
          ),
        ],
      ),
    );
  }

  // --- Market Tab ---
  Widget marketTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('ตลาด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('สินค้าเพื่อสิ่งแวดล้อม',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- My Home Tab (รวมทุกฟีเจอร์) ---
  Widget myHomeTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF666666),
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorWeight: 0,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(
                    text: 'โปรไฟล์',
                    icon: Icon(Icons.person_outline, size: 18)),
                Tab(
                    text: 'แชท',
                    icon: Icon(Icons.chat_bubble_outline, size: 18)),
                Tab(
                    text: 'ตะกร้า',
                    icon: Icon(Icons.shopping_cart_outlined, size: 18)),
                Tab(
                    text: 'แจ้งเตือน',
                    icon: Icon(Icons.notifications_outlined, size: 18)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MyActivityTab(),
                chatTab(),
                cartTab(),
                notificationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Chat Tab ---
  Widget chatTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'แชท',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ฟีเจอร์แชทจะเปิดให้ใช้งานเร็วๆ นี้\nสามารถพูดคุยกับผู้ขายได้โดยตรง',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.2),
                    ),
                  ),
                  child: const Text(
                    'เร็วๆ นี้',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // --- Cart Tab ---
  Widget cartTab() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.items.values.toList();

        if (cartItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('ยังไม่มีสินค้าในตะกร้า',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('เพิ่มสินค้าจากหน้าแรกเพื่อเริ่มช้อปปิ้ง',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Cart Summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ยอดรวม',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('฿${cartProvider.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('${cartProvider.totalItemsInCart} รายการ',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            // Cart Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final cartItem = cartItems[i];
                  final product = cartItem.product;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: product.imageUrls.isNotEmpty
                              ? Image.network(
                                  product.imageUrls.first,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey),
                                )
                              : const SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Icon(Icons.image,
                                      size: 40, color: Colors.grey),
                                ),
                        ),
                        // Product Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (product.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    product.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '฿${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            cartProvider.updateItemQuantity(
                                                product.id,
                                                cartItem.quantity - 1);
                                          },
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                          iconSize: 20,
                                        ),
                                        Text(
                                          '${cartItem.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            cartProvider.updateItemQuantity(
                                                product.id,
                                                cartItem.quantity + 1);
                                          },
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Remove Button
                        IconButton(
                          onPressed: () {
                            cartProvider.removeItem(product.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('ลบ ${product.name} ออกจากตะกร้าแล้ว'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Notifications Tab ---
  Widget notificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: const NotificationsCenterScreen(),
    );
  }

  // --- Error Screen ---
  Widget errorScreen({required String error}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('เกิดข้อผิดพลาด',
                style: TextStyle(fontSize: 18, color: Colors.red)),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// --- Modern User Info Header ---
class _UserInfoHeaderModern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Profile Avatar with Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentUser?.displayName ?? 'My Eco Profile',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF1B5E20),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _VerifiedBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.eco,
                            color: Color(0xFF43A047),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ระดับ: Eco Hero ${currentUser?.isAdmin == true ? "• Admin" : ""}',
                            style: const TextStyle(
                              color: Color(0xFF388E3C),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Settings Button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    // Navigate to settings
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Verified Badge Widget
class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Eco Coins Section
class _EcoCoinsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const EcoCoinsWidget(),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เหรียญ Eco Coins ของคุณ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'สะสมเพื่อแลกรางวัลพิเศษ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Quick Actions (Only 2 buttons as requested)
class _QuickActionsModern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Color(0xFF43A047), size: 24),
                SizedBox(width: 8),
                Text(
                  'การกระทำด่วน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.shopping_bag_outlined,
                    label: 'ออเดอร์ของฉัน',
                    color: const Color(0xFF1976D2),
                    onTap: () => _navigateToOrders(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.discount_outlined,
                    label: 'โค้ดส่วนลด',
                    color: const Color(0xFFE91E63),
                    onTap: () => _showCoupons(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOrders(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังไปยังหน้าออเดอร์ของฉัน'),
        backgroundColor: Color(0xFF43A047),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCoupons(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('โค้ดส่วนลดของฉัน'),
        content: const Text('คุณยังไม่มีโค้ดส่วนลดในขณะนี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}

// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyActivityTab extends StatefulWidget {
  @override
  State<_MyActivityTab> createState() => _MyActivityTabState();
}

class _MyActivityTabState extends State<_MyActivityTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, FirebaseService>(
      builder: (context, userProvider, firebaseService, child) {
        final currentUser = userProvider.currentUser;

        if (currentUser == null) {
          return const Center(
            child:
                Text('กรุณาเข้าสู่ระบบ', style: TextStyle(color: Colors.grey)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFF8F9FA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2E7D32),
                                  Color(0xFF388E3C),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF2E7D32).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.transparent,
                              backgroundImage: currentUser.photoUrl != null
                                  ? NetworkImage(currentUser.photoUrl!)
                                  : null,
                              child: currentUser.photoUrl == null
                                  ? Text(
                                      currentUser.displayName
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          currentUser.email
                                              .substring(0, 1)
                                              .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.displayName ??
                                      'ผู้ใช้ Green Market',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUser.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (currentUser.isAdmin) ...[
                                      _buildRoleBadge(
                                        'แอดมิน',
                                        Colors.red,
                                        Icons.admin_panel_settings,
                                      ),
                                    ],
                                    if (currentUser.isSeller) ...[
                                      _buildRoleBadge(
                                        'ผู้ขาย',
                                        const Color(0xFF2E7D32),
                                        Icons.store,
                                      ),
                                    ],
                                    _buildRoleBadge(
                                      'สมาชิก',
                                      const Color(0xFF1976D2),
                                      Icons.person,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Recent Orders Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF388E3C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'คำสั่งซื้อล่าสุด',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        print('View all orders');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'ดูทั้งหมด',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentOrders(firebaseService, currentUser.id),

              const SizedBox(height: 20),

              // Account Management Section
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1976D2),
                            Color(0xFF1E88E5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.manage_accounts_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'การจัดการบัญชี',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildAccountActionItem(
                      context,
                      Icons.person_outline_rounded,
                      'แก้ไขข้อมูลส่วนตัว',
                      'อัปเดตข้อมูลโปรไฟล์ของคุณ',
                      const Color(0xFF2E7D32),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildAccountActionItem(
                      context,
                      Icons.security_outlined,
                      'เปลี่ยนรหัสผ่าน',
                      'อัปเดตรหัสผ่านเพื่อความปลอดภัย',
                      const Color(0xFF1976D2),
                      () => print('Change password tapped'),
                    ),
                    _buildDivider(),
                    _buildAccountActionItem(
                      context,
                      Icons.help_outline_rounded,
                      'ความช่วยเหลือ',
                      'ศูนย์ช่วยเหลือและ FAQ',
                      const Color(0xFF8E24AA),
                      () => print('Help tapped'),
                    ),
                    _buildDivider(),
                    _buildAccountActionItem(
                      context,
                      Icons.logout_rounded,
                      'ออกจากระบบ',
                      'ออกจากบัญชีผู้ใช้',
                      Colors.red,
                      () => _showLogoutDialog(context),
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentOrders(FirebaseService firebaseService, String userId) {
    return StreamBuilder<List<app_order.Order>>(
      stream: firebaseService
          .getOrdersByUserId(userId)
          .map((orders) => orders.take(5).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF8F9FA),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: const Color(0xFF2E7D32).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ยังไม่มีคำสั่งซื้อ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เริ่มช้อปปิ้งเพื่อสิ่งแวดล้อมกันเถอะ!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: orders.map((order) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFFAFAFA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: _getOrderStatusColor(order.status).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    print('Tapped order: ${order.id}');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getOrderStatusColor(order.status)
                                        .withOpacity(0.1),
                                    _getOrderStatusColor(order.status)
                                        .withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getOrderStatusColor(order.status)
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _getOrderStatusIcon(order.status),
                                color: _getOrderStatusColor(order.status),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'คำสั่งซื้อ #${order.id.substring(0, 8)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.items.length} รายการ • ฿${order.totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getOrderStatusColor(order.status)
                                        .withOpacity(0.1),
                                    _getOrderStatusColor(order.status)
                                        .withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getOrderStatusColor(order.status)
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getOrderStatusText(order.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getOrderStatusColor(order.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: Colors.grey.withOpacity(0.2),
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateTime(order.orderDate.toDate()),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipping':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'shipping':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getOrderStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'confirmed':
        return 'ยืนยันแล้ว';
      case 'shipping':
        return 'กำลังจัดส่ง';
      case 'delivered':
        return 'จัดส่งแล้ว';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} วันที่แล้ว';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  // Helper method for account action items
  Widget _buildAccountActionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDestructive ? Colors.red : const Color(0xFF2E2E2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for divider
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withOpacity(0.1),
      indent: 56,
      endIndent: 20,
    );
  }

  // Helper method for logout dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'ออกจากระบบ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
          content: const Text(
            'คุณต้องการออกจากระบบหรือไม่?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Perform logout
                final firebaseService =
                    Provider.of<FirebaseService>(context, listen: false);
                await firebaseService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ออกจากระบบ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
