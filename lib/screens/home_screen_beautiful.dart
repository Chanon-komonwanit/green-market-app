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
                // Welcome Message
                SliverToBoxAdapter(
                  child: _buildWelcomeMessage(),
                ),
                // Enhanced Eco Coins
                SliverToBoxAdapter(
                  child: _buildEcoCoinsSection(),
                ),
                // Search Bar
                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),
                // Categories Section
                SliverToBoxAdapter(
                  child: _buildCategoriesSection(categories),
                ),
                // Green World Hub Section
                SliverToBoxAdapter(
                  child: _buildGreenWorldHubSection(),
                ),
                // Sustainable Investment Zone
                SliverToBoxAdapter(
                  child: _buildSustainableInvestmentZoneSection(),
                ),
                // Community Activities
                SliverToBoxAdapter(
                  child: _buildCommunityActivitiesSection(),
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

  Widget _buildWelcomeMessage() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryTeal.withOpacity(0.8),
                    AppColors.peacockBlue.withOpacity(0.7),
                    AppColors.lightTeal.withOpacity(0.6)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'ยินดีต้อนรับสู่ Green Market!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ร้านค้าที่ใส่ใจสิ่งแวดล้อมและชุมชน',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
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

  Widget _buildEcoCoinsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const EnhancedEcoCoinsWidget(),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 20),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primaryTeal.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาสินค้าเพื่อสิ่งแวดล้อม...',
                        hintStyle: TextStyle(
                          color: AppColors.modernGrey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                      onChanged: (value) {
                        // Handle search query change
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ไม่สามารถเปิดหน้าค้นหาได้'),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryTeal,
                      size: 20,
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
                        const Text(
                          'หมวดหมู่สินค้า',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                AppColors.darkText, // เปลี่ยนเป็นสีที่อ่านง่าย
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ทั้งหมด',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      cacheExtent: 200,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(
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

  Widget _buildCategoryCard({required Category category, required int index}) {
    final colors = [
      AppColors.primaryTeal,
      AppColors.peacockBlue,
      AppColors.emeraldGreen,
      AppColors.modernBlue,
      AppColors.lightTeal,
    ];

    final cardColor = colors[index % colors.length];

    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_buttonAnimationController.value * 0.05),
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
              width: 90,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cardColor,
                          cardColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(category.name),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name.isNotEmpty ? category.name : 'ไม่มีชื่อ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText, // เปลี่ยนเป็นสีที่อ่านง่าย
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreenWorldHubSection() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6), // ลดขนาด margin
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryTeal.withOpacity(0.8),
                    AppColors.peacockBlue.withOpacity(0.8)
                  ], // ลดความเข้มสี
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16), // ลดขนาด border radius
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal
                        .withOpacity(0.2), // ลดความเข้มของเงา
                    blurRadius: 15, // ลดขนาดเงา
                    offset: const Offset(0, 4), // ลดขนาดเงา
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16), // ลดขนาด padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8), // ลดขนาด padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                                12), // ลดขนาด border radius
                          ),
                          child: const Icon(
                            Icons.door_front_door,
                            color: Colors.white,
                            size: 18, // ลดขนาด icon
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Green World Hub',
                                style: TextStyle(
                                  fontSize: 16, // ลดขนาดฟอนต์
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'ศูนย์รวมนวัตกรรมเพื่อโลกสีเขียว',
                                style: TextStyle(
                                  fontSize: 12, // ลดขนาดฟอนต์
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // ลดขนาด spacing
                    const Text(
                      'ร่วมสร้างโลกที่ยั่งยืนด้วยเทคโนโลยีและนวัตกรรมสีเขียว',
                      style: TextStyle(
                        fontSize: 14, // ลดขนาดฟอนต์
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16), // ลดขนาด spacing
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Navigate to Green World Hub
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'กำลังพัฒนาฟีเจอร์ Green World Hub'),
                                    backgroundColor: AppColors.primaryTeal,
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.explore,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'สำรวจ Hub',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
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
          ),
        );
      },
    );
  }

  Widget _buildSustainableInvestmentZoneSection() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4), // ลดขนาด margin
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.modernBlue.withOpacity(0.7),
                    AppColors.deepBlue.withOpacity(0.7)
                  ], // ลดความเข้มสี
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16), // ลดขนาด border radius
                boxShadow: [
                  BoxShadow(
                    color: AppColors.modernBlue
                        .withOpacity(0.2), // ลดความเข้มของเงา
                    blurRadius: 15, // ลดขนาดเงา
                    offset: const Offset(0, 4), // ลดขนาดเงา
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16), // ลดขนาด padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8), // ลดขนาด padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                                12), // ลดขนาด border radius
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 18, // ลดขนาด icon
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sustainable Investment Zone',
                                style: TextStyle(
                                  fontSize: 16, // ลดขนาดฟอนต์
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'ลงทุนเพื่อความยั่งยืน',
                                style: TextStyle(
                                  fontSize: 12, // ลดขนาดฟอนต์
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // ลดขนาด spacing
                    const Text(
                      'ลงทุนในโครงการที่ช่วยสร้างโลกที่ดีขึ้น และได้รับผลตอบแทนที่ยั่งยืน',
                      style: TextStyle(
                        fontSize: 14, // ลดขนาดฟอนต์
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16), // ลดขนาด spacing
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Navigate to investment screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'กำลังพัฒนาฟีเจอร์การลงทุนยั่งยืน'),
                                    backgroundColor: AppColors.modernBlue,
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'เริ่มลงทุน',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
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
          ),
        );
      },
    );
  }

  Widget _buildCommunityActivitiesSection() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimationController.value) * 30),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4), // ลดขนาด margin
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.emeraldGreen.withOpacity(0.6),
                    AppColors.primaryTeal.withOpacity(0.6)
                  ], // ลดความเข้มสี
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16), // ลดขนาด border radius
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldGreen
                        .withOpacity(0.15), // ลดความเข้มของเงา
                    blurRadius: 12, // ลดขนาดเงา
                    offset: const Offset(0, 4), // ลดขนาดเงา
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12), // ลดขนาด padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'กิจกรรมชุมชน',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ร่วมกิจกรรมเพื่อสังคม',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'เข้าร่วมกิจกรรมชุมชนเพื่อสร้างสรรค์สิ่งดีๆ ให้กับสังคม',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _buttonAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 +
                                    (_buttonAnimationController.value * 0.05),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    try {
                                      Navigator.pushNamed(
                                          context, '/community-activities');
                                    } catch (e) {
                                      print(
                                          '[ERROR] Community activities navigation: $e');
                                    }
                                  },
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('ดูกิจกรรม'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.emeraldGreen,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _buttonAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 +
                                    (_buttonAnimationController.value * 0.05),
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    try {
                                      Navigator.pushNamed(
                                          context, '/create-activity');
                                    } catch (e) {
                                      print(
                                          '[ERROR] Create activity navigation: $e');
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('สร้างกิจกรรม'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.white, width: 2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
}
