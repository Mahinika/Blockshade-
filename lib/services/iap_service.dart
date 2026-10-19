import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

// TODO: Replace with real product IDs from Google Play Console before release
class IAPProducts {
  static const String removeAds = 'se.cognifox.blockshade.remove_ads';
  static const String starterPack = 'se.cognifox.blockshade.starter_pack';
  static const String coinPackSmall = 'se.cognifox.blockshade.coins_small';
  static const String coinPackLarge = 'se.cognifox.blockshade.coins_large';
  static const String extraMoves = 'se.cognifox.blockshade.extra_moves';

  static const Set<String> allProducts = {
    removeAds,
    starterPack,
    coinPackSmall,
    coinPackLarge,
    extraMoves,
  };

  static const Map<String, int> coinRewards = {
    coinPackSmall: 500,
    coinPackLarge: 2000,
  };
}

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  List<ProductDetails> _products = [];
  final Set<String> _purchasedProducts = {};

  Function(String productId)? onPurchaseSuccess;
  Function(String error)? onPurchaseError;

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;
  bool get hasRemovedAds => _purchasedProducts.contains(IAPProducts.removeAds);
  bool get hasStarterPack => _purchasedProducts.contains(IAPProducts.starterPack);

  Future<void> init() async {
    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        print('IAP not available (Play Store not present or not signed in)');
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('Purchase stream error: $error'),
      );

      try {
        await _loadProducts();
      } catch (e) {
        print('Failed to load IAP products: $e');
      }
      
      try {
        await _restorePurchases();
      } catch (e) {
        print('Failed to restore purchases: $e');
      }
    } catch (e) {
      print('IAP init failed: $e');
      _available = false;
    }
  }

  Future<void> _loadProducts() async {
    if (!_available) return;
    
    try {
      final response = await _iap.queryProductDetails(IAPProducts.allProducts);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      print('Loaded ${_products.length} products');
    } catch (e) {
      print('Error loading products: $e');
      _products = [];
    }
  }

  Future<void> _restorePurchases() async {
    if (!_available) return;
    
    try {
      await _iap.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.pending) {
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      onPurchaseError?.call(purchase.error?.message ?? 'Unknown error');
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      _purchasedProducts.add(purchase.productID);
      onPurchaseSuccess?.call(purchase.productID);
    }

    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> buyProduct(String productId) async {
    final product = getProduct(productId);
    if (product == null) {
      onPurchaseError?.call('Product not found');
      return false;
    }

    final isConsumable = productId == IAPProducts.coinPackSmall ||
        productId == IAPProducts.coinPackLarge ||
        productId == IAPProducts.extraMoves;

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      if (isConsumable) {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
      return true;
    } catch (e) {
      onPurchaseError?.call(e.toString());
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    
    try {
      await _iap.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
