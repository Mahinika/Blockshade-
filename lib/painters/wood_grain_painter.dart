import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/verkstad_tokens.dart';

/// Procedural björk-/bänkskiva med subtil ådring (ingen extern textur).
class WoodGrainPainter extends CustomPainter {
  WoodGrainPainter({
    required this.baseColor,
    this.seed = 42,
    this.showGrid = false,
    this.gridColumns,
    this.gridRows,
    this.cellSize,
  });

  final Color baseColor;
  final int seed;
  final bool showGrid;
  final int? gridColumns;
  final int? gridRows;
  final double? cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = baseColor);

    final rng = math.Random(seed);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (var i = 0; i < 28; i++) {
      final y = rng.nextDouble() * size.height;
      final amp = 2 + rng.nextDouble() * 4;
      final path = Path()..moveTo(0, y);
      var x = 0.0;
      while (x < size.width) {
        x += 8 + rng.nextDouble() * 14;
        path.lineTo(x, y + math.sin(x * 0.02 + i) * amp);
      }
      grain.color = VerkstadTokens.pencil.withValues(alpha: 0.04 + rng.nextDouble() * 0.04);
      canvas.drawPath(path, grain);
    }

    if (showGrid && gridColumns != null && gridRows != null && cellSize != null) {
      final line = Paint()
        ..color = VerkstadTokens.gridLine
        ..strokeWidth = 1.1;
      for (var c = 1; c < gridColumns!; c++) {
        final x = c * cellSize!;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
      }
      for (var r = 1; r < gridRows!; r++) {
        final y = r * cellSize!;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WoodGrainPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.seed != seed ||
        oldDelegate.showGrid != showGrid;
  }
}
