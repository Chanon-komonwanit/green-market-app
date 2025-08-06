// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/search_screen.dart';
import 'screens/flash_sale_screen.dart';
import 'screens/category_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/order_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/payment_screen.dart';
import 'models/order.dart';
import 'package:green_market/screens/notifications_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:green_market/firebase_options.dart';
import 'package:green_market/main_app_shell.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/providers/app_config_provider.dart';
import 'package:green_market/providers/cart_provider_enhanced.dart';
import 'package:green_market/theme/app_theme.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/edit_product_screen.dart';
import 'package:green_market/screens/shipping_address_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/screens/splash_screen.dart';
import 'package:green_market/screens/auth/login_screen.dart'; // Explicitly import LoginScreen
import 'package:green_market/services/notification_service.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/providers/eco_coins_provider.dart';
import 'package:green_market/providers/theme_provider.dart';
import 'package:green_market/screens/eco_coins_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/screens/investment_hub_screen.dart';
import 'package:green_market/screens/sustainable_activities_hub_screen.dart';
import 'package:green_market/screens/seller/seller_dashboard_screen.dart';
import 'package:green_market/screens/wishlist_screen.dart';
import 'package:green_market/providers/coupon_provider.dart';
import 'package:green_market/screens/orders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้น Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // เริ่มต้นการจัดรูปแบบวันที่
  await initializeDateFormatting('th', null);

  runApp(MyApp());
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
                print('Main.dart - Auth user: ${auth.user?.email}');
                print('Main.dart - Auth initializing: ${auth.isInitializing}');
                print('Main.dart - User loading: ${user.isLoading}');
                print('Main.dart - Current user: ${user.currentUser?.email}');

                // Show splash screen while initializing auth or loading user data for the first time.
                if (auth.isInitializing ||
                    (auth.user != null &&
                        user.isLoading &&
                        user.currentUser == null)) {
                  print('Main.dart - Showing SplashScreen');
                  return const SplashScreen();
                }

                if (auth.user == null) {
                  print('Main.dart - Showing LoginScreen');
                  // If user is not logged in, show the authentication screen.
                  return const LoginScreen();
                } else {
                  // ตรวจสอบว่า user data โหลดเสร็จแล้วหรือไม่
                  if (user.currentUser == null && !user.isLoading) {
                    print(
                        'Main.dart - User data missing, attempting to reload');
                    // ลอง reload user data อีกครั้ง
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      user.loadUserData(auth.user!.uid);
                    });
                    return const SplashScreen();
                  }

                  print('Main.dart - Showing MainAppShell');
                  // If user is logged in, show the main app shell.
                  // The shell itself can then decide what to show based on user role.
                  return const MainAppShell();
                }
              },
            ),
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == '/shipping-address') {
                // Reverted to string literal as ShippingAddressScreen.routeName is not defined in provided context
                return MaterialPageRoute(
                    builder: (_) => const ShippingAddressScreen());
              }
              if (settings.name == '/notifications') {
                return MaterialPageRoute(
                    builder: (_) => const NotificationsScreen());
              }
              if (settings.name == '/eco-coins') {
                return MaterialPageRoute(
                    builder: (_) => const EcoCoinsScreen());
              }
              if (settings.name == '/seller/add-product') {
                return MaterialPageRoute(
                    builder: (_) => const AddProductScreen());
              }
              if (settings.name == '/seller/edit-product') {
                final product = settings.arguments as Product?;
                if (product != null) {
                  return MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: product),
                  );
                }
              }
              if (settings.name == '/investment-hub') {
                return MaterialPageRoute(
                  builder: (_) => const InvestmentHubScreen(),
                );
              }
              if (settings.name == '/sustainable-activities-hub') {
                return MaterialPageRoute(
                  builder: (_) => const SustainableActivitiesHubScreen(),
                );
              }
              if (settings.name == '/search') {
                return MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                );
              }
              if (settings.name == '/flash-sale') {
                return MaterialPageRoute(
                  builder: (_) => FlashSaleScreen(),
                );
              }
              if (settings.name == '/categories') {
                return MaterialPageRoute(
                  builder: (_) => CategoryScreen(),
                );
              }
              if (settings.name == '/notifications') {
                return MaterialPageRoute(
                  builder: (_) => NotificationScreen(),
                );
              }
              if (settings.name == '/orders') {
                final userId = settings.arguments as String?;
                if (userId != null) {
                  return MaterialPageRoute(
                    builder: (_) => OrderScreen(userId: userId),
                  );
                }
              }
              if (settings.name == '/chat') {
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
              }
              if (settings.name == '/payment') {
                final order = settings.arguments as Order?;
                if (order != null) {
                  return MaterialPageRoute(
                    builder: (_) => PaymentScreen(order: order),
                  );
                }
              }
              // เพิ่ม route สำหรับ seller dashboard
              if (settings.name == '/seller-dashboard') {
                return MaterialPageRoute(
                  builder: (_) => const SellerDashboardScreen(),
                );
              }
              // เพิ่ม route สำหรับ wishlist
              if (settings.name == '/wishlist') {
                return MaterialPageRoute(
                  builder: (_) => const WishlistScreen(),
                );
              }
              // เพิ่ม route สำหรับ reorder
              if (settings.name == '/reorder') {
                return MaterialPageRoute(
                  builder: (_) => const OrdersScreen(),
                );
              }
              // หากไม่ตรงกับ route ที่กำหนดไว้ ให้ return null
              return null;
            },
          );
        },
      ),
    );
  }
}
