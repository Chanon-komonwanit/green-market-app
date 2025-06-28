// lib/screens/admin/shop_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ShopDetailScreen extends StatelessWidget {
  final Seller seller;

  const ShopDetailScreen({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(title: Text(seller.shopName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (seller.shopImageUrl != null && seller.shopImageUrl!.isNotEmpty)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(seller.shopImageUrl!),
                  backgroundColor:
                      Colors.grey[200], // Ensure shopImageUrl is not null
                  // Use a placeholder if shopImageUrl is null or empty
                  child: seller.shopImageUrl!.isNotEmpty
                      ? null
                      : const Icon(Icons.storefront, size: 50),
                ),
              )
            else
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.storefront, size: 50),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                seller.shopName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                seller.shopDescription ?? 'ไม่มีคำอธิบายร้านค้า',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 32),
            Text('ข้อมูลร้านค้า', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ชื่อร้าน: ${seller.shopName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      seller.shopDescription ?? '',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'อีเมลติดต่อ: ${seller.contactEmail}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'เบอร์โทรศัพท์: ${seller.contactPhone}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'เว็บไซต์: ${seller.website ?? 'N/A'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'เป็นผู้ขายตั้งแต่: ${DateFormat('dd MMM yyyy').format(seller.createdAt.toDate())}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'สินค้าทั้งหมดของร้าน',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Product>>(
              stream: firebaseService.getProductsBySeller(seller.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('ร้านนี้ยังไม่มีสินค้า'));
                }
                final products = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => ProductCard(product: products[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
