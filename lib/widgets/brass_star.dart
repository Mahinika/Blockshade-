import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/verkstad_tokens.dart';

/// Stjärna som mässingsstift (ifylld eller utstansad på tejp).
class BrassStar extends StatelessWidget {
  const BrassStar({
    super.key,
    required this.filled,
    this.size = 28,
  });

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BrassStarPainter(filled: filled),
    );
  }
}

class _BrassStarPainter extends CustomPainter {
  _BrassStarPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = _starPath(center, size.width * 0.42);

    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = VerkstadTokens.pencil.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
      canvas.drawPath(path, Paint()..color = VerkstadTokens.brassPin);
      canvas.drawPath(
        path,
        Paint()
          ..color = VerkstadTokens.pencil
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        center.translate(-size.width * 0.08, -size.height * 0.1),
        size.width * 0.06,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = VerkstadTokens.pencil
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  Path _starPath(Offset center, double radius) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BrassStarPainter oldDelegate) {
    return oldDelegate.filled != filled;
  }
}
