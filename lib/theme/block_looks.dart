import 'package:flutter/material.dart';

import '../utils/colors.dart';
import 'verkstad_tokens.dart';

/// Carved pattern geometry on blocks (replaces notch count).
enum BlockPatternKind {
  stripesH,
  dots,
  diagonal,
  chevron,
  grid,
  waves,
  stripesV,
  rings,
}

class BlockLook {
  const BlockLook({
    required this.fill,
    required this.arrow,
    required this.pattern,
    required this.arrowOutline,
  });

  final Color fill;
  final Color arrow;
  final BlockPatternKind pattern;
  final bool arrowOutline;
}

abstract final class BlockLooks {
  static const cream = Color(0xFFFFF8EC);
  static const nearBlack = Color(0xFF1A120C);
  static const black = Color(0xFF000000);

  static const groove = VerkstadTokens.pencil;
  static const grooveAlpha = 0.45;
  static const lipAlpha = 0.16;
  static const lipOffsetFactor = 0.012;

  static BlockLook? forColor(String colorName) => byColor[colorName.toLowerCase()];

  static Color arrowColor(String colorName) =>
      forColor(colorName)?.arrow ?? cream;

  static BlockPatternKind patternFor(String colorName) =>
      forColor(colorName)?.pattern ?? BlockPatternKind.stripesH;

  static Color blockFill(String colorName) =>
      BlockColors.getBlockColor(colorName);

  static const Map<String, BlockLook> byColor = {
    'red': BlockLook(
      fill: VerkstadTokens.blockRed,
      arrow: cream,
      pattern: BlockPatternKind.stripesH,
      arrowOutline: true,
    ),
    'blue': BlockLook(
      fill: VerkstadTokens.blockBlue,
      arrow: cream,
      pattern: BlockPatternKind.dots,
      arrowOutline: true,
    ),
    'yellow': BlockLook(
      fill: VerkstadTokens.blockYellow,
      arrow: nearBlack,
      pattern: BlockPatternKind.diagonal,
      arrowOutline: false,
    ),
    'green': BlockLook(
      fill: VerkstadTokens.blockGreen,
      arrow: cream,
      pattern: BlockPatternKind.chevron,
      arrowOutline: true,
    ),
    'purple': BlockLook(
      fill: VerkstadTokens.blockPurple,
      arrow: cream,
      pattern: BlockPatternKind.grid,
      arrowOutline: true,
    ),
    'orange': BlockLook(
      fill: Color(0xFFB5651D),
      arrow: black,
      pattern: BlockPatternKind.waves,
      arrowOutline: false,
    ),
    'cyan': BlockLook(
      fill: Color(0xFF3A6B7C),
      arrow: cream,
      pattern: BlockPatternKind.stripesV,
      arrowOutline: true,
    ),
    'pink': BlockLook(
      fill: Color(0xFF9A4A5E),
      arrow: cream,
      pattern: BlockPatternKind.rings,
      arrowOutline: true,
    ),
  };
}

abstract final class ArrowGeom {
  static const shaftHalf = 0.28;
  static const shaftWidth = 0.06;
  static const headLength = 0.20;
  static const headWidth = 0.24;
  static const closedStroke = 0.03;
  static const outlineWidth = 0.02;
  static const outlineAlpha = 0.55;
  static const planedDilate = 0.06;
  static const planedFeather = 0.02;
}

abstract final class PatternGeom {
  static const period = 0.25;
  static const line = 0.06;
  static const gridLine = 0.045;
  static const dotD = 0.11;
  static const ringD = 0.17;
  static const ringLine = 0.04;
  static const chevronLine = 0.05;
  static const waveAmp = 0.05;
  static const waveLength = 0.33;
  static const waveLine = 0.05;
}

abstract final class GateGeom {
  static const thicknessFactor = 0.25;
  static const minThickness = 8.0;
  static const inset = 2.0;
  static const radius = 3.0;
  static const edge = 1.5;
  static const knock = 0.04;
}
