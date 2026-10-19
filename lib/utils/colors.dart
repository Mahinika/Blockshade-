import 'package:flutter/material.dart';

class BlockColors {
  static const Map<String, Color> blockColors = {
    'red': Color(0xFFE53935),
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF43A047),
    'yellow': Color(0xFFFDD835),
    'purple': Color(0xFF8E24AA),
    'orange': Color(0xFFFF9800),
    'cyan': Color(0xFF00BCD4),
    'pink': Color(0xFFE91E63),
  };

  static const Map<String, Color> blockColorsDark = {
    'red': Color(0xFFC62828),
    'blue': Color(0xFF1565C0),
    'green': Color(0xFF2E7D32),
    'yellow': Color(0xFFF9A825),
    'purple': Color(0xFF6A1B9A),
    'orange': Color(0xFFEF6C00),
    'cyan': Color(0xFF0097A7),
    'pink': Color(0xFFC2185B),
  };

  static Color getBlockColor(String colorName) {
    return blockColors[colorName.toLowerCase()] ?? Colors.grey;
  }

  static Color getBlockColorDark(String colorName) {
    return blockColorsDark[colorName.toLowerCase()] ?? Colors.grey.shade700;
  }

  static Color getEchoShadowColor(String colorName) {
    final baseColor = getBlockColor(colorName);
    return baseColor.withOpacity(0.35);
  }
}

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color accent = Color(0xFFFF9800);
  
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);
  static const Color surfaceLight = Color(0xFF0F3460);
  
  static const Color text = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  
  static const Color starFilled = Color(0xFFFFD700);
  static const Color starEmpty = Color(0xFF4A4A4A);
  
  static const Color coinColor = Color(0xFFFFD700);
  static const Color lifeColor = Color(0xFFE91E63);

  static const Color gridCell = Color(0xFF2A2A4A);
  static const Color gridBorder = Color(0xFF3A3A6A);
  static const Color wall = Color(0xFF4A4A6A);
}

class WorldThemes {
  static const Map<int, WorldTheme> themes = {
    1: WorldTheme(
      name: 'Lagret',
      primaryColor: Color(0xFF8D6E63),
      backgroundColor: Color(0xFF3E2723),
      accentColor: Color(0xFFFFCC80),
    ),
    2: WorldTheme(
      name: 'Valvet',
      primaryColor: Color(0xFF546E7A),
      backgroundColor: Color(0xFF263238),
      accentColor: Color(0xFFB0BEC5),
    ),
    3: WorldTheme(
      name: 'Hamnen',
      primaryColor: Color(0xFF0288D1),
      backgroundColor: Color(0xFF01579B),
      accentColor: Color(0xFF81D4FA),
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

  const WorldTheme({
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.accentColor,
  });
}
