// lib/widgets/cart_icon_badge.dart
import 'package:flutter/material.dart';
import 'package:green_market/providers/cart_provider_enhanced.dart';
import 'package:green_market/screens/cart_screen.dart';
import 'package:green_market/utils/constants.dart'; // For AppColors
import 'package:provider/provider.dart';

class CartIconWithBadge extends StatelessWidget {
  const CartIconWithBadge({super.key, required bool isActive});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProviderEnhanced>(
      builder: (_, cart, ch) => Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const CartScreen(
                        navigateToCheckout: false,
                      )));
            },
          ),
          if (cart.itemCount > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors
                      .errorRed, // Ensure AppColors.errorRed is defined
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  cart.itemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
