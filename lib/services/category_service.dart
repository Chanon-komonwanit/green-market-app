import '../models/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final _categoryRef = FirebaseFirestore.instance.collection('categories');

  Stream<List<Category>> getCategories() {
    return _categoryRef.snapshots().map(
        (snap) => snap.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }
}
