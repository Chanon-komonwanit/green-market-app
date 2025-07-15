// lib/main.dart

import 'package:flutter/material.dart';
import 'package:green_market/screens/notifications_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:green_market/firebase_options.dart';
import 'package:green_market/main_app_shell.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/providers/app_config_provider.dart';
import 'package:green_market/providers/cart_provider.dart';
import 'package:green_market/providers/theme_provider.dart';
import 'package:green_market/screens/seller/add_product_screen.dart';
import 'package:green_market/screens/seller/edit_product_screen.dart';
import 'package:green_market/screens/shipping_address_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/screens/splash_screen.dart';
import 'package:green_market/screens/auth/login_screen.dart'; // Explicitly import LoginScreen
import 'package:green_market/services/notification_service.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/providers/eco_coins_provider.dart';
import 'package:green_market/screens/eco_coins_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_data_seeder.dart';
import 'package:flutter/foundation.dart';
import 'package:green_market/screens/investment_hub_screen.dart';
import 'package:green_market/screens/sustainable_activities_hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('th', null);
  await NotificationService().initialize();
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
            create: (context) => ThemeProvider(_firebaseService)),
        ChangeNotifierProvider(
            create: (context) => AuthProvider(_firebaseService)),
        ChangeNotifierProvider(
            create: (context) => AppConfigProvider(_firebaseService)),
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
          create: (context) => EcoCoinsProvider(),
        ),
      ],
      child: Consumer2<ThemeProvider, AppConfigProvider>(
        builder: (context, themeProvider, appConfigProvider, child) {
          return MaterialApp(
            title: appConfigProvider.appName,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
              // หากไม่ตรงกับ route ที่กำหนดไว้ ให้ return null
              return null;
            },
          );
        },
      ),
    );
  }
}
