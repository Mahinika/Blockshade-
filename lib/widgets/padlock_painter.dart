import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../painters/block_pattern_painter.dart';
import '../theme/block_looks.dart';
import '../utils/colors.dart';

/// Arrow color printed at full coverage on the key-colored lock body.
Color lockPatternColor(String colorName) => BlockLooks.arrowColor(colorName);

/// Tape-tag padlock anchored on a block. No countdown — the body is the key.
class PadlockPainter extends CustomPainter {
  PadlockPainter({
    required this.cellSize,
    required this.keyColorName,
    this.plateStrokeFactor = 1,
    this.openAmount = 0,
  });

  final double cellSize;
  final String keyColorName;

  /// 1 while locked, 2 when the key can leave ("snart öppen").
  final double plateStrokeFactor;

  /// 0–1 while the shackle lifts and turns.
  final double openAmount;

  static const Color _ink = Color(0xFF3B2A1E);
  static const Color _tape = Color(0xFFF1D9A0);

  @override
  void paint(Canvas canvas, Size size) {
    final c = cellSize;
    final center = Offset(size.width / 2, size.height / 2);

    final plateRadius = 0.28 * c;
    canvas.drawCircle(center, plateRadius, Paint()..color = _tape);
    canvas.drawCircle(
      center,
      plateRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03 * c * plateStrokeFactor
        ..color = _ink,
    );

    final bodyCenter = center.translate(0, 0.05 * c);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: 0.36 * c, height: 0.28 * c),
      Radius.circular(0.04 * c),
    );
    canvas.drawRRect(body, Paint()..color = BlockColors.getBlockColor(keyColorName));
    _paintKeyPattern(canvas, body, c);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03 * c
        ..color = _ink,
    );

    _paintShackle(canvas, center, c);
  }

  void _paintKeyPattern(Canvas canvas, RRect body, double c) {
    final pattern = BlockLooks.patternFor(keyColorName);
    final color = lockPatternColor(keyColorName);
    canvas.save();
    canvas.clipRRect(body);
    BlockPatternPainter.paintGroovePattern(
      canvas,
      body.outerRect,
      pattern,
      c * 0.5,
      gateStyle: true,
      inkColor: color,
    );
    canvas.restore();
  }

  void _paintShackle(Canvas canvas, Offset plateCenter, double c) {
    final bodyTop = plateCenter.dy + 0.05 * c - 0.14 * c;
    final leftLeg = Offset(plateCenter.dx - 0.11 * c, bodyTop);

    canvas.save();
    canvas.translate(leftLeg.dx, leftLeg.dy);
    canvas.rotate(-30 * math.pi / 180 * openAmount);
    canvas.translate(-leftLeg.dx, -leftLeg.dy);
    canvas.translate(0, -0.08 * c * openAmount);

    final arcRect = Rect.fromCenter(
      center: Offset(plateCenter.dx, bodyTop),
      width: 0.22 * c,
      height: 0.30 * c,
    );
    final shackle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05 * c
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    canvas.drawArc(arcRect, math.pi, math.pi, false, shackle);

    final leg = 0.06 * c;
    canvas.drawLine(leftLeg, leftLeg.translate(0, leg), shackle);
    canvas.drawLine(
      Offset(plateCenter.dx + 0.11 * c, bodyTop),
      Offset(plateCenter.dx + 0.11 * c, bodyTop + leg),
      shackle,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PadlockPainter oldDelegate) {
    return oldDelegate.cellSize != cellSize ||
        oldDelegate.keyColorName != keyColorName ||
        oldDelegate.plateStrokeFactor != plateStrokeFactor ||
        oldDelegate.openAmount != openAmount;
  }
}
