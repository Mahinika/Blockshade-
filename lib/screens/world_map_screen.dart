import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../services/services.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
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
        backgroundColor: theme.primaryColor,
        title: Text('${l10n.world} ${widget.world}: ${theme.name}'),
        actions: [
          _buildResourceChip(
            Icons.star,
            '${provider.progress.getStarsForWorld(widget.world)}',
            AppColors.starFilled,
          ),
          const SizedBox(width: 8),
          _buildResourceChip(
            Icons.monetization_on,
            '${provider.progress.coins}',
            AppColors.coinColor,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLevelGrid(provider, l10n),
    );
  }

  Widget _buildResourceChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    final theme = WorldThemes.getTheme(widget.world);
    final isBoss = levelNum == 20;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? theme.primaryColor : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(12),
          border: isBoss
              ? Border.all(color: AppColors.warning, width: 3)
              : null,
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
                  return Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: AppColors.starFilled,
                    size: 14,
                  );
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

  void _watchAdForLife() {
    final adService = context.read<AdService>();
    final provider = context.read<GameProvider>();

    if (adService.isRewardedAdReady) {
      adService.showRewardedAd(
        onRewarded: (amount) {
          provider.addLives(1);
        },
        onAdDismissed: () {},
      );
    } else {
      provider.addLives(1);
    }
  }
}
