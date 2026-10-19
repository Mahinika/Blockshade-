import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  test('UI-text mot bänkskiva ≥ 4.5:1', () {
    expect(contrastRatio(VerkstadTokens.ink, VerkstadTokens.benchBirch), greaterThanOrEqualTo(4.5));
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

  test('Skrafferingslinje mot björk ≥ 3:1', () {
    expect(
      contrastRatio(VerkstadTokens.pencil, VerkstadTokens.benchBirch),
      greaterThanOrEqualTo(3.0),
    );
  });
}
