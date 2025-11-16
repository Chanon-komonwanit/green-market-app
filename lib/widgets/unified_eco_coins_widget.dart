// lib/widgets/unified_eco_coins_widget.dart
// Unified Eco Coins Widget - รวม EcoCoinsWidget และ EnhancedEcoCoinsWidget เป็นหนึ่งเดียว

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eco_coin.dart';
import '../utils/constants.dart';
import '../screens/eco_coins_screen.dart';
import '../screens/eco_rewards_screen.dart';
import '../providers/eco_coins_provider.dart';
import '../providers/user_provider.dart';

/// Unified Eco Coins Widget สำหรับแสดงเหรียญ Eco ในรูปแบบต่างๆ
/// รองรับทั้งแบบ compact, enhanced, และ animated
class UnifiedEcoCoinsWidget extends StatelessWidget {
  final EcoCoinBalance? balance;
  final EcoCoinsWidgetStyle style;
  final double size;
  final bool showLabel;
  final bool showValue;
  final bool showAnimation;
  final bool enableTap;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final int? newCoins; // สำหรับแสดงการได้เหรียญใหม่

  const UnifiedEcoCoinsWidget({
    super.key,
    this.balance,
    this.style = EcoCoinsWidgetStyle.standard,
    this.size = 24.0,
    this.showLabel = true,
    this.showValue = true,
    this.showAnimation = false,
    this.enableTap = true,
    this.onTap,
    this.padding,
    this.newCoins,
  });

  /// Compact version for app bar
  const UnifiedEcoCoinsWidget.compact({
    super.key,
    this.balance,
    this.onTap,
  })  : style = EcoCoinsWidgetStyle.compact,
        size = 16.0,
        showLabel = false,
        showValue = true,
        showAnimation = false,
        enableTap = true,
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        newCoins = null;

  /// Enhanced version with gold gradient
  const UnifiedEcoCoinsWidget.enhanced({
    super.key,
    this.balance,
    this.size = 24.0,
    this.onTap,
  })  : style = EcoCoinsWidgetStyle.enhanced,
        showLabel = true,
        showValue = true,
        showAnimation = true,
        enableTap = true,
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        newCoins = null;

  /// Animated version with floating effect
  const UnifiedEcoCoinsWidget.animated({
    super.key,
    this.balance,
    this.newCoins,
    this.onTap,
  })  : style = EcoCoinsWidgetStyle.animated,
        size = 20.0,
        showLabel = false,
        showValue = true,
        showAnimation = true,
        enableTap = true,
        padding = null;

  @override
  Widget build(BuildContext context) {
    return _buildWidgetContent(context);
  }

  Widget _buildWidgetContent(BuildContext context) {
    try {
      return Consumer2<EcoCoinProvider, UserProvider>(
        builder: (context, ecoProvider, userProvider, child) {
          // ใช้ balance ตามลำดับความสำคัญ
          EcoCoinBalance displayBalance;

          if (balance != null) {
            displayBalance = balance!;
          } else if (ecoProvider.balance != null) {
            displayBalance = ecoProvider.balance!;
          } else {
            // สร้าง balance จาก UserProvider
            final currentUser = userProvider.currentUser;
            final ecoCoins = currentUser?.ecoCoins.toDouble() ?? 0.0;
            displayBalance = EcoCoinBalance(
              userId: currentUser?.id ?? 'anonymous',
              totalCoins: ecoCoins.toInt(),
              availableCoins: ecoCoins.toInt(),
              expiredCoins: 0,
              lifetimeEarned: ecoCoins.toInt(),
              lifetimeSpent: 0,
              currentTier:
                  EcoCoinTierExtension.getCurrentTier(ecoCoins.toInt()),
              coinsToNextTier: _calculateCoinsToNextTier(ecoCoins.toInt()),
              lastUpdated: Timestamp.now(),
            );
          }

          return _buildWidgetByStyle(context, displayBalance);
        },
      );
    } catch (e) {
      // Fallback หากไม่มี provider
      final fallbackBalance = balance ?? _getMockBalance();
      return _buildWidgetByStyle(context, fallbackBalance);
    }
  }

  Widget _buildWidgetByStyle(
      BuildContext context, EcoCoinBalance displayBalance) {
    switch (style) {
      case EcoCoinsWidgetStyle.compact:
        return _buildCompactWidget(context, displayBalance);
      case EcoCoinsWidgetStyle.enhanced:
        return _buildEnhancedWidget(context, displayBalance);
      case EcoCoinsWidgetStyle.animated:
        return _buildAnimatedWidget(context, displayBalance);
      case EcoCoinsWidgetStyle.standard:
        return _buildStandardWidget(context, displayBalance);
    }
  }

