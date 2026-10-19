/// Maps UMP consent-mode storage to Firebase consent mode v2 (basic).
///
/// `UMP_consentModeValues` is a four-character string written by UMP 3.2+:
/// ad_storage, ad_user_data, ad_personalization, analytics_storage.
/// Digits: 0 unknown, 1 granted, 2 denied, 3 not applicable, 4 not configured.
///
/// Basic mode enables Analytics collection only when every digit is granted,
/// not applicable, or not configured. Denied or unknown keeps collection off.
class ConsentModeDecision {
  const ConsentModeDecision({
    required this.analyticsStorage,
    required this.adStorage,
    required this.adUserData,
    required this.adPersonalization,
    required this.enableCollection,
    required this.adConsentProperty,
    required this.analyticsStorageLabel,
    required this.adStorageLabel,
    required this.adUserDataLabel,
    required this.adPersonalizationLabel,
    required this.umpStatus,
    required this.canRequestAds,
  });

  final bool analyticsStorage;
  final bool adStorage;
  final bool adUserData;
  final bool adPersonalization;
  final bool enableCollection;
  final String adConsentProperty;
  final String analyticsStorageLabel;
  final String adStorageLabel;
  final String adUserDataLabel;
  final String adPersonalizationLabel;
  final String umpStatus;
  final bool canRequestAds;

  static const unavailable = ConsentModeDecision(
    analyticsStorage: false,
    adStorage: false,
    adUserData: false,
    adPersonalization: false,
    enableCollection: false,
    adConsentProperty: 'unknown',
    analyticsStorageLabel: 'denied',
    adStorageLabel: 'denied',
    adUserDataLabel: 'denied',
    adPersonalizationLabel: 'denied',
    umpStatus: 'unknown',
    canRequestAds: false,
  );
}

class UmpConsentSnapshot {
  const UmpConsentSnapshot({
    required this.status,
    required this.canRequestAds,
    this.consentModeValues = '',
    this.purposeConsents = '',
  });

  /// `obtained`, `required`, `not_required`, or `unknown`.
  final String status;
  final bool canRequestAds;

  /// Raw `UMP_consentModeValues`, possibly empty.
  final String consentModeValues;

  /// Raw `IABTCF_PurposeConsents`, possibly empty.
  final String purposeConsents;
}

class ConsentModeMapper {
  const ConsentModeMapper();

  ConsentModeDecision decide(UmpConsentSnapshot snapshot) {
    if (snapshot.status == 'not_required') {
      return _all(
        granted: true,
        enableCollection: true,
        adConsentProperty: 'not_required',
        umpStatus: 'not_required',
        canRequestAds: snapshot.canRequestAds,
        label: 'granted',
      );
    }

    final digits = _digits(snapshot);
    if (digits == null) {
      if (snapshot.status == 'required' || snapshot.status == 'unknown') {
        return ConsentModeDecision(
          analyticsStorage: false,
          adStorage: false,
          adUserData: false,
          adPersonalization: false,
          enableCollection: false,
          adConsentProperty: snapshot.status == 'unknown' ? 'unknown' : 'denied',
          analyticsStorageLabel: 'denied',
          adStorageLabel: 'denied',
          adUserDataLabel: 'denied',
          adPersonalizationLabel: 'denied',
          umpStatus: snapshot.status == 'required' ? 'required' : 'unknown',
          canRequestAds: false,
        );
      }
      return ConsentModeDecision.unavailable;
    }

    final enable = digits.split('').every(_digitAllowsCollection);
    final adStorageDigit = digits[0];
    return ConsentModeDecision(
      analyticsStorage: _signalGranted(digits[3]),
      adStorage: _signalGranted(digits[0]),
      adUserData: _signalGranted(digits[1]),
      adPersonalization: _signalGranted(digits[2]),
      enableCollection: enable,
      adConsentProperty: _adConsentProperty(adStorageDigit),
      analyticsStorageLabel: _label(digits[3]),
      adStorageLabel: _label(digits[0]),
      adUserDataLabel: _label(digits[1]),
      adPersonalizationLabel: _label(digits[2]),
      umpStatus: snapshot.status == 'obtained' ? 'obtained' : snapshot.status,
      canRequestAds: snapshot.canRequestAds && _signalGranted(adStorageDigit),
    );
  }

  /// Google's basic-mode check: 1, 3 and 4 allow collection. 0 and 2 do not.
  static bool shouldEnableAnalyticsCollection(String? consentModeValues) {
    if (consentModeValues == null || consentModeValues.isEmpty) return false;
    for (final char in consentModeValues.split('')) {
      if (!_digitAllowsCollection(char)) return false;
    }
    return true;
  }

  static bool _digitAllowsCollection(String digit) =>
      digit == '1' || digit == '3' || digit == '4';

  /// Granted for setConsent. Not-applicable and not-configured are allowed
  /// signals so basic mode does not leave non-EEA users in a denied state.
  static bool _signalGranted(String digit) => digit == '1' || digit == '3' || digit == '4';

  static String _label(String digit) {
    switch (digit) {
      case '1':
      case '3':
      case '4':
        return 'granted';
      case '2':
      case '0':
        return 'denied';
      default:
        return 'denied';
    }
  }

  static String _adConsentProperty(String adStorageDigit) {
    switch (adStorageDigit) {
      case '1':
        return 'granted';
      case '3':
        return 'not_required';
      case '2':
      case '0':
        return 'denied';
      case '4':
        return 'unknown';
      default:
        return 'unknown';
    }
  }

  String? _digits(UmpConsentSnapshot snapshot) {
    final raw = snapshot.consentModeValues.trim();
    if (raw.length >= 4 && raw.substring(0, 4).split('').every(_knownDigit)) {
      return raw.substring(0, 4);
    }
    final purposes = snapshot.purposeConsents;
    if (purposes.isEmpty) return null;
    bool purpose(int n) => purposes.length >= n && purposes[n - 1] == '1';
    final adStorage = purpose(1);
    final adUserData = purpose(1) && purpose(7);
    final adPersonalization = purpose(3) && purpose(4);
    final analytics = purpose(1);
    return [
      adStorage ? '1' : '2',
      adUserData ? '1' : '2',
      adPersonalization ? '1' : '2',
      analytics ? '1' : '2',
    ].join();
  }

  static bool _knownDigit(String digit) =>
      digit == '0' || digit == '1' || digit == '2' || digit == '3' || digit == '4';

  ConsentModeDecision _all({
    required bool granted,
    required bool enableCollection,
    required String adConsentProperty,
    required String umpStatus,
    required bool canRequestAds,
    required String label,
  }) {
    return ConsentModeDecision(
      analyticsStorage: granted,
      adStorage: granted,
      adUserData: granted,
      adPersonalization: granted,
      enableCollection: enableCollection,
      adConsentProperty: adConsentProperty,
      analyticsStorageLabel: label,
      adStorageLabel: label,
      adUserDataLabel: label,
      adPersonalizationLabel: label,
      umpStatus: umpStatus,
      canRequestAds: canRequestAds,
    );
  }
}
