import 'package:flutter/material.dart';

import '../theme/block_looks.dart';
import '../theme/verkstad_tokens.dart';
import 'block_pattern_painter.dart';

class GatePainter extends CustomPainter {
  GatePainter({
    required this.colorName,
    required this.cellSize,
    required this.world,
    this.knock = 0,
    this.edgeScale = 1,
  });

  final String colorName;
  final double cellSize;
  final int world;
  final double knock;
  final double edgeScale;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = GateGeom.inset;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2)
        .shift(Offset(knock, 0));
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(GateGeom.radius));

    canvas.drawRRect(rrect, Paint()..color = BlockLooks.blockFill(colorName));

    BlockPatternPainter.paintGroovePattern(
      canvas,
      rect,
      BlockLooks.patternFor(colorName),
      cellSize,
      gateStyle: true,
      inkColor: BlockLooks.arrowColor(colorName),
    );

    final edgeColor = world == 2 ? VerkstadTokens.benchBirch : VerkstadTokens.pencil;
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GateGeom.edge * edgeScale
        ..color = edgeColor,
    );
  }

  @override
  bool shouldRepaint(covariant GatePainter oldDelegate) {
    return oldDelegate.colorName != colorName ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.world != world ||
        oldDelegate.knock != knock ||
        oldDelegate.edgeScale != edgeScale;
  }
}
