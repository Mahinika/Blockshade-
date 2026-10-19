import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(provider, l10n),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 48),
                    _buildPlayButton(context, l10n),
                  ],
                ),
              ),
            ),
            _buildFooter(context, l10n),
          ],
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
          _buildResourceDisplay(
            Icons.favorite,
            '${provider.progress.currentLives}/$maxLives',
            AppColors.lifeColor,
          ),
          _buildResourceDisplay(
            Icons.monetization_on,
            '${provider.progress.coins}',
            AppColors.coinColor,
          ),
          _buildResourceDisplay(
            Icons.star,
            '${provider.progress.totalStars}',
            AppColors.starFilled,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceDisplay(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  static const int maxLives = 5;

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
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
            fontSize: 42,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildWorldButton(context, 1, l10n.worldName(1), AppColors.primary),
        const SizedBox(height: 16),
        _buildWorldButton(context, 2, l10n.worldName(2), Colors.teal),
        const SizedBox(height: 16),
        _buildWorldButton(context, 3, l10n.worldName(3), Colors.indigo),
      ],
    );
  }

  Widget _buildWorldButton(BuildContext context, int world, String name, Color color) {
    final provider = context.read<GameProvider>();
    final stars = provider.progress.getStarsForWorld(world);
    final maxStars = 20 * 3;

    return SizedBox(
      width: 250,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorldMapScreen(world: world),
            ),
          );
        },
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 16, color: AppColors.starFilled),
                const SizedBox(width: 4),
                Text(
                  '$stars / $maxStars',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterButton(
            context,
            Icons.shopping_bag,
            l10n.shop,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShopScreen()),
            ),
          ),
          _buildFooterButton(
            context,
            Icons.settings,
            l10n.settings,
            () => _showSettingsDialog(context, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.text, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.settings, style: const TextStyle(color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingRow(l10n.sound, true, (v) {}),
            _buildSettingRow(l10n.music, true, (v) {}),
            _buildSettingRow(l10n.vibration, true, (v) {}),
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
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
