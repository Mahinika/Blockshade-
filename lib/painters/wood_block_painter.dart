import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/block_symbols.dart';
import '../theme/verkstad_tokens.dart';

class WoodBlockPainter extends CustomPainter {
  WoodBlockPainter({
    required this.fillColor,
    required this.colorName,
    required this.textureSeed,
    this.lift = 0,
    this.showDirection = true,
    this.directionAngle = 0,
  });

  final Color fillColor;
  final String colorName;
  final int textureSeed;
  final double lift;
  final bool showDirection;
  final double directionAngle;

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

    final symbol = BlockSymbols.forColorName(colorName);
    if (symbol != null) {
      BlockSymbols.paintSymbol(canvas, rect.deflate(8), symbol);
    }

    if (showDirection) {
      _paintDirectionArrow(canvas, rect);
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

  void _paintDirectionArrow(Canvas canvas, Rect rect) {
    final center = rect.center;
    final arrowSize = rect.shortestSide * 0.22;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(directionAngle);
    final arrow = Path();
    arrow.moveTo(arrowSize * 0.6, 0);
    arrow.lineTo(-arrowSize * 0.35, -arrowSize * 0.35);
    arrow.lineTo(-arrowSize * 0.15, 0);
    arrow.lineTo(-arrowSize * 0.35, arrowSize * 0.35);
    arrow.close();
    canvas.drawPath(
      arrow,
      Paint()
        ..color = VerkstadTokens.pencil.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WoodBlockPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.textureSeed != textureSeed ||
        oldDelegate.lift != lift ||
        oldDelegate.directionAngle != directionAngle;
  }
}

int woodTextureSeedForBlock(String blockId) {
  return blockId.hashCode.abs() % VerkstadTokens.woodTextureVariants + 1;
}
