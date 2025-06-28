// lib/main_app_shell.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/providers/app_config_provider.dart';
import 'package:green_market/screens/admin_panel_screen.dart';
import 'package:green_market/screens/admin/admin_user_management_screen.dart'; // Keep for admin
import 'package:green_market/screens/home_screen_beautiful.dart';
import 'package:green_market/screens/cart_screen.dart';
import 'package:green_market/screens/orders_screen.dart';
import 'package:green_market/screens/simple_chat_list_screen.dart';
import 'package:green_market/screens/profile_screen.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';
import 'package:green_market/screens/seller/seller_dashboard_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    final maxIndex = _getAllNavItems().length - 1;
    if (index <= maxIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // --- Page Lists - Now unified with dynamic tabs based on role ---
  List<Widget> _getAllPages() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    List<Widget> pages = [
      const HomeScreen(), // 0. ตลาด (ทุกคน) - ใช้ Beautiful Edition
      const CartScreen(), // 1. ตะกร้าสินค้า (ทุกคน)
      const OrdersScreen(), // 2. คำสั่งซื้อ (ทุกคน)
      const SimpleChatListScreen(), // 3. แชท (ทุกคน)
      const ProfileScreen(), // 4. ฉัน (ทุกคน)
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
      'ฉัน',
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
  List<BottomNavigationBarItem> _getAllNavItems() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'ตลาด'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'ตะกร้า'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'คำสั่งซื้อ'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'แชท'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'ฉัน'),
    ];

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
    return Consumer<AppConfigProvider>(
      builder: (context, appConfig, child) {
        final theme = Theme.of(context);

        final pages = _getAllPages();
        final navItems = _getAllNavItems();
        final titles = _getAllTitles();

        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // Debug information
        print('MainAppShell - Total pages: ${pages.length}');
        print('MainAppShell - Selected index: $_selectedIndex');
        print(
            'MainAppShell - Current page: ${pages[_selectedIndex].runtimeType}');
        print(
            'MainAppShell - User role: Admin=${userProvider.isAdmin}, Seller=${userProvider.isSeller}');

        // ตรวจสอบ index ให้อยู่ในช่วงที่ถูกต้อง
        if (_selectedIndex >= pages.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              titles[_selectedIndex],
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontSize: appConfig.config.baseFontSize + 4,
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
            iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: navItems,
            currentIndex: _selectedIndex,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurfaceVariant,
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
      },
    );
  }
}
