import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/verkstad_tokens.dart';
import '../utils/localization.dart';
import 'masking_tape.dart';

/// Hand-pointer coach for the first three campaign levels.
class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({
    super.key,
    required this.stepIndex,
    required this.onSkip,
    required this.onFinishedStep,
    this.anchorFraction = const Offset(0.5, 0.45),
  });

  /// 0 = slide, 1 = exit, 2 = echo shadow.
  final int stepIndex;
  final VoidCallback onSkip;
  final VoidCallback onFinishedStep;
  final Offset anchorFraction;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _handController;

  @override
  void initState() {
    super.initState();
    _handController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _handController.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l10n) {
    switch (widget.stepIndex) {
      case 0:
        return l10n.tutorialTapBlock;
      case 1:
        return l10n.tutorialExit;
      case 2:
        return l10n.tutorialEcho;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final anchor = Offset(
      size.width * widget.anchorFraction.dx,
      size.height * widget.anchorFraction.dy,
    );

    return Material(
      color: VerkstadTokens.pencil.withValues(alpha: 0.42),
      child: Stack(
        children: [
          Positioned(
            left: anchor.dx - 28,
            top: anchor.dy - 28 + (_handController.value * 10),
            child: AnimatedBuilder(
              animation: _handController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -0.25 + math.sin(_handController.value * math.pi) * 0.08,
                  child: child,
                );
              },
              child: const Icon(
                Icons.touch_app,
                size: 56,
                color: VerkstadTokens.maskingTape,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MaskingTape(
                    rotation: -0.03,
                    child: Text(
                      _message(l10n),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MaskingTapeButton(
                        label: l10n.skip,
                        onPressed: widget.onSkip,
                      ),
                      const SizedBox(width: 12),
                      MaskingTapeButton(
                        label: l10n.gotIt,
                        onPressed: widget.onFinishedStep,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
