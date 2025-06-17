// lib/screens/new_arrivals_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:provider/provider.dart';

class NewArrivalsScreen extends StatelessWidget {
  const NewArrivalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้ามาใหม่ทั้งหมด'),
      ),
      body: StreamBuilder<List<Product>>(
        // Assuming getApprovedProducts is already sorted by newest first (e.g., by createdAt or approvedAt descending)
        // If not, you might need a specific method in FirebaseService like getNewestApprovedProducts()
        stream: firebaseService.getApprovedProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบสินค้ามาใหม่'));
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
