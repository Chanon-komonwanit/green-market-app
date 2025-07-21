// lib/main_app_shell.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/providers/theme_provider.dart';
import 'package:green_market/providers/app_config_provider.dart';
import 'package:green_market/screens/admin_panel_screen.dart';
import 'package:green_market/screens/home_screen_beautiful.dart'; // ใช้ home_screen_beautiful.dart
import 'package:green_market/screens/my_home_screen.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';
import 'package:green_market/screens/seller/seller_dashboard_screen.dart';
import 'package:green_market/screens/green_community_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/notifications_center_screen.dart';
import 'package:green_market/services/notification_service.dart';
import 'package:green_market/widgets/green_world_icon.dart';

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

  // --- Page Lists - Simplified to 3 main tabs ---
  List<Widget> _getAllPages() {
    final userProvider =
        context.read<UserProvider>(); // ใช้ read แทน listen: false

    List<Widget> pages = [
      const HomeScreen(), // 0. ตลาด (ทุกคน) - จาก home_screen_beautiful.dart
      const MyHomeScreen(), // 1. My Home (ทุกคน - รวม Cart, Chat, Orders, Notifications)
      const GreenCommunityScreen(), // 2. ชุมชนสีเขียว
      const GreenWorldHubScreen(), // 3. โลกสีเขียว
    ];

    // เพิ่มแท็บสำหรับผู้ขายที่อนุมัติแล้ว
    if (userProvider.isSeller) {
      pages.add(const SellerDashboardScreen()); // 2. ร้านค้าของฉัน
    }

    // เพิ่มแท็บสำหรับแอดมิน
    if (userProvider.isAdmin) {
      pages.add(const AdminPanelScreen()); // 4. จัดการระบบ
    }

    return pages;
  }

  // --- AppBar Titles - Simplified to 3 main tabs ---
  List<String> _getAllTitles() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    List<String> titles = [
      'ตลาด',
      'My Home',
      'ชุมชนสีเขียว',
      'โลกสีเขียว',
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

  // --- Bottom Navigation Bar Items - Simplified to 3 main tabs ---
  List<BottomNavigationBarItem> _getAllNavItems() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'ตลาด'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'My Home'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.groups_3_rounded, size: 28),
          activeIcon: Icon(Icons.groups_3_rounded, size: 32),
          label: 'ชุมชนสีเขียว'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.public, color: Colors.green, size: 28),
          activeIcon: Icon(Icons.public, color: Colors.green, size: 32),
          label: 'โลกสีเขียว'),
    ];
    if (userProvider.isSeller) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.storefront_outlined),
        activeIcon: Icon(Icons.storefront),
        label: 'ร้านค้าของฉัน',
      ));
    }
    if (userProvider.isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings_outlined),
        activeIcon: Icon(Icons.admin_panel_settings),
        label: 'จัดการระบบ',
      ));
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
          // Theme toggle button
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  themeProvider.toggleDarkMode();
                },
                tooltip: themeProvider.isDarkMode
                    ? 'เปลี่ยนเป็นโหมดกลางวัน'
                    : 'เปลี่ยนเป็นโหมดกลางคืน',
              );
            },
          ),
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
    );
  }
}
