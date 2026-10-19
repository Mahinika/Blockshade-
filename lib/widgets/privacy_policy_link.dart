import 'package:flutter/material.dart';

import '../utils/external_link.dart';
import '../utils/localization.dart';

/// Text button that opens the configured privacy-policy URL.
class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({
    super.key,
    required this.url,
    this.openUrl,
    this.alignment = Alignment.centerLeft,
  });

  final String url;
  final Future<bool> Function(Uri uri)? openUrl;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: alignment,
      child: TextButton(
        onPressed: () => _open(context, l10n),
        child: Text(l10n.privacyPolicy),
      ),
    );
  }

  Future<void> _open(BuildContext context, AppLocalizations l10n) async {
    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null && uri.hasScheme) {
      try {
        opened = await (openUrl ?? openExternalUrl)(uri);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.privacyLinkFailed)),
      );
    }
  }
}
