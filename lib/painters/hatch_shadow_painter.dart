import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/verkstad_tokens.dart';

/// Blyertsskraffering för eko-skugga med prickräknare (|| → |).
class HatchShadowPainter extends CustomPainter {
  HatchShadowPainter({
    required this.progress,
    required this.remainingMoves,
    this.cornerRadius = 6,
    this.hatchAlpha = 0.55,
  });

  /// 0–1 hur mycket av skrafferingen som är ritad.
  final double progress;
  final int remainingMoves;
  final double cornerRadius;
  final double hatchAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    const spacing = 5.0;
    const angle = math.pi / 4;
    final hatch = Paint()
      ..color = VerkstadTokens.pencil.withValues(alpha: hatchAlpha)
      ..strokeWidth = 0.9;

    final diag = size.width + size.height;
    final lines = (diag / spacing).ceil();
    final visibleLines = (lines * progress).floor();

    for (var i = 0; i < visibleLines; i++) {
      final offset = i * spacing;
      final path = Path();
      path.moveTo(offset, 0);
      path.lineTo(offset - size.height * math.tan(angle), size.height);
      canvas.drawPath(path, hatch);
      final path2 = Path();
      path2.moveTo(0, offset);
      path2.lineTo(size.width, offset - size.width * math.tan(angle));
      canvas.drawPath(path2, hatch);
    }

    canvas.restore();

    // Marginalräknare: två streck → ett
    final margin = Paint()
      ..color = VerkstadTokens.pencil
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final baseX = size.width - 10;
    final baseY = 6.0;
    if (remainingMoves >= 2) {
      canvas.drawLine(Offset(baseX - 4, baseY), Offset(baseX - 4, baseY + 8), margin);
      canvas.drawLine(Offset(baseX, baseY), Offset(baseX, baseY + 8), margin);
    } else if (remainingMoves == 1) {
      canvas.drawLine(Offset(baseX - 2, baseY), Offset(baseX - 2, baseY + 8), margin);
    }
  }

  @override
  bool shouldRepaint(covariant HatchShadowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.remainingMoves != remainingMoves ||
        oldDelegate.hatchAlpha != hatchAlpha;
  }
}
