// lib/main_app_shell.dart

// lib/main_app_shell.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/theme/app_colors.dart' as colors;
import 'package:green_market/providers/app_config_provider.dart';
import 'package:green_market/screens/admin/complete_admin_panel_screen.dart';
import 'package:green_market/screens/home_screen_beautiful.dart'; // ใช้ home_screen_beautiful.dart
import 'screens/my_home_screen.dart'; // My Home Screen - ใช้ relative path
import 'package:green_market/screens/green_world_screen.dart';
import 'package:green_market/screens/seller/seller_dashboard_screen.dart';
import 'package:green_market/screens/seller/world_class_seller_dashboard.dart';
import 'package:green_market/screens/green_community_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:green_market/services/notification_service.dart';
import 'package:green_market/widgets/green_world_icon.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  Widget _buildGlobalSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Consumer<AppConfigProvider>(
            builder: (context, configProvider, _) {
              return DropdownButtonFormField<String>(
                value: configProvider.config.primaryFontFamily,
                decoration: const InputDecoration(labelText: 'Font'),
                items: const [
                  DropdownMenuItem(value: 'Sarabun', child: Text('Sarabun')),
                  DropdownMenuItem(value: 'Prompt', child: Text('Prompt')),
                  DropdownMenuItem(value: 'Kanit', child: Text('Kanit')),
                  DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                ],
                onChanged: (font) {
                  if (font != null) configProvider.updateFontFamily(font);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<AppConfigProvider>(
            builder: (context, configProvider, _) {
              return DropdownButtonFormField<String>(
                value: configProvider.config.locale,
                decoration: const InputDecoration(labelText: 'Language'),
                items: const [
                  DropdownMenuItem(value: 'th', child: Text('ไทย')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (locale) {
                  if (locale != null) configProvider.updateLocale(locale);
                },
              );
            },
          ),
        ],
      ),
    );
  }

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
      const MyHomeScreen(), // 1. My Home (ทุกคน - รวม Cart, Chat, Orders, Notifications) - ใช้ MyHomeScreen เดิม
      const GreenCommunityScreen(), // 2. ชุมชนสีเขียว
      const GreenWorldScreen(), // 3. โลกสีเขียว
    ];

    // เพิ่มแท็บสำหรับผู้ขายที่อนุมัติแล้ว
    if (userProvider.isSeller) {
      pages.add(
          const WorldClassSellerDashboard()); // 2. ร้านค้าของฉัน - Enhanced!
    }

    // เพิ่มแท็บสำหรับแอดมิน
    print(
        "Checking admin status for user: ${userProvider.currentUser?.email}, isAdmin: ${userProvider.isAdmin}");
    if (userProvider.isAdmin) {
      print("Adding CompleteAdminPanelScreen for admin user");
      pages.add(const CompleteAdminPanelScreen()); // 4. จัดการระบบ

      // เพิ่ม Debug Screen สำหรับแอดมิน
      // pages.add(const DebugProductsScreen()); // 5. Debug Products (removed)
    } else {
      print("User is not admin, not adding admin panel");
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
      'เปิดโลกสีเขียว',
    ];

    // เพิ่มชื่อแท็บสำหรับผู้ขายที่อนุมัติแล้ว
    if (userProvider.isSeller) {
      titles.add('ร้านค้าของฉัน');
    }

    // เพิ่มชื่อแท็บสำหรับแอดมิน
    if (userProvider.isAdmin) {
      titles.add('จัดการระบบ');
      titles.add('Debug Products'); // เพิ่ม title สำหรับ Debug Screen
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
          label: 'เปิดโลกสีเขียว'),
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
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.bug_report_outlined),
        activeIcon: Icon(Icons.bug_report),
        label: 'Debug',
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
                fontSize: 20,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            // User Header
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final user = userProvider.currentUser;
                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.AppColors.primary,
                        colors.AppColors.primaryDark
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  accountName: Text(user?.displayName ?? 'ผู้ใช้'),
                  accountEmail: Text(user?.email ?? 'ไม่มีอีเมล'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),

            // App Settings Section
            ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text('การตั้งค่าแอป'),
              children: [_buildGlobalSettings(context)],
            ),

            // User Role Info
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                return ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('สถานะบัญชี'),
                  subtitle: Text(
                    userProvider.isAdmin
                        ? 'Admin'
                        : userProvider.isSeller
                            ? 'Seller'
                            : 'Customer',
                    style: TextStyle(
                      color: userProvider.isAdmin
                          ? Colors.red
                          : userProvider.isSeller
                              ? Colors.blue
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),

            const Divider(),

            // Debug Options (แสดงเฉพาะ Admin)
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                if (!userProvider.isAdmin) return const SizedBox.shrink();

                return ExpansionTile(
                  leading: const Icon(Icons.bug_report, color: Colors.orange),
                  title: const Text('Debug Tools'),
                  children: [
                    // Debug Products removed
                  ],
                );
              },
            ),

            const Divider(),

            // App Info
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('เกี่ยวกับแอป'),
              subtitle: const Text('Green Market v1.0.0'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Green Market',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 Green Market Team',
                  children: const [
                    Text('แอปตลาดออนไลน์เพื่อสิ่งแวดล้อม'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            items: navItems,
            currentIndex: _selectedIndex,
            selectedItemColor: colors.AppColors.primary,
            unselectedItemColor: colors.AppColors.grayMedium,
            backgroundColor: Colors.white,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
