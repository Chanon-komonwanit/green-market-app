// lib/widgets/eco_coins_widget.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eco_coin.dart';
import '../utils/constants.dart';
import '../screens/eco_coins_screen.dart';
import '../providers/eco_coins_provider.dart';
import '../services/eco_coins_service.dart';

class EcoCoinsWidget extends StatelessWidget {
  final EcoCoinBalance? balance;
  final bool showAnimation;
  final VoidCallback? onTap;

  const EcoCoinsWidget({
    super.key,
    this.balance,
    this.showAnimation = false,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    // Try to get provider, but fallback to mock data if not available
    try {
      return Consumer<EcoCoinsProvider>(
        builder: (context, provider, child) {
          final displayBalance =
              balance ?? provider.balance ?? _getMockBalance();
          return _buildWidget(context, displayBalance);
        },
      );
    } catch (e) {
      // Fallback if provider is not available
      final displayBalance = balance ?? _getMockBalance();
      return _buildWidget(context, displayBalance);
    }
  }

  Widget _buildWidget(BuildContext context, EcoCoinBalance displayBalance) {
    return GestureDetector(
      onTap: onTap ?? () => _navigateToEcoCoinsScreen(context),
      child: Container(
        height: 48, // Fixed height to ensure visibility
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              displayBalance.currentTier.color.withOpacity(0.8),
              displayBalance.currentTier.color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: displayBalance.currentTier.color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          // Add a border for better visibility during testing
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Eco Coin Icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '🪙',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Balance
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${displayBalance.availableCoins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (displayBalance.coinsToNextTier > 0)
                  Text(
                    '+${displayBalance.coinsToNextTier}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            // Arrow
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_right,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEcoCoinsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcoCoinsScreen(balance: balance),
      ),
    );
  }

  // Mock data for development
  EcoCoinBalance _getMockBalance() {
    return EcoCoinBalance(
      userId: 'mock_user',
      totalCoins: 1250,
      availableCoins: 1250,
      expiredCoins: 0,
      lifetimeEarned: 2500,
      lifetimeSpent: 1250,
      currentTier: EcoCoinTierExtension.getCurrentTier(1250),
      coinsToNextTier: () {
        final currentTier = EcoCoinTierExtension.getCurrentTier(1250);
        final nextTier = currentTier.getNextTier();
        return nextTier != null ? nextTier.minCoins - 1250 : 0;
      }(),
      lastUpdated: Timestamp.now(),
    );
  }
}

// Animated Eco Coins Widget for special effects
class AnimatedEcoCoinsWidget extends StatefulWidget {
  final EcoCoinBalance? balance;
  final int? newCoins; // จำนวนเหลียญที่เพิ่งได้รับ

  const AnimatedEcoCoinsWidget({
    super.key,
    this.balance,
    this.newCoins,
  });

  @override
  State<AnimatedEcoCoinsWidget> createState() => _AnimatedEcoCoinsWidgetState();
}

class _AnimatedEcoCoinsWidgetState extends State<AnimatedEcoCoinsWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5),
    ));

    if (widget.newCoins != null && widget.newCoins! > 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main coins widget
        ScaleTransition(
          scale: _scaleAnimation,
          child: EcoCoinsWidget(balance: widget.balance),
        ),

        // New coins indicator
        if (widget.newCoins != null && widget.newCoins! > 0)
          Positioned(
            top: -10,
            right: -5,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '+${widget.newCoins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Compact version for app bar
class CompactEcoCoinsWidget extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;

  const CompactEcoCoinsWidget({
    super.key,
    required this.coins,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.primaryTeal.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.eco,
              color: AppColors.primaryTeal,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              coins.toString(),
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
