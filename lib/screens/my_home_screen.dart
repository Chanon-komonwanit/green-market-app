import 'package:flutter/material.dart';
import 'package:green_market/screens/chat_screen.dart';
import 'package:green_market/screens/cart_screen.dart';
// import 'package:green_market/widgets/test_eco_widget.dart';
import 'package:green_market/widgets/green_world_icon.dart';
import 'package:green_market/widgets/eco_coins_widget.dart';

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      print('🏡 DEBUG: Building MyHomeScreen');
      return Scaffold(
        backgroundColor: const Color(0xFFF3FBF4),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F5E9), Color(0xFFF3FBF4)],
              ),
            ),
            child: Column(
              children: [
                // User Info Section
                _UserInfoHeaderModern(),
                const SizedBox(height: 14),
                // Eco Coins Zone
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    children: const [
                      EcoCoinsWidget(),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'เหรียญ Eco Coins ของคุณ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF388E3C)),
                        ),
                      ),
                      Icon(Icons.emoji_events,
                          color: Color(0xFFFFD700), size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _QuickActionsModern(),
                const SizedBox(height: 14),
                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF2E7D32),
                    unselectedLabelColor: Colors.grey,
                    indicator: BoxDecoration(
                      color: const Color(0xFFB2DFDB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorWeight: 0,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: '🏡 Me Home', icon: Icon(Icons.home_rounded)),
                      Tab(text: 'แชท', icon: Icon(Icons.chat_bubble_outline)),
                      Tab(
                        text: 'เปิดโลกสีเขียว',
                        icon: GreenWorldIcon(),
                      ),
                      Tab(
                          text: 'แจ้งเตือน',
                          icon: Icon(Icons.notifications_none)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // TabBarView must be inside an Expanded to avoid layout errors
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _TabErrorBoundary(child: _MyActivityTab()),
                      _TabErrorBoundary(
                        child: ChatScreen(
                          chatId: null, // หรือใส่ chatId ที่ต้องการ
                          productId: 'test_product', // ตัวอย่าง id
                          productName: 'สินค้า Eco',
                          productImageUrl: '',
                          buyerId: 'test_buyer',
                          sellerId: 'test_seller',
                        ),
                      ),
                      _TabErrorBoundary(child: _CartTab()),
                      _TabErrorBoundary(child: _NotificationTab()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Show error widget if build fails
      print('🏡 ERROR: MyHomeScreen build failed: $e');
      print('🏡 ERROR: Stack trace: ${StackTrace.current}');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text('เกิดข้อผิดพลาดในการแสดงผล',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyHomeScreen(),
                    ),
                  );
                },
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// --- Modern User Info Header ---
class _UserInfoHeaderModern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: Colors.white.withOpacity(0.98),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.home_rounded,
                    color: Color(0xFF388E3C), size: 38),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Text('My Eco Home',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color(0xFF1B5E20))),
                        SizedBox(width: 8),
                        Icon(Icons.verified,
                            color: Color(0xFF43A047), size: 20),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text('ระดับ: Eco Hero',
                            style: TextStyle(
                                color: Color(0xFF388E3C), fontSize: 15)),
                        SizedBox(width: 8),
                        // Eco badge widget
                        // TestEcoWidget(),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.grey[600]),
                onPressed: () {},
                tooltip: 'ตั้งค่า',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Modern Dashboard Stats ---

