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
import 'package:green_market/screens/modern_my_home_screen.dart'; // ใช้หน้าใหม่
import 'package:green_market/screens/green_world_screen.dart';
import 'package:green_market/screens/seller/seller_dashboard_screen.dart';
import 'package:green_market/screens/green_community_screen.dart';
import 'package:green_market/screens/debug_products_screen.dart'; // Debug screen
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
      const ModernMyHomeScreen(), // 1. My Home (ทุกคน - รวม Cart, Chat, Orders, Notifications) - ใหม่
      const GreenCommunityScreen(), // 2. ชุมชนสีเขียว
      const GreenWorldScreen(), // 3. โลกสีเขียว
    ];

    // เพิ่มแท็บสำหรับผู้ขายที่อนุมัติแล้ว
    if (userProvider.isSeller) {
      pages.add(const SellerDashboardScreen()); // 2. ร้านค้าของฉัน
    }

    // เพิ่มแท็บสำหรับแอดมิน
    print(
        "Checking admin status for user: ${userProvider.currentUser?.email}, isAdmin: ${userProvider.isAdmin}");
    if (userProvider.isAdmin) {
      print("Adding CompleteAdminPanelScreen for admin user");
      pages.add(const CompleteAdminPanelScreen()); // 4. จัดการระบบ

      // เพิ่ม Debug Screen สำหรับแอดมิน
      pages.add(const DebugProductsScreen()); // 5. Debug Products
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
            DrawerHeader(child: Text('Settings')),
            _buildGlobalSettings(context),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: colors.AppColors.navBarSelectedColor,
        unselectedItemColor: colors.AppColors.navBarUnselectedColor,
        backgroundColor: colors.AppColors.navBarBackgroundColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
