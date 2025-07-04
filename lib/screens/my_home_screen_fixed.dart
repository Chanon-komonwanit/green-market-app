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
import 'package:green_market/models/product.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/screens/orders_screen.dart';

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
    _tabController =
        TabController(length: 3, vsync: this); // แชท, ตะกร้า, แจ้งเตือน
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
                _ModernTabBar(),
                const SizedBox(height: 4),

                // TabBarView - แชท, ตะกร้า, แจ้งเตือน
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ChatTab(),
                      _CartTab(),
                      _NotificationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return _ErrorScreen(error: e.toString());
    }
  }

  Widget _ModernTabBar() {
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
            text: 'แชท',
            icon: Icon(Icons.chat_bubble_outline, size: 22),
          ),
          Tab(
            text: 'ตะกร้า',
            icon: Icon(Icons.shopping_cart_outlined, size: 22),
          ),
          Tab(
            text: 'แจ้งเตือน',
            icon: Icon(Icons.notifications_outlined, size: 22),
          ),
        ],
      ),
    );
  }

  // --- Chat Tab ---
  Widget _ChatTab() {
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

  // --- Cart Tab (แก้ไข overflow) ---
  Widget _CartTab() {
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ยอดรวมทั้งหมด',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('฿${cartProvider.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cartProvider.totalItemsInCart} รายการ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Products List (แก้ไข overflow เป็น list แนวตั้ง)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: cartItems.map((cartItem) {
                    final product = cartItem.product;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Product Image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: product.imageUrls.isNotEmpty
                                    ? Image.network(
                                        product.imageUrls.first,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, o, s) => Container(
                                          color: Colors.grey[100],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.image,
                                          size: 30,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '฿${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Quantity Controls
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              cartProvider.updateItemQuantity(
                                                  product.id,
                                                  cartItem.quantity - 1);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.remove,
                                                  size: 16),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              '${cartItem.quantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              cartProvider.updateItemQuantity(
                                                  product.id,
                                                  cartItem.quantity + 1);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2E7D32),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.add,
                                                  size: 16,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Remove Button
                                      GestureDetector(
                                        onTap: () {
                                          cartProvider.removeItem(product.id);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'ลบ ${product.name} ออกจากตะกร้าแล้ว'),
                                              duration:
                                                  const Duration(seconds: 2),
                                              backgroundColor:
                                                  const Color(0xFF43A047),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Checkout Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to checkout
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กำลังไปยังหน้าชำระเงิน'),
                        backgroundColor: Color(0xFF43A047),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ดำเนินการชำระเงิน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Notifications Tab ---
  Widget _NotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: const NotificationsCenterScreen(),
    );
  }

  // --- Error Screen ---
  Widget _ErrorScreen({required String error}) {
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

// Modern Quick Actions (ปรับปรุงให้มีข้อมูลจริง)
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
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
