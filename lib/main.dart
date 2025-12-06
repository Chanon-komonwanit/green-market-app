// lib/main.dart
// Green Market - Entry point ของแอปพลิเคชัน
// จัดการ Firebase initialization, Provider setup, และ Route management

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Core
import 'package:green_market/firebase_options.dart';
import 'package:green_market/main_app_shell.dart';

// Services
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/services/notification_service.dart';
import 'package:green_market/services/image_cache_manager.dart';

// Providers
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/providers/app_config_provider.dart';
import 'package:green_market/providers/cart_provider_enhanced.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/providers/eco_coins_provider.dart';
import 'package:green_market/providers/theme_provider.dart';
import 'package:green_market/providers/coupon_provider.dart';

// Screens
import 'package:green_market/screens/splash_screen.dart';
import 'package:green_market/screens/auth/login_screen.dart';
import 'package:green_market/screens/search_screen.dart';
import 'package:green_market/screens/flash_sale_screen.dart';
import 'package:green_market/screens/category_screen.dart';
import 'package:green_market/screens/notifications_screen.dart';

import 'package:green_market/screens/orders_screen.dart';
import 'package:green_market/screens/chat_screen.dart';
import 'package:green_market/screens/payment_screen.dart';
import 'package:green_market/screens/shipping_address_screen.dart';
import 'package:green_market/screens/eco_coins_screen.dart';
import 'package:green_market/screens/investment_hub_screen.dart';
import 'package:green_market/screens/sustainable_activities_hub_screen.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/edit_product_screen.dart';
import 'package:green_market/screens/seller/complete_modern_seller_dashboard.dart';
import 'package:green_market/screens/wishlist_screen.dart';
import 'package:green_market/screens/trending_topics_screen.dart';
import 'package:green_market/screens/create_story_screen.dart';
import 'package:green_market/screens/community_groups_screen.dart';
import 'package:green_market/screens/eco_challenges_screen.dart';
import 'package:green_market/screens/story_viewer_screen.dart';
import 'package:green_market/screens/group_detail_screen.dart';
import 'package:green_market/screens/hashtag_feed_screen.dart';
import 'package:green_market/screens/saved_posts_screen.dart';
import 'package:green_market/screens/admin/ai_product_review_screen.dart';
import 'package:green_market/screens/admin/ai_settings_screen.dart';

// Models
import 'package:green_market/models/order.dart';
import 'package:green_market/models/product.dart';

