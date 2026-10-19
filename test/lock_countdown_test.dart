import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:blockshade/models/models.dart';
import 'package:blockshade/providers/game_provider.dart';
import 'package:blockshade/screens/game_screen.dart';
import 'package:blockshade/services/services.dart';
import 'package:blockshade/theme/app_typography.dart';
import 'package:blockshade/utils/localization.dart';
import 'package:blockshade/widgets/block_widget.dart';
import 'package:blockshade/widgets/game_grid.dart';
import 'package:blockshade/widgets/lock_tutorial_hint.dart';
import 'package:blockshade/widgets/padlock_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Swedish lock toast names the key color', () {
    final sv = AppLocalizations(const Locale('sv'));
    final en = AppLocalizations(const Locale('en'));

    expect(sv.lockKeyFirst('blue'), 'Få ut den blå klossen först');
    expect(sv.lockKeyFirst('red'), 'Få ut den röda klossen först');
    expect(en.lockKeyFirst('blue'), 'Get the blue block out first');
    expect(sv.tutorialLock, 'Låset öppnas när klossen med samma färg och mönster lämnar banan.');
    expect(en.tutorialLock, contains('same color and pattern'));
  });

  test('Recursive weights set the variable font axis', () {
    final variations = AppTypography.moveCounter(18).fontVariations;
    expect(variations, isNotNull);
    expect(
      variations!.any((variation) => variation.axis == 'wght' && variation.value == 700),
      isTrue,
    );
    expect(
      AppTypography.recursiveVariations(800, mono: 1).first.value,
      800,
    );
  });

  testWidgets('padlock shows the key pattern and shakes when tapped', (tester) async {
    var taps = 0;
    final block = Block(
      id: 'b',
      color: 'red',
      cells: const [BlockCell(0, 0)],
      direction: Direction.right,
      lockKeyBlockId: 'a',
    );

    Widget harness({
      required bool locked,
      required bool ready,
      int pulseSerial = 0,
      bool reduceMotion = false,
    }) {
      return MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          );
        },
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                BlockWidget(
                  key: const ValueKey('block-b'),
                  block: block,
                  cellSize: 80,
                  offsetX: 8,
                  offsetY: 8,
                  isLocked: locked,
                  keyReadyToExit: ready,
                  keyColorName: 'blue',
                  pulseSerial: pulseSerial,
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(harness(locked: true, ready: false));
    await tester.pump();

    final padlock = tester.widget<CustomPaint>(find.byKey(const ValueKey('padlock-b')));
    final painter = padlock.painter! as PadlockPainter;
    expect(painter.keyColorName, 'blue');
    expect(painter.plateStrokeFactor, 1);
    expect(find.descendant(of: find.byKey(const ValueKey('padlock-b')), matching: find.byType(Text)), findsNothing);

    await tester.tap(find.byType(BlockWidget));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(taps, 1);
    final translations = tester.widgetList<Transform>(find.byType(Transform)).map((transform) {
      return transform.transform.getTranslation().x;
    }).toList();
    expect(translations.any((dx) => dx.abs() > 0.5), isTrue, reason: 'translations=$translations');

    await tester.pumpWidget(harness(locked: true, ready: true));
    await tester.pump();
    final readyPainter = tester.widget<CustomPaint>(find.byKey(const ValueKey('padlock-b'))).painter! as PadlockPainter;
    expect(readyPainter.plateStrokeFactor, 2);

    await tester.pumpWidget(harness(locked: true, ready: true, pulseSerial: 1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(const Key('key-pulse')), findsOneWidget);

    await tester.pumpWidget(harness(locked: false, ready: false, reduceMotion: true));
    await tester.pump();
    expect(find.byKey(const ValueKey('padlock-b')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('padlock-b')), findsNothing);
  });

  testWidgets('game grid paints a padlock only on locked blocks', (tester) async {
    final level = Level(
      id: 'grid-lock',
      world: 2,
      grid: const GridSize(5, 5),
      moveLimit: 8,
      blocks: [
        Block(
          id: 'a',
          color: 'blue',
          cells: const [BlockCell(0, 1)],
          direction: Direction.up,
        ),
        Block(
          id: 'b',
          color: 'red',
          cells: const [BlockCell(3, 3)],
          direction: Direction.down,
          lockKeyBlockId: 'a',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameGrid(
            gameState: GameState.fromLevel(level),
            cellSize: 48,
            world: 2,
            onBlockTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('padlock-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('padlock-a')), findsNothing);
    final painter = tester.widget<CustomPaint>(find.byKey(const ValueKey('padlock-b'))).painter! as PadlockPainter;
    expect(painter.keyColorName, 'blue');
    expect(painter.plateStrokeFactor, 2);
  });

  testWidgets('lock tutorial hint explains the key and dismisses', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LockTutorialHint(onDismiss: () => dismissed = true),
        ),
      ),
    );

    expect(find.textContaining('samma färg och mönster'), findsOneWidget);
    await tester.tap(find.text('Förstått'));
    await tester.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('tapping a locked block toasts the key color and pulses that block', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final storage = StorageService();
    await storage.init();
    final remote = RemoteConfigService();
    final analytics = AnalyticsService();
    final levels = LevelService();
    final daily = DailyPuzzleService();
    await daily.init();
    final onboarding = OnboardingService();
    await onboarding.init();
    final game = GameProvider(
      levelService: levels,
      storageService: storage,
      analyticsService: analytics,
      remoteConfig: remote,
      dailyPuzzleService: daily,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          Provider<RemoteConfigService>.value(value: remote),
          Provider<AnalyticsService>.value(value: analytics),
          Provider<LevelService>.value(value: levels),
          Provider<DailyPuzzleService>.value(value: daily),
          Provider<OnboardingService>.value(value: onboarding),
          Provider<AdService>.value(value: AdService(remote)),
          Provider<IAPService>.value(value: IAPService()),
          ChangeNotifierProvider<GameProvider>.value(value: game),
        ],
        child: const MaterialApp(
          home: GameScreen(levelId: 'w2-006'),
        ),
      ),
    );

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('block-b')).evaluate().isNotEmpty &&
          find.byKey(const Key('lock-tutorial-hint')).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('padlock-b')), findsOneWidget);
    expect(find.textContaining('samma färg och mönster'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('block-b')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Få ut den röda klossen först'), findsOneWidget);
    expect(find.byKey(const Key('lock-toast')), findsOneWidget);
    expect(find.byKey(const Key('key-pulse')), findsOneWidget);

    await tester.tap(find.text('Förstått'));
    await tester.pump();
    expect(find.byKey(const Key('lock-tutorial-hint')), findsNothing);
    expect(await onboarding.hasSeenLockHint(), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
