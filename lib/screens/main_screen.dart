// main_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/auth_service.dart';
import 'package:green_market/utils/constants.dart'; // For AppColors
// For AppColors
// Import your actual screens here
import 'package:green_market/screens/profile_screen.dart'; // Your actual ProfileScreen
import 'package:green_market/screens/products_screen.dart'; // Your actual ProductsScreen
import 'package:green_market/screens/cart_screen.dart'; // Your actual CartScreen
import 'package:green_market/screens/orders_screen.dart'; // Your actual OrdersScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Ensure these are your correct screen widgets
  final List<Widget> _screens = [
    const ProductsScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const ProfileScreen(), // This should be your ProfileScreen
  ];

  final List<String> _appBarTitles = [
    'สินค้า',
    'ตะกร้าสินค้า',
    'คำสั่งซื้อ',
    'โปรไฟล์',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_currentIndex],
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              final bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('ยืนยันการออกจากระบบ'),
                    content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('ยกเลิก'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text('ออกจากระบบ',
                            style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                await AuthService().signOut();
                // Navigation to LoginScreen is handled by StreamBuilder in main.dart
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'สินค้า',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'ตะกร้า',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'คำสั่งซื้อ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
