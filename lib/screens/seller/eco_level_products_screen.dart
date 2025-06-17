// lib/screens/eco_level_products_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:provider/provider.dart';

class EcoLevelProductsScreen extends StatelessWidget {
  final EcoLevel ecoLevel;
  final String title;

  const EcoLevelProductsScreen({
    super.key,
    required this.ecoLevel,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getProductsByEcoLevel(ecoLevel),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบสินค้าในระดับนี้'));
          }
          final products = snapshot.data!;
          return GridView.builder(
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
      ),
    );
  }
}
