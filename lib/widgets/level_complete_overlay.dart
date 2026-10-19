import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/verkstad_tokens.dart';
import '../utils/localization.dart';
import 'brass_star.dart';
import 'masking_tape.dart';

class LevelCompleteOverlay extends StatefulWidget {
  const LevelCompleteOverlay({
    super.key,
    required this.stars,
    required this.movesUsed,
    required this.parMoves,
    required this.onNext,
    this.nextLabel,
    this.showNext = true,
  });

  final int stars;
  final int movesUsed;
  final int parMoves;
  final VoidCallback onNext;
  final String? nextLabel;
  final bool showNext;

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with TickerProviderStateMixin {
  late final List<AnimationController> _starControllers;
  late final List<Animation<double>> _starScales;

  @override
  void initState() {
    super.initState();
    _starControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      ),
    );
    _starScales = _starControllers
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.elasticOut),
          ),
        )
        .toList();

    for (var i = 0; i < widget.stars; i++) {
      Future<void>.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted) {
          _starControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _starControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parDelta = widget.movesUsed - widget.parMoves;
    final parText = parDelta <= 0
        ? 'Par: ${widget.parMoves} (${widget.movesUsed} drag)'
        : 'Par: ${widget.parMoves} (+$parDelta)';

    return Container(
      color: VerkstadTokens.pencil.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MaskingTape(
                rotation: -0.04,
                child: Text(
                  '✓ ${l10n.levelComplete}',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final filled = i < widget.stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ScaleTransition(
                      scale: filled
                          ? _starScales[i]
                          : const AlwaysStoppedAnimation(1.0),
                      child: BrassStar(filled: filled, size: 40),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              MaskingTape(
                showPin: false,
                rotation: 0.02,
                child: Text(
                  parText,
                  style: AppTypography.moveCounter(18),
                ),
              ),
              if (widget.showNext) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: 240,
                  child: MaskingTapeButton(
                    label: widget.nextLabel ?? l10n.nextLevel,
                    onPressed: widget.onNext,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