  /// Standard widget สำหรับการใช้งานทั่วไป
  Widget _buildStandardWidget(
      BuildContext context, EcoCoinBalance displayBalance) {
    Widget widget = GestureDetector(
      onTap: enableTap
          ? (onTap ?? () => _navigateToEcoCoinsScreen(context))
          : null,
      child: Container(
        height: 32,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Eco Coin Icon
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                '🪙',
                style: TextStyle(fontSize: size * 0.5),
              ),
            ),
            const SizedBox(width: 4),

            // Balance Text
            if (showValue)
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${displayBalance.availableCoins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (showLabel)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          displayBalance.currentTier.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Arrow icon
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 8,
            ),
          ],
        ),
      ),
    );

    // เพิ่ม new coins indicator หากมี
    if (newCoins != null && newCoins! > 0) {
      widget = Stack(
        children: [
          widget,
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '+$newCoins',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget;
  }

  /// Compact widget สำหรับ app bar
  Widget _buildCompactWidget(
      BuildContext context, EcoCoinBalance displayBalance) {
    return GestureDetector(
      onTap: enableTap
          ? (onTap ?? () => _navigateToEcoCoinsScreen(context))
          : null,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              Icons.monetization_on,
              color: Colors.amber[700],
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              displayBalance.availableCoins.toString(),
              style: TextStyle(
                color: Colors.amber[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced widget พร้อม gold gradient
  Widget _buildEnhancedWidget(
      BuildContext context, EcoCoinBalance displayBalance) {
    Widget coinWidget = Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700), // ทองเข้ม
            Color(0xFFFFF8DC), // ทองอ่อน
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB8860B),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Coin Icon
          if (showAnimation)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Container(
                    padding: EdgeInsets.all(size * 0.15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFB8860B),
                          Color(0xFFDAA520),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB8860B).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '🪙',
                      style: TextStyle(fontSize: size),
                    ),
                  ),
                );
              },
            )
          else
            Text('🪙', style: TextStyle(fontSize: size)),

          if (showValue || showLabel) const SizedBox(width: 8),

          if (showValue) ...[
            Text(
              displayBalance.availableCoins % 1 == 0
                  ? '${displayBalance.availableCoins}'
                  : displayBalance.availableCoins.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size * 0.8,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB8860B),
                shadows: const [
                  Shadow(
                    color: Color(0x40000000),
                    blurRadius: 1,
                    offset: Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
            if (showLabel) const SizedBox(width: 4),
          ],

          if (showLabel)
            Text(
              'เหรียญ Eco',
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB8860B),
              ),
            ),
        ],
      ),
    );

    // เพิ่ม tap functionality
    if (enableTap) {
      return GestureDetector(
        onTap: onTap ??
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EcoRewardsScreen(),
                  ),
                ),
        child: coinWidget,
      );
    }

    return coinWidget;
  }

  /// Animated widget พร้อมเอฟเฟกต์พิเศษ
  Widget _buildAnimatedWidget(
      BuildContext context, EcoCoinBalance displayBalance) {
    return AnimatedEcoCoinsWidget(
      balance: displayBalance,
      newCoins: newCoins,
      onTap: enableTap
          ? (onTap ?? () => _navigateToEcoCoinsScreen(context))
          : null,
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

  int _calculateCoinsToNextTier(int currentCoins) {
    final currentTier = EcoCoinTierExtension.getCurrentTier(currentCoins);
    final nextTier = currentTier.getNextTier();
    return nextTier != null ? nextTier.minCoins - currentCoins : 0;
  }

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

/// Animated Eco Coins Widget สำหรับเอฟเฟกต์พิเศษ
class AnimatedEcoCoinsWidget extends StatefulWidget {
  final EcoCoinBalance balance;
  final int? newCoins;
  final VoidCallback? onTap;

  const AnimatedEcoCoinsWidget({
    super.key,
    required this.balance,
    this.newCoins,
    this.onTap,
  });

  @override
  State<AnimatedEcoCoinsWidget> createState() => _AnimatedEcoCoinsWidgetState();
}

class _AnimatedEcoCoinsWidgetState extends State<AnimatedEcoCoinsWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.newCoins != null && widget.newCoins! > 0) {
      _controller.forward();
    }

    // เริ่ม pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main widget with pulse
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            child: UnifiedEcoCoinsWidget(
              balance: widget.balance,
              style: EcoCoinsWidgetStyle.standard,
              enableTap: false,
            ),
          ),
        ),

        // New coins floating indicator
        if (widget.newCoins != null && widget.newCoins! > 0)
          Positioned(
            top: -15,
            right: -10,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: EcoCoinsFloatingReward(
                  coins: widget.newCoins!,
                  reason: 'ได้รับ',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Floating reward widget
class EcoCoinsFloatingReward extends StatefulWidget {
  final int coins;
  final String reason;
  final VoidCallback? onComplete;

  const EcoCoinsFloatingReward({
    super.key,
    required this.coins,
    required this.reason,
    this.onComplete,
  });

  @override
  State<EcoCoinsFloatingReward> createState() => _EcoCoinsFloatingRewardState();
}

class _EcoCoinsFloatingRewardState extends State<EcoCoinsFloatingReward>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0),
    ));

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFF8DC)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB8860B)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Color(0xFFB8860B),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '+${widget.coins}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB8860B),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.reason,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFB8860B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// รูปแบบการแสดงผลของ widget
enum EcoCoinsWidgetStyle {
  standard, // แบบมาตรฐาน
  compact, // แบบกะทัดรัด
  enhanced, // แบบ enhanced พร้อม gold gradient
  animated, // แบบ animated พร้อมเอฟเฟกต์
}
