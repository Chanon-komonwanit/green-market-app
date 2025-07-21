import '../models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashSaleService {
  final _flashSaleRef = FirebaseFirestore.instance.collection('flash_sales');

  Stream<List<Product>> getActiveFlashSales() {
    return _flashSaleRef
        .where('endTime', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }
}
