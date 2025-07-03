import 'package:flutter/material.dart';
import 'package:green_market/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/promotion.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/screens/category_products_screen.dart';
import 'package:green_market/screens/product_detail_screen.dart';
// import 'package:green_market/screens/eco_level_products_screen.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';
import 'package:green_market/screens/admin/complete_admin_panel_screen.dart';
import 'package:green_market/widgets/eco_coins_widget.dart';
import 'package:green_market/widgets/enhanced_eco_coins_widget.dart';
import 'package:green_market/widgets/green_world_icon.dart';
import 'package:green_market/widgets/animated_green_world_button.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/thai_fuzzy_search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _homeDataFuture;
  Category? _selectedCategory; // สำหรับเก็บหมวดหมู่ที่เลือก
  EcoLevel? _selectedEcoLevel; // สำหรับเก็บ EcoLevel ที่เลือก
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ecoSearchController =
      TextEditingController(); // สำหรับ EcoLevel search
  String _searchQuery = '';
  final String _ecoSearchQuery = ''; // สำหรับ EcoLevel search

  // เพิ่ม TabController สำหรับระดับสินค้า
  late TabController _ecoLevelTabController;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
    // สร้าง TabController สำหรับระดับสินค้า (ทั้งหมด + 4 ระดับ = 5 tabs)
    _ecoLevelTabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ecoSearchController.dispose();
    _ecoLevelTabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    print('[DEBUG] Starting _fetchHomeData()');
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // Fetch data with timeout
      print('[DEBUG] About to fetch data from Firebase...');
      final futures = await Future.wait([
        firebaseService.getCategories().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('[DEBUG] Categories timeout');
            return <Category>[];
          },
        ),
        firebaseService.getActivePromotions().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('[DEBUG] Promotions timeout');
            return <Promotion>[];
          },
        ),
        firebaseService.getApprovedProducts().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('[DEBUG] Products timeout');
            return <Product>[];
          },
        ),
      ]);

      final categories = futures[0] as List<Category>;
      final promotions = futures[1] as List<Promotion>;
      final products = futures[2] as List<Product>;

      print('[DEBUG] Data fetched successfully:');
      print('  - Categories: ${categories.length}');
      print('  - Promotions: ${promotions.length}');
      print('  - Products: ${products.length}');

      // Debug first product if available
      if (products.isNotEmpty) {
        final firstProduct = products.first;
        print('[DEBUG] First product details:');
        print('  - Name: ${firstProduct.name}');
        print('  - ID: ${firstProduct.id}');
        print('  - Image URLs: ${firstProduct.imageUrls}');
        print('  - Image URLs count: ${firstProduct.imageUrls.length}');
        if (firstProduct.imageUrls.isNotEmpty) {
          print('  - First image URL: ${firstProduct.imageUrls.first}');
        }
        print('  - Status: ${firstProduct.status}');
        print('  - EcoLevel: ${firstProduct.ecoLevel}');
      } else {
        print('[DEBUG] No products found! This is the main issue.');
      }

      return {
        'categories': categories,
        'promotions': promotions,
        'products': products,
        'showWelcome':
            products.isEmpty && categories.isEmpty && promotions.isEmpty,
      };
    } catch (e) {
      print('[DEBUG] Error fetching home data: $e');
      print('[DEBUG] Error type: ${e.runtimeType}');
      print('[DEBUG] Stack trace: $e');
      return {
        'categories': <Category>[],
        'promotions': <Promotion>[],
        'products': <Product>[],
        'showWelcome': true,
      };
    }
  }

  @override
  bool get wantKeepAlive => true; // เก็บ state ไว้

  @override
  Widget build(BuildContext context) {
    super.build(context); // เรียก super.build()

    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final data = snapshot.data!;
          final categories = data['categories'] as List<Category>;
          final promotions = data['promotions'] as List<Promotion>;
          final products = data['products'] as List<Product>;
          final showWelcome = data['showWelcome'] as bool;

          if (showWelcome) {
            return _buildWelcomeState();
          }

          return _buildMainContent(categories, promotions, products);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E8), Color(0xFFF8FDF8)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2E7D32),
              strokeWidth: 4,
            ),
            SizedBox(height: 24),
            Text(
              'กำลังโหลดตลาดสีเขียว...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'เกิดข้อผิดพลาดในการโหลดข้อมูล',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _homeDataFuture = _fetchHomeData();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9), Color(0xFFF8FDF8)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Enhanced animated icon container
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 2),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryTeal.withOpacity(0.3 * value),
                            blurRadius: 40 * value,
                            offset: const Offset(0, 20),
                          ),
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2 * value),
                            blurRadius: 60 * value,
                            offset: const Offset(0, 30),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          width: 3,
                        ),
                      ),
                      child: const GreenWorldIcon(size: 140),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Text(
                      'ยินดีต้อนรับสู่',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'GREEN MARKET',
                      style: TextStyle(
                        fontSize: 48, // เพิ่มขนาดจาก 40 เป็น 48
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 3.0, // เพิ่ม letterSpacing
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Color(0x40000000),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Text(
                        'ตลาดสินค้าเพื่อโลกที่ยั่งยืน',
                        style: TextStyle(
                          fontSize: 20, // เพิ่มขนาดจาก 16 เป็น 20
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Enhanced Animated Green World Button
                    const AnimatedGreenWorldButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Category> categories,
      List<Promotion> promotions, List<Product> products) {
    // ใช้โครงสร้างแบบ home_screen.dart: เหลือแค่ Banner, Platinum, EcoLevel
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _homeDataFuture = _fetchHomeData();
        });
        await _homeDataFuture;
      },
      color: AppColors.primaryTeal,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          // Shopee-style Search Bar (real-time search)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(
                            color: Color(0xFF333333), fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาสินค้าทุกอย่าง เช่น "ต้นไม้"',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF999999), size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        tooltip: 'ล้างคำค้นหา',
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Banner ข่าวสาร/โปรโมชั่น (ถ้ามี)
          if (promotions.isNotEmpty) _buildPromotionBanner(promotions),
          // Eco Level Tabs และ Products
          _buildEcoLevelTabsSection(products),
          // Spacing ด้านล่าง
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF388E3C),
                Color(0xFF43A047),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2E7D32),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const GreenWorldIcon(size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GREEN MARKET',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28, // เพิ่มจาก 24
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0, // เพิ่มจาก 1.5
                                      fontFamily: 'Sarabun',
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFF1B5E20),
                                          blurRadius: 8, // เพิ่มจาก 6
                                          offset: Offset(0, 3), // เพิ่มจาก 2
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4), // เพิ่มจาก 2
                                  Text(
                                    'ตลาดสินค้าเพื่อโลกที่ยั่งยืน',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.95), // เพิ่มจาก 0.9
                                      fontSize: 14, // เพิ่มจาก 12
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8, // เพิ่มจาก 0.5
                                      fontFamily: 'Sarabun',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Admin Settings Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _showAdminSettings(context);
                      },
                      icon: const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 20),
                      tooltip: 'การตั้งค่าแอดมิน',
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Enhanced Eco Coins Widget
                  const EnhancedEcoCoinsWidget(
                    size: 20,
                    showLabel: false,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ลบ _buildSearchBar ออก (แทนที่ด้วยของ home_screen.dart)

  Widget _buildPromotionBanner(List<Promotion> promotions) {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        child: promotions.isEmpty
            ? _buildPromotionPlaceholder()
            : PageView.builder(
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  final promotion = promotions[index];
                  return _buildPromotionCard(promotion);
                },
              ),
      ),
    );
  }

  Widget _buildPromotionPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea), // Soft Periwinkle
            Color(0xFF764ba2), // Deep Lavender
            Color(0xFFf093fb), // Vibrant Pink
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text(
              '📢 พื้นที่โฆษณาและข่าวสาร',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18, // ลดขนาดลงจาก 20 เป็น 18
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'แอดมินสามารถเพิ่ม ลบ รูปภาพและข้อความได้',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (promotion.imageUrl.isNotEmpty)
              Image.network(
                promotion.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.white, size: 48),
                    ),
                  );
                },
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.campaign, color: Colors.white, size: 48),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminSettings(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ตรวจสอบว่าผู้ใช้เป็น admin หรือไม่
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final appUser = await firebaseService.getAppUser(currentUser.uid);
      final role = appUser?.role ?? 'user';

      if (role != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คุณไม่มีสิทธิ์เข้าถึงแผงควบคุมแอดมิน'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // เปิดหน้าแผงควบคุมแอดมิน
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CompleteAdminPanelScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to filter products
  List<Product> _getFilteredProducts(List<Product> products) {
    List<Product> filtered = products;

    // Filter by selected category
    if (_selectedCategory != null) {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategory!.id)
          .toList();
    }

    // Filter by selected EcoLevel
    if (_selectedEcoLevel != null) {
      filtered = filtered
          .where((product) => product.ecoLevel == _selectedEcoLevel)
          .toList();
    }

    // Fuzzy filter by main search query (Thai/Eng, typo-tolerant, robust)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.trim();
      filtered = filtered.where((product) {
        // รวม field สำคัญทั้งหมด
        final fields = [
          product.name,
          product.description,
          product.ecoLevel.name,
          product.materialDescription,
          product.ecoJustification,
          product.categoryName ?? '',
          product.sellerId,
          ...?product.keywords
        ];
        // เช็ค fuzzy match หรือ contains (สำรอง)
        return fields.any((field) =>
            field.trim().isNotEmpty &&
            (isFuzzyMatch(q, field, threshold: 0.48) ||
                field.toLowerCase().contains(q.toLowerCase())));
      }).toList();
    }

    // Fuzzy filter by eco search query (Thai/Eng, typo-tolerant, robust)
    if (_ecoSearchQuery.isNotEmpty) {
      final q = _ecoSearchQuery.trim();
      filtered = filtered.where((product) {
        final fields = [
          product.name,
          product.description,
          product.ecoLevel.name,
          product.materialDescription,
          product.ecoJustification,
          product.categoryName ?? '',
          product.sellerId,
          ...?product.keywords
        ];
        return fields.any((field) =>
            field.trim().isNotEmpty &&
            (isFuzzyMatch(q, field, threshold: 0.48) ||
                field.toLowerCase().contains(q.toLowerCase())));
      }).toList();
    }

    return filtered;
  }

  // Eco Level Tabs Section
  Widget _buildEcoLevelTabsSection(List<Product> products) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'สินค้าตามระดับความยั่งยืน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _ecoLevelTabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF666666),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'ทั้งหมด'),
                  Tab(text: 'เริ่มต้น'),
                  Tab(text: 'มาตรฐาน'),
                  Tab(text: 'พรีเมี่ยม'),
                  Tab(text: 'Eco Hero'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab Bar View
            SizedBox(
              height: 400, // กำหนดความสูงสำหรับ TabBarView
              child: TabBarView(
                controller: _ecoLevelTabController,
                children: [
                  _buildProductGrid(_getFilteredProducts(products)), // ทั้งหมด
                  _buildProductGrid(_getProductsByLevel(
                      products, EcoLevel.basic)), // เริ่มต้น
                  _buildProductGrid(_getProductsByLevel(
                      products, EcoLevel.standard)), // มาตรฐาน
                  _buildProductGrid(_getProductsByLevel(
                      products, EcoLevel.premium)), // พรีเมี่ยม
                  _buildProductGrid(
                      _getProductsByLevel(products, EcoLevel.hero)), // Eco Hero
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method สำหรับกรองสินค้าตามระดับ
  List<Product> _getProductsByLevel(List<Product> products, EcoLevel level) {
    return products.where((product) => product.ecoLevel == level).toList();
  }

  // Helper method สำหรับสร้าง Product Grid (แบบ Shopee)
  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่มีสินค้าในระดับนี้',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองเลือกระดับอื่นดูครับ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // ปรับให้เหมือน Shopee มากขึ้น (ลดลงจาก 0.7)
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.take(6).length,
      itemBuilder: (context, index) {
        final product = products[index];
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12), // เพิ่มจาก 8
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // เพิ่มเงาเล็กน้อย
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12), // เปลี่ยนจาก 8
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // Main Image
                          product.imageUrls.isNotEmpty
                              ? Image.network(
                                  product.imageUrls.first,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (c, o, s) => Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          // Eco Level Badge
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: product.ecoLevel.color.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        product.ecoLevel.color.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                product.ecoLevel.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Product Details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13, // เพิ่มจาก 12
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6), // เพิ่มจาก 4
                        // Price
                        Row(
                          children: [
                            Text(
                              '฿${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16, // เพิ่มจาก 14
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEE4D2D), // Shopee orange
                              ),
                            ),
                            const SizedBox(width: 4),
                            // ราคาเดิม (ถ้ามี)
                            Text(
                              '฿${(product.price * 1.2).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Bottom Row (Rating, Sales, etc.)
                        Row(
                          children: [
                            // Rating
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12, // เพิ่มจาก 10
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '4.8',
                                  style: TextStyle(
                                    fontSize: 10, // เพิ่มจาก 9
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            // Sales Count
                            Expanded(
                              child: Text(
                                'ขายแล้ว ${(product.ecoScore * 3).toInt()}', // ใช้ ecoScore สร้าง mock data
                                style: TextStyle(
                                  fontSize: 10, // เพิ่มจาก 9
                                  color: Colors.grey[500],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Discount Badge (ถ้ามี)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.red[300]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '-20%',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        );
      },
    );
  }
}
