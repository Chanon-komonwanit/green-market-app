import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('=== Debug Products Collection ===');

  try {
    // Check all products in products collection
    final productsQuery = await firestore.collection('products').get();
    print('Total products in collection: ${productsQuery.docs.length}');

    for (var doc in productsQuery.docs) {
      final data = doc.data();
      print('Product ID: ${doc.id}');
      print('  - Name: ${data['name']}');
      print('  - isApproved: ${data['isApproved']}');
      print('  - status: ${data['status']}');
      print('  - sellerId: ${data['sellerId']}');
      print('  - categoryId: ${data['categoryId']}');
      print('---');
    }

    // Check approved products only
    final approvedQuery = await firestore
        .collection('products')
        .where('isApproved', isEqualTo: true)
        .get();
    print('\nApproved products: ${approvedQuery.docs.length}');

    for (var doc in approvedQuery.docs) {
      final data = doc.data();
      print('Approved Product: ${data['name']} (ID: ${doc.id})');
    }

    // Check product requests
    final requestsQuery = await firestore.collection('product_requests').get();
    print('\nTotal product requests: ${requestsQuery.docs.length}');

    for (var doc in requestsQuery.docs) {
      final data = doc.data();
      print('Request ID: ${doc.id}');
      print('  - Status: ${data['status']}');
      if (data['productData'] != null) {
        final productData = data['productData'] as Map<String, dynamic>;
        print('  - Product Name: ${productData['name']}');
      }
      print('---');
    }
  } catch (e) {
    print('Error: $e');
  }
}
