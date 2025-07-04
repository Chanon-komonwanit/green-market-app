import 'package:flutter/material.dart';
import 'package:green_market/widgets/animated_sprouting_tree.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';

class AnimatedGreenWorldButton extends StatefulWidget {
  const AnimatedGreenWorldButton({super.key});

  @override
  State<AnimatedGreenWorldButton> createState() =>
      _AnimatedGreenWorldButtonState();
}

class _AnimatedGreenWorldButtonState extends State<AnimatedGreenWorldButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main scale animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Continuous pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation and repeat
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
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF4CAF50),
                  Color(0xFF66BB6A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4 * _pulseAnimation.value),
                  blurRadius: 20 * _pulseAnimation.value,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.green.withOpacity(0.2 * _pulseAnimation.value),
                  blurRadius: 10 * _pulseAnimation.value,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) => _controller.reverse(),
                onTapCancel: () => _controller.reverse(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GreenWorldHubScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Enhanced Sprouting Tree Animation
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const AnimatedSproutingTree(size: 32),
                      ),
                      const SizedBox(width: 16),
                      // Text with enhanced styling
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🌍 เปิดโลกสีเขียว',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF1B5E20),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'สำรวจกิจกรรมเพื่อสิ่งแวดล้อม',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Arrow icon with bounce animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(2 * (_pulseAnimation.value - 1), 0),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
