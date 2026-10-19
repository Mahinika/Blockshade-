import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../services/services.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
import '../theme/app_typography.dart';
import '../theme/verkstad_tokens.dart';
import '../widgets/game_grid.dart';
import '../widgets/level_complete_overlay.dart';
import '../widgets/lock_tutorial_hint.dart';
import '../widgets/masking_tape.dart';
import '../widgets/onboarding_overlay.dart';
import '../widgets/workshop_background.dart';

class GameScreen extends StatefulWidget {
  final String levelId;

  const GameScreen({super.key, required this.levelId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _failCount = 0;
  bool _wasWon = false;
  bool _wasLost = false;
  bool _showOnboarding = false;
  bool _onboardingChecked = false;
  bool _showLockHint = false;
  String? _lockToast;
  int _lockToastSerial = 0;
  Timer? _lockToastTimer;
  String? _pulsedBlockId;
  int _pulseSerial = 0;
  String? _dailyHintMessage;
  final _juiceKey = GlobalKey<JuiceOverlayState>();

  bool get _isDaily => DailyPuzzleService.isDailyLevelId(widget.levelId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<GameProvider>().loadLevel(widget.levelId);
      await _evaluateOnboarding();
    });
  }

  @override
  void dispose() {
    _lockToastTimer?.cancel();
    super.dispose();
  }

  Future<void> _evaluateOnboarding() async {
    final onboarding = context.read<OnboardingService>();
    final game = context.read<GameProvider>();
    final completed = await onboarding.isOnboardingCompleted();
    if (!mounted) return;
    final show = onboarding.shouldShowForLevel(widget.levelId, completed);
    final level = game.currentLevel;
    final hasLock = level?.blocks.any((block) => block.lockKeyBlockId != null) ?? false;
    final seenLockHint = await onboarding.hasSeenLockHint();
    final showLock = onboarding.shouldShowLockHint(
      levelHasLockedBlock: hasLock,
      hintAlreadySeen: seenLockHint,
    ) && !show;
    if (showLock) {
      await onboarding.markLockHintSeen();
    }
    if (mounted) {
      setState(() {
        _onboardingChecked = true;
        _showOnboarding = show;
        _showLockHint = showLock;
      });
    }
  }

  Future<void> _skipOnboarding() async {
    await context.read<OnboardingService>().markOnboardingCompleted();
    setState(() => _showOnboarding = false);
  }

  Future<void> _finishOnboardingStep() async {
    final onboarding = context.read<OnboardingService>();
    if (widget.levelId == 'w1-003') {
      await onboarding.markOnboardingCompleted();
    }
    setState(() => _showOnboarding = false);
  }

