import 'dart:convert';

/// AdMob ids and the privacy-policy URL from one place.
///
/// Priority: `--dart-define` (ADMOB_APP_ID, ADMOB_INTERSTITIAL_UNIT_ID,
/// ADMOB_REWARDED_UNIT_ID, PRIVACY_POLICY_URL) → `config/admob.json` →
/// Google's official test ids and the published policy URL.
/// The Android manifest app id is read from the same JSON at build time.
/// Robert replaces the test ids in `config/admob.json` before a store build.
class AdMobConfig {
  const AdMobConfig({
    required this.appId,
    required this.interstitialUnitId,
    required this.rewardedUnitId,
    required this.privacyPolicyUrl,
  });

  static const testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testInterstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const testRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const defaultPrivacyPolicyUrl = 'https://mahinika.github.io/blockshade/privacy.html';

  static const envAppId = String.fromEnvironment('ADMOB_APP_ID');
  static const envInterstitialUnitId = String.fromEnvironment('ADMOB_INTERSTITIAL_UNIT_ID');
  static const envRewardedUnitId = String.fromEnvironment('ADMOB_REWARDED_UNIT_ID');
  static const envPrivacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

  final String appId;
  final String interstitialUnitId;
  final String rewardedUnitId;
  final String privacyPolicyUrl;

  bool get usesTestIds =>
      appId == testAppId &&
      interstitialUnitId == testInterstitialUnitId &&
      rewardedUnitId == testRewardedUnitId;

  static AdMobConfig get test => const AdMobConfig(
        appId: testAppId,
        interstitialUnitId: testInterstitialUnitId,
        rewardedUnitId: testRewardedUnitId,
        privacyPolicyUrl: defaultPrivacyPolicyUrl,
      );

  static AdMobConfig resolve({String? jsonText}) {
    Map<String, dynamic> file = const {};
    if (jsonText != null && jsonText.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonText);
        if (decoded is Map<String, dynamic>) file = decoded;
      } catch (_) {
        file = const {};
      }
    }
    return AdMobConfig(
      appId: _pick(envAppId, file['ADMOB_APP_ID'], testAppId),
      interstitialUnitId: _pick(
        envInterstitialUnitId,
        file['ADMOB_INTERSTITIAL_UNIT_ID'],
        testInterstitialUnitId,
      ),
      rewardedUnitId: _pick(
        envRewardedUnitId,
        file['ADMOB_REWARDED_UNIT_ID'],
        testRewardedUnitId,
      ),
      privacyPolicyUrl: _pick(
        envPrivacyPolicyUrl,
        file['PRIVACY_POLICY_URL'],
        defaultPrivacyPolicyUrl,
      ),
    );
  }

  static String _pick(String fromEnv, Object? fromFile, String fallback) {
    if (fromEnv.isNotEmpty) return fromEnv;
    if (fromFile is String && fromFile.isNotEmpty) return fromFile;
    return fallback;
  }
}
