import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/promotion.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/screens/category_products_screen.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/screens/eco_level_products_screen.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';
import 'package:green_market/screens/admin_panel_screen.dart';
import 'package:green_market/widgets/eco_coins_widget.dart';
import 'package:green_market/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _homeDataFuture;
  Category? _selectedCategory; // สำหรับเก็บหมวดหมู่ที่เลือก
  EcoLevel? _selectedEcoLevel; // สำหรับเก็บ EcoLevel ที่เลือก
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ecoSearchController =
      TextEditingController(); // สำหรับ EcoLevel search
  String _searchQuery = '';
  String _ecoSearchQuery = ''; // สำหรับ EcoLevel search

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ecoSearchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    print('🔥 DEBUG: Starting _fetchHomeData()');
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // Fetch data with timeout
      print('🔥 DEBUG: About to fetch data from Firebase...');
      final futures = await Future.wait([
        firebaseService.getCategories().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('🔥 DEBUG: Categories timeout');
            return <Category>[];
          },
        ),
        firebaseService.getActivePromotions().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('🔥 DEBUG: Promotions timeout');
            return <Promotion>[];
          },
        ),
        firebaseService.getApprovedProducts().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('🔥 DEBUG: Products timeout');
            return <Product>[];
          },
        ),
      ]);

      final categories = futures[0] as List<Category>;
      final promotions = futures[1] as List<Promotion>;
      final products = futures[2] as List<Product>;

      print('🔥 DEBUG: Data fetched successfully:');
      print('  - Categories: ${categories.length}');
      print('  - Promotions: ${promotions.length}');
      print('  - Products: ${products.length}');

      // Debug first product if available
      if (products.isNotEmpty) {
        final firstProduct = products.first;
        print('🔥 DEBUG: First product details:');
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
        print('🔥 DEBUG: No products found! This is the main issue.');
      }

      return {
        'categories': categories,
        'promotions': promotions,
        'products': products,
        'showWelcome':
            products.isEmpty && categories.isEmpty && promotions.isEmpty,
      };
    } catch (e) {
      print('🔥 DEBUG: Error fetching home data: $e');
      print('🔥 DEBUG: Error type: ${e.runtimeType}');
      print('🔥 DEBUG: Stack trace: $e');
      return {
        'categories': <Category>[],
        'promotions': <Promotion>[],
        'products': <Product>[],
        'showWelcome': true,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.eco, size: 120, color: Color(0xFF2E7D32)),
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
                        fontSize: 40, // เพิ่มขนาดจาก 36 เป็น 40
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 2.2, // เพิ่ม letterSpacing เล็กน้อย
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        '🌍 ตลาดสินค้าเพื่อโลกที่ยั่งยืน',
                        style: TextStyle(
                          fontSize: 16, // เพิ่มขนาดจาก 14 เป็น 16
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GreenWorldHubScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.explore, size: 24),
                      label: const Text('เริ่มสำรวจ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                        elevation: 8,
                        shadowColor: Colors.green.withOpacity(0.4),
                      ),
                    ),
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
          _buildSearchBar(),
          if (promotions.isNotEmpty) _buildPromotionBanner(promotions),
          _buildPlatinumHeroSection(products),
          if (categories.isNotEmpty) _buildCategoriesSection(categories),
          _buildEcoLevelNavigationButtons(products),
          _buildCategoryProductsWithEcoLevel(products),
          _buildPopularProductsSection(products),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120, // ลดความสูงลงอีกจาก 140 เป็น 120
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
                Color(0xFF0D4F3C), // Deep Forest Green
                Color(0xFF1B5E20), // Forest Green
                Color(0xFF2E7D32), // Medium Green
                Color(0xFF388E3C), // Bright Green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF0D4F3C),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            // เพิ่ม SafeArea เพื่อหลีกเลี่ยง overflow
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 6), // ลด padding ลงอีก
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                // เพิ่ม Flexible เพื่อป้องกัน overflow
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                          6), // ลด padding เพิ่มเติม
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(
                                                0.25), // ลดความโปร่งใส
                                            Colors.white.withOpacity(0.12),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            12), // ลดรัศมี
                                        border: Border.all(
                                          color: Colors.white.withOpacity(
                                              0.4), // ลดความโปร่งใส
                                          width: 1.5, // ลดความหนาของเส้นขอบ
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        '🌱',
                                        style: TextStyle(
                                            fontSize:
                                                14), // ลดขนาดอีโมจิลงจาก 18 เป็น 14
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 10), // ลด spacing เพิ่มเติม
                                    Expanded(
                                      // เพิ่ม Expanded เพื่อป้องกัน overflow
                                      child: SingleChildScrollView(
                                        // เพิ่ม ScrollView
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize
                                              .min, // ลดขนาดให้เล็กที่สุด
                                          children: [
                                            ShaderMask(
                                              shaderCallback: (bounds) =>
                                                  const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Color(0xFFE8F5E8)
                                                ],
                                                stops: [0.0, 1.0],
                                              ).createShader(bounds),
                                              child: const Text(
                                                'GREEN MARKET',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      20, // ลดขนาดฟอนต์จาก 22 เป็น 20
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing:
                                                      1.2, // ลด letterSpacing จาก 1.3 เป็น 1.2
                                                  fontFamily: 'Sarabun',
                                                  shadows: [
                                                    Shadow(
                                                      color: Color(0xFF0D4F3C),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 3),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black26,
                                                      blurRadius: 12,
                                                      offset: Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal:
                                                      4, // ลด padding เพิ่มเติม
                                                  vertical:
                                                      1), // ลด padding เพิ่มเติม
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                    0.12), // ลดความโปร่งใส
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8), // ลดรัศมี
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(
                                                          0.15), // ลดความโปร่งใส
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: const Text(
                                                'ตลาดสินค้าเพื่อโลกที่ยั่งยืน',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      10, // ลดขนาดฟอนต์จาก 11 เป็น 10
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing:
                                                      0.2, // ลด letter spacing จาก 0.3 เป็น 0.2
                                                  fontFamily: 'Sarabun',
                                                ),
                                                overflow: TextOverflow
                                                    .ellipsis, // เพิ่ม overflow protection
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6), // ลด spacing
                              Flexible(
                                // เพิ่ม Flexible
                                child: SingleChildScrollView(
                                  // เพิ่ม scroll protection
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4), // ลด padding
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.25),
                                              Colors.white.withOpacity(0.15),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '🌍',
                                              style: TextStyle(
                                                  fontSize: 12), // ลดขนาด
                                            ),
                                            const SizedBox(width: 4),
                                            ShaderMask(
                                              shaderCallback: (bounds) =>
                                                  const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Color(0xFFB8E6B8)
                                                ],
                                              ).createShader(bounds),
                                              child: const Text(
                                                'The World\'s First Eco Market',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      8, // ลดขนาดฟอนต์จาก 9 เป็น 8
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing:
                                                      0.4, // ลด letterSpacing
                                                  fontFamily: 'Sarabun',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                5, // ลด padding เพิ่มเติม
                                            vertical:
                                                2), // ลด padding เพิ่มเติม
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF4CAF50),
                                              Color(0xFF8BC34A)
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              8), // ลดรัศมี
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(
                                                  0.25), // ลดความเข้ม
                                              blurRadius: 4, // ลด blur
                                              offset: const Offset(
                                                  0, 1), // ลด offset
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 7, // ลดขนาดฟอนต์เพิ่มเติม
                                            fontWeight: FontWeight.w900,
                                            letterSpacing:
                                                0.2, // ลด letter spacing
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Admin Settings Button (visible for admins)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
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
                                color: Colors.white, size: 18), // ลดขนาดไอคอน
                            tooltip: 'การตั้งค่าแอดมิน',
                            padding: const EdgeInsets.all(8), // ลด padding
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Eco Coins Widget
                        const EcoCoinsWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 6.0), // ลด padding
        child: Container(
          height: 42, // ลดความสูงลงจาก 48 เป็น 42
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(21.0), // ลดรัศมีลงจาก 24 เป็น 21
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0.5,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(
              fontSize: 13, // ลดขนาดฟอนต์ลงจาก 14 เป็น 13
              color: Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'ค้นหาสินค้าเพื่อสิ่งแวดล้อม...',
              hintStyle: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 13, // ลดขนาดฟอนต์ลงจาก 14 เป็น 13
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(5), // ลด margin ลงจาก 6 เป็น 5
                width: 32, // ลดขนาดลงจาก 36 เป็น 32
                height: 32, // ลดขนาดลงจาก 36 เป็น 32
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius:
                      BorderRadius.circular(16), // ลดรัศมีลงจาก 18 เป็น 16
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 16, // ลดขนาดไอคอนลงจาก 18 เป็น 16
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Color(0xFF999999),
                        size: 16, // ลดขนาดไอคอนลงจาก 18 เป็น 16
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildPlatinumHeroSection(List<Product> products) {
    final platinumProducts =
        products.where((p) => p.ecoLevel == EcoLevel.platinum).toList();

    if (platinumProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with diamond platinum border frame
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: const Color(0xFF9C27B0), // เปลี่ยนเป็นม่วงเพชรเข้ม
                ),
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE1BEE7).withOpacity(0.05), // ม่วงอ่อนเพชร
                    const Color(0xFF9C27B0).withOpacity(0.05), // ม่วงเข้มเพชร
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.3), // ม่วงเพชร
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
                      const Text(
                        '💎 ',
                        style: TextStyle(
                            fontSize: 12), // ลดขนาดลงอีกจาก 14 เป็น 12
                      ),
                      const Text(
                        'แพลตตินั่มฮีโร่',
                        style: TextStyle(
                          fontSize: 16, // ลดขนาดลงอีกจาก 18 เป็น 16
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6), // ลด spacing ลงจาก 8 เป็น 6
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1), // ลด padding ลง
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE1BEE7), // ม่วงอ่อนเพชร
                              Color(0xFF9C27B0), // ม่วงเข้มเพชร
                              Color(0xFF673AB7), // ม่วงเพชรลึก
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              10), // ลดรัศมีลงจาก 12 เป็น 10
                        ),
                        child: const Text(
                          'แนะนำสูงสุด',
                          style: TextStyle(
                            color: Colors.white, // เปลี่ยนเป็นสีขาวให้อ่านง่าย
                            fontSize: 9, // ลดขนาดฟอนต์ลงจาก 10 เป็น 9
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Diamond platinum corner decoration
                      Container(
                        width: 16, // ลดขนาดลงจาก 20 เป็น 16
                        height: 16, // ลดขนาดลงจาก 20 เป็น 16
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE1BEE7), // ม่วงอ่อนเพชร
                              Color(0xFF9C27B0), // ม่วงเข้มเพชร
                              Color(0xFF673AB7), // ม่วงเพชรลึก
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              8), // ลดรัศมีลงจาก 10 เป็น 8
                        ),
                        child: const Icon(
                          Icons.diamond, // เปลี่ยนจาก star เป็น diamond
                          color: Colors.white, // เปลี่ยนเป็นสีขาวให้เห็นชัด
                          size: 10, // ลดขนาดไอคอนลงจาก 12 เป็น 10
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // ลด spacing ลงจาก 8 เป็น 6
                  Text(
                    'สินค้าระดับสูงสุดสุดยอดแห่งความยั่งยืน • ${platinumProducts.length} รายการ',
                    style: const TextStyle(
                      fontSize: 10, // ลดขนาดลงอีกจาก 11 เป็น 10
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3), // ลด spacing ลงจาก 4 เป็น 3
                  // Diamond platinum accent line
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE1BEE7), // ม่วงอ่อนเพชร
                          Color(0xFF9C27B0), // ม่วงเข้มเพชร
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10), // ลด spacing ลงจาก 12 เป็น 10
            SizedBox(
              height: 180, // ลดความสูงลงจาก 200 เป็น 180
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: platinumProducts.take(6).length,
                itemBuilder: (context, index) {
                  final product = platinumProducts[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<Category> categories) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'หมวดหมู่สินค้า',
                    style: TextStyle(
                      fontSize: 16, // ลดขนาดลง
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 90, // ลดความสูงลงอีก จาก 100 เป็น 90
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1, // +1 สำหรับปุ่ม "ทั้งหมด"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // ปุ่ม "ทั้งหมด"
                    return Container(
                      width: 75, // ลดความกว้างลงอีก
                      margin: const EdgeInsets.only(right: 10), // ลด margin
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = null; // เลือกทั้งหมด
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 55, // ลดขนาดลงอีก
                              height: 55, // ลดขนาดลงอีก
                              decoration: BoxDecoration(
                                gradient: _selectedCategory == null
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF4CAF50),
                                          Color(0xFF66BB6A)
                                        ],
                                      )
                                    : null,
                                color: _selectedCategory == null
                                    ? null
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedCategory == null
                                      ? Colors.transparent
                                      : AppColors.primaryTeal.withOpacity(0.3),
                                  width: _selectedCategory == null ? 0 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _selectedCategory == null
                                        ? Colors.green.withOpacity(0.3)
                                        : AppColors.primaryTeal
                                            .withOpacity(0.1),
                                    blurRadius:
                                        _selectedCategory == null ? 15 : 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.apps,
                                color: _selectedCategory == null
                                    ? Colors.white
                                    : AppColors.primaryTeal,
                                size: 24, // ลดขนาดไอคอนลงอีก
                              ),
                            ),
                            const SizedBox(height: 6), // ลด spacing
                            Text(
                              'ทั้งหมด',
                              style: TextStyle(
                                fontSize: _selectedCategory == null
                                    ? 12 // ลดขนาดลงอีก
                                    : 11, // ลดขนาดลง
                                fontWeight: _selectedCategory == null
                                    ? FontWeight.w900 // เพิ่มความหนาให้เด่นขึ้น
                                    : FontWeight.w600,
                                color: _selectedCategory == null
                                    ? const Color(
                                        0xFF1B5E20) // เปลี่ยนสีให้เข้มขึ้น
                                    : const Color(0xFF333333),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final category =
                      categories[index - 1]; // -1 เพราะ index 0 เป็น "ทั้งหมด"
                  final isSelected = _selectedCategory?.id == category.id;

                  return Container(
                    width: 75, // ลดความกว้างลงอีก
                    margin: const EdgeInsets.only(right: 10), // ลด margin
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category; // เลือกหมวดหมู่
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 45, // ลดขนาดลงอีก
                            height: 45, // ลดขนาดลงอีก
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryTeal.withOpacity(0.2)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : AppColors.primaryTeal.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryTeal.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: category.imageUrl.isNotEmpty
                                  ? Image.network(
                                      category.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.transparent,
                                          child: const Icon(
                                            Icons.eco,
                                            color: AppColors.primaryTeal,
                                            size: 24, // ลดขนาดไอคอนลง
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.transparent,
                                      child: const Icon(
                                        Icons.eco,
                                        color: AppColors.primaryTeal,
                                        size: 20, // ลดขนาดไอคอนลง
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6), // ลด spacing
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 11, // ลดขนาดฟอนต์ลง
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryTeal
                                  : const Color(0xFF333333),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getEcoLevelGradient(EcoLevel level) {
    switch (level) {
      case EcoLevel.basic:
        return [const Color(0xFF66BB6A), const Color(0xFF4CAF50)]; // เขียว
      case EcoLevel.standard:
        return [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)]; // เงิน
      case EcoLevel.premium:
        return [const Color(0xFFFFE55C), const Color(0xFFFFD700)]; // ทอง
      case EcoLevel.platinum:
        return [
          const Color(0xFFE1BEE7), // ม่วงอ่อนเพชร
          const Color(0xFF9C27B0), // ม่วงเข้มเพชร
          const Color(0xFF673AB7) // ม่วงเพชรลึก
        ]; // เงินม่วงเพชรพิเศษสุด
    }
  }

  Widget _buildEcoLevelNavigationButtons(List<Product> products) {
    // กรองสินค้าตามหมวดหมู่ที่เลือก
    final filteredProducts = _selectedCategory == null
        ? products
        : products.where((p) => p.categoryId == _selectedCategory!.id).toList();

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'EcoLevel',
                  style: TextStyle(
                    fontSize: 16, // ลดขนาดลง
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'สินค้าตรวจสอบจาก Greenmarket',
                style: TextStyle(
                  fontSize: 12, // ลดขนาดลง
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // แถบค้นหาเล็กๆ สำหรับค้นหาสินค้าทั้งหมด
            Container(
              height: 38, // ลดความสูงลง
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20), // ลดรัศมี
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _ecoSearchController,
                onChanged: (value) {
                  setState(() {
                    _ecoSearchQuery = value;
                  });
                },
                style: const TextStyle(
                  fontSize: 13, // ลดขนาดฟอนต์
                  color: Color(0xFF333333),
                ),
                decoration: InputDecoration(
                  hintText:
                      'ค้นหาสินค้า หมวดหมู่ หรือชื่อผู้ขาย...', // เปลี่ยนข้อความ
                  hintStyle: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12, // ลดขนาดฟอนต์
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4CAF50),
                    size: 16, // ลดขนาดไอคอน
                  ),
                  suffixIcon: _ecoSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF999999),
                            size: 14,
                          ),
                          onPressed: () {
                            setState(() {
                              _ecoSearchController.clear();
                              _ecoSearchQuery = '';
                            });
                          },
                        )
                      : Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2), // ลด padding
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8), // ลดรัศมี
                          ),
                          child: const Center(
                            child: Text(
                              'ALL', // เปลี่ยนข้อความ
                              style: TextStyle(
                                fontSize: 9, // ลดขนาดฟอนต์
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8), // ลด padding
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Single row of compact buttons
            SizedBox(
              height: 42, // เพิ่มความสูงขึ้นจาก 36 เป็น 42
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "ทั้งหมด" button
                  _buildCompactEcoLevelButton(
                    title: '🌟 ทั้งหมด', // เปลี่ยนไอคอนให้เด่นกว่า
                    count: filteredProducts.length,
                    isSelected: _selectedEcoLevel == null,
                    colors: [const Color(0xFF2196F3), const Color(0xFF21CBF3)],
                    onTap: () {
                      setState(() {
                        _selectedEcoLevel = null;
                      });
                    },
                  ),
                  const SizedBox(width: 6), // ลด spacing ลงอีก

                  // EcoLevel buttons
                  ...EcoLevel.values.map((level) {
                    final levelProducts = filteredProducts
                        .where((p) => p.ecoLevel == level)
                        .toList();
                    final isSelected = _selectedEcoLevel == level;
                    return Padding(
                      padding:
                          const EdgeInsets.only(right: 6), // ลด spacing ลงอีก
                      child: _buildCompactEcoLevelButton(
                        title:
                            '${_getEcoLevelEmoji(level)} ${_getEcoLevelThaiName(level)}',
                        count: levelProducts.length,
                        isSelected: isSelected,
                        colors: _getEcoLevelGradient(level),
                        onTap: () {
                          setState(() {
                            _selectedEcoLevel = level;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularProductsSection(List<Product> products) {
    // กรองสินค้าตามหมวดหมู่ที่เลือก
    List<Product> filteredProducts = _selectedCategory == null
        ? products
        : products.where((p) => p.categoryId == _selectedCategory!.id).toList();

    // กรองเพิ่มเติมตาม EcoLevel ที่เลือก
    if (_selectedEcoLevel != null) {
      filteredProducts = filteredProducts
          .where((p) => p.ecoLevel == _selectedEcoLevel)
          .toList();
    }

    // กรองเพิ่มเติมตาม main search query (แถบค้นหาด้านบน)
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.ecoLevel.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // กรองเพิ่มเติมตาม EcoLevel search query
    if (_ecoSearchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.name
                .toLowerCase()
                .contains(_ecoSearchQuery.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(_ecoSearchQuery.toLowerCase()) ||
            product.ecoLevel.name
                .toLowerCase()
                .contains(_ecoSearchQuery.toLowerCase());
      }).toList();
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getSearchResultTitle(),
                        style: const TextStyle(
                          fontSize: 16, // ลดขนาดลง
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      _getSearchResultSubtitle(filteredProducts.length),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Products section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (filteredProducts.isEmpty)
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategory == null
                                  ? 'ไม่พบสินค้า'
                                  : 'ไม่พบสินค้าในหมวดหมู่ ${_selectedCategory!.name}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredProducts.take(6).length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 16),
                            child: ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
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
          builder: (context) => const AdminPanelScreen(),
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

  String _getSearchResultTitle() {
    bool hasMainSearch = _searchQuery.isNotEmpty;
    bool hasEcoSearch = _ecoSearchQuery.isNotEmpty;
    bool hasCategory = _selectedCategory != null;
    bool hasEcoLevel = _selectedEcoLevel != null;

    // สร้างข้อความตาม filter ที่เลือก
    List<String> parts = [];

    if (hasMainSearch && hasEcoSearch) {
      parts.add('ผลการค้นหา: "$_searchQuery" + "$_ecoSearchQuery"');
    } else if (hasMainSearch) {
      parts.add('ผลการค้นหา: "$_searchQuery"');
    } else if (hasEcoSearch) {
      parts.add('ผลการค้นหา EcoLevel: "$_ecoSearchQuery"');
    } else if (hasEcoLevel) {
      parts.add('สินค้าระดับ ${_getEcoLevelThaiName(_selectedEcoLevel!)}');
    } else {
      parts.add('สินค้ายอดนิยม');
    }

    if (hasCategory) {
      parts.add('ใน ${_selectedCategory!.name}');
    }

    return parts.join(' ');
  }

  String _getSearchResultSubtitle(int productCount) {
    bool hasMainSearch = _searchQuery.isNotEmpty;
    bool hasEcoSearch = _ecoSearchQuery.isNotEmpty;
    bool hasCategory = _selectedCategory != null;
    bool hasEcoLevel = _selectedEcoLevel != null;

    // สร้างข้อความย่อยตาม filter ที่เลือก
    if (hasMainSearch || hasEcoSearch) {
      if (hasCategory && hasEcoLevel) {
        return 'พบ $productCount รายการใน ${_selectedCategory!.name} • ${_getEcoLevelThaiName(_selectedEcoLevel!)}';
      } else if (hasCategory) {
        return 'พบ $productCount รายการใน ${_selectedCategory!.name}';
      } else if (hasEcoLevel) {
        return 'พบ $productCount รายการระดับ ${_getEcoLevelThaiName(_selectedEcoLevel!)}';
      }
      return 'พบ $productCount รายการ';
    } else {
      if (hasCategory && hasEcoLevel) {
        return 'สินค้าคุณภาพใน ${_selectedCategory!.name} • ระดับ ${_getEcoLevelThaiName(_selectedEcoLevel!)}';
      } else if (hasCategory) {
        return 'สินค้าคุณภาพในหมวดหมู่ ${_selectedCategory!.name}';
      } else if (hasEcoLevel) {
        return 'สินค้าคุณภาพระดับ ${_getEcoLevelThaiName(_selectedEcoLevel!)}';
      }
      return 'สินค้าคุณภาพที่ได้รับความนิยม';
    }
  }

  // ฟังก์ชันสำหรับจัดการ EcoLevel
  String _getEcoLevelEmoji(EcoLevel level) {
    switch (level) {
      case EcoLevel.basic:
        return '🌱'; // เริ่มต้น - ต้นอ่อน (เขียว)
      case EcoLevel.standard:
        return '🛡️'; // มาตรฐาน - โล่เงิน
      case EcoLevel.premium:
        return '🏆'; // พรีเมียม - โล่ทอง (ถ้วยทอง)
      case EcoLevel.platinum:
        return '💎'; // แพลตตินั่ม - เพชรระยิบระยับ (เงินขาวทอง)
    }
  }

  String _getEcoLevelThaiName(EcoLevel level) {
    switch (level) {
      case EcoLevel.basic:
        return 'เริ่มต้น';
      case EcoLevel.standard:
        return 'มาตราฐาน';
      case EcoLevel.premium:
        return 'พรีเมี่ยม';
      case EcoLevel.platinum:
        return 'แพลตตินั่ม';
    }
  }

  Widget _buildCompactEcoLevelButton({
    required String title,
    required int count,
    required bool isSelected,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    // ปรับสีขอบให้เหมาะสมกับแต่ละระดับ
    Color borderColor;
    if (title.contains('🌱')) {
      // Basic level - ใช้สีเทาเข้มสำหรับขอบ
      borderColor = isSelected ? Colors.transparent : const Color(0xFF9E9E9E);
    } else {
      borderColor =
          isSelected ? Colors.transparent : colors[0].withOpacity(0.3);
    }

    // ตรวจสอบว่าเป็น platinum หรือไม่ (สีเงินขาวเพชร)
    bool isPlatinum = title.contains('💎');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 5), // เพิ่ม padding ให้ใหญ่ขึ้น
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: colors)
              : LinearGradient(colors: [
                  title.contains('🌱') ? Colors.white : Colors.white,
                  title.contains('🌱')
                      ? Colors.grey.shade50
                      : Colors.grey.shade50
                ]),
          borderRadius: BorderRadius.circular(12), // เพิ่มรัศมีขึ้น
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colors[0].withOpacity(0.2)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: isSelected ? 4 : 2, // ลด blur ลงอีก
              offset: const Offset(0, 1), // ลด offset
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? (title.contains('🌱') || isPlatinum
                        ? const Color(0xFF333333) // เงินขาว/basic ใช้สีเข้ม
                        : Colors.white) // สีอื่นใช้สีขาว
                    : colors[0] == Colors.white ||
                            colors[0] == const Color(0xFFE0E0E0)
                        ? const Color(0xFF333333) // เงินขาว/basic ใช้สีเข้ม
                        : colors[0],
                fontSize:
                    title.contains('ทั้งหมด') ? 11 : 10, // เพิ่มขนาดฟอนต์ขึ้น
                fontWeight: title.contains('ทั้งหมด') && isSelected
                    ? FontWeight.w900 // เน้นพิเศษสำหรับ "ทั้งหมด" เมื่อถูกเลือก
                    : isSelected
                        ? FontWeight.bold
                        : FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1), // เพิ่ม spacing
            Text(
              '$count รายการ',
              style: TextStyle(
                color: isSelected
                    ? (title.contains('🌱') || isPlatinum
                        ? const Color(0xFF666666) // เงินขาว/basic ใช้สีเข้ม
                        : Colors.white.withOpacity(0.9)) // สีอื่นใช้สีขาว
                    : Colors.grey.shade600,
                fontSize: 8, // เพิ่มขนาดฟอนต์ขึ้น
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.ecoLevel.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by eco search query - ขยายการค้นหาให้ครอบคลุมมากขึ้น
    if (_ecoSearchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final query = _ecoSearchQuery.toLowerCase();
        return product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.ecoLevel.name.toLowerCase().contains(query) ||
            product.materialDescription.toLowerCase().contains(query) ||
            product.ecoJustification.toLowerCase().contains(query) ||
            (product.categoryName?.toLowerCase().contains(query) ?? false) ||
            product.sellerId
                .toLowerCase()
                .contains(query) || // ค้นหาตาม sellerId
            (product.keywords
                    ?.any((keyword) => keyword.toLowerCase().contains(query)) ??
                false); // ค้นหาตาม keywords
      }).toList();
    }

    return filtered;
  }

  // Enhanced section to show products by category with eco level grouping
  Widget _buildCategoryProductsWithEcoLevel(List<Product> products) {
    final filteredProducts = _getFilteredProducts(products);

    if (filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedCategory == null
                      ? 'ไม่พบสินค้า'
                      : 'ไม่พบสินค้าในหมวดหมู่ ${_selectedCategory!.name}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Group products by eco level
    Map<EcoLevel, List<Product>> productsByEcoLevel = {};
    for (var product in filteredProducts) {
      productsByEcoLevel.putIfAbsent(product.ecoLevel, () => []).add(product);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final ecoLevel = EcoLevel.values[index];
          final levelProducts = productsByEcoLevel[ecoLevel] ?? [];

          if (levelProducts.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eco level header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        _getEcoLevelEmoji(ecoLevel),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ระดับ ${_getEcoLevelThaiName(ecoLevel)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ecoLevel.color,
                              ),
                            ),
                            Text(
                              '${levelProducts.length} รายการ${_selectedCategory != null ? ' ใน ${_selectedCategory!.name}' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EcoLevelProductsScreen(ecoLevel: ecoLevel),
                            ),
                          );
                        },
                        child: const Text('ดูทั้งหมด'),
                      ),
                    ],
                  ),
                ),
                // Products horizontal list
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: levelProducts.take(5).length,
                    itemBuilder: (context, productIndex) {
                      final product = levelProducts[productIndex];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        child: ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        childCount: EcoLevel.values.length,
      ),
    );
  }
}