/// จุดเริ่มต้นของแอปพลิเคชัน Green Market
/// จัดการการเริ่มต้น Firebase และ Locale initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // เริ่มต้น Firebase พร้อม error handling
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // เริ่มต้นการจัดรูปแบบวันที่ภาษาไทย
    await initializeDateFormatting('th', null);
    debugPrint('✅ Thai locale initialized successfully');

    // เริ่มต้น Image Cache Manager สำหรับการจัดการรูปภาพระดับองค์กร
    ImageCacheManager().initialize();
    debugPrint('✅ Image Cache Manager initialized');

    runApp(MyApp());
  } catch (e, stackTrace) {
    // Log error และแสดง error page
    debugPrint('❌ App initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('เกิดข้อผิดพลาดในการเริ่มต้นแอป'),
                const SizedBox(height: 8),
                Text('Error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    main();
                  },
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key}); // Removed const from constructor

  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(create: (_) => _firebaseService),
        Provider<NotificationService>(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => CartProviderEnhanced()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(_firebaseService)),
        ChangeNotifierProvider(
            create: (context) => AppConfigProvider(_firebaseService)),
        ChangeNotifierProvider(
            create: (context) => AuthProvider(_firebaseService)),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          // Corrected: Already correct
          create: (context) => UserProvider(firebaseService: _firebaseService),
          update: (context, auth, previous) {
            // The UserProvider now listens to auth changes internally.
            // This proxy provider ensures it's available in the widget tree
            // and can be updated if needed, but the core logic is self-contained.
            final userProvider =
                previous ?? UserProvider(firebaseService: _firebaseService);
            // No explicit data loading calls needed here.
            return userProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => EcoCoinProvider(),
        ),
      ],
      child: Consumer<AppConfigProvider>(
        builder: (context, appConfigProvider, child) {
          return MaterialApp(
            title: appConfigProvider.appName,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF20C997), // Instagram-inspired green
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            themeMode: ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: Consumer2<AuthProvider, UserProvider>(
              // Use Consumer2 to listen to both
              builder: (context, auth, user, _) {
                // Auth Debug Information (Production: Remove or use conditional logging)
                if (kDebugMode) {
                  debugPrint('Main.dart - Auth user: ${auth.user?.email}');
                  debugPrint(
                      'Main.dart - Auth initializing: ${auth.isInitializing}');
                  debugPrint('Main.dart - User loading: ${user.isLoading}');
                  debugPrint(
                      'Main.dart - Current user: ${user.currentUser?.email}');
                }

                // Show splash screen while initializing auth or loading user data for the first time.
                if (auth.isInitializing ||
                    (auth.user != null &&
                        user.isLoading &&
                        user.currentUser == null)) {
                  if (kDebugMode) {
                    debugPrint('Main.dart - Showing SplashScreen');
                  }
                  return const SplashScreen();
                }

                if (auth.user == null) {
                  if (kDebugMode) {
                    debugPrint('Main.dart - Showing LoginScreen');
                  }
                  // If user is not logged in, show the authentication screen.
                  return const LoginScreen();
                } else {
                  // ตรวจสอบว่า user data โหลดเสร็จแล้วหรือไม่
                  if (user.currentUser == null && !user.isLoading) {
                    if (kDebugMode) {
                      debugPrint(
                          'Main.dart - User data missing, attempting to reload');
                    }
                    // ลอง reload user data อีกครั้ง
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      user.loadUserData(auth.user!.uid);
                    });
                    return const SplashScreen();
                  }

                  if (kDebugMode) {
                    debugPrint('Main.dart - Showing MainAppShell');
                  }
                  // If user is logged in, show the main app shell.
                  // The shell itself can then decide what to show based on user role.
                  return const MainAppShell();
                }
              },
            ),
            onGenerateRoute: (RouteSettings settings) {
              try {
                switch (settings.name) {
                  case '/shipping-address':
                    return MaterialPageRoute(
                        builder: (_) => const ShippingAddressScreen());

                  case '/notifications':
                    return MaterialPageRoute(
                        builder: (_) => const NotificationsScreen());

                  case '/eco-coins':
                    return MaterialPageRoute(
                        builder: (_) => const EcoCoinsScreen());

                  case '/seller/add-product':
                    return MaterialPageRoute(
                        builder: (_) => const AddProductScreen());

                  case '/seller/edit-product':
                    final product = settings.arguments as Product?;
                    if (product != null) {
                      return MaterialPageRoute(
                        builder: (_) => EditProductScreen(product: product),
                      );
                    }
                    // Return error route if product is null
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(
                          child: Text('ข้อมูลสินค้าไม่ถูกต้อง'),
                        ),
                      ),
                    );

                  case '/investment-hub':
                    return MaterialPageRoute(
                      builder: (_) => const InvestmentHubScreen(),
                    );

                  case '/sustainable-activities-hub':
                    return MaterialPageRoute(
                      builder: (_) => const SustainableActivitiesHubScreen(),
                    );

                  case '/search':
                    return MaterialPageRoute(
                      builder: (_) => const SearchScreen(),
                    );

                  case '/flash-sale':
                    return MaterialPageRoute(
                      builder: (_) => FlashSaleScreen(),
                    );

                  case '/categories':
                    return MaterialPageRoute(
                      builder: (_) => CategoryScreen(),
                    );

                  case '/orders':
                    // Use OrdersScreen instead (consolidated version)
                    return MaterialPageRoute(
                      builder: (_) => const OrdersScreen(),
                    );

                  case '/orders-old':
                    // Kept for backward compatibility
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(
                          child: Text('กรุณาใช้หน้า "คำสั่งซื้อของฉัน" แทน'),
                        ),
                      ),
                    );

                  case '/chat':
                    final args = settings.arguments as Map<String, dynamic>?;
                    if (args != null &&
                        args['productId'] != null &&
                        args['productName'] != null &&
                        args['productImageUrl'] != null &&
                        args['buyerId'] != null &&
                        args['sellerId'] != null) {
                      return MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: args['chatId'],
                          productId: args['productId'],
                          productName: args['productName'],
                          productImageUrl: args['productImageUrl'],
                          buyerId: args['buyerId'],
                          sellerId: args['sellerId'],
                        ),
                      );
                    }
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(
                          child: Text('ข้อมูลการแชทไม่ถูกต้อง'),
                        ),
                      ),
                    );

                  case '/payment':
                    final order = settings.arguments as Order?;
                    if (order != null) {
                      return MaterialPageRoute(
                        builder: (_) => PaymentScreen(order: order),
                      );
                    }
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(
                          child: Text('ข้อมูลคำสั่งซื้อไม่ถูกต้อง'),
                        ),
                      ),
                    );

                  case '/seller-dashboard':
                    return MaterialPageRoute(
                      builder: (_) => const CompleteModernSellerDashboard(),
                    );

                  case '/wishlist':
                    return MaterialPageRoute(
                      builder: (_) => const WishlistScreen(),
                    );

                  case '/saved_posts':
                  case '/saved-posts':
                    return MaterialPageRoute(
                      builder: (_) => const SavedPostsScreen(),
                    );

                  case '/reorder':
                    return MaterialPageRoute(
                      builder: (_) => const OrdersScreen(),
                    );

                  case '/trending-topics':
                    return MaterialPageRoute(
                      builder: (_) => const TrendingTopicsScreen(),
                    );

                  case '/create-story':
                    return MaterialPageRoute(
                      builder: (_) => const CreateStoryScreen(),
                    );

                  case '/community-groups':
                    return MaterialPageRoute(
                      builder: (_) => const CommunityGroupsScreen(),
                    );

                  case '/eco-challenges':
                    return MaterialPageRoute(
                      builder: (_) => const EcoChallengesScreen(),
                    );

                  case '/story-viewer':
                    final args = settings.arguments as Map<String, dynamic>?;
                    if (args != null &&
                        args['stories'] != null &&
                        args['currentUserId'] != null) {
                      return MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          stories: args['stories'],
                          initialIndex: args['initialIndex'] ?? 0,
                          currentUserId: args['currentUserId'],
                        ),
                      );
                    }
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(
                          child: Text('ข้อมูลสตอรี่ไม่ถูกต้อง'),
                        ),
                      ),
                    );

                  case '/group-detail':
                  case '/group_detail':
                    final groupId = settings.arguments as String?;
                    if (groupId != null) {
                      return MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(groupId: groupId),
                      );
                    }
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(
                          child: Text('ไม่พบข้อมูลกลุ่ม'),
                        ),
                      ),
                    );

                  case '/hashtag-feed':
                    final hashtag = settings.arguments as String?;
                    if (hashtag != null) {
                      return MaterialPageRoute(
                        builder: (_) => HashtagFeedScreen(hashtag: hashtag),
                      );
                    }
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(
                          child: Text('ไม่พบแฮชแท็ก'),
                        ),
                      ),
                    );

                  case '/admin/ai-review':
                    return MaterialPageRoute(
                      builder: (_) => const AIProductReviewScreen(),
                    );

                  case '/admin/ai-settings':
                    return MaterialPageRoute(
                      builder: (_) => const AISettingsScreen(),
                    );

                  default:
                    // Route not found - return null to use onUnknownRoute
                    return null;
                }
              } catch (e) {
                // Log error and return error page
                debugPrint('Route generation error: $e');
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('ข้อผิดพลาด')),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text('เกิดข้อผิดพลาดในการโหลดหน้า'),
                          const SizedBox(height: 8),
                          Text('Error: $e'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('กลับ'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
