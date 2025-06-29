import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:provider/provider.dart';

class TestDataPage extends StatelessWidget {
  const TestDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Data Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _createTestProducts(context),
              child: const Text('Create Test Products'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testProductFetch(context),
              child: const Text('Test Product Fetch'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: Provider.of<FirebaseService>(context, listen: false)
                    .getApprovedProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final products = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${product.id}'),
                              Text('Status: ${product.status}'),
                              Text('IsApproved: ${product.isApproved}'),
                              Text('Images: ${product.imageUrls.length}'),
                              if (product.imageUrls.isNotEmpty)
                                Text('First image: ${product.imageUrls.first}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTestProducts(BuildContext context) async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // สร้างข้อมูลทดสอบ
      print('Creating test products...');

      // Create test product data directly to Firestore
      // Note: This is a simplified version - in real app, you'd use proper Firebase admin tools
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use Firebase Console to add test data')),
      );
    } catch (e) {
      print('Error creating test products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _testProductFetch(BuildContext context) async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      print('🔥 TEST: Fetching products...');
      final products = await firebaseService.getApprovedProducts().first;

      print('🔥 TEST: Found ${products.length} products');
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        print('🔥 TEST: Product $i:');
        print('  - Name: ${product.name}');
        print('  - ID: ${product.id}');
        print('  - Status: ${product.status}');
        print('  - IsApproved: ${product.isApproved}');
        print('  - Image URLs: ${product.imageUrls}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Found ${products.length} products - check console')),
      );
    } catch (e) {
      print('🔥 TEST: Error fetching products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