  Offset _onboardingAnchor(String levelId) {
    switch (levelId) {
      case 'w1-001':
        return const Offset(0.42, 0.48);
      case 'w1-002':
        return const Offset(0.82, 0.42);
      case 'w1-003':
        return const Offset(0.5, 0.4);
      default:
        return const Offset(0.5, 0.45);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<GameProvider>();
    final gameState = provider.gameState;
    final level = provider.currentLevel;

    if (provider.isLoading || gameState == null || level == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = WorldThemes.getTheme(level.world == 0 ? 1 : level.world);

    if (provider.isWon && !_wasWon) {
      _wasWon = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _juiceKey.currentState?.onWin();
      });
    }
    if (provider.isLost && !_wasLost) {
      _wasLost = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _juiceKey.currentState?.onFail();
      });
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: WorkshopBackground(
        world: level.world == 0 ? 1 : level.world,
        seed: theme.benchSeed,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(provider, level, l10n, theme),
              Expanded(
                child: Center(
                  child: _buildGameArea(
                    provider,
                    gameState,
                    level.world == 0 ? 1 : level.world,
                  ),
                ),
              ),
              if (_showLockHint)
                LockTutorialHint(onDismiss: _dismissLockHint),
              _buildFooter(provider, l10n),
            ],
          ),
        ),
      ),
      floatingActionButton: _isDaily && !provider.isWon && !provider.isLost
          ? Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: MaskingTapeButton(
                label: l10n.dailyHint,
                icon: Icons.lightbulb_outline,
                onPressed: () => _requestDailyHint(provider),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(GameProvider provider, Level level, AppLocalizations l10n, WorldTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          MaskingTapeButton(
            label: '✕',
            onPressed: () => _showQuitDialog(provider, l10n),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MaskingTape(
              rotation: 0.01,
              child: Column(
                children: [
                  Text(
                    _isDaily
                        ? l10n.dailyPuzzle
                        : '${l10n.world} ${level.world} · ${l10n.level} ${level.levelNumber}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    theme.name,
                    style: const TextStyle(fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          MaskingTape(
            rotation: -0.03,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, size: 18, color: VerkstadTokens.ink),
                const SizedBox(width: 4),
                Text(
                  '${provider.movesRemaining}',
                  style: AppTypography.moveCounter(18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(GameProvider provider, GameState gameState, int world) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final level = gameState.level;

    final maxGridWidth = screenWidth - 32;
    final maxGridHeight = screenHeight * 0.6;

    final cellSizeByWidth = maxGridWidth / (level.grid.width + 0.5);
    final cellSizeByHeight = maxGridHeight / (level.grid.height + 0.5);
    final cellSize = cellSizeByWidth < cellSizeByHeight ? cellSizeByWidth : cellSizeByHeight;

    return JuiceOverlay(
      key: _juiceKey,
      child: Stack(
        children: [
          GameGrid(
            gameState: gameState,
            cellSize: cellSize,
            world: world,
            onBlockTap: (blockId) => _onBlockTap(provider, blockId),
            onBlockPress: (_) => _juiceKey.currentState?.onBlockPress(),
            pulsedBlockId: _pulsedBlockId,
            pulseSerial: _pulseSerial,
          ),
          if (provider.isWon) _buildWinOverlay(provider),
          if (provider.isLost) _buildLoseOverlay(provider),
          if (_showOnboarding && _onboardingChecked)
            OnboardingOverlay(
              stepIndex: context.read<OnboardingService>().stepIndexForLevel(widget.levelId),
              anchorFraction: _onboardingAnchor(widget.levelId),
              onSkip: _skipOnboarding,
              onFinishedStep: _finishOnboardingStep,
            ),
          if (_lockToast != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LockMoveToast(
                  key: ValueKey('lock-toast-$_lockToastSerial'),
                  message: _lockToast!,
                ),
              ),
            ),
          if (_dailyHintMessage != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: MaskingTape(
                  child: Text(_dailyHintMessage!, textAlign: TextAlign.center),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _requestDailyHint(GameProvider provider) {
    final l10n = AppLocalizations.of(context);
    final level = provider.currentLevel;
    if (level == null) return;

    final adService = context.read<AdService>();
    void revealHint() {
      final solver = Solver(level);
      final result = solver.solve();
      final firstMove = result.solution?.isNotEmpty == true ? result.solution!.first : null;
      setState(() {
        _dailyHintMessage = firstMove != null
            ? '${l10n.dailyHintBody} ($firstMove)'
            : l10n.dailyHintBody;
      });
    }

    if (adService.isRewardedAdReady) {
      adService.showRewardedAd(
        onRewarded: (_) => revealHint(),
        onAdDismissed: () {},
        onAdFailedToShow: (_) => revealHint(),
      );
    } else {
      revealHint();
    }
  }

  void _dismissLockHint() {
    setState(() => _showLockHint = false);
  }

  void _showLockToastMessage(String message) {
    _lockToastTimer?.cancel();
    setState(() {
      _lockToastSerial++;
      _lockToast = message;
    });
    _lockToastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _lockToast = null);
    });
  }

  void _onBlockTap(GameProvider provider, String blockId) {
    if (provider.isGameOver) return;
    final state = provider.gameState;
    if (state == null) return;
    final outcome = state.tryMoveBlock(blockId);
    if (outcome == null) return;
    if (outcome.result == MoveResult.blocked) {
      final key = state.blockById(outcome.block.lockKeyBlockId);
      setState(() {
        _pulseSerial++;
        _pulsedBlockId = key?.id;
      });
      if (key != null) {
        _showLockToastMessage(
          AppLocalizations.of(context).lockKeyFirst(key.color),
        );
      }
      return;
    }
    _juiceKey.currentState?.onMoveOutcome(outcome, outcome.block.color);
    provider.makeMove(blockId);
  }

  Widget _buildWinOverlay(GameProvider provider) {
    final l10n = AppLocalizations.of(context);
    final par = provider.currentLevel?.solver?.optimalMoves ?? provider.movesUsed;

    return LevelCompleteOverlay(
      stars: provider.stars,
      movesUsed: provider.movesUsed,
      parMoves: par,
      nextLabel: _isDaily ? l10n.backHome : null,
      showNext: true,
      onNext: () => _goToNextLevel(provider),
    );
  }

  Widget _buildLoseOverlay(GameProvider provider) {
    final l10n = AppLocalizations.of(context);
    final remoteConfig = context.read<RemoteConfigService>();
    final canBuyWithCoins = provider.canBuyContinueWithCoins(_failCount);
    final coinCost = _failCount <= 1
        ? remoteConfig.extraMovesCoinCost
        : remoteConfig.extraMovesCoinCostSecond;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          color: AppColors.surface,
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sentiment_dissatisfied, color: AppColors.error, size: 64),
                const SizedBox(height: 16),
                Text(
                  l10n.outOfMoves,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.extraMoves,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_failCount == 0)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => _watchAdForMoves(provider),
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(l10n.watchAd),
                  ),
                
                const SizedBox(height: 12),
                
                if (canBuyWithCoins)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coinColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => _buyMovesWithCoins(provider),
                    icon: const Icon(Icons.monetization_on),
                    label: Text('${l10n.buyCoins} $coinCost'),
                  ),
                
                const SizedBox(height: 24),
                
                TextButton(
                  onPressed: () => _giveUp(provider),
                  child: Text(
                    l10n.giveUp,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(GameProvider provider, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildResourceDisplay(
            Icons.favorite,
            '${provider.progress.currentLives}',
            AppColors.lifeColor,
          ),
          
          _buildResourceDisplay(
            Icons.monetization_on,
            '${provider.progress.coins}',
            AppColors.coinColor,
          ),
          
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.canUndo() ? AppColors.primary : AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: provider.canUndo() ? () => provider.undo() : null,
            icon: const Icon(Icons.undo, size: 20),
            label: Text(
              '${l10n.undo} (${provider.progress.undoBoostersOwned})',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceDisplay(IconData icon, String value, Color color) {
    return MaskingTape(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      showPin: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(value, style: AppTypography.moveCounter(15)),
        ],
      ),
    );
  }

  void _showQuitDialog(GameProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.quit, style: const TextStyle(color: AppColors.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.resume),
          ),
          TextButton(
            onPressed: () {
              provider.quitLevel();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _watchAdForMoves(GameProvider provider) {
    final adService = context.read<AdService>();
    
    if (adService.isRewardedAdReady) {
      adService.showRewardedAd(
        onRewarded: (amount) {
          provider.addExtraMoves(5);
          setState(() => _failCount++);
        },
        onAdDismissed: () {},
        onAdFailedToShow: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ad not available: $error')),
          );
        },
      );
    } else {
      provider.addExtraMoves(5);
      setState(() => _failCount++);
    }
  }

  void _buyMovesWithCoins(GameProvider provider) {
    provider.buyContinueWithCoins(_failCount);
    setState(() => _failCount++);
  }

  void _giveUp(GameProvider provider) {
    if (provider.progress.currentLives > 0) {
      provider.restartLevel();
      setState(() => _failCount = 0);
    } else {
      Navigator.pop(context);
    }
  }

  void _goToNextLevel(GameProvider provider) async {
    if (_isDaily) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final adService = context.read<AdService>();
    final currentLevel = provider.currentLevel?.levelNumber ?? 0;

    adService.onLevelCompleted();

    if (adService.shouldShowInterstitial(currentLevel, provider.progress.adsRemoved)) {
      adService.showInterstitial(
        onAdDismissed: () async {
          await provider.goToNextLevel();
          if (provider.currentLevel == null) {
            if (mounted) Navigator.pop(context);
          }
        },
      );
    } else {
      await provider.goToNextLevel();
      if (provider.currentLevel == null) {
        if (mounted) Navigator.pop(context);
      }
    }
  }
}
