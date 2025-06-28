// d:/Development/green_market/lib/screens/category_products_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/category.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/screens/product_detail_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:provider/provider.dart';

class CategoryProductsScreen extends StatelessWidget {
  final Category category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getProductsByCategoryId(category.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront,
                      size: 80, color: AppColors.lightGrey),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีสินค้าในหมวดหมู่ "${category.name}"'),
                ],
              ),
            );
          }

          final products = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                )),
              );
            },
          );
        },
      ),
    );
  }
}
