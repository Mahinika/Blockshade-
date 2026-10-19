import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/services/consent_mode.dart';
import 'package:blockshade/services/consent_service.dart';

void main() {
  const mapper = ConsentModeMapper();

  test('basic mode stays off until every consent digit allows collection', () {
    expect(ConsentModeMapper.shouldEnableAnalyticsCollection(null), isFalse);
    expect(ConsentModeMapper.shouldEnableAnalyticsCollection(''), isFalse);
    expect(ConsentModeMapper.shouldEnableAnalyticsCollection('1112'), isFalse);
    expect(ConsentModeMapper.shouldEnableAnalyticsCollection('1110'), isFalse);
    expect(ConsentModeMapper.shouldEnableAnalyticsCollection('1111'), isTrue);
    expect(ConsentModeMapper.shouldEnableAnalyticsCollection('3333'), isTrue);
    expect(ConsentModeMapper.shouldEnableAnalyticsCollection('4444'), isTrue);
  });

  test('not required grants consent mode v2 and still honors canRequestAds', () {
    final decision = mapper.decide(const UmpConsentSnapshot(
      status: 'not_required',
      canRequestAds: true,
    ));
    expect(decision.enableCollection, isTrue);
    expect(decision.analyticsStorage, isTrue);
    expect(decision.adStorage, isTrue);
    expect(decision.adUserData, isTrue);
    expect(decision.adPersonalization, isTrue);
    expect(decision.adConsentProperty, 'not_required');
    expect(decision.canRequestAds, isTrue);
    expect(decision.umpStatus, 'not_required');
  });

  test('denied ad storage keeps collection off and blocks ads', () {
    final decision = mapper.decide(const UmpConsentSnapshot(
      status: 'obtained',
      canRequestAds: true,
      consentModeValues: '2222',
    ));
    expect(decision.enableCollection, isFalse);
    expect(decision.adStorage, isFalse);
    expect(decision.adUserData, isFalse);
    expect(decision.canRequestAds, isFalse);
    expect(decision.adConsentProperty, 'denied');
  });

  test('TCF purposes map storage, user data and personalization', () {
    final decision = mapper.decide(const UmpConsentSnapshot(
      status: 'obtained',
      canRequestAds: true,
      // Purpose 1 and 7 granted, purpose 3 denied: storage and user data yes,
      // personalization no, so basic-mode collection stays off.
      purposeConsents: '1001001',
    ));
    expect(decision.adStorage, isTrue);
    expect(decision.adUserData, isTrue);
    expect(decision.adPersonalization, isFalse);
    expect(decision.analyticsStorage, isTrue);
    expect(decision.enableCollection, isFalse);
  });

  test('gather calls UMP info update and the consent form before ads', () async {
    final platform = _FakeConsentPlatform();
    final coordinator = ConsentCoordinator(platform: platform);
    final decision = await coordinator.gather(source: 'first_launch');

    expect(platform.calls, ['requestConsentInfoUpdate', 'loadAndShowFormIfRequired', 'readStorage', 'consentStatus', 'canRequestAds']);
    expect(decision.canRequestAds, isTrue);
    expect(decision.umpStatus, 'not_required');
  });
}

class _FakeConsentPlatform implements ConsentPlatform {
  final calls = <String>[];

  @override
  Future<void> requestConsentInfoUpdate() async {
    calls.add('requestConsentInfoUpdate');
  }

  @override
  Future<void> loadAndShowFormIfRequired() async {
    calls.add('loadAndShowFormIfRequired');
  }

  @override
  Future<void> showPrivacyOptionsForm() async {
    calls.add('showPrivacyOptionsForm');
  }

  @override
  Future<bool> canRequestAds() async {
    calls.add('canRequestAds');
    return true;
  }

  @override
  Future<String> consentStatus() async {
    calls.add('consentStatus');
    return 'not_required';
  }

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<({String consentModeValues, String purposeConsents})> readStorage() async {
    calls.add('readStorage');
    return (consentModeValues: '', purposeConsents: '');
  }
}
