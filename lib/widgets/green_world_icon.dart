import 'package:flutter/material.dart';

/// Custom green world icon with a small sprouting tree for eco branding.
class GreenWorldIcon extends StatelessWidget {
  final double size;
  const GreenWorldIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    // scale all elements by size/28
    final scale = size / 28.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Earth (circle with land)
          Container(
            width: 24 * scale,
            height: 24 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFB2DFDB), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 1 * scale),
            ),
            child: CustomPaint(
              painter: _EarthLandPainter(),
            ),
          ),
          // Sprout (stem)
          Positioned(
            bottom: 4 * scale,
            child: Container(
              width: 3 * scale,
              height: 10 * scale,
              decoration: BoxDecoration(
                color: Color(0xFF388E3C),
                borderRadius: BorderRadius.circular(2 * scale),
              ),
            ),
          ),
          // Sprout (leaves)
          Positioned(
            bottom: 14 * scale,
            left: 10 * scale,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 8 * scale,
                height: 5 * scale,
                decoration: BoxDecoration(
                  color: Color(0xFF66BB6A),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 14 * scale,
            right: 10 * scale,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                width: 8 * scale,
                height: 5 * scale,
                decoration: BoxDecoration(
                  color: Color(0xFF81C784),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
              ),
            ),
          ),
          // Sprout (soil)
          Positioned(
            bottom: 2 * scale,
            child: Container(
              width: 10 * scale,
              height: 4 * scale,
              decoration: BoxDecoration(
                color: Color(0xFF795548),
                borderRadius: BorderRadius.circular(4 * scale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for earth land shapes
class _EarthLandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.fill;
    // Draw some abstract land shapes
    final path1 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.5, size.width * 0.7,
          size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.9, size.width * 0.2,
          size.height * 0.7)
      ..close();
    canvas.drawPath(path1, paint);

    final paint2 = Paint()
      ..color = const Color(0xFF388E3C)
      ..style = PaintingStyle.fill;
    final path2 = Path()
      ..moveTo(size.width * 0.6, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.2, size.width * 0.7,
          size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.55,
          size.width * 0.6, size.height * 0.3)
      ..close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
