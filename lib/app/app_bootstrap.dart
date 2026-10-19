import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import '../providers/game_provider.dart';
import '../screens/startup_error_screen.dart';
import '../screens/screens.dart';
import '../services/services.dart';
import '../theme/app_typography.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
import '../utils/startup_timeout.dart';

/// Minimal shell shown on the first frame (no custom fonts, no native audio).
class StartupShell extends StatelessWidget {
  const StartupShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFE9DCC4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Blockshade',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B1D14),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3B2A1E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Builds the full app widget tree (providers + [BlockshadeApp]).
Widget buildBlockshadeApp({
  required StorageService storageService,
  required RemoteConfigService remoteConfigService,
  required AnalyticsService analyticsService,
  required LevelService levelService,
  required DailyPuzzleService dailyPuzzleService,
  required OnboardingService onboardingService,
  required AdService adService,
  required IAPService iapService,
}) {
  return MultiProvider(
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
  );
}

class BlockshadeBootstrap extends StatefulWidget {
  const BlockshadeBootstrap({super.key});

  @override
  State<BlockshadeBootstrap> createState() => _BlockshadeBootstrapState();
}

class _BlockshadeBootstrapState extends State<BlockshadeBootstrap> {
  Widget _root = const StartupShell();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.microtask(_mountFullAppAfterFirstFrame);
    });
  }

  void _showFatalError(String message) {
    if (!mounted) return;
    setState(() {
      _root = StartupErrorScreen(message: message);
    });
  }

  void _mountFullAppAfterFirstFrame() {
    try {
      final storageService = StorageService();
      final remoteConfigService = RemoteConfigService();
      final analyticsService = AnalyticsService();
      final levelService = LevelService();
      final dailyPuzzleService = DailyPuzzleService();
      final onboardingService = OnboardingService();
      final adService = AdService(remoteConfigService);
      final iapService = IAPService();

      if (!mounted) return;
      setState(() {
        _root = buildBlockshadeApp(
          storageService: storageService,
          remoteConfigService: remoteConfigService,
          analyticsService: analyticsService,
          levelService: levelService,
          dailyPuzzleService: dailyPuzzleService,
          onboardingService: onboardingService,
          adService: adService,
          iapService: iapService,
        );
      });

      unawaited(
        _runDeferredPluginInit(
          storageService: storageService,
          remoteConfigService: remoteConfigService,
          analyticsService: analyticsService,
          adService: adService,
          iapService: iapService,
        ),
      );
    } catch (e, stack) {
      _showFatalError('Bootstrap: $e\n$stack');
    }
  }

  Future<void> _runDeferredPluginInit({
    required StorageService storageService,
    required RemoteConfigService remoteConfigService,
    required AnalyticsService analyticsService,
    required AdService adService,
    required IAPService iapService,
  }) async {
    const timeout = Duration(seconds: 4);

    unawaited(
      startupWithTimeoutVoid(
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
        timeout: timeout,
        debugLabel: 'orientation',
      ),
    );

    await startupWithTimeoutVoid(
      HapticService.instance.load(),
      timeout: timeout,
      debugLabel: 'haptics',
    );

    await startupWithTimeoutVoid(
      SoundService.instance.init(),
      timeout: timeout,
      debugLabel: 'sound',
    );

    final firebaseOk = await startupWithTimeout(
      _tryInitFirebase(),
      timeout: timeout,
      fallback: false,
      debugLabel: 'firebase',
    );

    await startupWithTimeoutVoid(
      storageService.init(),
      timeout: timeout,
      debugLabel: 'storage',
    );

    if (firebaseOk) {
      await startupWithTimeoutVoid(
        remoteConfigService.init(),
        timeout: timeout,
        debugLabel: 'remote_config',
      );
      await startupWithTimeoutVoid(
        analyticsService.init(),
        timeout: timeout,
        debugLabel: 'analytics',
      );
    }

    await startupWithTimeoutVoid(
      adService.init(),
      timeout: timeout,
      debugLabel: 'ads',
    );

    await startupWithTimeoutVoid(
      iapService.init(),
      timeout: timeout,
      debugLabel: 'iap',
    );
  }

  Future<bool> _tryInitFirebase() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => _root;
}

class BlockshadeApp extends StatefulWidget {
  const BlockshadeApp({super.key});

  @override
  State<BlockshadeApp> createState() => _BlockshadeAppState();
}

class _BlockshadeAppState extends State<BlockshadeApp> {
  static const Duration _initTimeout = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    final gameProvider = context.read<GameProvider>();
    final storageService = context.read<StorageService>();
    final analyticsService = context.read<AnalyticsService>();
    final adService = context.read<AdService>();
    unawaited(_initGameSession(gameProvider, storageService, analyticsService, adService));
  }

  Future<void> _initGameSession(
    GameProvider gameProvider,
    StorageService storageService,
    AnalyticsService analyticsService,
    AdService adService,
  ) async {
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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('sv'),
      home: const HomeScreen(),
    );
  }
}
