import 'package:flutter/material.dart';
import 'package:green_market/screens/shopee_style_shop_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerShopScreen extends StatelessWidget {
  final String sellerID;
  const SellerShopScreen({super.key, required this.sellerID});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == sellerID;

    return ShopeeStyleShopScreen(
      sellerId: sellerID,
      isOwner: isOwner,
    );
  }
}
