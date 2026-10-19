import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/game_provider.dart';
import 'services/services.dart';
import 'screens/screens.dart';
import 'utils/colors.dart';
import 'utils/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Orientation lock error: $e');
  }

  // Initialize Firebase (optional - may not have google-services.json)
  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp();
    firebaseAvailable = true;
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase init skipped (no google-services.json): $e');
  }

  // Storage service - required, but guard anyway
  final storageService = StorageService();
  try {
    await storageService.init();
  } catch (e) {
    debugPrint('Storage service init error: $e');
  }

  // Remote config - optional, uses defaults if Firebase unavailable
  final remoteConfigService = RemoteConfigService();
  if (firebaseAvailable) {
    try {
      await remoteConfigService.init();
    } catch (e) {
      debugPrint('Remote config init error: $e');
    }
  }

  // Analytics - optional
  final analyticsService = AnalyticsService();
  if (firebaseAvailable) {
    try {
      await analyticsService.init();
    } catch (e) {
      debugPrint('Analytics init error: $e');
    }
  }

  // Level service - required for game
  final levelService = LevelService();

  // Ad service - optional
  final adService = AdService(remoteConfigService);

  // IAP service - optional
  final iapService = IAPService();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<RemoteConfigService>.value(value: remoteConfigService),
        Provider<AnalyticsService>.value(value: analyticsService),
        Provider<LevelService>.value(value: levelService),
        Provider<AdService>.value(value: adService),
        Provider<IAPService>.value(value: iapService),
        ChangeNotifierProvider<GameProvider>(
          create: (context) => GameProvider(
            levelService: levelService,
            storageService: storageService,
            analyticsService: analyticsService,
            remoteConfig: remoteConfigService,
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final adService = context.read<AdService>();
      final iapService = context.read<IAPService>();
      final gameProvider = context.read<GameProvider>();
      final storageService = context.read<StorageService>();
      final analyticsService = context.read<AnalyticsService>();

      // Initialize ads - guard against missing AdMob config
      try {
        await adService.init();
      } catch (e) {
        debugPrint('Ad service init error (non-fatal): $e');
      }

      // Initialize IAP - guard against Play Store unavailable
      try {
        await iapService.init();
      } catch (e) {
        debugPrint('IAP service init error (non-fatal): $e');
      }

      // Initialize game provider - required
      try {
        await gameProvider.init();
      } catch (e) {
        debugPrint('Game provider init error: $e');
      }

      // Log app open - optional
      try {
        final isFirstOpen = await storageService.isFirstOpen();
        final daysSinceInstall = await storageService.getDaysSinceInstall();
        await analyticsService.logAppOpen(
          firstOpen: isFirstOpen,
          daysSinceInstall: daysSinceInstall,
        );
      } catch (e) {
        debugPrint('Analytics log error (non-fatal): $e');
      }

      // Start ad session tracking
      try {
        adService.onSessionStart();
      } catch (e) {
        debugPrint('Ad session start error (non-fatal): $e');
      }

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Service initialization error: $e');
      if (mounted) {
        setState(() {
          _initialized = true; // Still show home screen even on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockshade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('sv'),
      home: _initialized ? const HomeScreen() : const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Blockshade',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
