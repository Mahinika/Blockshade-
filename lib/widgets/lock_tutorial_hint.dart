import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/verkstad_tokens.dart';
import '../utils/localization.dart';
import 'masking_tape.dart';

/// One-time workshop note shown the first time a level has a locked block.
class LockTutorialHint extends StatelessWidget {
  const LockTutorialHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: MaskingTape(
        key: const Key('lock-tutorial-hint'),
        rotation: -0.015,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.tutorialLock,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.25),
            ),
            const SizedBox(height: 10),
            MaskingTapeButton(
              label: l10n.gotIt,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

/// Short masking-tape toast, e.g. "Få ut den blå klossen först".
class LockMoveToast extends StatelessWidget {
  const LockMoveToast({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaskingTape(
      key: const Key('lock-toast'),
      rotation: -0.03,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.moveCounter(18).copyWith(color: VerkstadTokens.ink),
      ),
    );
  }
}
