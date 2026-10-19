import 'package:flutter/material.dart';
import 'verkstad_tokens.dart';

abstract final class AppTypography {
  static const String patrickHandFamily = 'PatrickHand';
  static const String recursiveFamily = 'Recursive';

  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: patrickHandFamily,
        color: VerkstadTokens.ink,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: patrickHandFamily,
        color: VerkstadTokens.ink,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: patrickHandFamily,
        color: VerkstadTokens.ink,
        fontSize: 28,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: patrickHandFamily,
        color: VerkstadTokens.ink,
        fontSize: 22,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: recursiveFamily,
        color: VerkstadTokens.ink,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: recursiveFamily,
        color: VerkstadTokens.ink,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: recursiveFamily,
        color: VerkstadTokens.ink.withValues(alpha: 0.85),
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: recursiveFamily,
        fontWeight: FontWeight.w600,
        color: VerkstadTokens.ink,
      ),
    );
  }

  /// Monospace-stil för dragräknare (Recursive Casual Mono).
  static TextStyle moveCounter(double size) {
    return TextStyle(
      fontFamily: recursiveFamily,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w700,
      fontSize: size,
      color: VerkstadTokens.ink,
    );
  }
}
