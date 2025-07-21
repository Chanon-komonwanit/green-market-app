import '../models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final _productRef = FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> searchProducts(String query) {
    return _productRef
        .where('keywords', arrayContains: query.toLowerCase())
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Stream<List<Product>> filterProducts(Map<String, dynamic> filters) {
    // TODO: implement dynamic filter logic
    return _productRef.snapshots().map(
        (snap) => snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }
}
