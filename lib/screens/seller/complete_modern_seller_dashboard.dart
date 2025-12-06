// lib/screens/seller/complete_modern_seller_dashboard.dart
// 🎨 Complete Modern Seller Dashboard - เชื่อมต่อทุกระบบครบถ้วน

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import ทุก Screen ที่จำเป็น
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:green_market/screens/seller/enhanced_shipping_management_screen.dart';
import 'package:green_market/screens/seller/wallet_screen.dart';
import 'package:green_market/screens/seller/shop_analytics_screen.dart';
import 'package:green_market/screens/seller/complete_shop_theme_system.dart';
import 'package:green_market/screens/seller/advanced_promotions_screen.dart';
import 'package:green_market/screens/seller/coupon_management_screen.dart';
import 'package:green_market/screens/seller/preview_my_shop_screen.dart';
import 'package:green_market/screens/seller/auto_reply_settings_screen.dart';
import 'package:green_market/screens/seller/return_refund_management_screen.dart';
import 'package:green_market/screens/seller/advanced_stock_management_screen.dart';
import 'package:green_market/screens/seller/customer_management_screen.dart';
import 'package:green_market/screens/seller/review_management_screen.dart';
import 'package:green_market/screens/seller/seller_notifications_screen.dart';
import 'package:green_market/screens/chat_list_screen.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/widgets/quick_stock_update_widget.dart';
import 'package:green_market/theme/app_colors.dart';

class CompleteModernSellerDashboard extends StatefulWidget {
  const CompleteModernSellerDashboard({super.key});

  @override
  State<CompleteModernSellerDashboard> createState() =>
      _CompleteModernSellerDashboardState();
}

