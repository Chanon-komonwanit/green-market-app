import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Add sample products
  await addSampleProducts();
  print('Sample products added successfully!');
}

Future<void> addSampleProducts() async {
  final firestore = FirebaseFirestore.instance;

  // Add sample categories first
  await firestore.collection('categories').doc('cat1').set({
    'name': 'ผักผลไม้อินทรีย์',
    'imageUrl': 'https://via.placeholder.com/150/4CAF50/FFFFFF?text=Organic',
    'isActive': true,
  });

  await firestore.collection('categories').doc('cat2').set({
    'name': 'สินค้าเพื่อสุขภาพ',
    'imageUrl': 'https://via.placeholder.com/150/2196F3/FFFFFF?text=Health',
    'isActive': true,
  });

  // Add sample products with real image URLs
  final products = [
    {
      'name': 'มะเขือเทศอินทรีย์',
      'description': 'มะเขือเทศปลอดสารพิษ ปลูกด้วยวิธีธรรมชาติ',
      'price': 50.0,
      'categoryId': 'cat1',
      'sellerId': 'seller1',
      'status': 'approved',
      'isApproved': true,
      'ecoLevel': 'moderate',
      'imageUrls': [
        'https://via.placeholder.com/300x300/FF5722/FFFFFF?text=Tomato',
        'https://via.placeholder.com/300x300/FF7043/FFFFFF?text=Organic+Tomato'
      ],
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'แครอทอินทรีย์',
      'description': 'แครอทหวานกรอบ ปลอดสารเคมี',
      'price': 40.0,
      'categoryId': 'cat1',
      'sellerId': 'seller1',
      'status': 'approved',
      'isApproved': true,
      'ecoLevel': 'high',
      'imageUrls': [
        'https://via.placeholder.com/300x300/FF9800/FFFFFF?text=Carrot',
        'https://via.placeholder.com/300x300/FFA726/FFFFFF?text=Fresh+Carrot'
      ],
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'ผักโขมอินทรีย์',
      'description': 'ผักโขมสดใหม่ เก็บใหม่ทุกวัน',
      'price': 30.0,
      'categoryId': 'cat1',
      'sellerId': 'seller2',
      'status': 'approved',
      'isApproved': true,
      'ecoLevel': 'high',
      'imageUrls': [
        'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=Spinach',
        'https://via.placeholder.com/300x300/66BB6A/FFFFFF?text=Organic+Spinach'
      ],
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'น้ำผึ้งแท้',
      'description': 'น้ำผึ้งแท้ 100% จากธรรมชาติ',
      'price': 200.0,
      'categoryId': 'cat2',
      'sellerId': 'seller2',
      'status': 'approved',
      'isApproved': true,
      'ecoLevel': 'high',
      'imageUrls': [
        'https://via.placeholder.com/300x300/FFC107/FFFFFF?text=Honey',
        'https://via.placeholder.com/300x300/FFD54F/FFFFFF?text=Pure+Honey'
      ],
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  // Add each product to Firestore
  for (int i = 0; i < products.length; i++) {
    await firestore.collection('products').doc('prod${i + 1}').set(products[i]);
  }

  // Add sample promotions
  await firestore.collection('promotions').doc('promo1').set({
    'title': 'ลดราคาสินค้าอินทรีย์',
    'description': 'ลด 20% สำหรับสินค้าอินทรีย์ทุกชิ้น',
    'image': 'https://via.placeholder.com/400x200/E91E63/FFFFFF?text=20%25+OFF',
    'isActive': true,
    'startDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
    'endDate': Timestamp.fromDate(DateTime(2025, 12, 31)),
  });
}
