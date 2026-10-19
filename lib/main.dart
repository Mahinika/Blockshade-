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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error (expected in dev without config): $e');
  }

  final storageService = StorageService();
  await storageService.init();

  final remoteConfigService = RemoteConfigService();
  await remoteConfigService.init();

  final analyticsService = AnalyticsService();
  await analyticsService.init();

  final levelService = LevelService();

  final adService = AdService(remoteConfigService);

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
    final adService = context.read<AdService>();
    final iapService = context.read<IAPService>();
    final gameProvider = context.read<GameProvider>();
    final storageService = context.read<StorageService>();
    final analyticsService = context.read<AnalyticsService>();

    try {
      await adService.init();
    } catch (e) {
      debugPrint('Ad service init error: $e');
    }

    try {
      await iapService.init();
    } catch (e) {
      debugPrint('IAP service init error: $e');
    }

    await gameProvider.init();

    final isFirstOpen = await storageService.isFirstOpen();
    final daysSinceInstall = await storageService.getDaysSinceInstall();
    await analyticsService.logAppOpen(
      firstOpen: isFirstOpen,
      daysSinceInstall: daysSinceInstall,
    );

    adService.onSessionStart();

    setState(() {
      _initialized = true;
    });
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
