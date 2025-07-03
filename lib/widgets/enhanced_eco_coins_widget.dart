import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/user_provider.dart';

class EnhancedEcoCoinsWidget extends StatelessWidget {
  final bool showLabel;
  final bool showValue;
  final double size;
  final EdgeInsets? padding;

  const EnhancedEcoCoinsWidget({
    super.key,
    this.showLabel = true,
    this.showValue = true,
    this.size = 24.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final ecoCoinCount = currentUser?.ecoCoins ?? 0.0;

        return Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      child: Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: size,
                      ),
                    ),
                  );
                },
              ),

              if (showValue || showLabel) const SizedBox(width: 8),

              if (showValue) ...[
                Text(
                  ecoCoinCount % 1 == 0
                      ? '${ecoCoinCount.toInt()}'
                      : ecoCoinCount.toStringAsFixed(1),
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
      },
    );
  }
}

class EcoCoinsAnimatedCounter extends StatefulWidget {
  final int targetValue;
  final int currentValue;
  final Duration duration;
  final TextStyle? textStyle;

  const EcoCoinsAnimatedCounter({
    super.key,
    required this.targetValue,
    required this.currentValue,
    this.duration = const Duration(milliseconds: 1000),
    this.textStyle,
  });

  @override
  State<EcoCoinsAnimatedCounter> createState() =>
      _EcoCoinsAnimatedCounterState();
}

class _EcoCoinsAnimatedCounterState extends State<EcoCoinsAnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = IntTween(
      begin: widget.currentValue,
      end: widget.targetValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value}',
          style: widget.textStyle ??
              const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB8860B),
              ),
        );
      },
    );
  }
}

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
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -100.0,
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

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFF8DC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
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
                      Icons.eco,
                      color: Color(0xFFB8860B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.coins}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8860B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
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
