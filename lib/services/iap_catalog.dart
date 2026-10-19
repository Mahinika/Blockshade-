/// Play product ids. The analytics plan's short names (`hints_s`, `coins_500`)
/// were assumptions; these match the ids already used in the client and the
/// names to create in Play Console.
class IapProducts {
  static const String removeAds = 'se.cognifox.blockshade.remove_ads';
  static const String starterPack = 'se.cognifox.blockshade.starter_pack';
  static const String hintsSmall = 'se.cognifox.blockshade.hints_small';
  static const String hintsMedium = 'se.cognifox.blockshade.hints_medium';
  static const String hintsLarge = 'se.cognifox.blockshade.hints_large';
  static const String extraMoves = 'se.cognifox.blockshade.extra_moves';
  static const String coinsSmall = 'se.cognifox.blockshade.coins_small';
  static const String coinsLarge = 'se.cognifox.blockshade.coins_large';

  static const Set<String> all = {
    removeAds,
    starterPack,
    hintsSmall,
    hintsMedium,
    hintsLarge,
    extraMoves,
    coinsSmall,
    coinsLarge,
  };

  static const Set<String> nonConsumable = {removeAds, starterPack};

  static const int starterPackHints = 10;
  static const int hintsSmallCount = 5;
  static const int hintsMediumCount = 15;
  static const int hintsLargeCount = 40;
  static const int coinsSmallCount = 500;
  static const int coinsLargeCount = 2000;
  static const int extraMoveCreditsPerPurchase = 1;

  /// Proposed Play Console prices in SEK. Shown only until [ProductDetails] loads.
  static const Map<String, int> proposedPriceSek = {
    removeAds: 39,
    starterPack: 49,
    hintsSmall: 19,
    hintsMedium: 39,
    hintsLarge: 99,
    extraMoves: 12,
    coinsSmall: 19,
    coinsLarge: 49,
  };

  static bool isKnown(String productId) => all.contains(productId);

  static bool isConsumable(String productId) =>
      isKnown(productId) && !nonConsumable.contains(productId);

  static bool removesAds(String productId) =>
      productId == removeAds || productId == starterPack;

  static int hintsFor(String productId) {
    switch (productId) {
      case starterPack:
        return starterPackHints;
      case hintsSmall:
        return hintsSmallCount;
      case hintsMedium:
        return hintsMediumCount;
      case hintsLarge:
        return hintsLargeCount;
      default:
        return 0;
    }
  }

  static int coinsFor(String productId) {
    switch (productId) {
      case coinsSmall:
        return coinsSmallCount;
      case coinsLarge:
        return coinsLargeCount;
      default:
        return 0;
    }
  }

  static int extraMoveCreditsFor(String productId) =>
      productId == extraMoves ? extraMoveCreditsPerPurchase : 0;

  static String fallbackPriceLabel(String productId) {
    final sek = proposedPriceSek[productId];
    if (sek == null) return '';
    return '$sek kr';
  }
}

/// What the game should apply after a verified purchase update.
class IapGrant {
  const IapGrant({
    required this.productId,
    required this.restored,
    required this.firstUnlock,
    required this.countsAsPurchase,
    required this.hints,
    required this.coins,
    required this.extraMoveCredits,
    required this.removesAds,
  });

  final String productId;
  final bool restored;
  final bool firstUnlock;
  final bool countsAsPurchase;
  final int hints;
  final int coins;
  final int extraMoveCredits;
  final bool removesAds;
}

enum IapPurchaseStatus { pending, purchased, restored, error, canceled }

class IncomingPurchase {
  const IncomingPurchase({
    required this.productId,
    required this.status,
    required this.pendingCompletePurchase,
    this.purchaseId,
    this.errorCode,
    this.localVerificationData = '',
  });

  final String productId;
  final IapPurchaseStatus status;
  final bool pendingCompletePurchase;
  final String? purchaseId;
  final String? errorCode;
  final String localVerificationData;
}

class PurchaseAction {
  const PurchaseAction({
    required this.completePurchase,
    required this.grant,
    required this.persistOwnership,
    required this.rememberPurchaseId,
    this.grantDetails,
    this.analyticsEvent,
    this.failStatus,
    this.errorCode,
  });

  final bool completePurchase;
  final bool grant;
  final bool persistOwnership;
  final bool rememberPurchaseId;
  final IapGrant? grantDetails;

