// lib/main_app_shell.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/providers/app_config_provider.dart';
import 'package:green_market/screens/admin_panel_screen.dart';
import 'package:green_market/screens/home_screen_beautiful.dart'; // ใช้ home_screen_beautiful.dart
import 'package:green_market/screens/cart_screen.dart';
import 'package:green_market/screens/orders_screen.dart';
import 'package:green_market/screens/simple_chat_list_screen.dart';
import 'package:green_market/screens/profile_screen.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';
import 'package:green_market/screens/seller/seller_dashboard_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/notifications_center_screen.dart';
import 'package:green_market/services/notification_service.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    final navItems = _getAllNavItems();
    if (index < navItems.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // --- Page Lists - Now unified with dynamic tabs based on role ---
  List<Widget> _getAllPages() {
    final userProvider =
        context.read<UserProvider>(); // ใช้ read แทน listen: false

    List<Widget> pages = [
      const HomeScreen(), // 0. ตลาด (ทุกคน) - จาก home_screen_beautiful.dart
      const CartScreen(), // 1. ตะกร้าสินค้า (ทุกคน)
      const OrdersScreen(), // 2. คำสั่งซื้อ (ทุกคน)
      const SimpleChatListScreen(), // 3. แชท (ทุกคน)
      const ProfileScreen(), // 4. โปรไฟล์ (ทุกคน)
    ];

    // เพิ่มแท็บสำหรับผู้ขายที่อนุมัติแล้ว
    if (userProvider.isSeller) {
      pages.add(const SellerDashboardScreen()); // 5. ร้านค้าของฉัน
    }

    // เพิ่มแท็บสำหรับแอดมิน
    if (userProvider.isAdmin) {
      pages.add(const AdminPanelScreen()); // 5 หรือ 6. จัดการระบบ
    }

    return pages;
  }

  // --- AppBar Titles - Now unified with dynamic titles based on role ---
  List<String> _getAllTitles() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    List<String> titles = [
      'ตลาด',
      'ตะกร้าสินค้า',
      'คำสั่งซื้อ',
      'แชท',
      '🏡 My Home',
    ];

    // เพิ่มชื่อแท็บสำหรับผู้ขายที่อนุมัติแล้ว
    if (userProvider.isSeller) {
      titles.add('ร้านค้าของฉัน');
    }

    // เพิ่มชื่อแท็บสำหรับแอดมิน
    if (userProvider.isAdmin) {
      titles.add('จัดการระบบ');
    }

    return titles;
  }

  // --- Bottom Navigation Bar Items - Now unified with dynamic items based on role ---
  static const List<BottomNavigationBarItem> _baseNavItems = [
    BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        activeIcon: Icon(Icons.store),
        label: 'ตลาด'),
    BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_outlined),
        activeIcon: Icon(Icons.shopping_cart),
        label: 'ตะกร้า'),
    BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'คำสั่งซื้อ'),
    BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: 'แชท'),
    BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'My Home'),
  ];

  List<BottomNavigationBarItem> _getAllNavItems() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    List<BottomNavigationBarItem> items = _baseNavItems.toList();

    // เพิ่มแท็บสำหรับผู้ขายที่อนุมัติแล้ว
    if (userProvider.isSeller) {
      items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          activeIcon: Icon(Icons.storefront),
          label: 'ร้านค้า'));
    }

    // เพิ่มแท็บสำหรับแอดมิน
    if (userProvider.isAdmin) {
      items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'จัดการ'));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getAllPages();
    final navItems = _getAllNavItems();
    final titles = _getAllTitles();

    // ตรวจสอบ index ให้อยู่ในช่วงที่ถูกต้อง
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 20, // ใช้ค่าคงที่แทน baseFontSize
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Notification icon with badge
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final userId = userProvider.currentUser?.id;
              if (userId == null) return const SizedBox.shrink();

              return StreamBuilder<int>(
                stream: NotificationService().getUnreadCountStream(userId),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationsCenterScreen(),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
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
                  );
                },
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex], // ใช้ pages array แทน _getSelectedScreene(
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GreenWorldHubScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        tooltip: 'เปิดโลกสีเขียว',
        child: const Icon(Icons.eco), // เปลี่ยนเป็นต้นไม้เล็ก
      ),
    );
  }
}
