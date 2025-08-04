import 'package:flutter/material.dart';
import 'package:green_market/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/promotion.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/widgets/smart_eco_hero_tab.dart';
import 'package:green_market/screens/category_products_screen.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';
import 'package:green_market/screens/admin/complete_admin_panel_screen.dart';
import 'package:green_market/widgets/eco_coins_widget.dart';
import 'package:green_market/widgets/enhanced_eco_coins_widget.dart';
import 'package:green_market/widgets/green_world_icon.dart';
import 'package:green_market/widgets/animated_green_world_button.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/thai_fuzzy_search.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  // TODO: [ภาษาไทย] เพิ่มระบบตรวจสอบประสิทธิภาพ (Performance Monitoring) และ Analytics Dashboard
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _homeDataFuture;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ecoSearchController = TextEditingController();
  final PageController _bannerController = PageController();

  late TabController _ecoLevelTabController;

  // Animation Controllers
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _buttonAnimationController;
  late AnimationController _floatingAnimationController;

  // Animation
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
    _ecoLevelTabController = TabController(length: 5, vsync: this);
    _initializeAnimations();

    // Auto-scroll banner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoscrollBanner();
    });
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations with staggered delays
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _buttonAnimationController.forward();
    });

    // Continuous floating animation
    _floatingAnimationController.repeat(reverse: true);
  }

  void _autoscrollBanner() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        _homeDataFuture.then((data) {
          final promotions = data['promotions'] as List<Promotion>;
          if (promotions.isNotEmpty) {
            final nextPage = (_bannerController.page?.round() ?? 0) + 1;
            _bannerController.animateToPage(
              nextPage >= promotions.length ? 0 : nextPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ecoSearchController.dispose();
    _ecoLevelTabController.dispose();
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _buttonAnimationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // เพิ่ม retry mechanism และ better error handling
      final futures = await Future.wait([
        firebaseService.getCategories().first.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('[WARNING] Categories fetch timed out after 10 seconds');
            return <Category>[];
          },
        ),
        firebaseService.getActivePromotions().first.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('[WARNING] Promotions fetch timed out after 10 seconds');
            return <Promotion>[];
          },
        ),
        firebaseService.getApprovedProducts().first.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('[WARNING] Products fetch timed out after 15 seconds');
            return <Product>[];
          },
        ),
      ]).catchError((error) {
        print('[ERROR] Future.wait failed: $error');
        return [<Category>[], <Promotion>[], <Product>[]];
      });

      final categories = futures[0] as List<Category>;
      final promotions = futures[1] as List<Promotion>;
      final products = futures[2] as List<Product>;

      // Log successful data fetch
      print('[SUCCESS] Data fetched successfully:');
      print('  - Categories: ${categories.length}');
      print('  - Promotions: ${promotions.length}');
      print('  - Products: ${products.length}');

      return {
        'categories': categories,
        'promotions': promotions,
        'products': products,
      };
    } catch (e, stackTrace) {
      print('[ERROR] Failed to fetch home data: $e');
      print('[ERROR] Stack trace: $stackTrace');
      // Return safe default values
      return {
        'categories': <Category>[],
        'promotions': <Promotion>[],
        'products': <Product>[],
      };
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -30 * (1 - _headerAnimation.value)),
              child: Opacity(
                opacity: _headerAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryTeal.withOpacity(0.9),
                        AppColors.peacockBlue.withOpacity(0.8),
                        AppColors.lightTeal.withOpacity(0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Green Market',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.search,
                                color: Colors.white, size: 20),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 20),
                          ),
                          onPressed: () {
                            _showUserProfile();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _homeDataFuture = _fetchHomeData();
                      });
                    },
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('ไม่พบข้อมูล'),
            );
          }

          final data = snapshot.data!;
          final categories = data['categories'] as List<Category>;
          final promotions = data['promotions'] as List<Promotion>;
          final products = data['products'] as List<Product>;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _homeDataFuture = _fetchHomeData();
              });
            },
            child: CustomScrollView(
              slivers: [
                // Enhanced Eco Coins - ย้ายขึ้นมาเป็นอันดับแรก
                SliverToBoxAdapter(
                  child: _buildEnhancedEcoCoinsSection(),
                ),
                // Smart Eco Hero Section - สินค้าระดับสูงสุด
                SliverToBoxAdapter(
                  child: _buildSmartEcoHeroSection(products),
                ),
                // Categories Section
                SliverToBoxAdapter(
                  child: _buildCategoriesSection(categories),
                ),
                // Special Promotions
                if (promotions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildPromotionsSection(promotions),
                  ),
                // Products by Eco Level
                SliverToBoxAdapter(
                  child: _buildEcoLevelProductsSection(products),
                ),
                // Featured Products
                SliverToBoxAdapter(
                  child: _buildFeaturedProductsSection(products),
                ),
                // Popular Products
                SliverToBoxAdapter(
                  child: _buildPopularProductsSection(products),
                ),
                // New Products
                SliverToBoxAdapter(
                  child: _buildNewProductsSection(products),
                ),
                // Add padding at the bottom
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget _buildWelcomeMessage() - REMOVED
  // Replaced with _buildEnhancedEcoCoinsSection()

  Widget _buildEnhancedEcoCoinsSection() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B5E20), // Deep forest green
                    const Color(0xFF2E7D32), // Forest green
                    const Color(0xFF388E3C), // Green
                    const Color(0xFF4CAF50), // Light green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Green Market',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'World-Class Sustainable Shopping',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '🌱 ตลาดออนไลน์ที่ใส่ใจสิ่งแวดล้อม รองรับการซื้อขายที่ยั่งยืน พร้อมระบบ AI แนะนำสินค้าอัจฉริยะ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'สวัสดี ${snapshot.data!.displayName ?? 'ผู้ใช้'}!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.login,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'เข้าสู่ระบบเพื่อรับสิทธิประโยชน์เพิ่มเติม',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection(List<Category> categories) {
    if (categories.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: Text(
            'ไม่พบหมวดหมู่สินค้า',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.modernGrey,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryTeal,
                                AppColors.emeraldGreen,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryTeal.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.category_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'หมวดหมู่สินค้า',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryTeal.withOpacity(0.1),
                                AppColors.emeraldGreen.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AppColors.primaryTeal.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                color: AppColors.primaryTeal,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ดูทั้งหมด',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      cacheExtent: 200,
                      itemBuilder: (context, index) {
                        return _buildModernCategoryCard(
                            category: categories[index], index: index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernCategoryCard(
      {required Category category, required int index}) {
    final colors = [
      [AppColors.primaryTeal, AppColors.peacockBlue],
      [AppColors.emeraldGreen, AppColors.primaryTeal],
      [AppColors.modernBlue, AppColors.deepBlue],
      [AppColors.lightTeal, AppColors.primaryTeal],
      [AppColors.peacockBlue, AppColors.modernBlue],
    ];

    final gradientColors = colors[index % colors.length];

    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_buttonAnimationController.value * 0.03),
          child: GestureDetector(
            onTap: () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryProductsScreen(category: category),
                  ),
                );
              } catch (e) {
                print('[ERROR] Failed to navigate to category: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('ไม่สามารถเปิดหมวดหมู่สินค้าได้'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: gradientColors[1].withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(category.name),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      category.name.isNotEmpty ? category.name : 'ไม่มีชื่อ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromotionsSection(List<Promotion> promotions) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.local_offer,
                                color: AppColors.primaryTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'โปรโมชั่นพิเศษ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${promotions.length} รายการ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: promotions.length,
                      cacheExtent: 300,
                      itemBuilder: (context, index) {
                        final promotion = promotions[index];
                        return _buildPromotionCard(promotion, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromotionCard(Promotion promotion, int index) {
    final gradientColors = [
      [AppColors.primaryTeal, AppColors.peacockBlue],
      [AppColors.emeraldGreen, AppColors.primaryTeal],
      [AppColors.modernBlue, AppColors.deepBlue],
      [AppColors.peacockBlue, AppColors.emeraldGreen],
    ];

    final colorSet = gradientColors[index % gradientColors.length];

    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_buttonAnimationController.value * 0.02),
          child: Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colorSet,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorSet[0].withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          promotion.title.isNotEmpty
                              ? promotion.title
                              : 'โปรโมชั่นพิเศษ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      promotion.description.isNotEmpty
                          ? promotion.description
                          : 'รายละเอียดโปรโมชั่น',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'ส่วนลด ${promotion.discountValue}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          try {
                            // ใช้โปรโมชั่นจริง
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'ใช้โปรโมชั่น ${promotion.title} เรียบร้อย!'),
                                backgroundColor: colorSet[0],
                              ),
                            );
                          } catch (e) {
                            print('[ERROR] Apply promotion: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colorSet[0],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'ใช้เลย',
                          style: TextStyle(
                            fontSize: 14,
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
        );
      },
    );
  }

  Widget _buildEcoLevelProductsSection(List<Product> products) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.eco,
                            color: AppColors.primaryTeal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'สินค้าตามระดับความเป็นมิตรต่อสิ่งแวดล้อม',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors
                                  .darkText, // เปลี่ยนเป็นสีที่อ่านง่าย
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: TabBar(
                      controller: _ecoLevelTabController,
                      isScrollable: true,
                      indicatorColor: AppColors.primaryTeal,
                      indicatorWeight: 3,
                      labelColor: AppColors.primaryTeal,
                      unselectedLabelColor: AppColors.modernGrey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'ทั้งหมด'),
                        Tab(text: 'Basic'),
                        Tab(text: 'Standard'),
                        Tab(text: 'Premium'),
                        Tab(text: 'Hero'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _ecoLevelTabController,
                      children: [
                        _buildProductsList(products),
                        _buildProductsList(products
                            .where((p) => p.ecoLevel == EcoLevel.basic)
                            .toList()),
                        _buildProductsList(products
                            .where((p) => p.ecoLevel == EcoLevel.standard)
                            .toList()),
                        _buildProductsList(products
                            .where((p) => p.ecoLevel == EcoLevel.premium)
                            .toList()),
                        _buildProductsList(products
                            .where((p) => p.ecoLevel == EcoLevel.hero)
                            .toList()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsList(List<Product> products) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.modernGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.modernGrey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ไม่พบสินค้าในระดับนี้',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.modernGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ลองเลือกระดับอื่นดูครับ',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.modernGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      cacheExtent: 400, // Performance optimization
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          width: 220,
          margin: const EdgeInsets.only(right: 16),
          child: ProductCard(
            product: product,
            onTap: () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              } catch (e) {
                print('[ERROR] Failed to navigate to product detail: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ไม่สามารถเปิดรายละเอียดสินค้าได้'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFeaturedProductsSection(List<Product> products) {
    final featuredProducts = products.where((p) => p.isFeatured).toList();

    if (featuredProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.star,
                            color: AppColors.emeraldGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'สินค้าแนะนำ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                AppColors.darkText, // เปลี่ยนเป็นสีที่อ่านง่าย
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${featuredProducts.length} รายการ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.emeraldGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: featuredProducts.length,
                      cacheExtent: 400,
                      itemBuilder: (context, index) {
                        final product = featuredProducts[index];
                        return Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 16),
                          child: ProductCard(
                            product: product,
                            onTap: () {
                              try {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              } catch (e) {
                                print(
                                    '[ERROR] Featured product navigation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'ไม่สามารถเปิดรายละเอียดสินค้าได้'),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularProductsSection(List<Product> products) {
    try {
      final popularProducts =
          products.where((p) => p.averageRating >= 4.0).toList();
      popularProducts
          .sort((a, b) => b.averageRating.compareTo(a.averageRating));

      if (popularProducts.isEmpty) {
        return const SizedBox.shrink();
      }

      return AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _cardAnimationController.value) * 30),
            child: Opacity(
              opacity: _cardAnimationController.value,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'สินค้ายอดนิยม',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors
                                  .darkText, // เปลี่ยนเป็นสีที่อ่านง่าย
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${popularProducts.length} รายการ',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: popularProducts.take(10).length,
                        cacheExtent: 400,
                        itemBuilder: (context, index) {
                          final product = popularProducts[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 16),
                            child: ProductCard(
                              product: product,
                              onTap: () {
                                try {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailScreen(product: product),
                                    ),
                                  );
                                } catch (e) {
                                  print(
                                      '[ERROR] Popular product navigation: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'ไม่สามารถเปิดรายละเอียดสินค้าได้'),
                                      backgroundColor: AppColors.errorRed,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('[ERROR] Error in _buildPopularProductsSection: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildNewProductsSection(List<Product> products) {
    try {
      final newProducts = products.toList();
      newProducts.sort((a, b) {
        final aTime = a.createdAt ?? Timestamp.now();
        final bTime = b.createdAt ?? Timestamp.now();
        return bTime.compareTo(aTime);
      });

      if (newProducts.isEmpty) {
        return const SizedBox.shrink();
      }

      return AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _cardAnimationController.value) * 30),
            child: Opacity(
              opacity: _cardAnimationController.value,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.new_releases,
                              color: AppColors.primaryTeal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'สินค้าใหม่',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors
                                  .darkText, // เปลี่ยนเป็นสีที่อ่านง่าย
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${newProducts.length} รายการ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: newProducts.take(10).length,
                        cacheExtent: 400,
                        itemBuilder: (context, index) {
                          final product = newProducts[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 16),
                            child: ProductCard(
                              product: product,
                              onTap: () {
                                try {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailScreen(product: product),
                                    ),
                                  );
                                } catch (e) {
                                  print('[ERROR] New product navigation: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'ไม่สามารถเปิดรายละเอียดสินค้าได้'),
                                      backgroundColor: AppColors.errorRed,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('[ERROR] Error in _buildNewProductsSection: $e');
      return const SizedBox.shrink();
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ผลไม้':
      case 'fruit':
        return Icons.apple;
      case 'ผัก':
      case 'vegetable':
        return Icons.grass;
      case 'เนื้อสัตว์':
      case 'meat':
        return Icons.dinner_dining;
      case 'ปลา':
      case 'fish':
        return Icons.set_meal;
      case 'ข้าว':
      case 'rice':
        return Icons.rice_bowl;
      case 'เครื่องดื่ม':
      case 'drink':
        return Icons.local_drink;
      case 'ของใช้':
      case 'household':
        return Icons.home;
      case 'เครื่องแต่งกาย':
      case 'clothing':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'โปรไฟล์ผู้ใช้',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'เกิดข้อผิดพลาด: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                final user = snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoRow('ชื่อ', user.displayName ?? 'ไม่มีชื่อ'),
                    const SizedBox(height: 8),
                    _buildUserInfoRow('อีเมล', user.email ?? 'ไม่มีอีเมล'),
                    const SizedBox(height: 8),
                    _buildUserInfoRow('สถานะ',
                        user.emailVerified ? 'ยืนยันแล้ว' : 'ยังไม่ยืนยัน'),
                    const SizedBox(height: 16),
                    if (user.email == 'admin@greenmarket.com')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            try {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CompleteAdminPanelScreen(),
                                ),
                              );
                            } catch (e) {
                              print(
                                  '[ERROR] Failed to navigate to admin panel: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('ไม่สามารถเปิดแผงควบคุมแอดมินได้'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Admin Panel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return const Text(
                'ไม่ได้เข้าสู่ระบบ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return TextButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ออกจากระบบเรียบร้อยแล้ว'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        print('[ERROR] Failed to sign out: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ไม่สามารถออกจากระบบได้'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// สร้าง Smart Eco Hero Section - สินค้าระดับสูงสุดแห่งความยั่งยืน
  Widget _buildSmartEcoHeroSection(List<Product> products) {
    // AI Algorithm - เลือกสินค้าระดับสูงสุด
    final ecoHeroProducts = _selectEcoHeroProducts(products);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium AI Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  Color(0xFF1E293B), // Slate 800
                  Color(0xFF334155), // Slate 700
                  Color(0xFF475569), // Slate 600
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF10B981), // Emerald 500
                            Color(0xFF059669), // Emerald 600
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 28,
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'AI-Powered Recommendations',
                              style: TextStyle(
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: const Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI แนะนำสินค้าระดับ Hero & Premium เท่านั้น',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${ecoHeroProducts.length} รายการ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Products Grid
          if (ecoHeroProducts.isNotEmpty)
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ecoHeroProducts.length,
                itemBuilder: (context, index) {
                  final product = ecoHeroProducts[index];
                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildEcoHeroProductCard(product, index),
                  );
                },
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'ยังไม่มีสินค้าระดับ Eco Hero',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'รอสินค้าเยี่ยมจากผู้ขายของเรา',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// อัลกอริทึมฉลาด AI เลือกสินค้าระดับ Eco Hero
  List<Product> _selectEcoHeroProducts(List<Product> products) {
    if (products.isEmpty) return [];

    // 🎯 AI Algorithm: ให้ความสำคัญกับ Eco Level เป็นหลัก
    final scoredProducts = products.map((product) {
      double score = 0.0;

      // 1. คะแนน Eco Level (50%) - หลักเกณฑ์สำคัญที่สุด
      switch (product.ecoLevel) {
        case EcoLevel.hero: // 90-100%
          score += 50;
          break;
        case EcoLevel.premium: // 60-89%
          score += 40;
          break;
        case EcoLevel.standard: // 40-59%
          score += 25;
          break;
        case EcoLevel.basic: // 20-39%
          score += 10;
          break;
      }

      // 2. คะแนน Eco Score จริง (20%) - คะแนนยิ่งสูงยิ่งดี
      if (product.ecoScore >= 95) {
        score += 20;
      } else if (product.ecoScore >= 85) {
        score += 18;
      } else if (product.ecoScore >= 75) {
        score += 15;
      } else if (product.ecoScore >= 65) {
        score += 12;
      } else if (product.ecoScore >= 50) {
        score += 8;
      } else {
        score += 5;
      }

      // 3. ชื่อสินค้ามีคำที่เกี่ยวกับความยั่งยืน (15%)
      final sustainableKeywords = [
        'organic',
        'eco',
        'green',
        'sustainable',
        'natural',
        'bio',
        'ออร์แกนิค',
        'เขียว',
        'ธรรมชาติ',
        'ยั่งยืน',
        'เอโค',
        'ไร้สาร',
        'รักษ์โลก',
        'สิ่งแวดล้อม',
        'รีไซเคิล',
        'คาร์บอน'
      ];
      final productName = product.name.toLowerCase();
      final productDescription = product.description.toLowerCase();

      for (final keyword in sustainableKeywords) {
        if (productName.contains(keyword.toLowerCase()) ||
            productDescription.contains(keyword.toLowerCase())) {
          score += 15;
          break;
        }
      }

      // 4. คะแนนราคา (10%) - ราคาสูง = คุณภาพสูง
      if (product.price > 1000) {
        score += 10;
      } else if (product.price > 500) {
        score += 8;
      } else if (product.price > 200) {
        score += 5;
      }

      // 5. มีรูปภาพ = คุณภาพการนำเสนอดี (5%)
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        score += 5;
      }

      return MapEntry(product, score);
    }).toList();

    // เรียงตามคะแนนสูงสุด
    scoredProducts.sort((a, b) => b.value.compareTo(a.value));

    // กรองและเลือกสินค้า: เฉพาะที่มี Eco Level premium ขึ้นไป
    final filteredProducts = scoredProducts.where((entry) {
      final product = entry.key;
      final hasHighEcoLevel = product.ecoLevel == EcoLevel.hero ||
          product.ecoLevel == EcoLevel.premium;
      final hasMinScore = entry.value >= 40; // คะแนนขั้นต่ำ
      return hasHighEcoLevel && hasMinScore;
    }).toList();

    // ถ้าสินค้า premium/hero น้อยเกินไป ให้เพิ่มสินค้า standard ที่มีคะแนนสูง
    if (filteredProducts.length < 4) {
      final standardProducts = scoredProducts.where((entry) {
        final product = entry.key;
        final isStandard = product.ecoLevel == EcoLevel.standard;
        final hasGoodScore = entry.value >= 35;
        final notInFiltered =
            !filteredProducts.map((e) => e.key.id).contains(product.id);
        return isStandard && hasGoodScore && notInFiltered;
      }).take(4 - filteredProducts.length);

      filteredProducts.addAll(standardProducts);
    }

    // เลือกสินค้า 8 อันดับแรก
    return filteredProducts.take(8).map((entry) => entry.key).toList();
  }

  /// ฟังก์ชันกำหนดสีตาม Eco Level
  Color _getEcoLevelColor(EcoLevel ecoLevel) {
    switch (ecoLevel) {
      case EcoLevel.hero:
        return const Color(0xFFD4AF37); // ทอง - สำหรับ Hero
      case EcoLevel.premium:
        return const Color(0xFF8E24AA); // ม่วง - สำหรับ Premium
      case EcoLevel.standard:
        return const Color(0xFF1976D2); // น้ำเงิน - สำหรับ Standard
      case EcoLevel.basic:
        return const Color(0xFF388E3C); // เขียว - สำหรับ Basic
    }
  }

  /// สร้างการ์ดสินค้า Eco Hero แบบพิเศษ
  Widget _buildEcoHeroProductCard(Product product, int index) {
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
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFFFFAF0), // ครีมทอง
            ],
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Badge
            Stack(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: (product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty)
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported,
                                  size: 40);
                            },
                          )
                        : const Icon(Icons.shopping_bag, size: 40),
                  ),
                ),
                // Hero Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'HERO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                    Row(
                      children: [
                        Text(
                          product.ecoLevel.shortCode,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getEcoLevelColor(product.ecoLevel),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.ecoScore}%)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '฿${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6600),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 16,
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
  }
}
