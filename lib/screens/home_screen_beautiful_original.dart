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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _homeDataFuture;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ecoSearchController = TextEditingController();

  late TabController _ecoLevelTabController;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
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
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

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
      };
    } catch (e) {
      print('[ERROR] Failed to fetch home data: $e');
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Green Market',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              _showUserProfile();
            },
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ยินดีต้อนรับสู่ Green Market!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ร้านค้าที่ใส่ใจสิ่งแวดล้อมและชุมชน',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Text(
                  'สวัสดี ${snapshot.data!.displayName ?? 'ผู้ใช้'}!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return const Text(
                'เข้าสู่ระบบเพื่อรับสิทธิประโยชน์เพิ่มเติม',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEcoCoinsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const EnhancedEcoCoinsWidget(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ค้นหาสินค้า...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                // Handle search query change
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(List<Category> categories) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'หมวดหมู่สินค้า',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(category: category),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(category.name),
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
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

  Widget _buildGreenWorldHubSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    GreenWorldIcon(),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Green World Hub',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ศูนย์รวมนวัตกรรมเพื่อโลกสีเขียว',
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
                SizedBox(height: 16),
                Text(
                  'ร่วมสร้างโลกที่ยั่งยืนด้วยเทคโนโลยีและนวัตกรรมสีเขียว',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                AnimatedGreenWorldButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSustainableInvestmentZoneSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.trending_up,
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
                            'Sustainable Investment Zone',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ลงทุนเพื่อความยั่งยืน',
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
                  'ลงทุนในโครงการที่ช่วยสร้างโลกที่ดีขึ้น และได้รับผลตอบแทนที่ยั่งยืน',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to investment screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1976D2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('เริ่มลงทุน'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Navigate to investment info screen
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('เรียนรู้เพิ่มเติม'),
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
  }

  Widget _buildCommunityActivitiesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to community activities screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF6B35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('ดูกิจกรรม'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Navigate to create activity screen
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('สร้างกิจกรรม'),
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
  }

  Widget _buildPromotionsSection(List<Promotion> promotions) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'โปรโมชั่นพิเศษ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final promotion = promotions[index];
                return _buildPromotionCard(promotion);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  promotion.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'ส่วนลด ${promotion.discountValue}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Apply promotion
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF5722),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('ใช้เลย'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEcoLevelProductsSection(List<Product> products) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'สินค้าตามระดับความเป็นมิตรต่อสิ่งแวดล้อม',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _ecoLevelTabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF4CAF50),
              labelColor: const Color(0xFF4CAF50),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'ทั้งหมด'),
                Tab(text: 'Basic'),
                Tab(text: 'Good'),
                Tab(text: 'Better'),
                Tab(text: 'Best'),
              ],
            ),
          ),
          SizedBox(
            height: 300,
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
    );
  }

  Widget _buildProductsList(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'ไม่พบสินค้าในระดับนี้',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: 12),
          child: ProductCard(
            product: product,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'สินค้าแนะนำ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
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
    );
  }

  Widget _buildPopularProductsSection(List<Product> products) {
    final popularProducts =
        products.where((p) => p.averageRating >= 4.0).toList();
    popularProducts.sort((a, b) => b.averageRating.compareTo(a.averageRating));

    if (popularProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'สินค้ายอดนิยม',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: popularProducts.take(10).length,
              itemBuilder: (context, index) {
                final product = popularProducts[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
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
    );
  }

  Widget _buildNewProductsSection(List<Product> products) {
    final newProducts = products.toList();
    newProducts.sort((a, b) => (b.createdAt ?? Timestamp.now())
        .compareTo(a.createdAt ?? Timestamp.now()));

    if (newProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'สินค้าใหม่',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: newProducts.take(10).length,
              itemBuilder: (context, index) {
                final product = newProducts[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
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
    );
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
      builder: (context) {
        return AlertDialog(
          title: const Text('โปรไฟล์ผู้ใช้'),
          content: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final user = snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ชื่อ: ${user.displayName ?? 'ไม่มีชื่อ'}'),
                    Text('อีเมล: ${user.email ?? 'ไม่มีอีเมล'}'),
                    const SizedBox(height: 16),
                    if (user.email == 'admin@greenmarket.com')
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CompleteAdminPanelScreen(),
                            ),
                          );
                        },
                        child: const Text('Admin Panel'),
                      ),
                  ],
                );
              }
              return const Text('ไม่ได้เข้าสู่ระบบ');
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
                      await FirebaseAuth.instance.signOut();
                      Navigator.pop(context);
                    },
                    child: const Text('ออกจากระบบ'),
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
}
