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
                colors: [
                  Color(0xFF4FC3F7), // ฟ้าสว่าง (น้ำ)
                  Color(0xFF81C784), // เขียวอ่อน (ป่าไผ่)
                  Color(0xFF2E7D32), // เขียวเข้ม (ป่าใหญ่)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4, 1.0],
              ),
              border: Border.all(
                color: Colors.white,
                width: 2 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 2 * scale),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _EarthLandPainter(scale),
            ),
          ),
          // Little soil patch at bottom
          Positioned(
            bottom: 0,
            child: Container(
              width: 14 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(8 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.3),
                    blurRadius: 2 * scale,
                    offset: Offset(0, 1 * scale),
                  ),
                ],
              ),
            ),
          ),
          // Sprout stem (from soil)
          Positioned(
            bottom: 4 * scale,
            child: Container(
              width: 2.5 * scale,
              height: 12 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF388E3C),
                borderRadius: BorderRadius.circular(2 * scale),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // First leaf (left)
          Positioned(
            bottom: 16 * scale,
            left: 10 * scale,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: 9 * scale,
                height: 6 * scale,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                  ),
                  borderRadius: BorderRadius.circular(8 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 2 * scale,
                      offset: Offset(0, 1 * scale),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Second leaf (right)
          Positioned(
            bottom: 16 * scale,
            right: 10 * scale,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 9 * scale,
                height: 6 * scale,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF9CCC65)],
                  ),
                  borderRadius: BorderRadius.circular(8 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 2 * scale,
                      offset: Offset(0, 1 * scale),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Third leaf (center top)
          Positioned(
            bottom: 20 * scale,
            child: Container(
              width: 7 * scale,
              height: 5 * scale,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF81C784), Color(0xFFAED581)],
                ),
                borderRadius: BorderRadius.circular(6 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 2 * scale,
                    offset: Offset(0, 1 * scale),
                  ),
                ],
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
  final double scale;
  _EarthLandPainter(this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    // Green continents
    final continentPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    // First continent (Asia-like)
    final continent1 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.1, size.width * 0.8,
          size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.6, size.width * 0.3,
          size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.3, size.width * 0.3,
          size.height * 0.2)
      ..close();
    canvas.drawPath(continent1, continentPaint);

    // Second continent (smaller one)
    final continentPaint2 = Paint()
      ..color = const Color(0xFF388E3C)
      ..style = PaintingStyle.fill;

    final continent2 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.7, size.width * 0.3,
          size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.8, size.width * 0.1,
          size.height * 0.6)
      ..close();
    canvas.drawPath(continent2, continentPaint2);

    // Third continent (another small one)
    final continent3 = Path()
      ..moveTo(size.width * 0.7, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.75,
          size.width * 0.85, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.85,
          size.width * 0.7, size.height * 0.7)
      ..close();
    canvas.drawPath(continent3, continentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
