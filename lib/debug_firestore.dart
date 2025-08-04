import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  print('=== Firebase Products Debug ===');

  try {
    final firestore = FirebaseFirestore.instance;

    // Check all products in products collection
    print('Checking products collection...');
    final productsQuery = await firestore.collection('products').get();
    print('Total products found: ${productsQuery.docs.length}');

    if (productsQuery.docs.isNotEmpty) {
      print('\n--- All Products ---');
      for (var doc in productsQuery.docs) {
        final data = doc.data();
        print('Product ID: ${doc.id}');
        print('  Name: ${data['name'] ?? 'No name'}');
        print('  isApproved: ${data['isApproved']}');
        print('  status: ${data['status'] ?? 'No status'}');
        print('  sellerId: ${data['sellerId'] ?? 'No seller'}');
        print('  categoryId: ${data['categoryId'] ?? 'No category'}');
        print('  createdAt: ${data['createdAt']}');
        print('  approvedAt: ${data['approvedAt']}');
        print('---');
      }
    }

    // Check approved products specifically
    print('\n--- Approved Products Query ---');
    final approvedQuery = await firestore
        .collection('products')
        .where('isApproved', isEqualTo: true)
        .get();
    print('Approved products found: ${approvedQuery.docs.length}');

    if (approvedQuery.docs.isNotEmpty) {
      for (var doc in approvedQuery.docs) {
        final data = doc.data();
        print('Approved Product:');
        print('  ID: ${doc.id}');
        print('  Name: ${data['name']}');
        print('  isApproved: ${data['isApproved']}');
        print('  status: ${data['status']}');
        print('---');
      }
    }

    // Check product_requests collection
    print('\n--- Product Requests ---');
    final requestsQuery = await firestore.collection('product_requests').get();
    print('Total product requests: ${requestsQuery.docs.length}');

    if (requestsQuery.docs.isNotEmpty) {
      for (var doc in requestsQuery.docs) {
        final data = doc.data();
        print('Request ID: ${doc.id}');
        print('  Status: ${data['status'] ?? 'No status'}');
        print('  ProcessedAt: ${data['processedAt']}');
        if (data['productData'] != null) {
          final productData = data['productData'] as Map<String, dynamic>;
          print('  Product Name: ${productData['name'] ?? 'No name'}');
        }
        print('---');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  print('=== Debug Complete ===');
}
