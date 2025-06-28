// lib/screens/home_screen.dart
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
import 'package:green_market/screens/eco_level_products_screen.dart';
import 'package:green_market/widgets/eco_coins_widget.dart';
import 'package:green_market/providers/eco_coins_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _homeDataFuture;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinAnimation;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();

    // แอนิเมชันสำหรับเหลียญ Eco
    _coinAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _coinAnimation = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _coinAnimationController,
      curve: Curves.easeInOut,
    ));

    // เริ่มแอนิเมชัน
    _coinAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _coinAnimationController.dispose();
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
            .timeout(Duration(seconds: 3), onTimeout: () {
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
              Duration(seconds: 3),
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
              Duration(seconds: 3),
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
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          _buildAppBarWithEcoCoins(),
          SliverToBoxAdapter(
            child: Container(
              height: 400,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          _buildAppBarWithEcoCoins(),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _homeDataFuture = _fetchHomeData();
                      });
                    },
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          _buildAppBarWithEcoCoins(),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.store, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'ยินดีต้อนรับสู่ Green Market',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('ตลาดออนไลน์เพื่อสิ่งแวดล้อม'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _homeDataFuture = _fetchHomeData();
                      });
                    },
                    child: const Text('รีเฟรช'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarWithEcoCoins() {
    return SliverAppBar(
      expandedHeight: 100, // ลดขนาดลง
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GREEN MARKET',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const Text(
                        'ตลาดออนไลน์เพื่อสิ่งแวดล้อม',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // โซนเหลียญ Eco ⭐
                Tooltip(
                  message:
                      'เหรียญ Eco 🪙\nใช้ซื้อสินค้าและแลกรางวัล\nแตะเพื่อดูรายละเอียด',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/eco-coins');
                    },
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFD700), // Gold
                            const Color(0xFFFFA500), // Orange
                          ],
                        ),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Consumer<EcoCoinsProvider>(
                        builder: (context, provider, child) {
                          final balance =
                              provider.balance?.availableCoins ?? 1250;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ไอคอนเหลียญ Eco พร้อมแอนิเมชัน
                              AnimatedBuilder(
                                animation: _coinAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _coinAnimation.value,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.shade400,
                                            Colors.yellow.shade600,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '🪙',
                                          style: TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 5),
                              Text(
                                balance.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 9,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, List<Promotion> promotions,
      List<Category> categories, List<Product> products) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          _buildAppBarWithEcoCoins(),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600]),
                      const SizedBox(width: 10),
                      Text(
                        'ค้นหาสินค้า...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 1. News/Promotions Banner (ข่าวสาร/โฆษณาบนสุด - แอดมินจัดการได้)
          if (promotions.isNotEmpty) _buildNewsPromotionBanner(promotions),

          // 2. Hero Products Section (สินค้าระดับ Platinum Hero เท่านั้น)
          _buildPlatinumHeroProductsSection(products),

          // 3. Categories (หมวดหมู่สินค้า)
          if (categories.isNotEmpty) _buildCategoriesSection(categories),

          // 4. All Products Section (รวมสินค้าทั้งหมด)
          if (products.isNotEmpty) _buildAllProductsSection(products),

          // 5. Products by Eco Level (สินค้าแยกระดับ Eco)
          _buildEcoLevelProductsSection(products),

          // Empty state
          if (products.isEmpty && categories.isEmpty && promotions.isEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'ยังไม่มีสินค้า',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรุณาลองใหม่อีกครั้งในภายหลัง',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  // 3. Categories Section
  Widget _buildCategoriesSection(List<Category> categories) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
            child: Row(
              children: [
                Icon(Icons.category, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  '📋 หมวดหมู่สินค้า',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          // Categories List
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CategoryProductsScreen(category: category),
                    ),
                  ),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: category.iconData != null
                              ? Icon(category.iconData,
                                  color: AppColors.primaryGreen, size: 30)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.network(
                                    category.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.category,
                                            color: AppColors.primaryGreen,
                                            size: 30),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
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
    );
  }

  // 4. All Products Section
  Widget _buildAllProductsSection(List<Product> products) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
            child: Row(
              children: [
                Icon(Icons.inventory_2,
                    color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  '🛒 สินค้าทั้งหมด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const Spacer(),
                Text(
                  '${products.length} รายการ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Products Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // สร้าง Eco Level Products Section Widget (สินค้าแยกระดับ Eco)
  Widget _buildEcoLevelProductsSection(List<Product> products) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.eco, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '🌱 สินค้าแยกตามระดับ Eco',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Eco Level Selection Cards
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: EcoLevel.values.length,
                itemBuilder: (context, index) {
                  final ecoLevel = EcoLevel.values[index];
                  final levelProductCount =
                      products.where((p) => p.ecoLevel == ecoLevel).length;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EcoLevelProductsScreen(ecoLevel: ecoLevel),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ecoLevel.gradientStart,
                            ecoLevel.gradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ecoLevel.color, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: ecoLevel.color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with background
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: ecoLevel.color, width: 2),
                            ),
                            child: Icon(
                              ecoLevel.icon,
                              color: ecoLevel.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Level name
                          Text(
                            ecoLevel.fullName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          // Product count
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$levelProductCount สินค้า',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ecoLevel.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Products by each Eco Level (เรียงจากระดับสูงสุดลงมา)
            ...EcoLevel.values.reversed.map((ecoLevel) {
              final levelProducts = products
                  .where((p) => p.ecoLevel == ecoLevel)
                  .take(4)
                  .toList();

              if (levelProducts.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ecoLevel.backgroundColor,
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Header with gradient background
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ecoLevel.gradientStart,
                            ecoLevel.gradientEnd
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ecoLevel.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icon with white background
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(ecoLevel.icon,
                                color: ecoLevel.color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      ecoLevel.shortCode,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (ecoLevel == EcoLevel.platinum) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.white, width: 1),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star,
                                                color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text(
                                              'แนะนำสูงสุด',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ecoLevel.marketingDescription,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
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
                                  builder: (_) => EcoLevelProductsScreen(
                                      ecoLevel: ecoLevel),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'ดูทั้งหมด',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: levelProducts.length,
                        itemBuilder: (context, index) {
                          final product = levelProducts[index];
                          return Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 12),
                            child: ProductCard(
                              product: product,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: product),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // สร้าง News/Promotion Banner Widget (ข่าวสาร/โฆษณาที่แอดมินจัดการได้ - รองรับรูปและข้อความ)
  Widget _buildNewsPromotionBanner(List<Promotion> promotions) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header สำหรับข่าวสาร/โฆษณา
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '📢 ข่าวสารและโปรโมชั่น',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${promotions.length} รายการ',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Banner แสดงข่าวสาร/โฆษณา พร้อม PageView
            Container(
              height: 200,
              child: PageView.builder(
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  final promotion = promotions[index];
                  final hasImage = promotion.image.isNotEmpty;

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Background: รูปภาพหรือ Gradient
                          Positioned.fill(
                            child: hasImage
                                ? Image.network(
                                    promotion.image,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildGradientBackground(index),
                                  )
                                : _buildGradientBackground(index),
                          ),
                          // Overlay สำหรับให้ข้อความชัดขึ้น
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black
                                        .withOpacity(hasImage ? 0.6 : 0.3),
                                    Colors.transparent,
                                    Colors.black
                                        .withOpacity(hasImage ? 0.4 : 0.1),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          // เนื้อหาข้อความและไอคอน
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // หัวข้อพร้อมพื้นหลัง
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      promotion.title,
                                      style: TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // รายละเอียด
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      promotion.description,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ไอคอนและป้ายมุมขวาบน
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(25),
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
                                  Icon(
                                    Icons.local_offer,
                                    color: AppColors.primaryGreen,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'HOT',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Page indicator dots (ถ้ามีมากกว่า 1 รายการ)
                          if (promotions.length > 1)
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${index + 1}/${promotions.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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

  // Helper method สำหรับสร้าง Gradient Background
  Widget _buildGradientBackground(int index) {
    final gradients = [
      LinearGradient(
        colors: [
          AppColors.primaryGreen.withOpacity(0.8),
          Colors.teal.shade400.withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [
          Colors.blue.shade500.withOpacity(0.8),
          Colors.indigo.shade400.withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [
          Colors.purple.shade500.withOpacity(0.8),
          Colors.pink.shade400.withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: gradients[index % gradients.length],
      ),
    );
  }

  // สร้าง Platinum Hero Products Section Widget (เฉพาะสินค้าระดับ Platinum เท่านั้น)
  Widget _buildPlatinumHeroProductsSection(List<Product> products) {
    final platinumProducts =
        products.where((p) => p.ecoLevel == EcoLevel.platinum).take(6).toList();

    if (platinumProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header with Platinum styling
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    EcoLevel.platinum.gradientStart,
                    EcoLevel.platinum.gradientEnd,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: EcoLevel.platinum.color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Platinum Icon with white background
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: EcoLevel.platinum.color, width: 2),
                    ),
                    child: Icon(
                      EcoLevel.platinum.icon,
                      color: EcoLevel.platinum.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '💎 แพลตตินั่มฮีโร่',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'แนะนำสูงสุด',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'สินค้าระดับสูงสุดที่เป็นจุดสุดยอดแห่งความยั่งยืน',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${platinumProducts.length} สินค้า',
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
            const SizedBox(height: 16),
            // Products horizontal list
            Container(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: platinumProducts.length,
                itemBuilder: (context, index) {
                  final product = platinumProducts[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          EcoLevel.platinum.backgroundColor,
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(
                        color: EcoLevel.platinum.color.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: EcoLevel.platinum.color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ProductCard(
                      product: product,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
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
}
