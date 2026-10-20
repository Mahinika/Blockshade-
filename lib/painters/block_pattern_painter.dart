import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/block_looks.dart';

/// Shared carved-wood patterns for blocks and gates.
abstract final class BlockPatternPainter {
  static void paintGroovePattern(
    Canvas canvas,
    Rect bounds,
    BlockPatternKind kind,
    double cellSize, {
    bool gateStyle = false,
    Color? inkColor,
  }) {
    if (gateStyle) {
      final color = inkColor ?? BlockLooks.cream;
      canvas.save();
      canvas.clipRect(bounds);
      _drawKind(canvas, bounds, kind, cellSize, color, 1, 1);
      canvas.restore();
      return;
    }

    final lipOffset = BlockLooks.lipOffsetFactor * cellSize;
    final lipRect = bounds.shift(Offset(lipOffset, lipOffset));
    canvas.save();
    canvas.clipRect(bounds);
    _drawKind(
      canvas,
      lipRect,
      kind,
      cellSize,
      Colors.white.withValues(alpha: BlockLooks.lipAlpha),
      BlockLooks.lipAlpha,
      1,
    );
    _drawKind(
      canvas,
      bounds,
      kind,
      cellSize,
      BlockLooks.groove.withValues(alpha: BlockLooks.grooveAlpha),
      BlockLooks.grooveAlpha,
      1,
    );
    canvas.restore();
  }

  static void _drawKind(
    Canvas canvas,
    Rect box,
    BlockPatternKind kind,
    double c,
    Color color,
    double alpha,
    double widthScale,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p = PatternGeom.period * c;
    double w(String key) {
      switch (key) {
        case 'grid':
          return math.max(1, PatternGeom.gridLine * c * widthScale);
        case 'ring':
          return math.max(1, PatternGeom.ringLine * c * widthScale);
        case 'chev':
          return math.max(1, PatternGeom.chevronLine * c * widthScale);
        case 'wave':
          return math.max(1, PatternGeom.waveLine * c * widthScale);
        default:
          return math.max(1, PatternGeom.line * c * widthScale);
      }
    }

    switch (kind) {
      case BlockPatternKind.stripesH:
        paint.strokeWidth = w('line');
        var y = box.top + p / 2;
        while (y < box.bottom) {
          canvas.drawLine(Offset(box.left, y), Offset(box.right, y), paint);
          y += p;
        }
      case BlockPatternKind.stripesV:
        paint.strokeWidth = w('line');
        var x = box.left + p / 2;
        while (x < box.right) {
          canvas.drawLine(Offset(x, box.top), Offset(x, box.bottom), paint);
          x += p;
        }
      case BlockPatternKind.diagonal:
        paint.strokeWidth = w('line');
        final step = p * math.sqrt(2);
        var k = box.left - (box.bottom - box.top);
        while (k < box.right) {
          canvas.drawLine(Offset(k, box.bottom), Offset(k + (box.bottom - box.top), box.top), paint);
          k += step;
        }
      case BlockPatternKind.grid:
        paint.strokeWidth = w('grid');
        var y = box.top + p / 2;
        while (y < box.bottom) {
          canvas.drawLine(Offset(box.left, y), Offset(box.right, y), paint);
          y += p;
        }
        var x = box.left + p / 2;
        while (x < box.right) {
          canvas.drawLine(Offset(x, box.top), Offset(x, box.bottom), paint);
          x += p;
        }
      case BlockPatternKind.dots:
        final r = PatternGeom.dotD * c / 2;
        final fill = Paint()..color = color.withValues(alpha: alpha);
        var row = 0;
        var y = box.top + p / 2;
        while (y < box.bottom + r) {
          var x = box.left + p / 2 + (row.isOdd ? p / 2 : 0);
          while (x < box.right + r) {
            canvas.drawCircle(Offset(x, y), r, fill);
            x += p;
          }
          y += p;
          row++;
        }
      case BlockPatternKind.rings:
        paint.strokeWidth = w('ring');
        final r = PatternGeom.ringD * c / 2;
        final pp = p * 1.2;
        var row = 0;
        var y = box.top + p / 2;
        while (y < box.bottom + r) {
          var x = box.left + pp / 2 + (row.isOdd ? pp / 2 : 0);
          while (x < box.right + r) {
            canvas.drawCircle(Offset(x, y), r, paint);
            x += pp;
          }
          y += pp;
          row++;
        }
      case BlockPatternKind.chevron:
        paint.strokeWidth = w('chev');
        var y = box.top + p;
        while (y < box.bottom + p) {
          final path = Path();
          var x = box.left;
          var started = false;
          while (x <= box.right + p) {
            final a = Offset(x, y);
            final b = Offset(x + p / 2, y - p / 2);
            if (!started) {
              path.moveTo(a.dx, a.dy);
              started = true;
            } else {
              path.lineTo(a.dx, a.dy);
            }
            path.lineTo(b.dx, b.dy);
            x += p;
          }
          canvas.drawPath(path, paint);
          y += p;
        }
      case BlockPatternKind.waves:
        paint.strokeWidth = w('wave');
        final lam = PatternGeom.waveLength * c;
        final amp = PatternGeom.waveAmp * c;
        var y = box.top + p / 2;
        while (y < box.bottom + amp) {
          final path = Path();
          var x = box.left;
          path.moveTo(x, y + amp * math.sin(2 * math.pi * x / lam));
          while (x <= box.right) {
            x += 2;
            path.lineTo(x, y + amp * math.sin(2 * math.pi * x / lam));
          }
          canvas.drawPath(path, paint);
          y += p;
        }
    }
  }
}
