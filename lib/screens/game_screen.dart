import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../services/services.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
import '../theme/app_typography.dart';
import '../theme/verkstad_tokens.dart';
import '../widgets/brass_star.dart';
import '../widgets/game_grid.dart';
import '../widgets/masking_tape.dart';
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
  final _juiceKey = GlobalKey<JuiceOverlayState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadLevel(widget.levelId);
    });
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

    final theme = WorldThemes.getTheme(level.world);

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
        world: level.world,
        seed: theme.benchSeed,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(provider, level, l10n, theme),
              Expanded(
                child: Center(
                  child: _buildGameArea(provider, gameState, level.world),
                ),
              ),
              _buildFooter(provider, l10n),
            ],
          ),
        ),
      ),
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
                    '${l10n.world} ${level.world} · ${l10n.level} ${level.levelNumber}',
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
          ),
          if (provider.isWon) _buildWinOverlay(provider),
          if (provider.isLost) _buildLoseOverlay(provider),
        ],
      ),
    );
  }

  void _onBlockTap(GameProvider provider, String blockId) {
    if (provider.isGameOver) return;
    final state = provider.gameState;
    if (state == null) return;
    final outcome = state.tryMoveBlock(blockId);
    if (outcome == null || outcome.result == MoveResult.blocked) return;
    _juiceKey.currentState?.onMoveOutcome(outcome, outcome.block.color);
    provider.makeMove(blockId);
  }

  Widget _buildWinOverlay(GameProvider provider) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      color: VerkstadTokens.pencil.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MaskingTape(
                rotation: -0.04,
                child: Text(
                  '✓ ${l10n.levelComplete}',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: BrassStar(filled: i < provider.stars, size: 36),
                  );
                }),
              ),
              const SizedBox(height: 24),
              MaskingTapeButton(
                label: l10n.nextLevel,
                onPressed: () => _goToNextLevel(provider),
              ),
            ],
          ),
        ),
      ),
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
