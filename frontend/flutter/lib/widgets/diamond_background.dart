import 'package:flutter/material.dart';

/// Draws the premium diamond/rhombus grid pattern seen on the Karuṇā mockups.
class DiamondBackground extends StatelessWidget {
  final Color bgColor;
  final Color diamondColor;
  final Widget child;

  const DiamondBackground({
    super.key,
    this.bgColor = const Color(0xFF0F766E),
    this.diamondColor = const Color(0xFF115E59),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: CustomPaint(
        painter: _DiamondPainter(diamondColor: diamondColor.withOpacity(0.4)),
        child: child,
      ),
    );
  }
}

/// A subtle grid pattern for light pages like login, registration, etc.
class LightDiamondBackground extends StatelessWidget {
  final Widget child;

  const LightDiamondBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFD),
      child: CustomPaint(
        painter: _DiamondPainter(diamondColor: const Color(0xFFE2E8F0)),
        child: child,
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  final Color diamondColor;

  _DiamondPainter({required this.diamondColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = diamondColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 48.0;
    const double half = spacing / 2;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final path = Path()
          ..moveTo(x, y - half)
          ..lineTo(x + half, y)
          ..lineTo(x, y + half)
          ..lineTo(x - half, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
