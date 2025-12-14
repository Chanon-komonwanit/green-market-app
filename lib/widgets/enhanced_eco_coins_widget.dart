// lib/widgets/enhanced_eco_coins_widget.dart
// 🪙 Enhanced Eco Coins Widget with Gold Coin Design
// เหรียญทองพร้อมลูกเล่น Animation และการออกแบบที่สวยงาม

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/eco_coin.dart';
import '../providers/eco_coins_provider.dart';
import '../screens/eco_coins_screen.dart';
import '../utils/constants.dart';

/// Enhanced Eco Coins Widget - เหรียญทองแบบเต็มรูปแบบ
class EnhancedEcoCoinsWidget extends StatefulWidget {
  final bool compact;
  final VoidCallback? onTap;

  const EnhancedEcoCoinsWidget({
    super.key,
    this.compact = false,
    this.onTap,
  });

  @override
  State<EnhancedEcoCoinsWidget> createState() => _EnhancedEcoCoinsWidgetState();
}

class _EnhancedEcoCoinsWidgetState extends State<EnhancedEcoCoinsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EcoCoinProvider>(
      builder: (context, provider, child) {
        final balance = provider.balance;
        if (balance == null) {
          return _buildLoadingWidget();
        }

        return widget.compact
            ? _buildCompactWidget(balance)
            : _buildFullWidget(balance);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactWidget(EcoCoinBalance balance) {
    return GestureDetector(
      onTap: widget.onTap ?? () => _navigateToEcoCoinsScreen(balance),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              balance.currentTier.color.withOpacity(0.9),
              balance.currentTier.color.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: balance.currentTier.color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGoldCoin(size: 20),
            const SizedBox(width: 6),
            Text(
              _formatCoins(balance.availableCoins),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidget(EcoCoinBalance balance) {
    return GestureDetector(
      onTap: widget.onTap ?? () => _navigateToEcoCoinsScreen(balance),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              balance.currentTier.color.withOpacity(0.9),
              balance.currentTier.color.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: balance.currentTier.color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildGoldCoin(size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eco Coins',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatCoins(balance.availableCoins),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        balance.currentTier.icon,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        balance.currentTier.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _getProgressToNextTier(balance),
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              balance.coinsToNextTier > 0
                  ? 'อีก ${_formatCoins(balance.coinsToNextTier)} เหรียญสู่ระดับถัดไป'
                  : 'คุณถึงระดับสูงสุดแล้ว!',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldCoin({required double size}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFE55C),
                const Color(0xFFFFD700),
                const Color(0xFFFFA500),
              ],
              stops: const [0.3, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.6),
                blurRadius: size * 0.3,
                spreadRadius: size * 0.05,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer effect
              ClipOval(
                child: Transform.translate(
                  offset: Offset(_shimmerAnimation.value * size, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Coin icon
              Center(
                child: Transform.rotate(
                  angle: math.pi / 12,
                  child: Text(
                    '💰',
                    style: TextStyle(
                      fontSize: size * 0.6,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, size * 0.05),
                          blurRadius: size * 0.1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getProgressToNextTier(EcoCoinBalance balance) {
    if (balance.coinsToNextTier <= 0) return 1.0;

    final currentTierMinCoins = balance.currentTier.minCoins;
    final nextTier = balance.currentTier.getNextTier();
    if (nextTier == null) return 1.0;

    final nextTierMinCoins = nextTier.minCoins;
    final totalCoinsNeeded = nextTierMinCoins - currentTierMinCoins;
    final coinsEarned = balance.availableCoins - currentTierMinCoins;

    return (coinsEarned / totalCoinsNeeded).clamp(0.0, 1.0);
  }

  String _formatCoins(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    }
    return coins.toString();
  }

  void _navigateToEcoCoinsScreen(EcoCoinBalance balance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcoCoinsScreen(balance: balance),
      ),
    );
  }
}

/// Floating Eco Coin Animation - สำหรับแสดงเมื่อได้รับเหรียญ
class FloatingEcoCoin extends StatefulWidget {
  final int amount;
  final Offset startPosition;
  final VoidCallback? onComplete;

  const FloatingEcoCoin({
    super.key,
    required this.amount,
    required this.startPosition,
    this.onComplete,
  });

  @override
  State<FloatingEcoCoin> createState() => _FloatingEcoCoinState();
}

class _FloatingEcoCoinState extends State<FloatingEcoCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.startPosition + const Offset(0, -100),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '💰',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${widget.amount}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
