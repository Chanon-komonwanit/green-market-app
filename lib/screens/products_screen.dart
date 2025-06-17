// products_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart'; // Your Product model
import 'package:green_market/screens/seller/eco_level_products_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:green_market/utils/constants.dart'; // For AppColors and AppTextStyles
// For navigation
import 'package:green_market/widgets/product_card.dart'; // Import the new ProductCard
import 'package:green_market/models/category.dart'; // Import Category model
import 'package:green_market/screens/new_arrivals_screen.dart'; // Import NewArrivalsScreen
// Import the new screen
// Import NewArrivalsScreen
import 'package:green_market/screens/category_products_screen.dart'; // Import CategoryProductsScreen

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  EcoLevel? _selectedEcoFilter; // To store the selected EcoLevel filter
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // Start a timer to auto-scroll the banner
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_bannerPageController.hasClients) {
        int nextPage = _bannerPageController.page!.toInt() + 1;
        if (nextPage >= _getBannerItems().length) {
          nextPage = 0;
        }
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // This screen will now be a more complex Home Screen
    // The Scaffold and AppBar are handled by MainScreen.
    Stream<List<Product>> allProductsStream;
    if (_selectedEcoFilter != null) {
      allProductsStream =
          firebaseService.getProductsByEcoLevel(_selectedEcoFilter!);
    } else {
      allProductsStream = firebaseService.getApprovedProducts();
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromoBannerCarousel(), // Changed to a carousel
          const SizedBox(height: 16),
          _buildSectionTitle('สินค้ารักษ์โลก ระดับ Hero', onViewMore: () {
            // TODO: Navigate to a screen showing all EcoLevel.hero products
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const EcoLevelProductsScreen(
                ecoLevel: EcoLevel.hero,
                title: 'สินค้ารักษ์โลก ระดับ Hero',
              ),
            ));
          }),
          _buildHorizontalProductList(firebaseService
              .getProductsByEcoLevel(EcoLevel.hero)
              .map((products) => products.take(6).toList())),
          const SizedBox(height: 16), // Adjusted spacing
          _buildSectionTitle('สินค้ามาใหม่', onViewMore: () {
            // TODO: Navigate to a screen showing all new products
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const NewArrivalsScreen(),
            ));
          }),
          _buildHorizontalProductList(firebaseService.getApprovedProducts().map(
              (products) => products
                  .take(6)
                  .toList())), // Example: Show latest 6 approved products
          const SizedBox(height: 16), // Adjusted spacing
          _buildSectionTitle('หมวดหมู่แนะนำ',
              onViewMore: null), // No "View More" for categories for now
          _buildCategorySection(firebaseService),
          const SizedBox(height: 16),
          _buildSectionTitle('Filter by Eco Level', onViewMore: null),
          _buildEcoLevelFilterChips(), // Add EcoLevel filter chips
          const SizedBox(height: 24),
          _buildSectionTitle('สินค้าทั้งหมด',
              onViewMore: null), // Title for the general grid
          _buildAllProductsGrid(
              allProductsStream), // Pass the filtered or all products stream
        ],
      ),
    );
  }

  List<Widget> _getBannerItems() {
    // Replace with your actual banner data
    return [
      _buildBannerItem(
        imageUrl:
            'https://via.placeholder.com/600x250/A9DBCF/004D40?Text=Discover+Eco+Products',
        title: 'Discover Eco Products',
        subtitle: 'Shop sustainably, live better.',
        onTap: () {/* TODO: Navigate to a specific page */},
      ),
      _buildBannerItem(
        imageUrl:
            'https://via.placeholder.com/600x250/81C784/FFFFFF?Text=Fresh+Organic+Arrivals',
        title: 'Fresh Organic Arrivals',
        subtitle: 'Healthy choices for a healthy planet.',
        onTap: () {/* TODO: Navigate to new arrivals */},
      ),
      _buildBannerItem(
        imageUrl:
            'https://via.placeholder.com/600x250/4DB6AC/FFFFFF?Text=Join+Our+Green+Community',
        title: 'Join Our Green Community',
        subtitle: 'Invest in a sustainable future.',
        onTap: () {/* TODO: Navigate to investment zone or community page */},
      ),
    ];
  }

  Widget _buildBannerItem(
      {required String imageUrl,
      required String title,
      required String subtitle,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  // Added a darker overlay for better text visibility
                  // ignore: deprecated_member_use
                  Colors.black.withOpacity(0.5), // Slightly darker overlay
                  BlendMode.darken),
            ),
            boxShadow: [
              // Added a subtle shadow for depth
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]),
        child: Container(
          // Added an inner container for padding and alignment
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.headline.copyWith(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold, // Make title bolder
                      shadows: [
                        Shadow(
                            // Enhanced shadow for better readability
                            blurRadius: 4,
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.7))
                      ])),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTextStyles.body.copyWith(
                      // ignore: deprecated_member_use
                      color: AppColors.white.withOpacity(0.95),
                      fontSize: 14,
                      shadows: [
                        Shadow(
                            // Enhanced shadow
                            blurRadius: 3,
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.7))
                      ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBannerCarousel() {
    final bannerItems = _getBannerItems();
    return SizedBox(
      height: 200, // Increased height for better visual
      child: PageView.builder(
        controller: _bannerPageController,
        itemCount: bannerItems.length,
        itemBuilder: (context, index) {
          return bannerItems[index];
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewMore}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            // Added Row for icon and title
            children: [
              Icon(
                  // Changed icon based on title for more variety
                  title.contains('Hero')
                      ? Icons.star_outline_rounded
                      : title.contains('มาใหม่')
                          ? Icons.new_releases_outlined
                          : title.contains('หมวดหมู่')
                              ? Icons.category_outlined
                              : title.contains('Filter')
                                  ? Icons.tune_outlined // Changed filter icon
                                  : Icons.eco_outlined,
                  color: AppColors.primaryGreen,
                  size: 24),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Even slightly larger section title
                      // ignore: deprecated_member_use
                      color: AppColors.primaryDarkGreen.withOpacity(0.9))),
            ],
          ),
          if (onViewMore != null)
            TextButton(
              onPressed: onViewMore,
              child: Text('ดูทั้งหมด',
                  style: AppTextStyles.link.copyWith(fontSize: 14)),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductList(Stream<List<Product>> productStream) {
    return SizedBox(
      height: 290, // Adjust height as needed for your ProductCard
      child: StreamBuilder<List<Product>>(
        stream: productStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('เกิดข้อผิดพลาด',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.errorRed)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('ไม่มีสินค้าในส่วนนี้',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.modernGrey)));
          }
          final products = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: products.length,
            itemBuilder: (ctx, i) => SizedBox(
              width: 170, // Adjust width as needed for your ProductCard
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: ProductCard(product: products[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(FirebaseService firebaseService) {
    return Container(
      height: 100, // Increased height for larger category items
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: StreamBuilder<List<Category>>(
        stream: firebaseService.getCategories().map((categories) =>
            categories.take(5).toList()), // Example: Take top 5 categories
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryTeal)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('ไม่สามารถโหลดหมวดหมู่ได้',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.errorRed)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('ไม่มีหมวดหมู่',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.modernGrey)));
          }
          final categories = snapshot.data!;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        CategoryProductsScreen(category: category),
                  ));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80, // Fixed width for category item
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                      color:
                          AppColors.white, // Brighter background for category
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          // ignore: deprecated_member_use
                          color: AppColors.primaryTeal.withOpacity(
                              0.35)), // Slightly more visible border
                      boxShadow: [
                        BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.grey.withOpacity(
                                0.15), // Slightly more pronounced shadow
                            blurRadius: 3,
                            offset: Offset(1, 2))
                      ]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.iconData ??
                            Icons.category_outlined, // Use default if no icon
                        color: AppColors
                            .primaryTeal, // Changed to Teal for category icon
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.name,
                        style: AppTextStyles.caption.copyWith(
                            // Use caption style
                            color: AppColors.primaryDarkGreen,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEcoLevelFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              // Added padding to the "All Levels" chip
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: _selectedEcoFilter == null
                    ? Icon(Icons.check_circle_outline_rounded, // Changed icon
                        color: AppColors.white,
                        size: 18) // Adjusted size
                    : null,
                label: Text('All Levels',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: _selectedEcoFilter == null
                            ? AppColors.white
                            : AppColors.primaryDarkGreen,
                        fontWeight: _selectedEcoFilter == null
                            ? FontWeight.w600
                            : FontWeight.normal // Adjusted font weight
                        )),
                backgroundColor: _selectedEcoFilter == null
                    ? AppColors
                        .primaryGreen // Use primaryGreen for selected "All"
                    : AppColors.lightTeal
                        // ignore: deprecated_member_use
                        .withOpacity(0.1), // Lighter for unselected
                onPressed: () {
                  setState(() {
                    _selectedEcoFilter = null;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: AppColors.primaryGreen
                          // ignore: deprecated_member_use
                          .withOpacity(0.5)), // More visible border
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6), // Adjusted padding
              ),
            ),
            ...EcoLevel.values.map((level) {
              final isSelected = _selectedEcoFilter == level;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: isSelected
                      ? Icon(level.icon, color: AppColors.white, size: 18)
                      : Icon(level.icon,
                          color: level.color, // Full color for unselected icon
                          size: 18), // Slightly less opaque for unselected icon
                  label: Text(level.englishName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.white : level.color,
                        fontWeight: isSelected
                            ? FontWeight.w600 // Adjusted font weight
                            : FontWeight.normal,
                      )),
                  backgroundColor: isSelected
                      ? level.color
                      : AppColors.lightTeal
                          // ignore: deprecated_member_use
                          .withOpacity(0.1), // Lighter for unselected
                  onPressed: () {
                    setState(() {
                      _selectedEcoFilter = isSelected ? null : level;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: level.color
                            // ignore: deprecated_member_use
                            .withOpacity(0.5)), // More visible border
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6), // Adjusted padding
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAllProductsGrid(Stream<List<Product>> productStream) {
    // This is the original GridView for all products
    return StreamBuilder<List<Product>>(
      stream: productStream, // Use the passed stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child:
                      CircularProgressIndicator(color: AppColors.primaryTeal)));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text(
                  'เกิดข้อผิดพลาดในการโหลดสินค้าทั้งหมด: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ยังไม่มีสินค้าในขณะนี้'));
        }
        final products = snapshot.data!;
        return GridView.builder(
          shrinkWrap:
              true, // Important for GridView inside SingleChildScrollView
          physics:
              const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
          padding: const EdgeInsets.all(12.0),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (ctx, i) => ProductCard(product: products[i]),
        );
      },
    );
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }
}
