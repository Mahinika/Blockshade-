import 'package:flutter/material.dart';

/// Design tokens for riktning 2 – Verkstad (handgjort trä och papper).
abstract final class VerkstadTokens {
  // --- Palett ---
  static const Color benchBirch = Color(0xFFE9DCC4);
  static const Color gridLine = Color(0xFFCDB998);
  static const Color ink = Color(0xFF2B1D14);
  static const Color pencil = Color(0xFF3B2A1E);
  static const Color woodEdge = Color(0xFF3B2A1E);

  static const Color blockRed = Color(0xFFA63D2A);
  static const Color blockBlue = Color(0xFF2F5D7C);
  static const Color blockYellow = Color(0xFFB5810F);
  static const Color blockGreen = Color(0xFF4F6B2E);
  static const Color blockPurple = Color(0xFF7A4A6E);

  static const Color maskingTape = Color(0xFFF1D9A0);
  static const Color brassPin = Color(0xFFC89B3C);

  // Världar – bänkskivor
  static const Color world1Bench = benchBirch;
  static const Color world2Bench = Color(0xFF5C4033); // valnöt
  static const Color world3Bench = Color(0xFFD4B896); // målad furu

  // --- Animationstider (ms) ---
  static const int pressMs = 90;
  static const int slideOutMs = 240;
  static const int bounceMs = 140;
  static const int echoDrawMs = 200;
  static const int echoEraseMs = 260;
  static const int lockOpenMs = 320;
  static const int winMs = 450;
  static const int failTiltMs = 350;
  static const int reducedMotionCapMs = 100;

  // --- Easing ---
  static const Curve pressEase = Curves.easeOutCubic;
  static const Curve slideEase = Curves.easeInCubic;
  static const Curve bounceEase = Curves.easeOutBack;
  static const Curve winEase = Curves.easeOutQuint;

  static const double blockCornerRadius = 6;
  static const double woodEdgeWidth = 2;
  static const int woodTextureVariants = 8;

  static Color benchForWorld(int world) {
    switch (world) {
      case 2:
        return world2Bench;
      case 3:
        return world3Bench;
      default:
        return world1Bench;
    }
  }
}