// --- Modern Quick Actions ---
class _QuickActionsModern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickAction(Icons.add_box, 'เพิ่มสินค้า', Color(0xFF388E3C)),
          _buildQuickAction(Icons.list_alt, 'ออเดอร์ของฉัน', Color(0xFF1976D2)),
          _buildQuickAction(Icons.reviews, 'รีวิว', Color(0xFF8E24AA)),
          _buildQuickAction(
              Icons.card_giftcard, 'โค้ดส่วนลดของฉัน', Color(0xFFFB8C00)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(13),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 7),
        Text(label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MyActivityTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('กิจกรรมล่าสุด',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // ตัวอย่างรายการกิจกรรม (mock)
    final List<Map<String, dynamic>> activities = [
      {
        'icon': Icons.shopping_bag,
        'title': 'สั่งซื้อสินค้า #1234',
        'time': '2 ชม.ที่แล้ว',
        'type': 'order',
        'orderId': '1234',
      },
      {
        'icon': Icons.receipt_long,
        'title': 'คำสั่งซื้อ #5678',
        'time': '1 ชม.ที่แล้ว',
        'type': 'order',
        'orderId': '5678',
      },
      {
        'icon': Icons.chat,
        'title': 'แชทกับร้าน GreenShop',
        'time': '5 ชม.ที่แล้ว',
        'type': 'chat',
      },
      {
        'icon': Icons.star,
        'title': 'ให้คะแนนสินค้า',
        'time': 'เมื่อวาน',
        'type': 'review',
      },
    ];
    if (activities.isEmpty) {
      return const Center(
        child: Text('ยังไม่มีกิจกรรม', style: TextStyle(color: Colors.grey)),
      );
    }
    print('DEBUG: Rendering activities:');
    for (final a in activities) {
      print(' - ${a['title']} (${a['type']})');
    }
    return Column(
      children: activities.map((a) {
        final icon = a['icon'];
        final title = a['title']?.toString() ?? '-';
        final time = a['time']?.toString() ?? '';
        final type = a['type']?.toString();
        final orderId = a['orderId']?.toString();
        return ListTile(
          leading: icon is IconData
              ? Icon(icon, color: Colors.teal)
              : const Icon(Icons.info_outline, color: Colors.teal),
          title: Text('[${type ?? ''}] $title',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
          subtitle: Text(time, style: const TextStyle(fontSize: 12)),
          contentPadding: EdgeInsets.zero,
          dense: true,
          trailing: type == 'order' && orderId != null
              ? ElevatedButton(
                  onPressed: () {
                    print('DEBUG: Clicked order $orderId');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text('ดูคำสั่งซื้อ'),
                )
              : null,
        );
      }).toList(),
    );
  }
}

// --- Cart Tab with market-style product details ---
class _CartTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real cart data from provider/service
    final List<Map<String, dynamic>> cartItems = [
      {
        'image':
            'https://cdn.pixabay.com/photo/2017/01/20/15/06/vegetables-1995056_1280.jpg',
        'name': 'ผักกาดหอม',
        'price': 35,
        'qty': 2,
        'desc': 'ผักสดปลอดสารพิษจากฟาร์ม',
      },
      {
        'image':
            'https://cdn.pixabay.com/photo/2016/03/05/19/02/hot-pepper-1239426_1280.jpg',
        'name': 'พริกแดง',
        'price': 20,
        'qty': 1,
        'desc': 'พริกแดงสดใหม่จากสวน',
      },
    ];
    if (cartItems.isEmpty) {
      return const Center(
        child: Text('ยังไม่มีสินค้าในตะกร้า',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: cartItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, i) {
        final item = cartItems[i];
        final image = item['image'];
        final name = item['name']?.toString() ?? '-';
        final desc = item['desc']?.toString() ?? '';
        final price = item['price'] ?? 0;
        final qty = item['qty'] ?? 0;
        Widget imageWidget;
        if (image is String &&
            (image.startsWith('http') || image.startsWith('https'))) {
          imageWidget = Image.network(image,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) =>
                  const Icon(Icons.broken_image, size: 60, color: Colors.grey));
        } else if (image is String) {
          imageWidget =
              Image.asset(image, width: 90, height: 90, fit: BoxFit.cover);
        } else {
          imageWidget = const Icon(Icons.image, size: 60, color: Colors.grey);
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: imageWidget,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF222222)),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(desc,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('฿$price x$qty',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                  fontSize: 15)),
                          const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
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
  }
}

// --- Notification Tab (placeholder) ---
class _NotificationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('ยังไม่มีการแจ้งเตือน',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// --- Tab Error Boundary Widget ---
class _TabErrorBoundary extends StatefulWidget {
  final Widget child;
  const _TabErrorBoundary({required this.child});

  @override
  State<_TabErrorBoundary> createState() => _TabErrorBoundaryState();
}

class _TabErrorBoundaryState extends State<_TabErrorBoundary> {
  Object? _error;
  // Removed unused _stackTrace field

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text('เกิดข้อผิดพลาดในแท็บนี้',
                  style: TextStyle(fontSize: 18, color: Colors.red)),
              const SizedBox(height: 8),
              Text(_error.toString(),
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                },
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }
    try {
      return widget.child;
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = e;
          });
        }
      });
      return const SizedBox.shrink();
    }
  }
}
