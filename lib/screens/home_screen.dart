import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/daily_puzzle_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import 'game_screen.dart';
import '../theme/verkstad_tokens.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
import '../widgets/brass_star.dart';
import '../widgets/masking_tape.dart';
import '../widgets/workshop_background.dart';
import 'world_map_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: WorkshopBackground(
        world: 1,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(provider, l10n),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(context),
                      const SizedBox(height: 40),
                      _buildDailyPuzzle(context, provider, l10n),
                      const SizedBox(height: 20),
                      _buildPlayButtons(context, l10n),
                    ],
                  ),
                ),
              ),
              _buildFooter(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GameProvider provider, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildResourceTape(Icons.favorite, '${provider.progress.currentLives}/$maxLives', AppColors.lifeColor),
          _buildResourceTape(Icons.monetization_on, '${provider.progress.coins}', AppColors.coinColor),
          _buildResourceTape(Icons.star, '${provider.progress.totalStars}', AppColors.starFilled, star: true),
        ],
      ),
    );
  }

  Widget _buildResourceTape(IconData icon, String value, Color color, {bool star = false}) {
    return MaskingTape(
      showPin: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (star)
            const BrassStar(filled: true, size: 16)
          else
            Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(value),
        ],
      ),
    );
  }

  static const int maxLives = 5;

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        MaskingTape(
          rotation: -0.02,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'Blockshade',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 12),
        MaskingTape(
          showPin: false,
          rotation: 0.03,
          child: const Text(
            'Trä, papper och skuggor',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPuzzle(
    BuildContext context,
    GameProvider provider,
    AppLocalizations l10n,
  ) {
    final today = DateTime.now();
    final completed = provider.progress.isDailyCompletedOn(today);
    final streak = provider.progress.dailyStreak;

    return Column(
      children: [
        SizedBox(
          width: 280,
          child: MaskingTapeButton(
            label: completed ? '${l10n.dailyPuzzle} ✓' : l10n.dailyPuzzle,
            icon: Icons.calendar_today,
            onPressed: () {
              final levelId = DailyPuzzleService.levelIdForDate(today);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(levelId: levelId),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        MaskingTape(
          showPin: true,
          rotation: 0.02,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            '${l10n.dailyStreak}: $streak${completed ? ' · ${l10n.dailyComplete}' : ''}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildWorldButton(context, 1, l10n.worldName(1)),
        const SizedBox(height: 14),
        _buildWorldButton(context, 2, l10n.worldName(2)),
        const SizedBox(height: 14),
        _buildWorldButton(context, 3, l10n.worldName(3)),
      ],
    );
  }

  Widget _buildWorldButton(BuildContext context, int world, String name) {
    final provider = context.read<GameProvider>();
    final stars = provider.progress.getStarsForWorld(world);
    final maxStars = 20 * 3;

    return Column(
      children: [
        SizedBox(
          width: 260,
          child: MaskingTapeButton(
            label: name,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorldMapScreen(world: world),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$stars / $maxStars',
          style: TextStyle(
            color: VerkstadTokens.ink.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          MaskingTapeButton(
            label: l10n.shop,
            icon: Icons.shopping_bag_outlined,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShopScreen()),
            ),
          ),
          MaskingTapeButton(
            label: l10n.settings,
            icon: Icons.tune,
            onPressed: () => _showSettingsDialog(context, l10n),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VerkstadTokens.maskingTape,
        title: Text(l10n.settings, style: const TextStyle(color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingRow(l10n.sound, SoundService.instance.sfxEnabled, (v) {
              SoundService.instance.setSfxEnabled(v);
            }),
            _buildSettingRow(l10n.music, SoundService.instance.musicEnabled, (v) {
              SoundService.instance.setMusicEnabled(v);
            }),
            _buildSettingRow(l10n.vibration, HapticService.instance.isEnabled, (v) {
              HapticService.instance.setEnabled(v);
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.text)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: VerkstadTokens.brassPin,
          ),
        ],
      ),
    );
  }
}
