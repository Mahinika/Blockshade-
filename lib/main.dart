import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/game_provider.dart';
import 'services/services.dart';
import 'screens/screens.dart';
import 'theme/app_typography.dart';
import 'utils/colors.dart';
import 'utils/localization.dart';
import 'utils/startup_timeout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  final remoteConfigService = RemoteConfigService();
  final analyticsService = AnalyticsService();
  final levelService = LevelService();
  final dailyPuzzleService = DailyPuzzleService();
  final onboardingService = OnboardingService();
  final adService = AdService(remoteConfigService);
  final iapService = IAPService();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<RemoteConfigService>.value(value: remoteConfigService),
        Provider<AnalyticsService>.value(value: analyticsService),
        Provider<LevelService>.value(value: levelService),
        Provider<DailyPuzzleService>.value(value: dailyPuzzleService),
        Provider<OnboardingService>.value(value: onboardingService),
        Provider<AdService>.value(value: adService),
        Provider<IAPService>.value(value: iapService),
        ChangeNotifierProvider<GameProvider>(
          create: (context) => GameProvider(
            levelService: levelService,
            storageService: storageService,
            analyticsService: analyticsService,
            remoteConfig: remoteConfigService,
            dailyPuzzleService: dailyPuzzleService,
          ),
        ),
      ],
      child: const BlockshadeApp(),
    ),
  );
}

class BlockshadeApp extends StatefulWidget {
  const BlockshadeApp({super.key});

  @override
  State<BlockshadeApp> createState() => _BlockshadeAppState();
}

class _BlockshadeAppState extends State<BlockshadeApp> {
  static const Duration _initTimeout = Duration(seconds: 4);

  bool _firebaseAvailable = false;

  @override
  void initState() {
    super.initState();
    final storageService = context.read<StorageService>();
    final remoteConfigService = context.read<RemoteConfigService>();
    final analyticsService = context.read<AnalyticsService>();
    final adService = context.read<AdService>();
    final iapService = context.read<IAPService>();
    final gameProvider = context.read<GameProvider>();
    unawaited(
      _initializeServices(
        storageService: storageService,
        remoteConfigService: remoteConfigService,
        analyticsService: analyticsService,
        adService: adService,
        iapService: iapService,
        gameProvider: gameProvider,
      ),
    );
  }

  Future<void> _initializeServices({
    required StorageService storageService,
    required RemoteConfigService remoteConfigService,
    required AnalyticsService analyticsService,
    required AdService adService,
    required IAPService iapService,
    required GameProvider gameProvider,
  }) async {
    unawaited(
      startupWithTimeoutVoid(
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
        timeout: _initTimeout,
        debugLabel: 'orientation',
      ),
    );

    await startupWithTimeoutVoid(
      HapticService.instance.load(),
      timeout: _initTimeout,
      debugLabel: 'haptics',
    );

    await startupWithTimeoutVoid(
      SoundService.instance.init(),
      timeout: _initTimeout,
      debugLabel: 'sound',
    );

    _firebaseAvailable = await startupWithTimeout(
      _tryInitFirebase(),
      timeout: _initTimeout,
      fallback: false,
      debugLabel: 'firebase',
    );

    await startupWithTimeoutVoid(
      storageService.init(),
      timeout: _initTimeout,
      debugLabel: 'storage',
    );

    if (_firebaseAvailable) {
      await startupWithTimeoutVoid(
        remoteConfigService.init(),
        timeout: _initTimeout,
        debugLabel: 'remote_config',
      );
    }

    if (_firebaseAvailable) {
      await startupWithTimeoutVoid(
        analyticsService.init(),
        timeout: _initTimeout,
        debugLabel: 'analytics',
      );
    }

    await startupWithTimeoutVoid(
      adService.init(),
      timeout: _initTimeout,
      debugLabel: 'ads',
    );

    await startupWithTimeoutVoid(
      iapService.init(),
      timeout: _initTimeout,
      debugLabel: 'iap',
    );

    await startupWithTimeoutVoid(
      gameProvider.init(),
      timeout: _initTimeout,
      debugLabel: 'game_provider',
    );

    try {
      final daysSinceInstall = await startupWithTimeout(
        storageService.getDaysSinceInstall(),
        timeout: const Duration(seconds: 2),
        fallback: 0,
        debugLabel: 'install_age',
      );
      final isFirstOpen = await startupWithTimeout(
        storageService.isFirstOpen(),
        timeout: const Duration(seconds: 2),
        fallback: false,
        debugLabel: 'first_open',
      );
      await startupWithTimeoutVoid(
        analyticsService.logAppOpen(
          firstOpen: isFirstOpen,
          daysSinceInstall: daysSinceInstall,
        ),
        timeout: const Duration(seconds: 2),
        debugLabel: 'analytics_app_open',
      );
    } catch (e) {
      debugPrint('Analytics log error (non-fatal): $e');
    }

    adService.onSessionStart();
  }

  Future<bool> _tryInitFirebase() async {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Firebase init skipped (no google-services.json): $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockshade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          onSurface: AppColors.text,
        ),
        textTheme: AppTypography.textTheme(ThemeData.light().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0,
          titleTextStyle: AppTypography.textTheme(ThemeData.light().textTheme).titleLarge,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.text,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('sv'),
      home: const HomeScreen(),
    );
  }
}
