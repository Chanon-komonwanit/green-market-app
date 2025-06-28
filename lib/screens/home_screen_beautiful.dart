// d:/Development/green_market/lib/screens/home_screen_beautiful.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/models/promotion.dart';
import 'package:green_market/screens/category_products_screen.dart';
import 'package:green_market/screens/search_screen.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';
import 'package:provider/provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/screens/investment_hub_screen.dart';
import 'package:green_market/screens/sustainable_activities_hub_screen.dart';
import 'package:green_market/models/news_article_model.dart';
import 'package:green_market/services/news_service.dart';
import 'package:green_market/screens/news_article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _homeDataFuture;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();

    // Animation for shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    print('HomeScreen: Starting to fetch data...');
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // Fetch categories first with shorter timeout
      print('HomeScreen: Fetching categories...');
      List<Category> categories = [];
      try {
        categories = await firebaseService
            .getCategories()
            .first
            .timeout(Duration(seconds: 5), onTimeout: () {
          print('Categories timeout - using empty list');
          return <Category>[];
        });
        print('HomeScreen: Categories loaded: ${categories.length}');
      } catch (e) {
        print('Error fetching categories: $e');
        categories = [];
      }

      // Fetch promotions
      List<Promotion> promotions = [];
      try {
        promotions = await firebaseService.getActivePromotions().first.timeout(
              Duration(seconds: 5),
              onTimeout: () => <Promotion>[],
            );
        print('HomeScreen: Promotions loaded: ${promotions.length}');
      } catch (e) {
        print('Error fetching promotions: $e');
        promotions = [];
      }

      // Fetch products
      List<Product> products = [];
      try {
        products = await firebaseService.getApprovedProducts().first.timeout(
              Duration(seconds: 5),
              onTimeout: () => <Product>[],
            );
        print('HomeScreen: Products loaded: ${products.length}');
      } catch (e) {
        print('Error fetching products: $e');
        products = [];
      }

      return {
        'promotions': promotions,
        'categories': categories,
        'products': products,
        'showWelcome':
            products.isEmpty && categories.isEmpty && promotions.isEmpty,
      };
    } catch (e) {
      print('Error in _fetchHomeData: $e');
      return {
        'promotions': <Promotion>[],
        'categories': <Category>[],
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
          final promotions = data['promotions'] as List<Promotion>;
          final categories = data['categories'] as List<Category>;
          final products = data['products'] as List<Product>;
          final showWelcome = data['showWelcome'] as bool;

          if (showWelcome) {
            return _buildWelcomeState();
          }

          return _buildMainContent(context, promotions, categories, products);
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
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
                strokeWidth: 4,
              ),
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
            SizedBox(height: 8),
            Text(
              'ตลาดออนไลน์แห่งแรกในโลกเพื่อสิ่งแวดล้อม',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEBEE), Color(0xFFF8FDF8)],
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withAlpha(25),
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
              const SizedBox(height: 8),
              const Text(
                'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
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
              // Hero Logo Section
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withAlpha(51),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.eco, size: 120, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 40),

              // Welcome Text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                      ).createShader(bounds),
                      child: const Text(
                        'ยินดีต้อนรับสู่',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      ).createShader(bounds),
                      child: const Text(
                        'GREEN MARKET',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
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
                            color: Colors.green.withAlpha(51),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        '🌍 ตลาดออนไลน์แห่งแรกในโลกเพื่อสิ่งแวดล้อม',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ร่วมเป็นส่วนหนึ่งในการเปลี่ยนแปลงโลกให้ดีขึ้น\nด้วยการซื้อขายผลิตภัณฑ์เพื่อสิ่งแวดล้อม',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF555555),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Call to Action
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Text(
                      '🌱 เริ่มต้นการเดินทางสีเขียวของคุณ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        shadowColor: Colors.green.withAlpha(102),
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

  Widget _buildMainContent(BuildContext context, List<Promotion> promotions,
      List<Category> categories, List<Product> products) {
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
          // Beautiful App Bar
          _buildSliverAppBar(),

          // Hero Banner
          if (promotions.isNotEmpty) _buildHeroBanner(promotions),

          // Categories Section
          if (categories.isNotEmpty) _buildCategoriesSection(categories),

          // Featured Products
          if (products.isNotEmpty) _buildFeaturedProducts(products),

          // Eco Impact Section
          _buildEcoImpactSection(),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GREEN MARKET',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'ตลาดออนไลน์เพื่อสิ่งแวดล้อม',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GreenWorldHubScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.explore, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        },
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'ค้นหาผลิตภัณฑ์เพื่อสิ่งแวดล้อม...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(List<Promotion> promotions) {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        child: PageView.builder(
          itemCount: promotions.length,
          itemBuilder: (context, index) {
            final promotion = promotions[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withAlpha(76),
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
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(153),
                          ],
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
          },
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${categories.length} หมวดหมู่',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CategoryProductsScreen(category: category),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryTeal.withAlpha(25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
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
                                          color:
                                              AppColors.lightTeal.withAlpha(51),
                                          child: const Icon(
                                            Icons.eco,
                                            color: AppColors.primaryTeal,
                                            size: 30,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: AppColors.lightTeal.withAlpha(51),
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
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

  Widget _buildFeaturedProducts(List<Product> products) {
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
                    'สินค้าแนะนำ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${products.length} รายการ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: products.take(10).length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.of(context).push(
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

  Widget _buildEcoImpactSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withAlpha(76),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              '🌍 ผลกระทบเชิงบวกต่อสิ่งแวดล้อม',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    icon: Icons.co2,
                    value: '1,234',
                    unit: 'kg CO₂',
                    label: 'ลดการปล่อย',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImpactCard(
                    icon: Icons.recycling,
                    value: '567',
                    unit: 'ชิ้น',
                    label: 'รีไซเคิล',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImpactCard(
                    icon: Icons.nature_people,
                    value: '89',
                    unit: 'โครงการ',
                    label: 'สนับสนุน',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GreenWorldHubScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.explore),
              label: const Text('เปิดโลกสีเขียว'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2E7D32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
