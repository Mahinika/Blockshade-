import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../services/services.dart';
import '../theme/verkstad_tokens.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
import '../widgets/brass_star.dart';
import '../widgets/masking_tape.dart';
import '../widgets/workshop_background.dart';
import 'game_screen.dart';

class WorldMapScreen extends StatefulWidget {
  final int world;

  const WorldMapScreen({super.key, required this.world});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  List<Level>? _levels;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final levelService = context.read<LevelService>();
    final levels = await levelService.loadWorldLevels(widget.world);
    setState(() {
      _levels = levels;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = WorldThemes.getTheme(widget.world);
    final provider = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: MaskingTape(
          showPin: true,
          child: Text('${l10n.world} ${widget.world}: ${theme.name}'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MaskingTape(
              showPin: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrassStar(filled: true, size: 16),
                  const SizedBox(width: 4),
                  Text('${provider.progress.getStarsForWorld(widget.world)}'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: WorkshopBackground(
        world: widget.world,
        seed: theme.benchSeed,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _buildLevelGrid(provider, l10n),
      ),
    );
  }

  Widget _buildLevelGrid(GameProvider provider, AppLocalizations l10n) {
    if (_levels == null || _levels!.isEmpty) {
      return Center(
        child: Text(
          'No levels available',
          style: TextStyle(color: AppColors.text),
        ),
      );
    }

    final allLevelIds = _levels!.map((l) => l.id).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _levels!.length,
      itemBuilder: (context, index) {
        final level = _levels![index];
        final progress = provider.progress.levelProgress[level.id];
        final isUnlocked = provider.progress.isLevelUnlocked(level.id, allLevelIds);
        final stars = progress?.stars ?? 0;

        return _buildLevelTile(
          level: level,
          levelNum: index + 1,
          stars: stars,
          isUnlocked: isUnlocked,
          isCompleted: progress?.completed ?? false,
          onTap: isUnlocked ? () => _startLevel(level) : null,
        );
      },
    );
  }

  Widget _buildLevelTile({
    required Level level,
    required int levelNum,
    required int stars,
    required bool isUnlocked,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    final isBoss = levelNum == 20;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.surface.withValues(alpha: 0.92)
              : VerkstadTokens.pencil.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isBoss ? AppColors.warning : VerkstadTokens.pencil.withValues(alpha: 0.35),
            width: isBoss ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isUnlocked)
              Icon(
                Icons.lock,
                color: Colors.white54,
                size: 28,
              )
            else
              Text(
                '$levelNum',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (isCompleted) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return BrassStar(filled: i < stars, size: 12);
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startLevel(Level level) {
    final provider = context.read<GameProvider>();
    
    if (provider.progress.currentLives <= 0) {
      _showNoLivesDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(levelId: level.id),
      ),
    );
  }

  void _showNoLivesDialog() {
    final l10n = AppLocalizations.of(context);
    final provider = context.read<GameProvider>();
    final timeUntilLife = provider.progress.timeUntilNextLife;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.noLives, style: const TextStyle(color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, color: AppColors.lifeColor, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.waitForLife,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (timeUntilLife != null) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.newLifeIn}: ${timeUntilLife.inMinutes}:${(timeUntilLife.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.text),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(context);
              _watchAdForLife();
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l10n.watchAd),
          ),
        ],
      ),
    );
  }

  Future<void> _watchAdForLife() async {
    final provider = context.read<GameProvider>();
    final result = await context.read<AdService>().showRewarded(
          placement: 'life',
          rewardType: 'life',
          rewardAmount: 1,
        );
    if (!mounted) return;
    if (result.granted) {
      provider.addLives(1);
    } else if (result.messageSv.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.messageSv)));
    }
  }
}
