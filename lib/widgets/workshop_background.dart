import 'package:flutter/material.dart';
import '../painters/wood_grain_painter.dart';
import '../theme/verkstad_tokens.dart';

/// Hela skärmens bänkskiva med valfri världston.
class WorkshopBackground extends StatelessWidget {
  const WorkshopBackground({
    super.key,
    required this.world,
    this.child,
    this.seed = 7,
  });

  final int world;
  final Widget? child;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final color = VerkstadTokens.benchForWorld(world);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: WoodGrainPainter(baseColor: color, seed: seed + world * 11),
        ),
        if (world == 1) _cornerDoodle(),
        if (child != null) child!,
      ],
    );
  }

  Widget _cornerDoodle() {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Opacity(
        opacity: 0.35,
        child: CustomPaint(
          size: const Size(48, 48),
          painter: _CoffeeStainPainter(),
        ),
      ),
    );
  }
}

class _CoffeeStainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VerkstadTokens.pencil.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(Rect.fromLTWH(4, 8, 40, 32), paint);
    canvas.drawOval(Rect.fromLTWH(10, 14, 28, 20), paint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
