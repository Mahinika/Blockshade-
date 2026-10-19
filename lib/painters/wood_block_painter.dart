import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/verkstad_tokens.dart';

class WoodBlockPainter extends CustomPainter {
  WoodBlockPainter({
    required this.fillColor,
    required this.colorName,
    required this.textureSeed,
    this.lift = 0,
    this.horizontal = true,
    this.negativeHead = true,
    this.positiveHead = true,
    this.notchCount = 1,
    this.showMarkings = true,
  });

  final Color fillColor;
  final String colorName;
  final int textureSeed;
  final double lift;
  final bool horizontal;
  final bool negativeHead;
  final bool positiveHead;
  final int notchCount;
  final bool showMarkings;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = VerkstadTokens.blockCornerRadius;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // Kontaktskugga
    final shadowPaint = Paint()
      ..color = VerkstadTokens.pencil.withValues(alpha: 0.22 + lift * 0.08)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + lift * 2);
    canvas.drawRRect(
      rrect.shift(Offset(1.5, 2 + lift * 2)),
      shadowPaint,
    );

    canvas.drawRRect(rrect, Paint()..color = fillColor);

    // Lack – lätt satin highlight upptill
    final highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0, 0.45],
      ).createShader(rect);
    canvas.drawRRect(rrect, highlight);

    _paintGrain(canvas, rrect);

    final needsEdge = colorName.toLowerCase() == 'yellow';
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = VerkstadTokens.woodEdgeWidth
      ..color = VerkstadTokens.woodEdge;
    canvas.drawRRect(rrect, edge);
    if (needsEdge) {
      canvas.drawRRect(rrect.deflate(0.5), edge..strokeWidth = 1);
    }

    if (showMarkings) {
      _paintNotches(canvas, rect);
      _paintAxisArrows(canvas, rect);
    }
  }

  void _paintGrain(Canvas canvas, RRect rrect) {
    final rng = math.Random(textureSeed);
    final grain = Paint()..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipRRect(rrect);
    for (var i = 0; i < 6 + rng.nextInt(3); i++) {
      final y = rng.nextDouble() * rrect.height;
      grain.color = VerkstadTokens.pencil.withValues(alpha: 0.06 + rng.nextDouble() * 0.05);
      grain.strokeWidth = 0.5 + rng.nextDouble() * 0.6;
      final path = Path()..moveTo(0, y);
      var x = 0.0;
      while (x < rrect.width) {
        x += 6 + rng.nextDouble() * 10;
        path.lineTo(x, y + math.sin(x * 0.05 + textureSeed) * 1.5);
      }
      canvas.drawPath(path, grain);
    }
    canvas.restore();
  }

  void _paintNotches(Canvas canvas, Rect rect) {
    final count = notchCount.clamp(1, 8);
    final paint = Paint()
      ..color = VerkstadTokens.pencil.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final span = rect.width * 0.55;
    final start = rect.center.dx - span / 2;
    final y = rect.bottom - 6;
    for (var i = 0; i < count; i++) {
      final x = count == 1 ? rect.center.dx : start + span * (i / (count - 1));
      canvas.drawLine(Offset(x, y), Offset(x, y - 4), paint);
    }
  }

  void _paintAxisArrows(Canvas canvas, Rect rect) {
    final center = rect.center;
    final len = rect.shortestSide * 0.28;
    final shaft = Paint()
      ..color = VerkstadTokens.pencil.withValues(alpha: 0.8)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    if (horizontal) {
      canvas.drawLine(
        Offset(center.dx - len, center.dy),
        Offset(center.dx + len, center.dy),
        shaft,
      );
      _head(canvas, Offset(center.dx - len, center.dy), const Offset(-1, 0), negativeHead);
      _head(canvas, Offset(center.dx + len, center.dy), const Offset(1, 0), positiveHead);
    } else {
      canvas.drawLine(
        Offset(center.dx, center.dy - len),
        Offset(center.dx, center.dy + len),
        shaft,
      );
      _head(canvas, Offset(center.dx, center.dy - len), const Offset(0, -1), negativeHead);
      _head(canvas, Offset(center.dx, center.dy + len), const Offset(0, 1), positiveHead);
    }
  }

  void _head(Canvas canvas, Offset tip, Offset dir, bool open) {
    final paint = Paint()
      ..color = VerkstadTokens.pencil.withValues(alpha: open ? 0.85 : 0.18)
      ..style = PaintingStyle.fill;
    final n = Offset(-dir.dy, dir.dx);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - dir.dx * 7 + n.dx * 4, tip.dy - dir.dy * 7 + n.dy * 4)
      ..lineTo(tip.dx - dir.dx * 7 - n.dx * 4, tip.dy - dir.dy * 7 - n.dy * 4)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WoodBlockPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.textureSeed != textureSeed ||
        oldDelegate.lift != lift ||
        oldDelegate.horizontal != horizontal ||
        oldDelegate.negativeHead != negativeHead ||
        oldDelegate.positiveHead != positiveHead ||
        oldDelegate.notchCount != notchCount ||
        oldDelegate.showMarkings != showMarkings;
  }
}

int woodTextureSeedForBlock(String blockId) {
  return blockId.hashCode.abs() % VerkstadTokens.woodTextureVariants + 1;
}
