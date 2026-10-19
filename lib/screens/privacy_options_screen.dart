import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import '../services/consent_service.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
import '../widgets/masking_tape.dart';
import '../widgets/privacy_policy_link.dart';
import '../widgets/workshop_background.dart';

/// Settings screen for UMP privacy options and the privacy-policy link.
class PrivacyOptionsScreen extends StatelessWidget {
  const PrivacyOptionsScreen({super.key, this.openUrl});

  /// Test hook. Production opens the URL with [openExternalUrl].
  final Future<bool> Function(Uri uri)? openUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final policyUrl = context.read<AdService>().privacyPolicyUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: WorkshopBackground(
        world: 1,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MaskingTapeButton(
                      label: '←',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MaskingTape(
                        child: Text(
                          l10n.privacyChoices,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.privacyChoicesBody,
                  style: const TextStyle(color: AppColors.text, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _manageConsent(context, l10n),
                    child: Text(l10n.managePrivacyChoices),
                  ),
                ),
                PrivacyPolicyLink(url: policyUrl, openUrl: openUrl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _manageConsent(BuildContext context, AppLocalizations l10n) async {
    final consent = context.read<ConsentCoordinator>();
    final result = await consent.showPrivacyOptions();
    if (!context.mounted) return;
    final ads = context.read<AdService>();
    ads.setAdsAllowed(consent.canRequestAds);
    if (consent.canRequestAds) {
      await ads.init();
    }
    if (!context.mounted) return;
    final message = switch (result) {
      PrivacyOptionsResult.notRequired => l10n.privacyNotRequired,
      PrivacyOptionsResult.failed => l10n.privacyUnavailable,
      PrivacyOptionsResult.updated => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
