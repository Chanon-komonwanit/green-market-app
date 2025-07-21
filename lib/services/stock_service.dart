import '../models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockService {
  final _productRef = FirebaseFirestore.instance.collection('products');

  Stream<int> getStock(String productId) {
    return _productRef
        .doc(productId)
        .snapshots()
        .map((doc) => doc['stock'] ?? 0);
  }
}
