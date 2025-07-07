import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedGlobeIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedGlobeIcon({
    super.key,
    this.size = 32,
    this.color = Colors.white,
  });

  @override
  State<AnimatedGlobeIcon> createState() => _AnimatedGlobeIconState();
}

class _AnimatedGlobeIconState extends State<AnimatedGlobeIcon>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation - slow continuous rotation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Pulse animation - breathing effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Sparkle animation - twinkling effect
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    // Start all animations
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _sparkleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationAnimation,
        _pulseAnimation,
        _sparkleAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main globe with rotation
                Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF4CAF50).withOpacity(0.9),
                          Color(0xFF2E7D32),
                          Color(0xFF1B5E20),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Continents (simplified)
                        Positioned(
                          top: widget.size * 0.2,
                          left: widget.size * 0.15,
                          child: Container(
                            width: widget.size * 0.3,
                            height: widget.size * 0.25,
                            decoration: BoxDecoration(
                              color: Color(0xFF1B5E20).withOpacity(0.6),
                              borderRadius:
                                  BorderRadius.circular(widget.size * 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          top: widget.size * 0.45,
                          right: widget.size * 0.1,
                          child: Container(
                            width: widget.size * 0.25,
                            height: widget.size * 0.2,
                            decoration: BoxDecoration(
                              color: Color(0xFF1B5E20).withOpacity(0.6),
                              borderRadius:
                                  BorderRadius.circular(widget.size * 0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: widget.size * 0.15,
                          left: widget.size * 0.25,
                          child: Container(
                            width: widget.size * 0.2,
                            height: widget.size * 0.15,
                            decoration: BoxDecoration(
                              color: Color(0xFF1B5E20).withOpacity(0.6),
                              borderRadius:
                                  BorderRadius.circular(widget.size * 0.06),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Sparkle effects
                ...List.generate(6, (index) {
                  final angle = (index * 60.0) * math.pi / 180;
                  final distance = widget.size * 0.6;
                  final x =
                      math.cos(angle + _sparkleAnimation.value * 2 * math.pi) *
                          distance;
                  final y =
                      math.sin(angle + _sparkleAnimation.value * 2 * math.pi) *
                          distance;

                  return Positioned(
                    left: widget.size / 2 + x - 2,
                    top: widget.size / 2 + y - 2,
                    child: Opacity(
                      opacity:
                          (math.sin(_sparkleAnimation.value * 2 * math.pi) *
                                      0.5 +
                                  0.5) *
                              0.8,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color,
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.8),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                // Center highlight
                Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
