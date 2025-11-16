// lib/screens/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/screens/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  List<Product> _wishlistProducts = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // Enhanced: Load wishlist products from Firebase
      final wishlistSnapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('userId', isEqualTo: user.uid)
          .get();

      final productIds = wishlistSnapshot.docs
          .map((doc) => doc.data()['productId'] as String)
          .toList();

      if (productIds.isNotEmpty) {
        // Load actual product data
        final productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: productIds)
            .get();

        _wishlistProducts = productsSnapshot.docs
            .map((doc) => Product.fromMap({'id': doc.id, ...doc.data()}))
            .toList();
      } else {
        _wishlistProducts = [];
      }
    } catch (e) {
      print('Error loading wishlist: $e');
      // Fallback: show empty list
      _wishlistProducts = [];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายการโปรด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('รายการโปรด'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: AppColors.grayMedium),
              SizedBox(height: 16),
              Text('กรุณาเข้าสู่ระบบเพื่อดูรายการโปรด',
                  style: TextStyle(color: AppColors.grayMedium)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการโปรด'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildWishlistContent(),
    );
  }

  Widget _buildWishlistContent() {
    if (_wishlistProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 64, color: AppColors.grayMedium),
            SizedBox(height: 16),
            Text(
              'ยังไม่มีสินค้าในรายการโปรด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.grayDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'กดใจสินค้าที่ชอบเพื่อเพิ่มในรายการโปรด',
              style: TextStyle(color: AppColors.grayMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _wishlistProducts.length,
        itemBuilder: (context, index) {
          final product = _wishlistProducts[index];
          return ProductCard(
            product: product,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
