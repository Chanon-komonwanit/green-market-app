// lib/models/category.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl; // URL รูปภาพไอคอน/แบนเนอร์ของหมวดหมู่
  final Timestamp createdAt; // วันที่สร้าง

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
  });

  // สร้าง Category object จาก Firestore DocumentSnapshot
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError(
          'Failed to parse category from Firestore: data is null for doc ${doc.id}');
    }
    return Category(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Category',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Null get iconData => null;

  // แปลง Category object ไปเป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
}
