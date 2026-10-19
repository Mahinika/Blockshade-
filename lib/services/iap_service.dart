import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'analytics_service.dart';
import 'iap_catalog.dart';

class IapUiEvent {
  const IapUiEvent({required this.kind, required this.messageSv, this.productId});

  final String kind;
  final String messageSv;
  final String? productId;
}

abstract class BillingGateway {
  Future<bool> isAvailable();
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<void> restorePurchases();
  Future<bool> buyConsumable({required PurchaseParam purchaseParam});
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Future<void> completePurchase(PurchaseDetails purchase);
}

class PluginBillingGateway implements BillingGateway {
  PluginBillingGateway([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _iap.queryProductDetails(identifiers);

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyConsumable(purchaseParam: purchaseParam);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) => _iap.completePurchase(purchase);
}

abstract class IapEntitlementStore {
  Future<Set<String>> loadOwnedProducts();
  Future<void> saveOwnedProducts(Set<String> ids);
  Future<List<String>> loadProcessedPurchaseIds();
  Future<void> saveProcessedPurchaseIds(List<String> ids);
  Future<bool> loadHasCompletedPurchase();
  Future<void> saveHasCompletedPurchase(bool value);
}

class IAPService extends ChangeNotifier {
  IAPService({
    BillingGateway? gateway,
    required AnalyticsService analytics,
    required IapEntitlementStore store,
    PurchaseVerifier? verifier,
    this.onGrant,
  })  : _gateway = gateway ?? PluginBillingGateway(),
        _analytics = analytics,
        _store = store,
        _verifier = verifier ?? const PurchaseVerifier();

  final BillingGateway _gateway;
  final AnalyticsService _analytics;
  final IapEntitlementStore _store;
  final PurchaseVerifier _verifier;

  /// Applies a verified entitlement. Must be set before [init] restores purchases.
  Future<void> Function(IapGrant grant)? onGrant;

  final StreamController<IapUiEvent> _events = StreamController<IapUiEvent>.broadcast();
  Stream<IapUiEvent> get events => _events.stream;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false;
  List<ProductDetails> _products = [];
  final Set<String> _owned = {};
  final List<String> _processedIds = [];
  final Map<String, String> _placement = {};
  bool _hasCompletedPurchase = false;
  bool _userRestore = false;
  int _userRestoreCount = 0;
  Duration restoreSettleDelay = const Duration(milliseconds: 1500);

  bool get isAvailable => _available;
  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get hasRemovedAds =>
      _owned.contains(IapProducts.removeAds) || _owned.contains(IapProducts.starterPack);
  bool get hasStarterPack => _owned.contains(IapProducts.starterPack);
  Set<String> get ownedProducts => Set.unmodifiable(_owned);

  String priceLabel(String productId) {
    final product = getProduct(productId);
    final storePrice = product?.price ?? '';
    if (storePrice.isNotEmpty) return storePrice;
    return IapProducts.fallbackPriceLabel(productId);
  }

  ProductDetails? getProduct(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<void> init() async {
    try {
      _owned.addAll(await _store.loadOwnedProducts());
      _processedIds.addAll(await _store.loadProcessedPurchaseIds());
      _hasCompletedPurchase = await _store.loadHasCompletedPurchase();
    } catch (e) {
      debugPrint('IAP entitlement load failed: $e');
    }

    try {
      _available = await _gateway.isAvailable();
    } catch (e) {
      debugPrint('IAP availability check failed: $e');
      _available = false;
    }
    if (!_available) {
      notifyListeners();
      return;
    }

    _subscription = _gateway.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) => debugPrint('Purchase stream error: $error'),
    );

    try {
      await _loadProducts();
    } catch (e) {
      debugPrint('Failed to load IAP products: $e');
    }

    try {
      await _gateway.restorePurchases();
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
    }

