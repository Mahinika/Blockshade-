import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:blockshade/services/analytics_service.dart';
import 'package:blockshade/services/consent_mode.dart';
import 'package:blockshade/services/iap_catalog.dart';
import 'package:blockshade/services/iap_service.dart';

void main() {
  const verifier = PurchaseVerifier();

  IncomingPurchase incoming(IapPurchaseStatus status, {String id = IapProducts.removeAds, String? purchaseId = 't1', String proof = 'receipt', bool complete = true}) {
    return IncomingPurchase(
      productId: id,
      status: status,
      pendingCompletePurchase: complete,
      purchaseId: purchaseId,
      localVerificationData: proof,
    );
  }

  test('remove-ads is non-consumable, verified, and completed once', () {
    final action = verifier.decide(
      purchase: incoming(IapPurchaseStatus.purchased),
      ownedNonConsumables: {},
      processedPurchaseIds: {},
    );
    expect(action.grant, isTrue);
    expect(action.persistOwnership, isTrue);
    expect(action.completePurchase, isTrue);
    expect(action.grantDetails!.removesAds, isTrue);
    expect(action.grantDetails!.countsAsPurchase, isTrue);
    expect(action.analyticsEvent, 'iap_purchase_complete');

    final again = verifier.decide(
      purchase: incoming(IapPurchaseStatus.purchased),
      ownedNonConsumables: {IapProducts.removeAds},
      processedPurchaseIds: {'t1'},
    );
    expect(again.grant, isFalse);
    expect(again.completePurchase, isTrue);
  });

  test('restore grants remove-ads without a manual purchase event', () {
    final action = verifier.decide(
      purchase: incoming(IapPurchaseStatus.restored),
      ownedNonConsumables: {},
      processedPurchaseIds: {},
    );
    expect(action.grantDetails!.removesAds, isTrue);
    expect(action.grantDetails!.countsAsPurchase, isFalse);
    expect(action.analyticsEvent, isNull);
    expect(action.persistOwnership, isTrue);
  });

  test('starter pack grants hints only the first time', () {
    final first = verifier.decide(
      purchase: incoming(IapPurchaseStatus.purchased, id: IapProducts.starterPack, purchaseId: 's1'),
      ownedNonConsumables: {},
      processedPurchaseIds: {},
    );
    expect(first.grantDetails!.hints, IapProducts.starterPackHints);
    expect(first.grantDetails!.removesAds, isTrue);

    final restored = verifier.decide(
      purchase: incoming(IapPurchaseStatus.restored, id: IapProducts.starterPack, purchaseId: 's1'),
      ownedNonConsumables: {IapProducts.starterPack},
      processedPurchaseIds: {},
    );
    expect(restored.grantDetails!.hints, 0);
    expect(restored.grantDetails!.removesAds, isTrue);
  });

  test('failed and unverified purchases do not grant', () {
    final failed = verifier.decide(
      purchase: incoming(IapPurchaseStatus.error, purchaseId: null, proof: ''),
      ownedNonConsumables: {},
      processedPurchaseIds: {},
    );
    expect(failed.grant, isFalse);
    expect(failed.analyticsEvent, 'iap_purchase_fail');
    expect(failed.completePurchase, isTrue);

    final empty = verifier.decide(
      purchase: incoming(IapPurchaseStatus.purchased, purchaseId: '', proof: ''),
      ownedNonConsumables: {},
      processedPurchaseIds: {},
    );
    expect(empty.grant, isFalse);
    expect(empty.completePurchase, isFalse);
    expect(empty.errorCode, 'verification_failed');
  });

  test('pending does not complete or grant', () {
    final pending = verifier.decide(
      purchase: incoming(IapPurchaseStatus.pending),
      ownedNonConsumables: {},
      processedPurchaseIds: {},
    );
    expect(pending.grant, isFalse);
    expect(pending.completePurchase, isFalse);
    expect(pending.analyticsEvent, isNull);
  });

  test('service uses ProductDetails price and restores remove-ads', () async {
    final events = <String>[];
    final analytics = AnalyticsService(sink: (name, _) => events.add(name));
    await analytics.applyConsent(
      const ConsentModeMapper().decide(UmpConsentSnapshot(status: 'not_required', canRequestAds: true)),
      source: 'first_launch',
    );
    final store = _MemoryStore();
    final billing = _FakeBilling();
    IapGrant? granted;
    final iap = IAPService(gateway: billing, analytics: analytics, store: store, onGrant: (grant) async {
      granted = grant;
    });
    iap.restoreSettleDelay = Duration.zero;

    await iap.init();
    expect(iap.priceLabel(IapProducts.removeAds), '39 kr');
    expect(iap.priceLabel(IapProducts.hintsMedium), '39 kr');

    billing.emit(PurchaseDetails(
      purchaseID: 'order-1',
      productID: IapProducts.removeAds,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'signed',
        serverVerificationData: 'signed',
        source: 'google_play',
      ),
      transactionDate: '1',
      status: PurchaseStatus.restored,
    )..pendingCompletePurchase = true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(granted?.removesAds, isTrue);
    expect(store.owned, contains(IapProducts.removeAds));
    expect(billing.completed, hasLength(1));
    expect(events, isNot(contains('purchase')));
    expect(events, isNot(contains('in_app_purchase')));
    expect(events.where((name) => name == 'iap_purchase_complete'), isEmpty);

    final result = await iap.restorePurchases();
    expect(result, 'nothing');
    expect(events, contains('iap_restore'));
  });
}

class _MemoryStore implements IapEntitlementStore {
  Set<String> owned = {};
  List<String> processed = [];
  bool purchased = false;

  @override
  Future<bool> loadHasCompletedPurchase() async => purchased;

  @override
  Future<List<String>> loadProcessedPurchaseIds() async => processed;

  @override
  Future<Set<String>> loadOwnedProducts() async => owned;

  @override
  Future<void> saveHasCompletedPurchase(bool value) async => purchased = value;

  @override
  Future<void> saveOwnedProducts(Set<String> ids) async => owned = ids;

  @override
  Future<void> saveProcessedPurchaseIds(List<String> ids) async => processed = ids;
}

class _FakeBilling implements BillingGateway {
  final StreamController<List<PurchaseDetails>> _controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];

  void emit(PurchaseDetails purchase) {
    _controller.add([purchase]);
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: IapProducts.removeAds,
          title: 'Ta bort annonser',
          description: 'Inga annonser',
          price: '39 kr',
          rawPrice: 39,
          currencyCode: 'SEK',
        ),
      ],
      notFoundIDs: identifiers.where((id) => id != IapProducts.removeAds).toList(),
    );
  }

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam}) async => true;

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async => true;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }
}