  /// `iap_purchase_complete` or `iap_purchase_fail`. Never `purchase`.
  final String? analyticsEvent;
  final String? failStatus;
  final String? errorCode;

  static const ignore = PurchaseAction(
    completePurchase: false,
    grant: false,
    persistOwnership: false,
    rememberPurchaseId: false,
  );
}

class PurchaseVerifier {
  const PurchaseVerifier();

  PurchaseAction decide({
    required IncomingPurchase purchase,
    required Set<String> ownedNonConsumables,
    required Set<String> processedPurchaseIds,
  }) {
    switch (purchase.status) {
      case IapPurchaseStatus.pending:
        return PurchaseAction.ignore;
      case IapPurchaseStatus.error:
      case IapPurchaseStatus.canceled:
        return PurchaseAction(
          completePurchase: purchase.pendingCompletePurchase,
          grant: false,
          persistOwnership: false,
          rememberPurchaseId: false,
          analyticsEvent: 'iap_purchase_fail',
          failStatus: purchase.status == IapPurchaseStatus.canceled ? 'canceled' : 'error',
          errorCode: purchase.errorCode,
        );
      case IapPurchaseStatus.purchased:
      case IapPurchaseStatus.restored:
        return _verified(purchase, ownedNonConsumables, processedPurchaseIds);
    }
  }

  PurchaseAction _verified(
    IncomingPurchase purchase,
    Set<String> owned,
    Set<String> processed,
  ) {
    final restored = purchase.status == IapPurchaseStatus.restored;
    if (!IapProducts.isKnown(purchase.productId) || !_hasLocalProof(purchase)) {
      return PurchaseAction(
        completePurchase: false,
        grant: false,
        persistOwnership: false,
        rememberPurchaseId: false,
        analyticsEvent: 'iap_purchase_fail',
        failStatus: 'error',
        errorCode: 'verification_failed',
      );
    }

    final id = purchase.purchaseId;
    if (id != null && id.isNotEmpty && processed.contains(id)) {
      return PurchaseAction(
        completePurchase: purchase.pendingCompletePurchase,
        grant: false,
        persistOwnership: false,
        rememberPurchaseId: false,
      );
    }

    if (IapProducts.isConsumable(purchase.productId)) {
      if (restored) {
        return PurchaseAction(
          completePurchase: purchase.pendingCompletePurchase,
          grant: false,
          persistOwnership: false,
          rememberPurchaseId: id != null && id.isNotEmpty,
        );
      }
      return PurchaseAction(
        completePurchase: purchase.pendingCompletePurchase,
        grant: true,
        persistOwnership: false,
        rememberPurchaseId: id != null && id.isNotEmpty,
        grantDetails: _grant(purchase.productId, restored: false, firstUnlock: false, counts: true),
        analyticsEvent: 'iap_purchase_complete',
      );
    }

    final alreadyOwned = owned.contains(purchase.productId);
    final firstUnlock = !alreadyOwned;
    return PurchaseAction(
      completePurchase: purchase.pendingCompletePurchase,
      grant: true,
      persistOwnership: true,
      rememberPurchaseId: id != null && id.isNotEmpty,
      grantDetails: _grant(
        purchase.productId,
        restored: restored,
        firstUnlock: firstUnlock,
        counts: !restored,
      ),
      analyticsEvent: restored ? null : 'iap_purchase_complete',
    );
  }

  bool _hasLocalProof(IncomingPurchase purchase) {
    final id = purchase.purchaseId;
    if (id != null && id.isNotEmpty) return true;
    return purchase.localVerificationData.isNotEmpty;
  }

  IapGrant _grant(
    String productId, {
    required bool restored,
    required bool firstUnlock,
    required bool counts,
  }) {
    final grantHints = IapProducts.isConsumable(productId) || firstUnlock;
    return IapGrant(
      productId: productId,
      restored: restored,
      firstUnlock: firstUnlock,
      countsAsPurchase: counts,
      hints: grantHints ? IapProducts.hintsFor(productId) : 0,
      coins: IapProducts.isConsumable(productId) ? IapProducts.coinsFor(productId) : 0,
      extraMoveCredits:
          IapProducts.isConsumable(productId) ? IapProducts.extraMoveCreditsFor(productId) : 0,
      removesAds: IapProducts.removesAds(productId),
    );
  }
}
