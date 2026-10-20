import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/theme/block_looks.dart';
import 'package:blockshade/theme/verkstad_tokens.dart';
import 'package:blockshade/utils/colors.dart';
import 'package:blockshade/widgets/padlock_painter.dart';

double _relativeLuminance(Color c) {
  double channel(double v) {
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(c.r);
  final g = channel(c.g);
  final b = channel(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

Color mix(Color fg, Color bg, double alpha) => Color.lerp(bg, fg, alpha)!;

void main() {
  test('UI-text mot bänkskiva ≥ 4.5:1', () {
    for (var w = 1; w <= 3; w++) {
      expect(
        contrastRatio(VerkstadTokens.ink, VerkstadTokens.boardForWorld(w)),
        greaterThanOrEqualTo(4.5),
        reason: 'world $w',
      );
    }
  });

  test('Pilfärg mot blockfärg ≥ 4.5:1', () {
    for (final entry in BlockLooks.byColor.entries) {
      final ratio = contrastRatio(entry.value.arrow, entry.value.fill);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: entry.key);
    }
  });

  test('Blockfärger mot bakgrund (gul med kant undantag)', () {
    final bench = VerkstadTokens.benchBirch;
    final colors = ['red', 'blue', 'green', 'purple', 'yellow'];
    for (final name in colors) {
      final block = BlockColors.getBlockColor(name);
      final ratio = contrastRatio(block, bench);
      if (name == 'yellow') {
        expect(ratio, greaterThan(2.0));
      } else {
        expect(ratio, greaterThanOrEqualTo(3.0));
      }
    }
  });

  test('Låsmönster mot nyckelfärg ≥ 3:1', () {
    final colors = ['red', 'blue', 'yellow', 'green', 'purple', 'orange', 'cyan', 'pink'];
    for (final name in colors) {
      final ratio = contrastRatio(lockPatternColor(name), BlockColors.getBlockColor(name));
      expect(ratio, greaterThanOrEqualTo(3.0), reason: name);
    }
    expect(lockPatternColor('yellow'), const Color(0xFF1A120C));
    expect(lockPatternColor('orange'), const Color(0xFF000000));
    expect(lockPatternColor('blue'), const Color(0xFFFFF8EC));
  });

  test('Skraffering och vägg mot bänk ≥ 3:1', () {
    for (var w = 1; w <= 3; w++) {
      final board = VerkstadTokens.boardForWorld(w);
      final hatchAlpha = w == 3 ? 0.62 : 0.55;
      final hatch = mix(VerkstadTokens.pencil, board, hatchAlpha);
      expect(contrastRatio(hatch, board), greaterThanOrEqualTo(3.0), reason: 'hatch w$w');
      final wall = AppColors.wall.withValues(alpha: 0.75);
      expect(contrastRatio(wall, board), greaterThanOrEqualTo(3.0), reason: 'wall w$w');
      expect(contrastRatio(VerkstadTokens.pencil, board), greaterThanOrEqualTo(3.0), reason: 'pencil w$w');
    }
  });

  test('Undo-text och coinInk mot björk ≥ 4.5:1', () {
    const undoText = Color(0xFFFFF8EC);
    expect(contrastRatio(undoText, AppColors.primary), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(VerkstadTokens.coinInk, VerkstadTokens.benchBirch), greaterThanOrEqualTo(4.5));
  });

  test('Valvet: björk mot valnöt och mässing mot valnöt', () {
    expect(
      contrastRatio(VerkstadTokens.benchBirch, VerkstadTokens.world2Bench),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(VerkstadTokens.valvetRim, VerkstadTokens.world2Bench),
      greaterThanOrEqualTo(3.0),
    );
  });

  test('Portmönster mot portfärg ≥ 3', () {
    for (final entry in BlockLooks.byColor.entries) {
      final ratio = contrastRatio(entry.value.arrow, entry.value.fill);
      expect(ratio, greaterThanOrEqualTo(3.0), reason: entry.key);
    }
  });

  test('Portkant mot bänk ≥ 3 per värld', () {
    for (var w = 1; w <= 3; w++) {
      final edge = w == 2 ? VerkstadTokens.benchBirch : VerkstadTokens.pencil;
      final bench = VerkstadTokens.benchForWorld(w);
      expect(contrastRatio(edge, bench), greaterThanOrEqualTo(3.0), reason: 'world $w');
    }
  });
}