class _CompleteModernSellerDashboardState
    extends State<CompleteModernSellerDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isSidebarCollapsed = false;
  Map<String, dynamic> _stats = {};
  String? _sellerId;
  String? _sellerName;
  String? _shopImageUrl;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _notificationsSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    _loadDashboardData();
    _setupRealTimeListeners();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _messagesSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ===== REAL-TIME DATA LISTENERS =====
  void _setupRealTimeListeners() {
    if (_sellerId == null) return;

    // Listen to orders
    _ordersSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: _sellerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _stats['pendingOrders'] = snapshot.docs.length;
        });
      }
    });

    // Listen to unread messages
    _messagesSubscription = FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('participants', arrayContains: _sellerId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        int unreadCount = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
          if (unreadMap != null && unreadMap[_sellerId] != null) {
            unreadCount += (unreadMap[_sellerId] as int);
          }
        }
        setState(() {
          _stats['unreadMessages'] = unreadCount;
        });
      }
    });

    // Listen to notifications
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _sellerId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _stats['unreadNotifications'] = snapshot.docs.length;
        });
      }
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      if (_sellerId != null) {
        // Load seller info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_sellerId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          _sellerName = data?['displayName'] ?? 'ผู้ขาย';
          _shopImageUrl = data?['photoURL'];
        }

        // Load comprehensive stats
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Products count
        final productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: _sellerId)
            .get();

        final totalProducts = productsSnapshot.docs.length;
        final activeProducts = productsSnapshot.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length;
        final lowStockProducts = productsSnapshot.docs
            .where((doc) => (doc.data()['stock'] ?? 0) < 5)
            .length;

        // Orders stats
        int pendingOrders = 0;
        int todayOrders = 0;
        double todaySales = 0.0;
        double totalRevenue = 0.0;

        try {
          final ordersSnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .where('sellerId', isEqualTo: _sellerId)
              .get();

          for (var doc in ordersSnapshot.docs) {
            final data = doc.data();
            final status = data['status'] as String?;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final total = (data['totalPrice'] ?? 0.0) as num;

            if (status == 'pending') pendingOrders++;

            if (createdAt != null && createdAt.isAfter(today)) {
              todayOrders++;
              todaySales += total.toDouble();
            }

            if (status == 'completed') {
              totalRevenue += total.toDouble();
            }
          }
        } catch (e) {
          print('Orders query error: $e');
        }

        _stats = {
          'totalProducts': totalProducts,
          'activeProducts': activeProducts,
          'lowStockProducts': lowStockProducts,
          'pendingOrders': pendingOrders,
          'todayOrders': todayOrders,
          'todaySales': todaySales,
          'totalRevenue': totalRevenue,
          'unreadMessages': _stats['unreadMessages'] ?? 0,
          'unreadNotifications': _stats['unreadNotifications'] ?? 0,
        };
      }
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          _buildLeftSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== LEFT SIDEBAR =====
  Widget _buildLeftSidebar() {
    final sidebarWidth = _isSidebarCollapsed ? 70.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo & Shop Info
          _buildShopHeader(),

          const SizedBox(height: 20),

          // Toggle Button
          if (!_isSidebarCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IconButton(
                icon: const Icon(Icons.menu_open, color: Colors.white),
                onPressed: () {
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                },
              ),
            ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _buildMenuItems(),
            ),
          ),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildShopHeader() {
    if (_isSidebarCollapsed) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Icon(Icons.store, color: Colors.white, size: 30),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Shop Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _shopImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      _shopImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.store,
                    size: 40,
                    color: AppColors.primary,
                  ),
          ),

          const SizedBox(height: 12),

          // Shop Name
          Text(
            _sellerName ?? 'ร้านค้า',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // View Shop Button
          ElevatedButton.icon(
            onPressed: () {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreviewMyShopScreen(
                    sellerId: _sellerId ?? '',
                    sellerName:
                        userProvider.currentUser?.displayName ?? 'ร้านค้า',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('ดูหน้าร้าน'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final menuSections = [
      {
        'title': 'หน้าหลัก',
        'items': [
          _MenuItem(0, Icons.dashboard, 'ภาพรวม', null),
          _MenuItem(1, Icons.storefront, 'ดูหน้าร้าน', AppColors.warning),
        ]
      },
      {
        'title': 'จัดการสินค้า',
        'items': [
          _MenuItem(2, Icons.inventory_2, 'สินค้าทั้งหมด', null),
          _MenuItem(3, Icons.add_circle, 'เพิ่มสินค้า', AppColors.success),
          _MenuItem(4, Icons.warehouse, 'จัดการสต็อก', null,
              badge: _stats['lowStockProducts'] ?? 0),
        ]
      },
      {
        'title': 'คำสั่งซื้อ',
        'items': [
          _MenuItem(5, Icons.shopping_bag, 'คำสั่งซื้อ', null,
              badge: _stats['pendingOrders'] ?? 0),
          _MenuItem(6, Icons.local_shipping, 'การจัดส่ง', null),
          _MenuItem(7, Icons.assignment_return, 'คืนสินค้า/เงิน', null),
        ]
      },
      {
        'title': 'การสื่อสาร',
        'items': [
          _MenuItem(8, Icons.chat_bubble_outline, 'แชท', null,
              badge: _stats['unreadMessages'] ?? 0),
          _MenuItem(9, Icons.notifications_outlined, 'การแจ้งเตือน', null,
              badge: _stats['unreadNotifications'] ?? 0),
          _MenuItem(10, Icons.reply_all, 'Auto Reply', null),
        ]
      },
      {
        'title': 'การตลาด',
        'items': [
          _MenuItem(11, Icons.local_offer, 'โปรโมชั่น', null),
          _MenuItem(12, Icons.card_giftcard, 'คูปอง/ส่วนลด', null),
        ]
      },
      {
        'title': 'การเงิน',
        'items': [
          _MenuItem(13, Icons.account_balance_wallet, 'กระเป๋าเงิน', null),
          _MenuItem(14, Icons.analytics, 'รายงานยอดขาย', null),
        ]
      },
      {
        'title': 'ลูกค้า',
        'items': [
          _MenuItem(15, Icons.people_outline, 'จัดการลูกค้า', null),
          _MenuItem(16, Icons.star_outline, 'รีวิวสินค้า', null),
        ]
      },
      {
        'title': 'ตั้งค่า',
        'items': [
          _MenuItem(17, Icons.store, 'ตกแต่งร้าน', null),
          _MenuItem(18, Icons.settings, 'ตั้งค่าร้านค้า', null),
        ]
      },
    ];

    List<Widget> widgets = [];
    for (var section in menuSections) {
      widgets.add(_buildMenuSection(
        section['title'] as String,
        section['items'] as List<_MenuItem>,
      ));
      widgets.add(const Divider(color: Colors.white24, height: 30));
    }

    return widgets;
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    if (_isSidebarCollapsed) {
      return Column(
        children: items.map((item) => _buildMenuItem(item)).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => _buildMenuItem(item)),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    final isSelected = _selectedIndex == item.index;

    if (_isSidebarCollapsed) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Stack(
          children: [
            IconButton(
              icon: Icon(
                item.icon,
                color: item.highlightColor ?? Colors.white,
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isSelected ? Colors.white.withOpacity(0.2) : null,
              ),
              onPressed: () {
                setState(() => _selectedIndex = item.index);
              },
            ),
            if (item.badge != null && item.badge! > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${item.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: item.highlightColor ?? Colors.white,
          size: 24,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: item.badge != null && item.badge! > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.badge}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          setState(() => _selectedIndex = item.index);
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
      ),
      child: _isSidebarCollapsed
          ? IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            )
          : ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                'ออกจากระบบ',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
    );
  }

  // ===== TOP BAR =====
  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Toggle sidebar button
          if (_isSidebarCollapsed)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                setState(() => _isSidebarCollapsed = false);
              },
            ),

          // Title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getPageTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                _getPageSubtitle(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Quick Stats
          _buildQuickStat(
            Icons.trending_up,
            'ยอดขายวันนี้',
            '฿${_formatNumber(_stats['todaySales'] ?? 0)}',
            Colors.green,
          ),

          const SizedBox(width: 24),

          _buildQuickStat(
            Icons.shopping_bag,
            'รอดำเนินการ',
            '${_stats['pendingOrders'] ?? 0}',
            Colors.orange,
          ),

          const SizedBox(width: 24),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'รีเฟรช',
          ),

          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 28),
                if ((_stats['unreadNotifications'] ?? 0) > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_stats['unreadNotifications']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() => _selectedIndex = 9);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== MAIN CONTENT =====
  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0: // ภาพรวม
        return _buildDashboardContent();
      case 1: // ดูหน้าร้าน
        return _buildPreviewShop();
      case 2: // สินค้าทั้งหมด
        return const MyProductsScreen();
      case 3: // เพิ่มสินค้า
        return const AddProductScreen();
      case 4: // จัดการสต็อก
        return const AdvancedStockManagementScreen();
      case 5: // คำสั่งซื้อ
        return const SellerOrdersScreen();
      case 6: // การจัดส่ง
        return const EnhancedShippingManagementScreen();
      case 7: // คืนสินค้า/เงิน
        return const ReturnRefundManagementScreen();
      case 8: // แชท
        return const ChatListScreen();
      case 9: // การแจ้งเตือน
        return const SellerNotificationsScreen();
      case 10: // Auto Reply
        return const AutoReplySettingsScreen();
      case 11: // โปรโมชั่น
        return const AdvancedPromotionsScreen();
      case 12: // คูปอง/ส่วนลด
        return const CouponManagementScreen();
      case 13: // กระเป๋าเงิน
        return const WalletScreen();
      case 14: // รายงานยอดขาย
        return const ShopAnalyticsScreen();
      case 15: // จัดการลูกค้า
        return const CustomerManagementScreen();
      case 16: // รีวิวสินค้า
        return const ReviewManagementScreen();
      case 17: // ตกแต่งร้าน
        return CompleteShopThemeSystem(sellerId: _sellerId ?? '');
      case 18: // ตั้งค่าร้านค้า
        return const ShopSettingsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            _buildWelcomeBanner(),

            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsCards(),

            const SizedBox(height: 24),

            // Quick Stock Update
            const QuickStockUpdateWidget(),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),

            const SizedBox(height: 24),

            // Recent Products
            _buildRecentProducts(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    final hour = DateTime.now().hour;
    String greeting = 'สวัสดี';
    IconData greetingIcon = Icons.wb_sunny;

    if (hour < 12) {
      greeting = 'สวัสดีตอนเช้า';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'สวัสดีตอนบ่าย';
      greetingIcon = Icons.wb_sunny;
    } else {
      greeting = 'สวัสดีตอนเย็น';
      greetingIcon = Icons.nights_stay;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(greetingIcon, color: Colors.white, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${_sellerName ?? 'ผู้ขาย'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'วันนี้มีคำสั่งซื้อ ${_stats['todayOrders'] ?? 0} รายการ • ยอดขาย ฿${_formatNumber(_stats['todaySales'] ?? 0)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'สินค้าล่าสุด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 2),
              child: const Text('ดูทั้งหมด'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('sellerId', isEqualTo: _sellerId)
              .orderBy('createdAt', descending: true)
              .limit(4)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final products = snapshot.data!.docs;

            if (products.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'ยังไม่มีสินค้า',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'เริ่มเพิ่มสินค้าแรกของคุณวันนี้!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _selectedIndex = 3),
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มสินค้า'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final data = products[index].data() as Map<String, dynamic>;
                final name = data['name'] ?? 'ไม่มีชื่อ';
                final price = data['price'] ?? 0;
                final stock = data['stock'] ?? 0;
                final images = data['images'] as List<dynamic>? ?? [];
                final isActive = data['isActive'] ?? true;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Stack(
                        children: [
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: images.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      images[0],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                          ),
                          // Status Badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'เปิดขาย' : 'ปิดขาย',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Product Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                '฿${_formatNumber(price)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.inventory,
                                    size: 14,
                                    color: stock < 5 ? Colors.red : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'คงเหลือ: $stock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: stock < 5
                                          ? Colors.red
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'title': 'ยอดขายวันนี้',
        'value': '฿${_formatNumber(_stats['todaySales'] ?? 0)}',
        'icon': Icons.trending_up,
        'color': const Color(0xFF10B981),
        'trend': '+12.5%',
      },
      {
        'title': 'รอดำเนินการ',
        'value': '${_stats['pendingOrders'] ?? 0}',
        'icon': Icons.pending_actions,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'สินค้าทั้งหมด',
        'value': '${_stats['totalProducts'] ?? 0}',
        'icon': Icons.inventory,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'รายได้รวม',
        'value': '฿${_formatNumber(_stats['totalRevenue'] ?? 0)}',
        'icon': Icons.attach_money,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive columns
        int columns = 4;
        if (constraints.maxWidth < 1200) columns = 3;
        if (constraints.maxWidth < 900) columns = 2;
        if (constraints.maxWidth < 600) columns = 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2, // เพิ่มความสูง
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(
              stat['title'] as String,
              stat['value'] as String,
              stat['icon'] as IconData,
              stat['color'] as Color,
              stat['trend'] as String?,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          // Value & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trend != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trend,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'เพิ่มสินค้า',
        'icon': Icons.add_box,
        'color': AppColors.success,
        'index': 3
      },
      {
        'title': 'ดูคำสั่งซื้อ',
        'icon': Icons.shopping_cart,
        'color': AppColors.primary,
        'index': 5
      },
      {
        'title': 'แชทกับลูกค้า',
        'icon': Icons.chat,
        'color': AppColors.info,
        'index': 8
      },
      {
        'title': 'สถิติร้านค้า',
        'icon': Icons.analytics,
        'color': AppColors.info,
        'index': 14
      },
      {
        'title': 'สร้างโปรโมชั่น',
        'icon': Icons.local_offer,
        'color': AppColors.warning,
        'index': 11
      },
      {
        'title': 'ตกแต่งร้าน',
        'icon': Icons.palette,
        'color': AppColors.warning,
        'index': 17
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การดำเนินการด่วน',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return InkWell(
              onTap: () =>
                  setState(() => _selectedIndex = action['index'] as int),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (action['color'] as Color).withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreviewShop() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return PreviewMyShopScreen(
      sellerId: _sellerId ?? '',
      sellerName: userProvider.currentUser?.displayName ?? 'ร้านค้า',
    );
  }

  // ===== HELPER METHODS =====
  String _getPageTitle() {
    const titles = [
      'ภาพรวม',
      'หน้าร้าน',
      'สินค้าทั้งหมด',
      'เพิ่มสินค้า',
      'จัดการสต็อก',
      'คำสั่งซื้อ',
      'การจัดส่ง',
      'คืนสินค้า/เงิน',
      'แชท',
      'การแจ้งเตือน',
      'Auto Reply',
      'โปรโมชั่น',
      'คูปอง/ส่วนลด',
      'กระเป๋าเงิน',
      'รายงานยอดขาย',
      'จัดการลูกค้า',
      'รีวิวสินค้า',
      'ตกแต่งร้าน',
      'ตั้งค่าร้านค้า',
    ];
    return titles[_selectedIndex];
  }

  String _getPageSubtitle() {
    const subtitles = [
      'สรุปข้อมูลร้านค้าของคุณ',
      'ดูตัวอย่างหน้าร้านของคุณ',
      'จัดการสินค้าทั้งหมด',
      'เพิ่มสินค้าใหม่',
      'ตรวจสอบและอัปเดตสต็อก',
      'จัดการคำสั่งซื้อทั้งหมด',
      'จัดการการจัดส่งสินค้า',
      'จัดการคำขอคืนสินค้าและเงิน',
      'สนทนากับลูกค้า',
      'ดูการแจ้งเตือนทั้งหมด',
      'ตั้งค่าการตอบกลับอัตโนมัติ',
      'สร้างและจัดการโปรโมชั่น',
      'จัดการคูปองและส่วนลด',
      'ดูยอดเงินและธุรกรรม',
      'รายงานและสถิติยอดขาย',
      'ดูและจัดการข้อมูลลูกค้า',
      'จัดการรีวิวและคะแนนสินค้า',
      'ปรับแต่งหน้าร้านของคุณ',
      'ตั้งค่าข้อมูลร้านค้า',
    ];
    return subtitles[_selectedIndex];
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final number = value is num ? value : 0;
    return NumberFormat('#,##0.00').format(number);
  }
}

// ===== MENU ITEM CLASS =====
class _MenuItem {
  final int index;
  final IconData icon;
  final String title;
  final Color? highlightColor;
  final int? badge;

  _MenuItem(this.index, this.icon, this.title, this.highlightColor,
      {this.badge});
}
