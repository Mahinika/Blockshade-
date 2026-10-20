import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../services/services.dart';
import '../theme/verkstad_tokens.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
import '../widgets/masking_tape.dart';
import '../widgets/workshop_background.dart';
import '../widgets/wood_panel_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.entryPoint = 'home'});

  final String entryPoint;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  StreamSubscription<IapUiEvent>? _events;
  bool _loggedOffers = false;

  @override
  void initState() {
    super.initState();
    final iap = context.read<IAPService>();
    _events = iap.events.listen(_onIapEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _logOffers());
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  void _onIapEvent(IapUiEvent event) {
    if (!mounted || event.messageSv.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(event.messageSv)));
  }

  void _logOffers() {
    if (!mounted || _loggedOffers) return;
    _loggedOffers = true;
    final iap = context.read<IAPService>();
    final analytics = context.read<AnalyticsService>();
    analytics.logStoreOpen(entryPoint: widget.entryPoint);
    for (final productId in IapProducts.all) {
      analytics.logIapOfferShown(
        productId: productId,
        placement: 'store',
        trigger: 'store_open',
        priceLabel: iap.priceLabel(productId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<GameProvider>();
    final iapService = context.watch<IAPService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: WorkshopBackground(
        world: 1,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    MaskingTapeButton(
                      label: '←',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MaskingTape(
                        child: Text(
                          l10n.shop,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    MaskingTape(
                      showPin: false,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on, color: VerkstadTokens.coinInk, size: 18),
                          const SizedBox(width: 4),
                          Text('${provider.progress.coins}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!provider.progress.starterPackPurchased)
                      _buildStarterPackCard(context, provider, iapService, l10n),
                    const SizedBox(height: 16),
                    _buildSectionTape('Annonser'),
                    if (!provider.progress.adsRemoved)
                      _buildShopItem(
                        context: context,
                        seed: 3,
                        icon: Icons.block,
                        title: l10n.removeAds,
                        subtitle: 'Ta bort mellanliggande annonser',
                        price: iapService.priceLabel(IapProducts.removeAds),
                        color: AppColors.error,
                        onTap: () => _purchaseRemoveAds(context, iapService),
                      )
                    else
                      _buildPurchasedItem(
                        icon: Icons.check_circle,
                        title: l10n.removeAds,
                        subtitle: 'Annonser borttagna',
                      ),
                    const SizedBox(height: 20),
                    _buildSectionTape('Mynt'),
                    _buildShopItem(
                      context: context,
                      seed: 5,
                      icon: Icons.monetization_on,
                      title: l10n.coinPackSmall,
                      subtitle: '500 mynt',
                      price: iapService.priceLabel(IapProducts.coinsSmall),
                      color: AppColors.coinColor,
                      onTap: () => _purchaseCoins(context, iapService, IapProducts.coinsSmall),
                    ),
                    const SizedBox(height: 12),
                    _buildShopItem(
                      context: context,
                      seed: 7,
                      icon: Icons.monetization_on,
                      title: l10n.coinPackLarge,
                      subtitle: '2000 mynt',
                      price: iapService.priceLabel(IapProducts.coinsLarge),
                      color: AppColors.coinColor,
                      featured: true,
                      onTap: () => _purchaseCoins(context, iapService, IapProducts.coinsLarge),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTape('Tips'),
                    _hintItem(context, iapService, l10n.hintsSmall, '5 tips', IapProducts.hintsSmall, 11),
                    const SizedBox(height: 12),
                    _hintItem(context, iapService, l10n.hintsMedium, '15 tips', IapProducts.hintsMedium, 13),
                    const SizedBox(height: 12),
                    _hintItem(context, iapService, l10n.hintsLarge, '40 tips', IapProducts.hintsLarge, 15, featured: true),
                    const SizedBox(height: 12),
                    _buildShopItem(
                      context: context,
                      seed: 17,
                      icon: Icons.more_time,
                      title: l10n.extraMovesPack,
                      subtitle: '+5 drag när banan tar slut',
                      price: iapService.priceLabel(IapProducts.extraMoves),
                      color: AppColors.primary,
                      onTap: () => iapService.buyProduct(IapProducts.extraMoves, placement: 'store'),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTape('Boosters'),
                    _buildShopItem(
                      context: context,
                      seed: 9,
                      icon: Icons.undo,
                      title: 'Ångra x5',
                      subtitle: 'Backa ett drag',
                      price: '200 mynt',
                      color: AppColors.primary,
                      isCoinPurchase: true,
                      onTap: () => _purchaseBooster(context, provider, 200, 5),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: MaskingTapeButton(
                        label: l10n.restorePurchases,
                        onPressed: () => iapService.restorePurchases(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTape(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: MaskingTape(
          rotation: -0.02,
          showPin: true,
          child: Text(title, style: const TextStyle(fontSize: 18)),
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
    return WoodPanelCard(
      seed: 21,
      featured: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MaskingTape(
                showPin: true,
                child: Text(
                  l10n.starterPack,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const Spacer(),
              MaskingTape(
                showPin: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Text('-50%', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPackItem(Icons.block, 'Ta bort annonser'),
          _buildPackItem(Icons.lightbulb_outline, '${IapProducts.starterPackHints} tips'),
          const SizedBox(height: 14),
          MaskingTapeButton(
            label: iapService.priceLabel(IapProducts.starterPack),
            onPressed: () => iapService.buyProduct(IapProducts.starterPack, placement: 'store'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: VerkstadTokens.ink.withValues(alpha: 0.75), size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildShopItem({
    required BuildContext context,
    required int seed,
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
    required Color color,
    required VoidCallback onTap,
    bool featured = false,
    bool isCoinPurchase = false,
  }) {
    return WoodPanelCard(
      seed: seed,
      featured: featured,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: VerkstadTokens.ink.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          MaskingTapeButton(
            label: price,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return WoodPanelCard(
      seed: 4,
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintItem(
    BuildContext context,
    IAPService iapService,
    String title,
    String subtitle,
    String productId,
    int seed, {
    bool featured = false,
  }) {
    return _buildShopItem(
      context: context,
      seed: seed,
      icon: Icons.lightbulb_outline,
      title: title,
      subtitle: subtitle,
      price: iapService.priceLabel(productId),
      color: AppColors.accent,
      featured: featured,
      onTap: () => iapService.buyProduct(productId, placement: 'store'),
    );
  }

  void _purchaseRemoveAds(BuildContext context, IAPService iapService) {
    iapService.buyProduct(IapProducts.removeAds, placement: 'store');
  }

  void _purchaseCoins(BuildContext context, IAPService iapService, String productId) {
    iapService.buyProduct(productId, placement: 'store');
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
