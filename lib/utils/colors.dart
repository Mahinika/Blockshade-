import 'package:flutter/material.dart';
import '../theme/verkstad_tokens.dart';

class BlockColors {
  static const Map<String, Color> blockColors = {
    'red': VerkstadTokens.blockRed,
    'blue': VerkstadTokens.blockBlue,
    'green': VerkstadTokens.blockGreen,
    'yellow': VerkstadTokens.blockYellow,
    'purple': VerkstadTokens.blockPurple,
    'orange': Color(0xFFB5651D),
    'cyan': Color(0xFF3A6B7C),
    'pink': Color(0xFF9A4A5E),
  };

  static const Map<String, Color> blockColorsDark = {
    'red': Color(0xFF7A2E1F),
    'blue': Color(0xFF1E3F54),
    'green': Color(0xFF3A4F22),
    'yellow': Color(0xFF8A620C),
    'purple': Color(0xFF5A3650),
    'orange': Color(0xFF8A4A12),
    'cyan': Color(0xFF2A4F5C),
    'pink': Color(0xFF6E3545),
  };

  static Color getBlockColor(String colorName) {
    return blockColors[colorName.toLowerCase()] ?? VerkstadTokens.pencil;
  }

  static Color getBlockColorDark(String colorName) {
    return blockColorsDark[colorName.toLowerCase()] ?? VerkstadTokens.pencil;
  }

  static Color getEchoShadowColor(String colorName) {
    return VerkstadTokens.pencil;
  }
}

class AppColors {
  static const Color primary = VerkstadTokens.blockBlue;
  static const Color primaryDark = Color(0xFF1E3F54);
  static const Color accent = VerkstadTokens.brassPin;

  static const Color background = VerkstadTokens.benchBirch;
  static const Color surface = VerkstadTokens.maskingTape;
  static const Color surfaceLight = VerkstadTokens.benchBirch;

  static const Color text = VerkstadTokens.ink;
  static const Color textSecondary = Color(0xFF5C4A3A);

  static const Color success = VerkstadTokens.blockGreen;
  static const Color warning = VerkstadTokens.blockYellow;
  static const Color error = VerkstadTokens.blockRed;

  static const Color starFilled = VerkstadTokens.brassPin;
  static const Color starEmpty = Color(0xFF8A7A68);

  static const Color coinColor = VerkstadTokens.brassPin;
  static const Color lifeColor = VerkstadTokens.blockRed;

  static const Color gridCell = Colors.transparent;
  static const Color gridBorder = VerkstadTokens.gridLine;
  static const Color wall = VerkstadTokens.pencil;
}

class WorldThemes {
  static const Map<int, WorldTheme> themes = {
    1: WorldTheme(
      name: 'Lagret',
      primaryColor: VerkstadTokens.blockRed,
      backgroundColor: VerkstadTokens.world1Bench,
      accentColor: VerkstadTokens.maskingTape,
      benchSeed: 3,
    ),
    2: WorldTheme(
      name: 'Valvet',
      primaryColor: VerkstadTokens.brassPin,
      backgroundColor: VerkstadTokens.world2Bench,
      accentColor: VerkstadTokens.maskingTape,
      benchSeed: 17,
    ),
    3: WorldTheme(
      name: 'Hamnen',
      primaryColor: VerkstadTokens.blockBlue,
      backgroundColor: VerkstadTokens.world3Bench,
      accentColor: VerkstadTokens.maskingTape,
      benchSeed: 29,
    ),
  };

  static WorldTheme getTheme(int world) {
    return themes[world] ?? themes[1]!;
  }
}

class WorldTheme {
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final Color accentColor;
  final int benchSeed;

  const WorldTheme({
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.accentColor,
    this.benchSeed = 1,
  });
}
