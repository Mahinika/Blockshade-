import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/services.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<GameProvider>();
    final iapService = context.read<IAPService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.shop),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppColors.coinColor, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${provider.progress.coins}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!provider.progress.starterPackPurchased)
            _buildStarterPackCard(context, provider, iapService, l10n),
          
          const SizedBox(height: 16),
          _buildSectionTitle('Annonser'),
          if (!provider.progress.adsRemoved)
            _buildShopItem(
              context: context,
              icon: Icons.block,
              title: l10n.removeAds,
              subtitle: 'Ta bort mellanliggande annonser',
              price: '29 kr',
              color: AppColors.error,
              onTap: () => _purchaseRemoveAds(context, provider, iapService),
            )
          else
            _buildPurchasedItem(
              icon: Icons.check_circle,
              title: l10n.removeAds,
              subtitle: 'Annonser borttagna',
            ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Mynt'),
          _buildShopItem(
            context: context,
            icon: Icons.monetization_on,
            title: l10n.coinPackSmall,
            subtitle: '500 mynt',
            price: '29 kr',
            color: AppColors.coinColor,
            onTap: () => _purchaseCoins(context, provider, iapService, 500),
          ),
          const SizedBox(height: 12),
          _buildShopItem(
            context: context,
            icon: Icons.monetization_on,
            title: l10n.coinPackLarge,
            subtitle: '2000 mynt + 500 bonus',
            price: '99 kr',
            color: AppColors.coinColor,
            featured: true,
            onTap: () => _purchaseCoins(context, provider, iapService, 2500),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Boosters'),
          _buildShopItem(
            context: context,
            icon: Icons.undo,
            title: 'Ångra x5',
            subtitle: 'Backa ett drag',
            price: '200 mynt',
            color: AppColors.primary,
            isCoinPurchase: true,
            onTap: () => _purchaseBooster(context, provider, 200, 5),
          ),
          
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => iapService.restorePurchases(),
              child: Text(
                l10n.restorePurchases,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStarterPackCard(
    BuildContext context,
    GameProvider provider,
    IAPService iapService,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                l10n.starterPack,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '-50%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPackItem(Icons.block, 'Ta bort annonser'),
          _buildPackItem(Icons.monetization_on, '1500 mynt'),
          _buildPackItem(Icons.undo, '3x Ångra'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _purchaseStarterPack(context, provider, iapService),
              child: const Text(
                '19 kr',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
    required Color color,
    required VoidCallback onTap,
    bool featured = false,
    bool isCoinPurchase = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: featured ? Border.all(color: AppColors.warning, width: 2) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isCoinPurchase ? AppColors.coinColor : AppColors.primary,
            foregroundColor: isCoinPurchase ? Colors.black : Colors.white,
          ),
          onPressed: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCoinPurchase)
                const Icon(Icons.monetization_on, size: 16),
              if (isCoinPurchase) const SizedBox(width: 4),
              Text(price),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasedItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.success, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.success),
        ),
      ),
    );
  }

  void _purchaseStarterPack(BuildContext context, GameProvider provider, IAPService iapService) {
    iapService.buyProduct(IAPProducts.starterPack);
    iapService.onPurchaseSuccess = (productId) {
      if (productId == IAPProducts.starterPack) {
        provider.purchaseStarterPack();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Startpaket köpt!')),
        );
      }
    };
  }

  void _purchaseRemoveAds(BuildContext context, GameProvider provider, IAPService iapService) {
    iapService.buyProduct(IAPProducts.removeAds);
    iapService.onPurchaseSuccess = (productId) {
      if (productId == IAPProducts.removeAds) {
        provider.removeAds();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonser borttagna!')),
        );
      }
    };
  }

  void _purchaseCoins(BuildContext context, GameProvider provider, IAPService iapService, int amount) {
    final productId = amount <= 500 ? IAPProducts.coinPackSmall : IAPProducts.coinPackLarge;
    iapService.buyProduct(productId);
    iapService.onPurchaseSuccess = (purchasedId) {
      if (purchasedId == productId) {
        provider.addCoins(amount, 'iap');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$amount mynt tillagda!')),
        );
      }
    };
  }

  void _purchaseBooster(BuildContext context, GameProvider provider, int coinCost, int amount) {
    if (provider.progress.coins < coinCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inte tillräckligt med mynt')),
      );
      return;
    }
    
    provider.addUndoBoosters(amount);
    provider.progress.spendCoins(coinCost);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$amount Ångra tillagda!')),
    );
  }
}
