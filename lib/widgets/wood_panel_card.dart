import 'package:flutter/material.dart';

import '../painters/wood_grain_painter.dart';
import '../theme/verkstad_tokens.dart';

/// Träkort med subtil ådring – används i butik och liknande.
class WoodPanelCard extends StatelessWidget {
  const WoodPanelCard({
    super.key,
    required this.child,
    this.seed = 11,
    this.padding = const EdgeInsets.all(16),
    this.featured = false,
  });

  final Widget child;
  final int seed;
  final EdgeInsets padding;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WoodGrainPainter(
        baseColor: VerkstadTokens.benchBirch,
        seed: seed,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: featured
                ? VerkstadTokens.brassPin
                : VerkstadTokens.pencil.withValues(alpha: 0.35),
            width: featured ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: VerkstadTokens.pencil.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
