import 'package:flutter/material.dart';
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
import 'package:green_market/providers/cart_provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/order.dart' as app_order;
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
    _tabController = TabController(length: 4, vsync: this);
  }

  // quickActionsModern widget stub
  Widget quickActionsModernWidget() {
    // ใช้งาน _QuickActionsModern จริง
    return _QuickActionsModern();
  }

  // notificationsTab widget stub
  Widget notificationsTabWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(child: Text('Notifications Placeholder')),
    );
  }

  // smartEcoHeroTab widget stub
  Widget smartEcoHeroTabWidget() {
    return Container(
      color: Colors.green[100],
      child: Center(child: Text('Smart Eco Hero Placeholder')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            ModernHomeHeader(
              title: 'Green Market',
              subtitle: 'ตลาดสีเขียวเพื่อชุมชน',
              backgroundGradient: const LinearGradient(
                colors: [
                  Color(0xFF059669),
                  Color(0xFF10B981),
                  Color(0xFF34D399)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: 8),
            ModernCard(
              color: const Color(0xFFFFF8DC),
              borderRadius: 18,
              child: _EcoCoinsSection(),
            ),
            modernTabBar(),
            const SizedBox(height: 8),
            quickActionsModern(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  smartEcoHeroTab(),
                  chatTab(),
                  cartTab(),
                  notificationsTabReal(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget smartEcoHeroTab() {
    return smartEcoHeroTabWidget();
  }

  Widget chatTab() {
    // ตัวอย่างการใช้งาน _ChatListItem แบบ mock data
    final mockChatData = {
      'participants': ['user1', 'user2'],
      'lastMessage': 'สวัสดีครับ',
      'lastMessageTime': Timestamp.now(),
      'isRead': false,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChatListItem(
          chatId: 'chat1',
          chatData: mockChatData,
          currentUserId: 'user1',
        ),
      ],
    );
  }

  Widget notificationsTab() {
    return notificationsTabWidget();
  }

  Widget modernTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.eco), text: 'Eco Hero'),
        Tab(icon: Icon(Icons.chat), text: 'Chat'),
        Tab(icon: Icon(Icons.shopping_cart), text: 'Cart'),
        Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
      ],
    );
  }

  Widget quickActionsModern() {
    return quickActionsModernWidget();
  }

  Widget cartTab() {
    // ...existing code...
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.items.values.toList();
        if (cartItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('ตะกร้าของคุณว่างเปล่า',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('เพิ่มสินค้าเพื่อเริ่มต้นการช้อปปิ้ง',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }
        return Column(
          children: [
            ModernCard(
              color: const Color(0xFF2E7D32),
              borderRadius: 16,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('รวม ${cartItems.length} รายการ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('฿${cartProvider.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = cartItems[index];
                  final product = cartItem.product;
                  return ModernCard(
                    color: Colors.white,
                    borderRadius: 12,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.imageUrls.isNotEmpty
                              ? Image.network(
                                  product.imageUrls.first,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('฿${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
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
                                                  BorderRadius.circular(6)),
                                          child: const Icon(Icons.remove,
                                              size: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text('${cartItem.quantity}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
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
                                                  BorderRadius.circular(6)),
                                          child: const Icon(Icons.add,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      cartProvider.removeItem(product.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'ลบ ${product.name} ออกจากตะกร้าแล้ว'),
                                          duration: const Duration(seconds: 2),
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
                                              BorderRadius.circular(6)),
                                      child: const Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ModernButton(
                  label: 'ดำเนินการชำระเงิน',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                  color: const Color(0xFF2E7D32),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} // ปิดคลาส _MyHomeScreenState

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
              Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('ตะกร้าของคุณว่างเปล่า',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text('เพิ่มสินค้าเพื่อเริ่มต้นการช้อปปิ้ง',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        );
      }
      return Column(
        children: [
          ModernCard(
            color: const Color(0xFF2E7D32),
            borderRadius: 16,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('รวม ${cartItems.length} รายการ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('฿${cartProvider.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartItems[index];
                final product = cartItem.product;
                return ModernCard(
                  color: Colors.white,
                  borderRadius: 12,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.imageUrls.isNotEmpty
                            ? Image.network(
                                product.imageUrls.first,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('฿${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        cartProvider.updateItemQuantity(
                                            product.id, cartItem.quantity - 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child:
                                            const Icon(Icons.remove, size: 16),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text('${cartItem.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        cartProvider.updateItemQuantity(
                                            product.id, cartItem.quantity + 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF2E7D32),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: const Icon(Icons.add,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    cartProvider.removeItem(product.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'ลบ ${product.name} ออกจากตะกร้าแล้ว'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor:
                                            const Color(0xFF43A047),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(6)),
                                    child: const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ModernButton(
                label: 'ดำเนินการชำระเงิน',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
                color: const Color(0xFF2E7D32),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// --- Notifications Tab (ปรับปรุงให้ดึงข้อมูลจริง) ---
Widget notificationsTabReal() {
  // Widget _modernTabBar() {
  //   return TabBar(
  //     controller: _tabController,
  //     tabs: const [
  //       Tab(icon: Icon(Icons.eco), text: 'Eco Hero'),
  //       Tab(icon: Icon(Icons.chat), text: 'Chat'),
  //       Tab(icon: Icon(Icons.shopping_cart), text: 'Cart'),
  //       Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
  //     ],
  //   );
  // }

  // Widget _quickActionsModern() {
  //   return _QuickActionsModern();
  // }

  // Widget chatTab() {
  //   // Placeholder for chat tab
  //   return Center(child: Text('Chat Tab (Coming Soon)'));
  // }
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      if (userProvider.isLoading) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
        );
      }

      final currentUser = userProvider.currentUser;
      if (currentUser == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'กรุณาเข้าสู่ระบบเพื่อดูการแจ้งเตือน',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.id)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
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
                            Icons.notifications_outlined,
                            size: 60,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ไม่มีการแจ้งเตือน',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'เมื่อมีข่าวสารใหม่ เช่น การอัปเดตออเดอร์\nหรือข้อมูลสำคัญอื่นๆ จะแสดงที่นี่',
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
                            'ทันสมัยอยู่เสมอ',
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

          // แสดงรายการแจ้งเตือน
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationData =
                  notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;

              return _NotificationListItem(
                notificationId: notificationId,
                notificationData: notificationData,
              );
            },
          );
        },
      );
    },
  );
}

// Verified Badge Widget (ลบออก - ใช้ _buildStatusBadge แทน)

// Chat List Item Widget
class _ChatListItem extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> chatData;
  final String currentUserId;

  const _ChatListItem({
    required this.chatId,
    required this.chatData,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final participants = chatData['participants'] as List<dynamic>? ?? [];
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => 'ไม่ทราบ',
    );

    final lastMessage = chatData['lastMessage'] as String? ?? '';
    final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
    final isRead = chatData['isRead'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isRead
              ? Colors.transparent
              : const Color(0xFF2E7D32).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
        title: Text(
          'แชทกับ: $otherUserId',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF2E2E2E),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastMessage.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                lastMessage,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (lastMessageTime != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(lastMessageTime),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: isRead
            ? const Icon(Icons.chevron_right, color: Colors.grey)
            : Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail, color: Colors.white, size: 16),
              ),
        onTap: () {
          // สำหรับตอนนี้ให้แสดง placeholder เพราะ ChatScreen ต้องการ parameters หลายตัว
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text('แชท'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_outlined,
                    size: 60,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 16),
                  Text('แชทกับ: $otherUserId'),
                  const SizedBox(height: 8),
                  const Text(
                    'ฟีเจอร์แชทจะพัฒนาเพิ่มเติมในเวอร์ชันต่อไป',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ตกลง'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

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
}

// Notification List Item Widget
class _NotificationListItem extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> notificationData;

  const _NotificationListItem({
    required this.notificationId,
    required this.notificationData,
  });

  @override
  Widget build(BuildContext context) {
    final title = notificationData['title'] as String? ?? 'แจ้งเตือน';
    final message = notificationData['message'] as String? ?? '';
    final type = notificationData['type'] as String? ?? 'general';
    final isRead = notificationData['isRead'] as bool? ?? false;
    final createdAt = notificationData['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isRead
              ? Colors.transparent
              : const Color(0xFF2E7D32).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getNotificationColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getNotificationIcon(type),
            color: _getNotificationColor(type),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF2E2E2E),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(createdAt),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: isRead
            ? const Icon(Icons.chevron_right, color: Colors.grey)
            : Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 8, height: 8),
              ),
        onTap: () {
          _markAsRead(context);
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.payment;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return const Color(0xFF1976D2);
      case 'payment':
        return const Color(0xFF388E3C);
      case 'delivery':
        return const Color(0xFFFF6F00);
      case 'promotion':
        return const Color(0xFFE91E63);
      case 'system':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

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

  void _markAsRead(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถอัปเดตสถานะการอ่านได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Enhanced Eco Coins Section (ปรับปรุงให้เด่นและใช้งานได้จริง)
class _EcoCoinsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, userProvider, child) {
      final currentUser = userProvider.currentUser;
      final ecoCoinCount = currentUser?.ecoCoins ?? 0;
      final equivalentBaht = (ecoCoinCount * 0.01); // 1 เหรียญ = 0.01 บาท

      return GestureDetector(
        onTap: () {
          // Navigate to Eco Rewards Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EcoRewardsScreen(),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700), // ทองเข้ม
                Color(0xFFFFF8DC), // ทองอ่อน
                Color(0xFFFFE55C), // ทองกลาง
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(18), // ลดจาก 24 เป็น 18
            border: Border.all(
              color: const Color(0xFFB8860B), // เส้นขอบทอง
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 12, // ลดจาก 20 เป็น 12
                offset: const Offset(0, 4), // ลดจาก 8 เป็น 4
                spreadRadius: 1, // ลดจาก 2 เป็น 1
              ),
              BoxShadow(
                color: Colors.orange.withOpacity(0.15),
                blurRadius: 20, // ลดจาก 30 เป็น 20
                offset: const Offset(0, 8), // ลดจาก 15 เป็น 8
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18), // ลดจาก 24 เป็น 18
            child: Column(
              children: [
                Row(
                  children: [
                    // Enhanced Coin Display
                    Container(
                      padding: const EdgeInsets.all(12), // ลดจาก 16 เป็น 12
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16), // ลดจาก 20 เป็น 16
                        border: Border.all(
                          color: const Color(0xFFB8860B),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8, // ลดจาก 12 เป็น 8
                            offset: const Offset(0, 3), // ลดจาก 4 เป็น 3
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Coin Icon
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1500),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 2 * 3.14159, // หมุน 1 รอบ
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(6), // ลดจาก 8 เป็น 6
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFD700,
                                        ).withOpacity(0.3),
                                        blurRadius: 6, // ลดจาก 8 เป็น 6
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.eco,
                                    color: Colors.white,
                                    size: 22, // ลดจาก 28 เป็น 22
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10), // ลดจาก 12 เป็น 10
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$ecoCoinCount',
                                style: const TextStyle(
                                  fontSize: 24, // ลดจาก 28 เป็น 24
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB8860B),
                                  shadows: [
                                    Shadow(
                                      color: Color(0x40000000),
                                      blurRadius: 2,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '🪙 เหรียญ Eco',
                                style: TextStyle(
                                  fontSize: 11, // ลดจาก 12 เป็น 11
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, // ลดจาก 12 เป็น 10
                                  vertical: 5, // ลดจาก 6 เป็น 5
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(
                                      16), // ลดจาก 20 เป็น 16
                                  border: Border.all(
                                    color: const Color(
                                      0xFFB8860B,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet,
                                      color: Color(0xFFB8860B),
                                      size: 14, // ลดจาก 16 เป็น 14
                                    ),
                                    const SizedBox(width: 5), // ลดจาก 6 เป็น 5
                                    Text(
                                      'มูลค่า',
                                      style: TextStyle(
                                        fontSize: 11, // ลดจาก 12 เป็น 11
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6), // ลดจาก 8 เป็น 6
                          Row(
                            children: [
                              Text(
                                '฿${equivalentBaht.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18, // ลดจาก 20 เป็น 18
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB8860B),
                                  shadows: [
                                    Shadow(
                                      color: Color(0x40000000),
                                      blurRadius: 1,
                                      offset: Offset(0.5, 0.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6), // ลดจาก 8 เป็น 6
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6, // ลดจาก 8 เป็น 6
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '1:0.01',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getProgressText(ecoCoinCount),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Small info icon (visual indicator only)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFB8860B).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFFB8860B),
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _getProgressPercent(ecoCoinCount),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ), // Container closing
      ); // GestureDetector closing
    }); // Consumer closing
  }

  String _getProgressText(double ecoCoins) {
    final coinsInt = ecoCoins.round();
    if (coinsInt >= 1000) {
      return 'คุณคือ Eco Legend แล้ว! 🌟';
    } else if (coinsInt >= 500) {
      final remaining = 1000 - coinsInt;
      return 'อีก $remaining เหรียญจะเป็น Eco Legend';
    } else if (coinsInt >= 200) {
      final remaining = 500 - coinsInt;
      return 'อีก $remaining เหรียญจะเป็น Eco Master';
    } else if (coinsInt >= 50) {
      final remaining = 200 - coinsInt;
      return 'อีก $remaining เหรียญจะเป็น Eco Hero';
    } else {
      final remaining = 50 - coinsInt;
      return 'อีก $remaining เหรียญจะเป็น Eco Friend';
    }
  }

  double _getProgressPercent(double ecoCoins) {
    final coinsInt = ecoCoins.round();
    if (coinsInt >= 1000) {
      return 1.0; // 100%
    } else if (coinsInt >= 500) {
      return (coinsInt - 500) / 500; // ช่วง 500-1000
    } else if (coinsInt >= 200) {
      return (coinsInt - 200) / 300; // ช่วง 200-500
    } else if (coinsInt >= 50) {
      return (coinsInt - 50) / 150; // ช่วง 50-200
    } else {
      return coinsInt / 50; // ช่วง 0-50
    }
  }
}

// Modern Quick Actions (ปรับปรุงให้มีข้อมูลจริงและใช้งานได้)
class _QuickActionsModern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;

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

                // แถวที่ 1: ออเดอร์ และ โค้ดส่วนลด
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.shopping_bag_outlined,
                        label: 'ออเดอร์ของฉัน',
                        color: const Color(0xFF059669),
                        onTap: () => _navigateToOrders(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.discount_outlined,
                        label: 'โค้ดส่วนลด',
                        color: const Color(0xFF7C3AED),
                        onTap: () => _showCoupons(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // แถวที่ 2: ตะกร้าของฉัน และ การจัดส่ง
                Row(
                  children: [
                    // ปุ่มด้านซ้าย: ตะกร้าของฉัน (ทุกคน)
                    Expanded(
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final totalItems = cartProvider.totalItemsInCart;
                          final totalAmount = cartProvider.totalAmount;

                          return _QuickActionButton(
                            icon: Icons.shopping_cart_outlined,
                            label:
                                'ตะกร้าของฉัน\n$totalItems รายการ ฿${totalAmount.toStringAsFixed(0)}',
                            color: const Color(0xFF059669),
                            onTap: () => _navigateToCart(context),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ปุ่มด้านขวา: การจัดส่ง
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.local_shipping_outlined,
                        label: 'การจัดส่ง',
                        color: const Color(0xFF0891B2),
                        onTap: () => _navigateToShipping(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // แถวที่ 3: การตั้งค่า/จัดการระบบ
                Row(
                  children: [
                    // ปุ่มด้านซ้าย: สำหรับแอดมินแสดงจัดการระบบ, อื่นๆ แสดงการตั้งค่า
                    Expanded(
                      child: currentUser?.isAdmin == true
                          ? _QuickActionButton(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'จัดการระบบ',
                              color: const Color(0xFF6366F1),
                              onTap: () => _showAdminPanel(context),
                            )
                          : _QuickActionButton(
                              icon: Icons.settings_outlined,
                              label: 'การตั้งค่า',
                              color: const Color(0xFF6B7280),
                              onTap: () => _navigateToSettings(context),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // ปุ่มด้านขวา: ช่องว่าง
                    Expanded(child: Container()),
                  ],
                ),
                const SizedBox(height: 16),
                // Open Shop Button (ปุ่มเปิดร้านค้า)
                if (currentUser?.isSeller != true)
                  _OpenShopButton(
                    onTap: () {
                      // นำทางไปยังหน้าลงทะเบียนผู้ขาย
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SellerApplicationFormScreen(),
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

  void _navigateToOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrdersScreen()),
    );
  }

  void _navigateToShipping(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const CustomerShippingDashboardScreen()),
    );
  }

  void _showCoupons(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Color(0xFFE91E63)),
            SizedBox(width: 8),
            Text('โค้ดส่วนลดของฉัน'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('คุณยังไม่มีโค้ดส่วนลดในขณะนี้'),
            SizedBox(height: 8),
            Text(
              'กิจกรรมโปรโมชั่นจะมีโค้ดส่วนลดให้เร็วๆ นี้',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showAdminPanel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFFFF6F00)),
            SizedBox(width: 8),
            Text('จัดการระบบ'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_outlined, size: 60, color: Color(0xFFFF6F00)),
            SizedBox(height: 16),
            Text('แผงควบคุมสำหรับผู้ดูแลระบบ'),
            SizedBox(height: 8),
            Text(
              'จัดการผู้ใช้, สินค้า, และการตั้งค่าระบบ',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SellerDashboardScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F00),
              foregroundColor: Colors.white,
            ),
            child: const Text('เข้าสู่ระบบ'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedEditProfileScreen(),
      ),
    );
  }

  void _navigateToCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
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

// Open Shop Button Widget (Special banner for non-sellers)
class _OpenShopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OpenShopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF059669),
              Color(0xFF10B981),
              Color(0xFF34D399),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏪 เปิดร้านค้าของคุณ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เริ่มขายสินค้าเป็นมิตรกับสิ่งแวดล้อม',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '✨ สมัครฟรี! ไม่มีค่าใช้จ่าย',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Smart Eco Hero Tab ---
// Widget _SmartEcoHeroTab() {
//   return Consumer<UserProvider>(
//     builder: (context, userProvider, child) {
//       ... (โค้ดเดิมทั้งหมดถูกคอมเมนต์ไว้ ไม่ลบ) ...
//     },
//   );
// }
