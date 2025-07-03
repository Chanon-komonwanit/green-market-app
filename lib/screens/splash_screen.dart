// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
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

    // The navigation logic is now handled by MyApp's home Consumer2.
    // This screen will simply be replaced when AuthProvider/UserProvider finish initializing.
    if (!mounted) return;
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
                    ?.copyWith(color: AppColors.white.withAlpha(204))),
            const SizedBox(height: 40),
            // เพิ่มข้อความแสดงสถานะ
            Text('กำลังโหลดข้อมูลผู้ใช้...',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.white.withAlpha(179))),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
