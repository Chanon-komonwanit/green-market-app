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
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // Fetch data with timeout
      final futures = await Future.wait([
        firebaseService.getCategories().first.timeout(
              const Duration(seconds: 5),
              onTimeout: () => <Category>[],
            ),
        firebaseService.getActivePromotions().first.timeout(
              const Duration(seconds: 5),
              onTimeout: () => <Promotion>[],
            ),
        firebaseService.getApprovedProducts().first.timeout(
              const Duration(seconds: 5),
              onTimeout: () => <Product>[],
            ),
      ]);

      final categories = futures[0] as List<Category>;
      final promotions = futures[1] as List<Promotion>;
      final products = futures[2] as List<Product>;

      return {
        'categories': categories,
        'promotions': promotions,
        'products': products,
        'showWelcome':
            products.isEmpty && categories.isEmpty && promotions.isEmpty,
      };
    } catch (e) {
      print('Error fetching home data: $e');
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
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 2,
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
                        '🌍 ตลาดออนไลน์เพื่อสิ่งแวดล้อม',
                        style: TextStyle(
                          fontSize: 16,
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
          _buildSelectedEcoLevelProducts(products),
          _buildPopularProductsSection(products),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              '🌱',
                              style: TextStyle(fontSize: 26),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [Colors.white, Color(0xFFE8F5E8)],
                                  stops: [0.0, 1.0],
                                ).createShader(bounds),
                                child: const Text(
                                  'GREEN MARKET',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: const Text(
                                  'ตลาดออนไลน์เพื่อโลกแห่งความยั่งยืน',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    fontFamily: 'Sarabun',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
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
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [Colors.white, Color(0xFFB8E6B8)],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'The World\'s First Eco Market',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      fontFamily: 'Sarabun',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Admin Settings Button (visible for admins)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
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
                  ),
                ),
                const SizedBox(width: 8),
                // Eco Coins Widget
                const EcoCoinsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: GestureDetector(
          onTap: () {
            // Navigate to search screen
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 15,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF667eea).withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: TextFormField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '🔍 ค้นหาสินค้า ร้านค้า หมวดหมู่...',
                hintStyle: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'GREEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                fontSize: 20,
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
            // Header with gold underline
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '💎 ',
                        style: TextStyle(fontSize: 18),
                      ),
                      const Text(
                        'แพลตตินั่มฮีโร่',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'แนะนำสูงสุด',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Gold underline
                  Container(
                    height: 3,
                    width: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                          Color(0xFFFFD700),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สินค้าระดับสูงสุดสุดยอดแห่งความยั่งยืน • ${platinumProducts.length} รายการ',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1, // +1 สำหรับปุ่ม "ทั้งหมด"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // ปุ่ม "ทั้งหมด"
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = null; // เลือกทั้งหมด
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
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
                                size: 35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ทั้งหมด',
                              style: TextStyle(
                                fontSize: _selectedCategory == null ? 14 : 12,
                                fontWeight: _selectedCategory == null
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _selectedCategory == null
                                    ? const Color(0xFF2E7D32)
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
                    width: 100,
                    margin: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category; // เลือกหมวดหมู่
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
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
                                            size: 30,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.transparent,
                                      child: const Icon(
                                        Icons.eco,
                                        color: AppColors.primaryTeal,
                                        size: 30,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 12,
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
        return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)]; // Green
      case EcoLevel.standard:
        return [
          const Color(0xFF2196F3),
          const Color(0xFF03DAC6)
        ]; // Blue to Teal
      case EcoLevel.premium:
        return [
          const Color(0xFF9C27B0),
          const Color(0xFFE91E63)
        ]; // Purple to Pink
      case EcoLevel.platinum:
        return [
          const Color(0xFFFF9800),
          const Color(0xFFFFC107)
        ]; // Orange to Amber
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
                    fontSize: 18,
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
                  fontSize: 14,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // แถบค้นหาเล็กๆ ที่ใช้งานได้จริง
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
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
                decoration: InputDecoration(
                  hintText: 'ค้นหาสินค้าใน EcoLevel...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'ECO',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Single row of compact buttons
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "ทั้งหมด" button
                  _buildCompactEcoLevelButton(
                    title: '📱 ทั้งหมด',
                    count: filteredProducts.length,
                    isSelected: _selectedEcoLevel == null,
                    colors: [const Color(0xFF2196F3), const Color(0xFF21CBF3)],
                    onTap: () {
                      setState(() {
                        _selectedEcoLevel = null;
                      });
                    },
                  ),
                  const SizedBox(width: 12),

                  // EcoLevel buttons
                  ...EcoLevel.values.map((level) {
                    final levelProducts = filteredProducts
                        .where((p) => p.ecoLevel == level)
                        .toList();
                    final isSelected = _selectedEcoLevel == level;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
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
                          fontSize: 22,
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

    if (hasMainSearch && hasEcoSearch) {
      if (hasCategory) {
        return 'ผลการค้นหา: "$_searchQuery" + "$_ecoSearchQuery" ใน ${_selectedCategory!.name}';
      }
      return 'ผลการค้นหา: "$_searchQuery" + "$_ecoSearchQuery"';
    } else if (hasMainSearch) {
      if (hasCategory) {
        return 'ผลการค้นหา: "$_searchQuery" ใน ${_selectedCategory!.name}';
      }
      return 'ผลการค้นหา: "$_searchQuery"';
    } else if (hasEcoSearch) {
      if (hasCategory) {
        return 'ผลการค้นหา EcoLevel: "$_ecoSearchQuery" ใน ${_selectedCategory!.name}';
      }
      return 'ผลการค้นหา EcoLevel: "$_ecoSearchQuery"';
    } else {
      if (hasCategory) {
        return 'สินค้ายอดนิยม - ${_selectedCategory!.name}';
      }
      return 'สินค้ายอดนิยม';
    }
  }

  String _getSearchResultSubtitle(int productCount) {
    bool hasMainSearch = _searchQuery.isNotEmpty;
    bool hasEcoSearch = _ecoSearchQuery.isNotEmpty;
    bool hasCategory = _selectedCategory != null;

    if (hasMainSearch || hasEcoSearch) {
      if (hasCategory) {
        return 'พบ $productCount รายการใน ${_selectedCategory!.name}';
      }
      return 'พบ $productCount รายการ';
    } else {
      if (hasCategory) {
        return 'สินค้าคุณภาพในหมวดหมู่ ${_selectedCategory!.name}';
      }
      return 'สินค้าคุณภาพที่ได้รับความนิยม';
    }
  }

  // ฟังก์ชันสำหรับจัดการ EcoLevel
  String _getEcoLevelEmoji(EcoLevel level) {
    switch (level) {
      case EcoLevel.basic:
        return '🌱'; // เริ่มต้น - ต้นอ่อน
      case EcoLevel.standard:
        return '🌿'; // มาตราฐาน - ใบไผ่
      case EcoLevel.premium:
        return '🌳'; // พรีเมี่ยม - ต้นไม้ใหญ่
      case EcoLevel.platinum:
        return '💎'; // แพลตินั่ม - เพชร
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: colors)
              : LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : colors[0].withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colors[0].withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : colors[0],
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '$count รายการ',
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedEcoLevelProducts(List<Product> products) {
    if (_selectedEcoLevel == null)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    // กรองสินค้าตามหมวดหมู่และ EcoLevel ที่เลือก
    List<Product> filteredProducts =
        products.where((p) => p.ecoLevel == _selectedEcoLevel).toList();

    if (_selectedCategory != null) {
      filteredProducts = filteredProducts
          .where((p) => p.categoryId == _selectedCategory!.id)
          .toList();
    }

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
                Text(
                  _getEcoLevelEmoji(_selectedEcoLevel!),
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  'ไม่พบสินค้าระดับ ${_getEcoLevelThaiName(_selectedEcoLevel!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCategory != null
                      ? 'ในหมวดหมู่ ${_selectedCategory!.name}'
                      : 'กรุณาลองเลือกหมวดหมู่อื่น',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                  Text(
                    _getEcoLevelEmoji(_selectedEcoLevel!),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สินค้าระดับ ${_getEcoLevelThaiName(_selectedEcoLevel!)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          '${filteredProducts.length} รายการ${_selectedCategory != null ? ' ใน ${_selectedCategory!.name}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Products list
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
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
          ],
        ),
      ),
    );
  }
}
