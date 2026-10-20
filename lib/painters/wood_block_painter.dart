import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/block_looks.dart';
import '../theme/verkstad_tokens.dart';
import 'block_pattern_painter.dart';

class WoodBlockPainter extends CustomPainter {
  WoodBlockPainter({
    required this.fillColor,
    required this.colorName,
    required this.textureSeed,
    required this.cellSize,
    this.lift = 0,
    this.horizontal = true,
    this.negativeHead = true,
    this.positiveHead = true,
    this.showMarkings = true,
    this.lightEdge = false,
  });

  final Color fillColor;
  final String colorName;
  final int textureSeed;
  final double cellSize;
  final double lift;
  final bool horizontal;
  final bool negativeHead;
  final bool positiveHead;
  final bool showMarkings;
  final bool lightEdge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c = cellSize > 0 ? cellSize : rect.shortestSide;
    final r = VerkstadTokens.blockCornerRadius;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    final shadowPaint = Paint()
      ..color = VerkstadTokens.pencil.withValues(alpha: 0.22 + lift * 0.08)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + lift * 2);
    canvas.drawRRect(
      rrect.shift(Offset(1.5, 2 + lift * 2)),
      shadowPaint,
    );

    canvas.drawRRect(rrect, Paint()..color = fillColor);

    Path? markingsClip;
    if (showMarkings) {
      final zone = _planedZonePath(rect, c);
      final blockClip = Path()..addRRect(rrect);
      markingsClip = Path.combine(PathOperation.difference, blockClip, zone);
    }

    void withMarkingsClip(VoidCallback draw) {
      if (markingsClip == null) {
        draw();
        return;
      }
      canvas.save();
      canvas.clipPath(markingsClip);
      draw();
      canvas.restore();
    }

    withMarkingsClip(() {
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
      final pattern = BlockLooks.patternFor(colorName);
      BlockPatternPainter.paintGroovePattern(
        canvas,
        rect,
        pattern,
        c,
      );
    });

    if (lightEdge) {
      final outer = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = VerkstadTokens.benchBirch;
      canvas.drawRRect(rrect, outer);
      final inner = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = VerkstadTokens.woodEdge;
      canvas.drawRRect(rrect.deflate(2), inner);
    } else {
      final needsEdge = colorName.toLowerCase() == 'yellow';
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = VerkstadTokens.woodEdgeWidth
        ..color = VerkstadTokens.woodEdge;
      canvas.drawRRect(rrect, edge);
      if (needsEdge) {
        canvas.drawRRect(rrect.deflate(0.5), edge..strokeWidth = 1);
      }
    }

    if (showMarkings) {
      _paintAxisArrows(canvas, rect, c);
    }
  }

  Path _planedZonePath(Rect rect, double c) {
    final center = rect.center;
    final half = ArrowGeom.shaftHalf * c;
    final headW = ArrowGeom.headWidth * c;
    final shaftW = ArrowGeom.shaftWidth * c;
    final headL = ArrowGeom.headLength * c;
    final pad = (ArrowGeom.planedDilate + ArrowGeom.planedFeather) * c;

    final path = Path();
    if (horizontal) {
      final width = half * 2 + headL * 2 + pad * 2;
      final height = math.max(headW, shaftW) + pad * 2;
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: width, height: height),
          Radius.circular(pad),
        ),
      );
    } else {
      final height = half * 2 + headL * 2 + pad * 2;
      final width = math.max(headW, shaftW) + pad * 2;
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: width, height: height),
          Radius.circular(pad),
        ),
      );
    }
    return path;
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

  void _paintAxisArrows(Canvas canvas, Rect rect, double c) {
    final look = BlockLooks.forColor(colorName);
    final arrowColor = look?.arrow ?? BlockLooks.cream;
    final outline = look?.arrowOutline ?? true;

    final center = rect.center;
    final half = ArrowGeom.shaftHalf * c;
    final shaftW = ArrowGeom.shaftWidth * c;

    final shaft = Paint()
      ..color = arrowColor
      ..strokeWidth = shaftW
      ..strokeCap = StrokeCap.round;

    if (horizontal) {
      canvas.drawLine(
        Offset(center.dx - half, center.dy),
        Offset(center.dx + half, center.dy),
        shaft,
      );
      _head(canvas, Offset(center.dx - half, center.dy), const Offset(-1, 0), negativeHead, arrowColor, c, outline);
      _head(canvas, Offset(center.dx + half, center.dy), const Offset(1, 0), positiveHead, arrowColor, c, outline);
    } else {
      canvas.drawLine(
        Offset(center.dx, center.dy - half),
        Offset(center.dx, center.dy + half),
        shaft,
      );
      _head(canvas, Offset(center.dx, center.dy - half), const Offset(0, -1), negativeHead, arrowColor, c, outline);
      _head(canvas, Offset(center.dx, center.dy + half), const Offset(0, 1), positiveHead, arrowColor, c, outline);
    }
  }

  void _head(
    Canvas canvas,
    Offset tip,
    Offset dir,
    bool open,
    Color color,
    double c,
    bool creamOutline,
  ) {
    final n = Offset(-dir.dy, dir.dx);
    final headL = ArrowGeom.headLength * c;
    final headW = ArrowGeom.headWidth * c;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - dir.dx * headL + n.dx * headW / 2, tip.dy - dir.dy * headL + n.dy * headW / 2)
      ..lineTo(tip.dx - dir.dx * headL - n.dx * headW / 2, tip.dy - dir.dy * headL - n.dy * headW / 2)
      ..close();

    if (open) {
      canvas.drawPath(path, Paint()..color = color);
      if (creamOutline) {
        canvas.drawPath(
          path,
          Paint()
            ..color = VerkstadTokens.pencil.withValues(alpha: ArrowGeom.outlineAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = ArrowGeom.outlineWidth * c
            ..strokeJoin = StrokeJoin.round,
        );
      }
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = ArrowGeom.closedStroke * c
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WoodBlockPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.textureSeed != textureSeed ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.lift != lift ||
        oldDelegate.horizontal != horizontal ||
        oldDelegate.negativeHead != negativeHead ||
        oldDelegate.positiveHead != positiveHead ||
        oldDelegate.showMarkings != showMarkings ||
        oldDelegate.lightEdge != lightEdge;
  }
}

int woodTextureSeedForBlock(String blockId) {
  return blockId.hashCode.abs() % VerkstadTokens.woodTextureVariants + 1;
}
