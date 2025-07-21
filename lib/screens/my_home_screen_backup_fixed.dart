// lib/screens/my_home_screen_backup_fixed.dart

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
    _tabController = TabController(
      length: 4, // เพิ่มจาก 3 เป็น 4 แท็บ
      vsync: this,
    ); // Smart Eco Hero, แชท, ตะกร้า, แจ้งเตือน
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
        backgroundColor: const Color(0xFFF8FAF9),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Modern Home Header
                  ModernHomeHeader(
                      title: 'Green Market',
                      subtitle: 'ตลาดสีเขียวเพื่อชุมชน',
                      backgroundGradient: const LinearGradient(colors: [
                        Color(0xFF059669),
                        Color(0xFF10B981),
                        Color(0xFF34D399)
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  const SizedBox(height: 8),

                  // Modern Card for Eco Coins
                  ModernCard(
                    color: const Color(0xFFFFF8DC),
                    borderRadius: 18,
                    child: _EcoCoinsSection(),
                  ),
                  const SizedBox(height: 8),

                  // Modern Card for Quick Actions
                  ModernCard(
                    color: Colors.white,
                    borderRadius: 20,
                    child: _QuickActionsModern(),
                  ),
                  const SizedBox(height: 8),

                  // Modern Tab Bar
                  _modernTabBar(),
                  const SizedBox(height: 4),

                  // TabBarView - Smart Eco Hero, แชท, ตะกร้า, แจ้งเตือน
                  SizedBox(
                    height: 400, // กำหนดความสูงคงที่
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        const Center(
                          child: Text('Smart Eco Hero Tab - Coming Soon'),
                        ), // แท็บใหม่
                        _chatTab(), // แชท
                        _cartTab(), // ตะกร้า
                        _notificationsTab(), // แจ้งเตือน
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return _errorScreen(error: e.toString());
    }
  }

  Widget _modernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFAFAFA),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF059669).withOpacity(0.12),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF374151),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF059669),
              Color(0xFF10B981),
              Color(0xFF34D399),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorWeight: 0,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Eco Hero', icon: Icon(Icons.auto_awesome, size: 20)),
          Tab(text: 'แชท', icon: Icon(Icons.chat_bubble_outline, size: 20)),
          Tab(
            text: 'ตะกร้า',
            icon: Icon(Icons.shopping_cart_outlined, size: 20),
          ),
          Tab(
            text: 'แจ้งเตือน',
            icon: Icon(Icons.notifications_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  // --- Chat Tab (ปรับปรุงให้ดึงข้อมูลจริง) ---
  Widget _chatTab() {
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
                  'กรุณาเข้าสู่ระบบเพื่อใช้งานแชท',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUser.id)
              .orderBy('lastMessageTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              );
            }

            final chatDocs = snapshot.data?.docs ?? [];

            if (chatDocs.isEmpty) {
              return const Center(
                child: Text('ยังไม่มีการสนทนา'),
              );
            }

            // แสดงรายการแชท
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatDocs.length,
              itemBuilder: (context, index) {
                final chatId = chatDocs[index].id;
                return ListTile(
                  title: Text('แชท $chatId'),
                  onTap: () {
                    // TODO: Navigate to chat
                    // TODO: [ภาษาไทย] เมื่อผู้ใช้แตะรายการแชท ให้เปลี่ยนหน้าไปยังหน้าสนทนา (Chat Screen)
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Cart Tab (แก้ไข overflow) ---
  Widget _cartTab() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.items.values.toList();

        if (cartItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'ตะกร้าของคุณว่างเปล่า',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'เพิ่มสินค้าเพื่อเริ่มต้นการช้อปปิ้ง',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Cart Summary
            ModernCard(
              color: const Color(0xFF2E7D32),
              borderRadius: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รวม ${cartItems.length} รายการ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '฿${cartProvider.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                  children: cartItems
                      .map((cartItem) => ModernCard(
                            color: Colors.white,
                            borderRadius: 12,
                            child: ListTile(
                              title: Text(cartItem.product.name),
                              subtitle:
                                  Text('จำนวน: ${cartItem.quantity} ชิ้น'),
                              trailing: Text(
                                '฿${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            // Checkout Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ModernButton(
                  label: 'ดำเนินการสั่งซื้อ',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartScreen()),
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

  // --- Notifications Tab (ปรับปรุงให้ดึงข้อมูลจริง) ---
  Widget _notificationsTab() {
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
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final notifications = snapshot.data?.docs ?? [];

            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'ไม่มีการแจ้งเตือน',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
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

                return Card(
                  child: ListTile(
                    title: Text(notificationData['title'] ?? 'แจ้งเตือน'),
                    subtitle: Text(notificationData['message'] ?? ''),
                    onTap: () {
                      // TODO: Handle notification tap
                      // TODO: [ภาษาไทย] เมื่อผู้ใช้แตะรายการแจ้งเตือน ให้เปิดรายละเอียดหรือดำเนินการตามประเภทแจ้งเตือน
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Error Screen ---
  Widget _errorScreen({required String error}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Modern User Info Header (ปรับปรุงให้แสดงข้อมูลจริง) ---

// Enhanced Eco Coins Section (ปรับปรุงให้เด่นและใช้งานได้จริง)
class _EcoCoinsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFB8860B), // เส้นขอบทอง
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.orange.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Enhanced Coin Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFB8860B),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
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
                                    padding: const EdgeInsets.all(6),
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
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.eco,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$ecoCoinCount',
                                  style: const TextStyle(
                                    fontSize: 24,
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
                                    fontSize: 11,
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
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
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
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'มูลค่า',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '฿${equivalentBaht.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
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
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
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
                              _getProgressText(ecoCoinCount.toDouble()),
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
                      widthFactor: _getProgressPercent(ecoCoinCount.toDouble()),
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
          ),
        );
      },
    );
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
      return 1.0;
    } else if (coinsInt >= 500) {
      return (coinsInt - 500) / 500;
    } else if (coinsInt >= 200) {
      return (coinsInt - 200) / 300;
    } else if (coinsInt >= 50) {
      return (coinsInt - 50) / 150;
    } else {
      return coinsInt / 50;
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
                          final itemCount = cartProvider.itemCount;
                          return _QuickActionButton(
                            icon: Icons.shopping_cart_outlined,
                            label: 'ตะกร้า ($itemCount)',
                            color: const Color(0xFFEF4444),
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
                              icon: Icons.admin_panel_settings,
                              label: 'จัดการระบบ',
                              color: const Color(0xFFFF6F00),
                              onTap: () => _showAdminPanel(context),
                            )
                          : _QuickActionButton(
                              icon: Icons.settings,
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
              // แผงควบคุมแอดมินจะเปิดให้ใช้งานเร็วๆ นี้
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('แผงควบคุมแอดมินจะเปิดให้ใช้งานเร็วๆ นี้'),
                  backgroundColor: Color(0xFFFF6F00),
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
                      'เปิดร้านค้าของคุณ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เริ่มต้นขายสินค้าและสร้างรายได้',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
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
