import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/config/admob_config.dart';
import 'package:blockshade/services/analytics_service.dart';
import 'package:blockshade/services/consent_mode.dart';

void main() {
  test('ad config defaults to Google test ids', () {
    final config = AdMobConfig.resolve();
    expect(config.usesTestIds, isTrue);
    expect(config.appId, AdMobConfig.testAppId);
    expect(config.interstitialUnitId, AdMobConfig.testInterstitialUnitId);
    expect(config.rewardedUnitId, AdMobConfig.testRewardedUnitId);

    final file = File('config/admob.json').readAsStringSync();
    final fromFile = AdMobConfig.resolve(jsonText: file);
    expect(fromFile.usesTestIds, isTrue);
    expect(fromFile.privacyPolicyUrl, AdMobConfig.defaultPrivacyPolicyUrl);
    expect(
      AdMobConfig.resolve(jsonText: '{"PRIVACY_POLICY_URL":"https://example.com/privacy"}')
          .privacyPolicyUrl,
      'https://example.com/privacy',
    );
  });

  test('dart-free json override replaces a single unit id', () {
    final config = AdMobConfig.resolve(jsonText: '''
      {"ADMOB_REWARDED_UNIT_ID": "ca-app-pub-1/2"}
    ''');
    expect(config.rewardedUnitId, 'ca-app-pub-1/2');
    expect(config.appId, AdMobConfig.testAppId);
    expect(config.usesTestIds, isFalse);
  });

  test('analytics stays silent without consent and never logs purchase revenue', () async {
    final events = <MapEntry<String, Map<String, Object>>>[];
    final analytics = AnalyticsService(sink: (name, params) {
      events.add(MapEntry(name, params));
    });

    await analytics.logAdPaid(
      adFormat: 'rewarded',
      adUnitName: 'rewarded',
      placement: 'hint',
      valueMicros: 8100,
      currencyCode: 'sek',
      precision: 'precise',
    );
    await analytics.logIapPurchaseComplete(
      productId: 'se.cognifox.blockshade.remove_ads',
      placement: 'store',
      isFirstPurchase: true,
    );
    expect(events, isEmpty);

    await analytics.applyConsent(
      const ConsentModeMapper().decide(const UmpConsentSnapshot(
        status: 'not_required',
        canRequestAds: true,
      )),
      source: 'first_launch',
    );

    await analytics.logAdPaid(
      adFormat: 'rewarded',
      adUnitName: 'rewarded',
      placement: 'hint',
      valueMicros: 8100,
      currencyCode: 'eur',
      precision: 'estimated',
    );
    await analytics.logRewardedComplete(
      placement: 'hint',
      rewardType: 'hint',
      rewardAmount: 1,
    );
    await analytics.logIapPurchaseFail(
      productId: 'se.cognifox.blockshade.coins_small',
      placement: 'store',
      status: 'canceled',
    );

    final names = events.map((event) => event.key).toList();
    expect(names, contains('consent_updated'));
    expect(names, contains('ad_paid'));
    expect(names, contains('rewarded_complete'));
    expect(names, contains('iap_purchase_fail'));
    expect(names, isNot(contains('ad_impression')));
    expect(names, isNot(contains('purchase')));
    expect(names, isNot(contains('in_app_purchase')));

    final paid = events.firstWhere((event) => event.key == 'ad_paid').value;
    expect(paid['value'], closeTo(0.0081, 0.0000001));
    expect(paid['currency'], 'EUR');
    expect(paid['ad_format'], 'rewarded');
    expect(paid['precision'], 'estimated');

    final failed = events.firstWhere((event) => event.key == 'iap_purchase_fail').value;
    expect(failed.containsKey('value'), isFalse);
    expect(failed.containsKey('currency'), isFalse);
  });
}
