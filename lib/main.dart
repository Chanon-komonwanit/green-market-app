// lib/main.dart
import 'dart:async'; // Import for TimeoutException
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for date formatting
import 'package:green_market/providers/cart_provider.dart';
import 'package:green_market/providers/user_provider.dart'; // Import UserProvider
import 'package:green_market/screens/splash_screen.dart'; // Import the SplashScreen
import 'package:green_market/screens/admin_panel_screen.dart'; // Import AdminPanelScreen
import 'package:green_market/screens/main_screen.dart'; // Assuming your main app screen
import 'package:green_market/screens/auth/login_screen.dart'; // Your login screen
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/services/auth_service.dart'; // Your AuthService
import 'package:green_market/utils/constants.dart'; // For AppColors
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // ไฟล์ที่ Firebase CLI สร้างให้

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(
      'th_TH', null); // Initialize date formatting for Thai

  bool firebaseInitialized = false;
  String? firebaseError;
  try {
    final FirebaseOptions firebaseOptions =
        DefaultFirebaseOptions.currentPlatform;
    // Optional: Log a part of the options to confirm it's loaded
    print(
        "MAIN: Firebase options loaded. Project ID: ${firebaseOptions.projectId}, API Key (first 5 chars): ${firebaseOptions.apiKey.substring(0, 5)}...");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Use generated options
    ).timeout(const Duration(seconds: 15));
    print("MAIN: Firebase initialized successfully!");
    firebaseInitialized = true;
  } on TimeoutException catch (e) {
    print("MAIN: Error initializing Firebase: Timeout after 15 seconds. $e");
    firebaseError =
        "Firebase initialization timed out. Please check your network connection and Firebase setup.";
  } catch (e, s) {
    if (kDebugMode) {
      print("MAIN: Error initializing Firebase: $e");
    }
    print("MAIN: Stack trace: $s");
    firebaseError =
        "Error initializing Firebase: ${e.toString()}. Check console for details.";
  }
  if (firebaseInitialized) {
    runApp(const MyApp());
  } else {
    runApp(FirebaseErrorApp(
        error: firebaseError ?? "Unknown Firebase initialization error."));
  }
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;
  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Failed to initialize Firebase. Please check your connection or Firebase setup.\n\nError: $error",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(
            firebaseService: context.read<FirebaseService>(),
          ),
        ),
        // เพิ่ม Provider อื่นๆ ที่คุณมีที่นี่
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Green Market',
        theme: ThemeData(
          primarySwatch: Colors.teal, // หรือใช้ AppColors.primaryTeal
          fontFamily:
              'Nunito', // Ensure Nunito font is added to pubspec.yaml and assets
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.teal, // Should match primarySwatch
          ).copyWith(secondary: AppColors.lightTeal),
          scaffoldBackgroundColor: AppColors.offWhite,
          appBarTheme: const AppBarTheme(
            backgroundColor:
                AppColors.primaryGreen, // Consistent Green for AppBar
            foregroundColor: AppColors.white,
            elevation: 1,
            iconTheme: IconThemeData(color: AppColors.white),
            actionsIconTheme: IconThemeData(color: AppColors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen, // Consistent Green
              foregroundColor: AppColors.white,
              textStyle:
                  AppTextStyles.bodyBold.copyWith(color: AppColors.white),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen, // Consistent Green
              side: const BorderSide(color: AppColors.primaryTeal),
              textStyle: AppTextStyles.bodyBold,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGreen, // Consistent Green
              textStyle: AppTextStyles.bodyBold,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.lightModernGrey)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.lightModernGrey)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2.0)), // Consistent Green
            labelStyle:
                AppTextStyles.body.copyWith(color: AppColors.modernGrey),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: AppColors.offWhite,
            selectedItemColor: AppColors.primaryGreen, // Consistent Green
            // unselectedItemColor is deprecated. Use unselectedIconTheme and unselectedLabelStyle instead.
            // ignore: deprecated_member_use
            unselectedIconTheme:
                // ignore: deprecated_member_use
                IconThemeData(color: AppColors.modernGrey.withOpacity(0.8)),
            // ignore: deprecated_member_use
            unselectedLabelStyle:
                // ignore: deprecated_member_use
                TextStyle(color: AppColors.modernGrey.withOpacity(0.8)),
            type: BottomNavigationBarType.fixed,
          ),
          chipTheme: ChipThemeData(
            // backgroundColor ถูก deprecated, ใช้ color หรือ style Chip โดยตรง
            color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors
                    .primaryGreen; // Consistent Green for selected Chip
              }
              // ignore: deprecated_member_use
              return AppColors.veryLightTeal.withOpacity(0.5); // สีปกติ
            }),
            labelStyle: const TextStyle(
                color: AppColors.modernGrey, fontWeight: FontWeight.normal),
            secondaryLabelStyle: const TextStyle(
                // ใช้สำหรับ selected state
                color: AppColors.white,
                fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
            showCheckmark: false,
            // selectedColor: AppColors.primaryTeal, // ถูกจัดการโดย color property ด้านบนแล้ว
          ),
        ),
        home: const AuthWrapper(), // Use AuthWrapper to handle auth state
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to both auth state and UserProvider's loading state
    final authService =
        AuthService(); // Or Provider.of<AuthService>(context) if provided
    final userProvider = Provider.of<UserProvider>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          // Still waiting for auth state, show splash or loading
          return const SplashScreen(); // Or a simpler loading indicator
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          // User is authenticated by Firebase Auth
          // Now, check UserProvider for user data and admin status
          if (userProvider.isLoading && userProvider.userData == null) {
            // UserProvider is still loading Firestore data
            // You might want to show a loading screen or a more integrated splash
            print(
                "AuthWrapper: User authenticated, UserProvider loading data...");
            return const Scaffold(
                body: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryTeal)));
          }

          // UserProvider has finished loading (or attempted to load)
          if (userProvider.isAdmin) {
            print(
                "AuthWrapper: User is Admin. Navigating to AdminPanelScreen.");
            return const AdminPanelScreen();
          } else {
            print("AuthWrapper: User is not Admin. Navigating to MainScreen.");
            return const MainScreen();
          }
        } else {
          // User is not logged in
          return const LoginScreen();
        }
      },
    );
  }
}