    if (hasRemovedAds) {
      try {
        await onGrant?.call(IapGrant(
          productId: hasStarterPack ? IapProducts.starterPack : IapProducts.removeAds,
          restored: true,
          firstUnlock: false,
          countsAsPurchase: false,
          hints: 0,
          coins: 0,
          extraMoveCredits: 0,
          removesAds: true,
        ));
      } catch (e) {
        debugPrint('Syncing remove-ads entitlement failed: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final response = await _gateway.queryProductDetails(IapProducts.all);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
    }
    _products = response.productDetails;
    notifyListeners();
  }

  Future<bool> buyProduct(String productId, {required String placement}) async {
    final product = getProduct(productId);
    final label = priceLabel(productId);
    _placement[productId] = placement;
    if (product == null) {
      await _analytics.logIapPurchaseFail(
        productId: productId,
        placement: placement,
        status: 'error',
        errorCode: 'product_unavailable',
      );
      _emit(IapUiEvent(
        kind: 'error',
        messageSv: 'Köpet kunde inte genomföras.',
        productId: productId,
      ));
      return false;
    }

    await _analytics.logIapPurchaseStart(
      productId: productId,
      placement: placement,
      priceLabel: label,
    );

    final param = PurchaseParam(productDetails: product);
    try {
      if (IapProducts.isConsumable(productId)) {
        return await _gateway.buyConsumable(purchaseParam: param);
      }
      return await _gateway.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('buyProduct failed: $e');
      await _analytics.logIapPurchaseFail(
        productId: productId,
        placement: placement,
        status: 'error',
        errorCode: 'buy_threw',
      );
      _emit(const IapUiEvent(kind: 'error', messageSv: 'Köpet kunde inte genomföras.'));
      return false;
    }
  }

  /// User tapped "Återställ köp". Returns `restored`, `nothing`, or `error`.
  Future<String> restorePurchases() async {
    if (!_available) {
      await _analytics.logIapRestore(result: 'error', restoredCount: 0);
      _emit(const IapUiEvent(
        kind: 'restore',
        messageSv: 'Köpen kunde inte återställas just nu.',
      ));
      return 'error';
    }
    _userRestore = true;
    _userRestoreCount = 0;
    try {
      await _gateway.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases failed: $e');
      _userRestore = false;
      await _analytics.logIapRestore(result: 'error', restoredCount: 0);
      _emit(const IapUiEvent(
        kind: 'restore',
        messageSv: 'Köpen kunde inte återställas just nu.',
      ));
      return 'error';
    }

    // Play delivers restored purchases on the stream after this call returns.
    await Future<void>.delayed(restoreSettleDelay);
    final count = _userRestoreCount;
    final result = count > 0 ? 'restored' : 'nothing';
    _userRestore = false;
    await _analytics.logIapRestore(result: result, restoredCount: count);
    _emit(IapUiEvent(
      kind: 'restore',
      messageSv: count > 0 ? 'Köpen är återställda.' : 'Inga tidigare köp att återställa.',
    ));
    return result;
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    if (purchases.isEmpty) return;
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    var actionGrantWasFirst = false;
    final incoming = IncomingPurchase(
      productId: purchase.productID,
      status: _mapStatus(purchase.status),
      pendingCompletePurchase: purchase.pendingCompletePurchase,
      purchaseId: purchase.purchaseID,
      errorCode: purchase.error?.code,
      localVerificationData: purchase.verificationData.localVerificationData,
    );
    final action = _verifier.decide(
      purchase: incoming,
      ownedNonConsumables: _owned,
      processedPurchaseIds: _processedIds.toSet(),
    );

    if (action.grant && action.grantDetails != null) {
      try {
        await onGrant?.call(action.grantDetails!);
      } catch (e) {
        debugPrint('Grant failed, purchase left incomplete: $e');
        return;
      }
      if (action.persistOwnership) {
        _owned.add(purchase.productID);
        try {
          await _store.saveOwnedProducts(_owned);
        } catch (e) {
          debugPrint('Failed to persist ownership: $e');
        }
      }
      final wasFirstPurchase = !_hasCompletedPurchase && action.grantDetails!.countsAsPurchase;
      if (wasFirstPurchase) {
        _hasCompletedPurchase = true;
        try {
          await _store.saveHasCompletedPurchase(true);
        } catch (e) {
          debugPrint('Failed to persist payer flag: $e');
        }
      }
      actionGrantWasFirst = wasFirstPurchase;
      if (_userRestore &&
          purchase.status == PurchaseStatus.restored &&
          IapProducts.removesAds(purchase.productID)) {
        _userRestoreCount += 1;
      }
    }

    if (action.rememberPurchaseId) {
      final id = purchase.purchaseID;
      if (id != null && id.isNotEmpty && !_processedIds.contains(id)) {
        _processedIds.add(id);
        if (_processedIds.length > 80) {
          _processedIds.removeRange(0, _processedIds.length - 80);
        }
        try {
          await _store.saveProcessedPurchaseIds(_processedIds);
        } catch (e) {
          debugPrint('Failed to persist purchase ids: $e');
        }
      }
    }

    if (action.completePurchase) {
      try {
        await _gateway.completePurchase(purchase);
      } catch (e) {
        debugPrint('completePurchase failed: $e');
      }
    }

    final placement = _placement[purchase.productID] ?? 'store';
    if (action.analyticsEvent == AnalyticsEvents.iapPurchaseComplete && action.grantDetails != null) {
      await _analytics.logIapPurchaseComplete(
        productId: purchase.productID,
        placement: placement,
        isFirstPurchase: actionGrantWasFirst,
      );
      _emit(IapUiEvent(
        kind: 'purchased',
        messageSv: 'Köpet är klart.',
        productId: purchase.productID,
      ));
    } else if (action.analyticsEvent == AnalyticsEvents.iapPurchaseFail) {
      await _analytics.logIapPurchaseFail(
        productId: purchase.productID,
        placement: placement,
        status: action.failStatus ?? 'error',
        errorCode: action.errorCode,
      );
      if (purchase.status != PurchaseStatus.canceled) {
        _emit(IapUiEvent(
          kind: 'error',
          messageSv: 'Köpet kunde inte genomföras.',
          productId: purchase.productID,
        ));
      }
    } else if (purchase.status == PurchaseStatus.pending) {
      _emit(IapUiEvent(
        kind: 'pending',
        messageSv: 'Köpet väntar på godkännande.',
        productId: purchase.productID,
      ));
    }

    notifyListeners();
  }

  IapPurchaseStatus _mapStatus(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.pending:
        return IapPurchaseStatus.pending;
      case PurchaseStatus.purchased:
        return IapPurchaseStatus.purchased;
      case PurchaseStatus.restored:
        return IapPurchaseStatus.restored;
      case PurchaseStatus.error:
        return IapPurchaseStatus.error;
      case PurchaseStatus.canceled:
        return IapPurchaseStatus.canceled;
    }
  }

  void _emit(IapUiEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _events.close();
    super.dispose();
  }
}
