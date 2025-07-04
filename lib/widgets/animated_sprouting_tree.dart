import 'package:flutter/material.dart';

class AnimatedSproutingTree extends StatefulWidget {
  final double size;
  const AnimatedSproutingTree({super.key, this.size = 32});

  @override
  State<AnimatedSproutingTree> createState() => _AnimatedSproutingTreeState();
}

class _AnimatedSproutingTreeState extends State<AnimatedSproutingTree>
    with TickerProviderStateMixin {
  late AnimationController _growthController;
  late AnimationController _swayController;
  late Animation<double> _growthAnimation;
  late Animation<double> _swayAnimation;

  @override
  void initState() {
    super.initState();

    // Growth animation (sprout grows from soil)
    _growthController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _growthAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _growthController,
      curve: Curves.easeOutBack,
    ));

    // Gentle sway animation
    _swayController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _swayAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _swayController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _growthController.forward();
    _swayController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _growthController.dispose();
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_growthAnimation, _swayAnimation]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _swayAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _SproutingTreePainter(
                growthProgress: _growthAnimation.value,
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SproutingTreePainter extends CustomPainter {
  final double growthProgress;
  final double size;

  _SproutingTreePainter({required this.growthProgress, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final scale = size / 32.0;

    // Soil base
    final soilPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;

    final soilRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        4 * scale,
        24 * scale,
        24 * scale,
        8 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(soilRect, soilPaint);

    if (growthProgress > 0) {
      // Stem (grows upward)
      final stemPaint = Paint()
        ..color = const Color(0xFF4CAF50)
        ..style = PaintingStyle.fill;

      final stemHeight = 16 * scale * growthProgress;
      final stemRect = Rect.fromLTWH(
        14 * scale,
        24 * scale - stemHeight,
        4 * scale,
        stemHeight,
      );
      canvas.drawRect(stemRect, stemPaint);

      // Leaves (appear after stem reaches certain height)
      if (growthProgress > 0.5) {
        final leafProgress = (growthProgress - 0.5) * 2;
        final leafPaint = Paint()
          ..color = Color.lerp(
            const Color(0xFF81C784),
            const Color(0xFF4CAF50),
            leafProgress,
          )!
          ..style = PaintingStyle.fill;

        // Left leaf
        final leftLeafPath = Path();
        leftLeafPath.moveTo(16 * scale, 16 * scale);
        leftLeafPath.quadraticBezierTo(
          8 * scale * leafProgress,
          12 * scale,
          12 * scale * leafProgress,
          8 * scale,
        );
        leftLeafPath.quadraticBezierTo(
          14 * scale,
          10 * scale,
          16 * scale,
          14 * scale,
        );
        leftLeafPath.close();
        canvas.drawPath(leftLeafPath, leafPaint);

        // Right leaf
        final rightLeafPath = Path();
        rightLeafPath.moveTo(16 * scale, 16 * scale);
        rightLeafPath.quadraticBezierTo(
          24 * scale * leafProgress,
          12 * scale,
          20 * scale * leafProgress,
          8 * scale,
        );
        rightLeafPath.quadraticBezierTo(
          18 * scale,
          10 * scale,
          16 * scale,
          14 * scale,
        );
        rightLeafPath.close();
        canvas.drawPath(rightLeafPath, leafPaint);
      }

      // Small flowers/buds (appear at full growth)
      if (growthProgress > 0.8) {
        final budProgress = (growthProgress - 0.8) * 5;
        final budPaint = Paint()
          ..color = Color.lerp(
            const Color(0xFFFFF3E0),
            const Color(0xFFFFEB3B),
            budProgress,
          )!
          ..style = PaintingStyle.fill;

        // Small bud at top
        canvas.drawCircle(
          Offset(16 * scale, 8 * scale),
          2 * scale * budProgress,
          budPaint,
        );
      }
    }

    // Sparkle effects around the growing plant
    if (growthProgress > 0.3) {
      final sparklePaint = Paint()
        ..color = Colors.yellow.withOpacity(0.6 * growthProgress)
        ..style = PaintingStyle.fill;

      // Multiple small sparkles
      final sparklePositions = [
        Offset(8 * scale, 12 * scale),
        Offset(24 * scale, 14 * scale),
        Offset(6 * scale, 20 * scale),
        Offset(26 * scale, 18 * scale),
      ];

      for (int i = 0; i < sparklePositions.length; i++) {
        final sparkleSize = (0.8 + (i * 0.1)) * scale * growthProgress;
        canvas.drawCircle(sparklePositions[i], sparkleSize, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
