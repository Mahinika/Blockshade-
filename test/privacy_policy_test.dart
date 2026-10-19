import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blockshade/config/admob_config.dart';
import 'package:blockshade/providers/game_provider.dart';
import 'package:blockshade/screens/home_screen.dart';
import 'package:blockshade/services/ad_service.dart';
import 'package:blockshade/services/analytics_service.dart';
import 'package:blockshade/services/consent_service.dart';
import 'package:blockshade/services/daily_puzzle_service.dart';
import 'package:blockshade/services/level_service.dart';
import 'package:blockshade/services/remote_config_service.dart';
import 'package:blockshade/services/storage_service.dart';
import 'package:blockshade/utils/localization.dart';

void main() {
  testWidgets('settings and privacy choices open the configured policy', (tester) async {
    final opened = <Uri>[];
    Future<bool> openUrl(Uri uri) async {
      opened.add(uri);
      return true;
    }

    final storage = StorageService();
    final remote = RemoteConfigService();
    final analytics = AnalyticsService();
    final ads = AdService(remote, analytics: analytics, quotaStore: storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AdService>.value(value: ads),
          Provider<ConsentCoordinator>.value(
            value: ConsentCoordinator(platform: _QuietConsent()),
          ),
          ChangeNotifierProvider(
            create: (_) => GameProvider(
              levelService: LevelService(),
              storageService: storage,
              analyticsService: analytics,
              remoteConfig: remote,
              dailyPuzzleService: DailyPuzzleService(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('sv'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(openUrl: openUrl),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Inställningar'));
    await tester.pumpAndSettle();

    expect(find.text('Integritetspolicy'), findsOneWidget);
    await tester.tap(find.text('Integritetspolicy'));
    await tester.pump();
    expect(opened, [Uri.parse(AdMobConfig.defaultPrivacyPolicyUrl)]);

    opened.clear();
    await tester.tap(find.text('Integritetsval'));
    await tester.pumpAndSettle();

    expect(find.text('Ändra integritetsval'), findsOneWidget);
    expect(find.text('Integritetspolicy'), findsOneWidget);
    await tester.tap(find.text('Integritetspolicy'));
    await tester.pump();
    expect(opened.single, Uri.parse('https://mahinika.github.io/blockshade/privacy.html'));
  });
}

class _QuietConsent implements ConsentPlatform {
  @override
  Future<bool> canRequestAds() async => false;

  @override
  Future<String> consentStatus() async => 'unknown';

  @override
  Future<void> loadAndShowFormIfRequired() async {}

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<({String consentModeValues, String purposeConsents})> readStorage() async {
    return (consentModeValues: '', purposeConsents: '');
  }

  @override
  Future<void> requestConsentInfoUpdate() async {}

  @override
  Future<void> showPrivacyOptionsForm() async {}
}
