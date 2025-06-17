// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:green_market/main.dart'; // Import AuthWrapper from main.dart
import 'package:green_market/utils/constants.dart'; // For AppColors

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate a delay for splash screen visibility, adjust as needed
    await Future.delayed(
        const Duration(seconds: 2)); // Standard splash duration

    if (!mounted) return; // Check if the widget is still in the tree

    // Always navigate to AuthWrapper after splash. AuthWrapper will handle the rest.
    print("SPLASH_SCREEN: Initialization complete. Navigating to AuthWrapper.");
    Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTeal, // Match app theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco, size: 80, color: AppColors.white),
            const SizedBox(height: 20),
            Text('Green Market',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('ตลาดสินค้าเพื่อโลกสีเขียว',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    // ignore: deprecated_member_use
                    ?.copyWith(color: AppColors.white.withOpacity(0.8))),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
