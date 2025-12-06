import 'package:flutter/material.dart';
import 'package:green_market/screens/buyer/public_shop_screen.dart';
import 'package:green_market/screens/seller/preview_my_shop_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerShopScreen extends StatelessWidget {
  final String sellerID;
  const SellerShopScreen({super.key, required this.sellerID});

  Future<String?> _getSellerName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerID)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['shopName'] ?? data?['displayName'] ?? 'ร้านค้า';
      }
    } catch (e) {
      print('Error getting seller name: $e');
    }
    return 'ร้านค้า';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == sellerID;

    return FutureBuilder<String?>(
      future: _getSellerName(),
      builder: (context, snapshot) {
        final sellerName = snapshot.data ?? 'ร้านค้า';

        // ถ้าเป็นเจ้าของร้าน ใช้ PreviewMyShopScreen (แก้ไขได้)
        if (isOwner) {
          return PreviewMyShopScreen(
            sellerId: sellerID,
            sellerName: sellerName,
          );
        }

        // ถ้าเป็นลูกค้า ใช้ PublicShopScreen (ดูอย่างเดียว)
        return PublicShopScreen(
          sellerId: sellerID,
          sellerName: sellerName,
        );
      },
    );
  }
}
