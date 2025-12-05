import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart';
import 'cart_screen.dart';
import 'edit_profile_screen.dart';
import 'user/enhanced_edit_profile_screen.dart';
import 'notifications_center_screen.dart';
import 'orders_screen.dart';
import 'profile/my_coupons_screen.dart';
import 'customer_shipping_dashboard_screen.dart';
import 'seller/seller_dashboard_screen.dart';
import 'seller/seller_application_form_screen.dart';
import 'eco_rewards_screen.dart';
import 'product_detail_screen.dart';

import '../widgets/modern_home_header.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/smart_eco_hero_tab.dart';
import '../widgets/product_card.dart';

import '../providers/cart_provider_enhanced.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';

import '../models/order.dart' as app_order;
import '../models/product.dart';
import '../models/cart_item.dart' as app_cart;
import '../utils/constants.dart';

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
        length: 4, vsync: this); // 4 แท็บ: ตะกร้า, Eco Hero, แชท, การแจ้งเตือน
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // TabBar Section (4 แท็บ) - ย้ายขึ้นมาด้านบน
            _buildTabBarSection(),

            // TabBarView Content (4 แท็บ) พร้อม Header ข้างใน
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCartTabWithHeader(),
                  _buildEcoHeroTab(),
                  _buildChatTab(),
                  _buildNotificationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Build Methods ===

  Widget _buildModernHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        return Semantics(
          label: 'ส่วนหัวโปรไฟล์',
          child: ModernHomeHeader(
            title: currentUser?.displayName ?? 'Green Market',
            subtitle: 'ตลาดสีเขียวเพื่อชุมชน',
            avatarUrl: currentUser?.photoUrl,
            ecoCoins: currentUser?.ecoCoins.floor(),
            isVerified:
                currentUser?.isAdmin == true || currentUser?.isSeller == true,
            onProfileTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedEditProfileScreen(),
                ),
              );
            },
            actions: [
              // ปุ่มแจ้งเตือน
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF059669),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsCenterScreen(),
                    ),
                  );
                },
              ),
              // ปุ่มการตั้งค่า
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF059669),
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
        );
      },
    );
  }

  Widget _buildEcoCoinsSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final ecoCoinCount = currentUser?.ecoCoins ?? 0;
        final equivalentBaht = (ecoCoinCount * 0.01);

        return GestureDetector(
          onTap: () {
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
                  Color(0xFFFFD700),
                  Color(0xFFFFF8DC),
                  Color(0xFFFFE55C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFB8860B),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // กล่องแสดงเหรียญ
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
                        // ไอคอนเหรียญ
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD700),
                                Color(0xFFFFA500),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ecoCoinCount.toInt()}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8860B),
                              ),
                            ),
                            Text(
                              '🪙 เหรียญ Eco',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ข้อมูลมูลค่า
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'มูลค่า: ฿${equivalentBaht.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getUserLevel(ecoCoinCount),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ไอคอนลูกศร
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
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

                // แถวที่ 1: ออเดอร์ และ คูปองส่วนลด
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.shopping_bag_outlined,
                        label: 'ออเดอร์ของฉัน',
                        color: const Color(0xFF059669),
                        onTap: () => _navigateToOrders(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.discount_outlined,
                        label: 'คูปองส่วนลด',
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
                    Expanded(
                      child: Consumer<CartProviderEnhanced>(
                        builder: (context, cartProvider, child) {
                          final totalItems = cartProvider.totalItemsInCart;
                          final totalAmount = cartProvider.totalAmount;

                          return _buildQuickActionButton(
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
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.local_shipping_outlined,
                        label: 'การจัดส่ง',
                        color: const Color(0xFF0891B2),
                        onTap: () => _navigateToShipping(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ปุ่มเปิดร้านค้า (สำหรับผู้ที่ไม่ใช่ผู้ขาย)
                if (currentUser?.isSeller != true) _buildOpenShopButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBarSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF059669),
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF059669),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(
            icon: Icon(Icons.shopping_cart_outlined, size: 24),
            child:
                Text('ตะกร้า', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Tab(
            icon: Icon(Icons.emoji_events_outlined, size: 24),
            child:
                Text('Eco Hero', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Tab(
            icon: Icon(Icons.chat_bubble_outline, size: 24),
            child: Text('แชท', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Tab(
            icon: Icon(Icons.notifications_outlined, size: 24),
            child: Text('การแจ้งเตือน',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // === Tab Content Methods ===

  // ============================================================
  // 4️⃣ Cart Tab with Header (ตะกร้าพร้อม Header)
  // ============================================================

  Widget _buildCartTabWithHeader() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ส่วนหัวโปรไฟล์ (Modern Header พร้อมการแจ้งเตือน)
          _buildModernHeader(),

          const SizedBox(height: 10),

          // Eco Coins Section (ปรับปรุงใหม่ครบถ้วน)
          _buildEcoCoinsSection(),

          const SizedBox(height: 10),

          // Quick Actions (ปรับปรุงใหม่ครบถ้วน)
          _buildQuickActionsSection(),

          const SizedBox(height: 10),

          // Cart Content
          SizedBox(
            height: 600,
            child: _buildCartTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTab() {
    return Consumer<CartProviderEnhanced>(
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
            // ส่วนสรุปยอด
            ModernCard(
              color: const Color(0xFF2E7D32),
              borderRadius: 16,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            // รายการสินค้า
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = cartItems[index];
                  final product = cartItem.product;

                  return _buildCartItemCard(cartItem, product, cartProvider);
                },
              ),
            ),

            // ปุ่มชำระเงิน
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEcoHeroTab() {
    // ใช้ Smart Eco Hero System ตาม documentation
    return FutureBuilder<List<Product>>(
      future: _getEcoHeroProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.green[50],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดสินค้า Eco Hero...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final ecoHeroProducts = snapshot.data ?? [];

        return Container(
          color: Colors.green[50],
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section พร้อมข้อมูล AI
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                        Color(0xFF334155),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Smart Eco Hero AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'AI แนะนำ ${ecoHeroProducts.length} รายการ',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Products Grid หรือข้อความว่าง
                if (ecoHeroProducts.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: ecoHeroProducts.length,
                    itemBuilder: (context, index) {
                      final product = ecoHeroProducts[index];
                      return _buildEcoHeroProductCard(product);
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.eco_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'ยังไม่มีสินค้าระดับ Eco Hero',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'รอสินค้าเยี่ยมจากผู้ขายของเรา',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEcoHeroProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFFAF0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image พร้อม Eco Hero Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(
                            product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 30),
                          )
                        : const Icon(Icons.shopping_bag,
                            size: 30, color: Colors.grey),
                  ),
                ),
                // Eco Hero Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'HERO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Eco Score
                    Row(
                      children: [
                        const Icon(Icons.eco,
                            size: 14, color: Color(0xFFFFD700)),
                        const SizedBox(width: 4),
                        Text(
                          '${product.ecoScore}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ราคา
                    Text(
                      '฿${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method สำหรับดึงข้อมูลสินค้า Eco Hero
  Future<List<Product>> _getEcoHeroProducts() async {
    try {
      // ใช้ Firebase Service static method
      final allProducts = await FirebaseService.getProducts(limit: 50);

      // กรองสินค้าระดับ Hero และ Premium เท่านั้น
      final ecoProducts = allProducts
          .where((product) =>
              product.ecoLevel == EcoLevel.hero ||
              (product.ecoLevel == EcoLevel.premium && product.ecoScore >= 80))
          .toList();

      // เรียงตาม eco score และเลือก 8 อันแรก
      ecoProducts.sort((a, b) => b.ecoScore.compareTo(a.ecoScore));
      return ecoProducts.take(8).toList();
    } catch (e) {
      // Fallback กรณี error - ส่งค่า list ว่างเพื่อแสดงหน้า "ยังไม่มีสินค้า"
      return <Product>[];
    }
  }

  Widget _buildChatTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUserId = userProvider.currentUser?.id ?? 'user1';

        // Mock data สำหรับแชท
        final mockChatList = [
          {
            'id': 'chat1',
            'participants': ['user1', 'user2'],
            'lastMessage': 'สวัสดีครับ สนใจสินค้า',
            'lastMessageTime': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            'isRead': false,
          },
          {
            'id': 'chat2',
            'participants': ['user1', 'user3'],
            'lastMessage': 'ขอบคุณสำหรับการสั่งซื้อ',
            'lastMessageTime': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 2)),
            ),
            'isRead': true,
          },
        ];

        if (mockChatList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('ยังไม่มีแชท',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('เริ่มสนทนากับผู้ขายหรือผู้ซื้อ',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: mockChatList.length,
          itemBuilder: (context, index) {
            final chat = mockChatList[index];
            return _buildChatListItem(
              chatId: chat['id'].toString(),
              chatData: chat,
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
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
                Text('กรุณาเข้าสู่ระบบ',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('เพื่อดูการแจ้งเตือน',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        // Mock notifications data
        final mockNotifications = [
          {
            'id': 'notif1',
            'title': 'คำสั่งซื้อใหม่',
            'message': 'คุณมีคำสั่งซื้อใหม่ รหัส #12345',
            'type': 'order',
            'timestamp': Timestamp.fromDate(
                DateTime.now().subtract(const Duration(minutes: 10))),
            'isRead': false,
          },
          {
            'id': 'notif2',
            'title': 'โปรโมชันใหม่!',
            'message': 'ลด 20% สำหรับสินค้าเพื่อสิ่งแวดล้อม',
            'type': 'promotion',
            'timestamp': Timestamp.fromDate(
                DateTime.now().subtract(const Duration(hours: 1))),
            'isRead': true,
          },
        ];

        if (mockNotifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_outlined,
                    size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('ไม่มีการแจ้งเตือน',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('การแจ้งเตือนจะแสดงที่นี่',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: mockNotifications.length,
          itemBuilder: (context, index) {
            final notification = mockNotifications[index];
            return _buildNotificationItem(notification);
          },
        );
      },
    );
  }

  // === Support Widget Methods ===

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
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
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenShopButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SellerApplicationFormScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.storefront, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🪙 เปิดร้านค้าของคุณ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'เริ่มขายสินค้าเพื่อสิ่งแวดล้อม',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(
      dynamic cartItem, Product product, CartProviderEnhanced cartProvider) {
    return ModernCard(
      color: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // รูปสินค้า
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.imageUrls.isNotEmpty
                ? Image.network(
                    product.imageUrls.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[100],
                      child:
                          const Icon(Icons.image, size: 30, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[100],
                    child:
                        const Icon(Icons.image, size: 30, color: Colors.grey),
                  ),
          ),

          const SizedBox(width: 12),

          // ข้อมูลสินค้า
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
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

                // ส่วนควบคุมจำนวน และลบสินค้า
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ปุ่มควบคุมจำนวน
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (cartItem.quantity > 1) {
                              cartProvider.updateItemQuantity(
                                  product.id, cartItem.quantity - 1);
                            } else {
                              cartProvider.removeItem(product.id);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFF2E7D32)),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${cartItem.quantity}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            cartProvider.updateItemQuantity(
                                product.id, cartItem.quantity + 1);
                          },
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF2E7D32)),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),

                    // ปุ่มลบ
                    GestureDetector(
                      onTap: () {
                        cartProvider.removeItem(product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('ลบ ${product.name} ออกจากตะกร้าแล้ว'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF43A047),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
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
  }

  Widget _buildChatListItem({
    required String chatId,
    required Map<String, dynamic> chatData,
    required String currentUserId,
  }) {
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
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
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
        onTap: () => _showChatDialog(context, otherUserId),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool? ?? true;
    final type = notification['type'] as String? ?? 'general';
    final timestamp = notification['timestamp'] as Timestamp?;

    IconData getIconByType(String type) {
      switch (type) {
        case 'order':
          return Icons.shopping_bag_outlined;
        case 'promotion':
          return Icons.local_offer_outlined;
        case 'eco_coins':
          return Icons.eco_outlined;
        case 'chat':
          return Icons.chat_bubble_outline;
        default:
          return Icons.notifications_outlined;
      }
    }

    Color getColorByType(String type) {
      switch (type) {
        case 'order':
          return const Color(0xFF2E7D32);
        case 'promotion':
          return const Color(0xFFE91E63);
        case 'eco_coins':
          return const Color(0xFFFFD700);
        case 'chat':
          return const Color(0xFF2196F3);
        default:
          return const Color(0xFF6B7280);
      }
    }

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
              : getColorByType(type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: getColorByType(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Icon(getIconByType(type), color: getColorByType(type), size: 24),
        ),
        title: Text(
          notification['title'] as String? ?? 'การแจ้งเตือน',
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
            const SizedBox(height: 4),
            Text(
              notification['message'] as String? ?? 'ไม่มีข้อความ',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: isRead
            ? const Icon(Icons.chevron_right, color: Colors.grey)
            : Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: getColorByType(type), shape: BoxShape.circle),
                child: const Icon(Icons.circle, color: Colors.white, size: 8),
              ),
        onTap: () => _showNotificationDialog(context, notification),
      ),
    );
  }

  // === Helper Methods ===

  String _getUserLevel(double ecoCoins) {
    final coinsInt = ecoCoins.round();
    if (coinsInt >= 1000) {
      return 'Eco Legend ⭐';
    } else if (coinsInt >= 500) {
      return 'Eco Master 🏆';
    } else if (coinsInt >= 200) {
      return 'Eco Hero 🌟';
    } else if (coinsInt >= 50) {
      return 'Eco Friend 🌱';
    } else {
      return 'มือใหม่ 🌿';
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

  // === Navigation Methods ===

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

  void _navigateToCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  // === Dialog Methods ===

  void _showCoupons(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Color(0xFFE91E63)),
            SizedBox(width: 8),
            Text('คูปองส่วนลดของฉัน'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('คุณยังไม่มีคูปองส่วนลดในขณะนี้'),
            SizedBox(height: 8),
            Text(
              'กิจกรรมโปรโมชันจะมีคูปองส่วนลดให้เร็วๆ นี้',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
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

  void _showChatDialog(BuildContext context, String otherUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const Icon(Icons.chat_outlined, size: 60, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            Text('แชทกับ: $otherUserId'),
            const SizedBox(height: 8),
            const Text(
              'ฟีเจอร์แชทจะถูกพัฒนาเพิ่มเติมในเวอร์ชันต่อไป',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
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

  void _showNotificationDialog(
      BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications_outlined, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification['title'] as String? ?? 'การแจ้งเตือน',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'] as String? ?? 'ไม่มีข้อความ',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'เวลา: ${_formatTimestamp(notification['timestamp'] as Timestamp? ?? Timestamp.now())}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
}
