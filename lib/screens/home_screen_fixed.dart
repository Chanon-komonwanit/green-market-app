// lib/screens/home_screen_fixed.dart
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
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
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
            child: SizedBox(
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
                    children: const [
                      Text(
                        'GREEN MARKET',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'ตลาดออนไลน์เพื่อสิ่งแวดล้อม',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Eco Coins Widget ขนาดเล็ก
                Container(
                  height: 28,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, color: Colors.white, size: 10),
                      SizedBox(width: 2),
                      Text(
                        '1250',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 6),
                    ],
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

          // Categories
          if (categories.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'หมวดหมู่สินค้า',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
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
                                color: AppColors.lightTeal,
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
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            Icon(Icons.category,
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
            ),
          ],

          // Products Grid
          if (products.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Text(
                  'สินค้าทั้งหมด',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                  childCount: products.length,
                ),
              ),
            ),
          ],

          // Empty state
          if (products.isEmpty && categories.isEmpty) ...[
            SliverToBoxAdapter(
              child: SizedBox(
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
        ],
      ),
    );
  }
}
