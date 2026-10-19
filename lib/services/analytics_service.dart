import 'package:firebase_analytics/firebase_analytics.dart';

import 'consent_mode.dart';

/// Event names from the measurement plan (ads, purchases, consent only).
class AnalyticsEvents {
  static const adRequest = 'ad_request';
  static const adLoadResult = 'ad_load_result';
  static const adPaid = 'ad_paid';
  static const rewardedOfferShown = 'rewarded_offer_shown';
  static const rewardedUnavailable = 'rewarded_unavailable';
  static const rewardedStart = 'rewarded_start';
  static const rewardedComplete = 'rewarded_complete';
  static const rewardedDismissed = 'rewarded_dismissed';
  static const interstitialShown = 'interstitial_shown';
  static const interstitialSkipped = 'interstitial_skipped';
  static const storeOpen = 'store_open';
  static const iapOfferShown = 'iap_offer_shown';
  static const iapPurchaseStart = 'iap_purchase_start';
  static const iapPurchaseComplete = 'iap_purchase_complete';
  static const iapPurchaseFail = 'iap_purchase_fail';
  static const iapRestore = 'iap_restore';
  static const consentUpdated = 'consent_updated';
}

typedef AnalyticsSink = void Function(String name, Map<String, Object> parameters);

/// Drops nulls, converts bool to 0/1, and caps strings at 100 characters.
Map<String, Object> sanitizeAnalyticsParams(Map<String, Object?> raw) {
  final out = <String, Object>{};
  raw.forEach((key, value) {
    if (value == null) return;
    if (value is bool) {
      out[key] = value ? 1 : 0;
      return;
    }
    if (value is String) {
      out[key] = value.length > 100 ? value.substring(0, 100) : value;
      return;
    }
    if (value is int) {
      out[key] = value;
      return;
    }
    if (value is double) {
      out[key] = value;
      return;
    }
    if (value is num) {
      out[key] = value.toDouble();
    }
  });
  return out;
}

class AnalyticsService {
  AnalyticsService({AnalyticsSink? sink}) : _sink = sink;

  final AnalyticsSink? _sink;
  FirebaseAnalytics? _firebase;
  bool _collectionEnabled = false;
  String? _userId;
  String? _sessionId;
  String? _adsRemoved;
  String? _payerStatus;

  /// Existing callers keep working, and stay silent until basic-mode consent
  /// turns collection on. Without Firebase config [_firebase] stays null.
  FirebaseAnalytics? get _analytics => _collectionEnabled ? _firebase : null;

  bool get collectionEnabled => _collectionEnabled;

  Future<void> init() async {
    try {
      _firebase = FirebaseAnalytics.instance;
      await _firebase!.setAnalyticsCollectionEnabled(false);
      _collectionEnabled = false;
    } catch (e) {
      print('Analytics init error: $e');
      _firebase = null;
      _collectionEnabled = false;
    }
  }

  /// Consent mode v2. Collection stays off unless [decision] allows it
  /// (basic mode: no GA4 events before consent, and none if consent is denied).
  Future<void> applyConsent(ConsentModeDecision decision, {required String source}) async {
    final firebase = _firebase;
    if (firebase == null) {
      _collectionEnabled = false;
      if (_sink != null && decision.enableCollection) {
        _collectionEnabled = true;
        await _safeLog(AnalyticsEvents.consentUpdated, {
          'analytics_storage': decision.analyticsStorageLabel,
          'ad_storage': decision.adStorageLabel,
          'ad_user_data': decision.adUserDataLabel,
          'ad_personalization': decision.adPersonalizationLabel,
          'source': source,
          'ump_status': decision.umpStatus,
        });
      }
      return;
    }
    try {
      await firebase.setConsent(
        analyticsStorageConsentGranted: decision.analyticsStorage,
        adStorageConsentGranted: decision.adStorage,
        adUserDataConsentGranted: decision.adUserData,
        adPersonalizationSignalsConsentGranted: decision.adPersonalization,
      );
      await firebase.setAnalyticsCollectionEnabled(decision.enableCollection);
      _collectionEnabled = decision.enableCollection;
      if (!_collectionEnabled) return;
      await firebase.setUserProperty(name: 'ad_consent', value: decision.adConsentProperty);
      await _flushUserProperty('ads_removed', _adsRemoved);
      await _flushUserProperty('payer_status', _payerStatus);
      await _safeLog(AnalyticsEvents.consentUpdated, {
        'analytics_storage': decision.analyticsStorageLabel,
        'ad_storage': decision.adStorageLabel,
        'ad_user_data': decision.adUserDataLabel,
        'ad_personalization': decision.adPersonalizationLabel,
        'source': source,
        'ump_status': decision.umpStatus,
      });
    } catch (e) {
      print('Analytics consent update failed: $e');
      _collectionEnabled = false;
    }
  }

  Future<void> setAdsRemoved(bool removed) async {
    _adsRemoved = removed ? '1' : '0';
    await _flushUserProperty('ads_removed', _adsRemoved);
  }

  Future<void> setPayerStatus(String status) async {
    _payerStatus = status;
    await _flushUserProperty('payer_status', status);
  }

  Future<void> _flushUserProperty(String name, String? value) async {
    if (!_collectionEnabled || value == null) return;
    final firebase = _firebase;
    if (firebase == null) return;
    try {
      await firebase.setUserProperty(name: name, value: value);
    } catch (e) {
      print('Analytics user property $name skipped: $e');
    }
  }

  Future<void> _safeLog(String name, Map<String, Object?> parameters) async {
    if (!_collectionEnabled) return;
    try {
      final cleaned = sanitizeAnalyticsParams(parameters);
      final sink = _sink;
      if (sink != null) {
        sink(name, cleaned);
        return;
      }
      final firebase = _firebase;
      if (firebase == null) return;
      await firebase.logEvent(name: name, parameters: cleaned);
    } catch (e) {
      print('Analytics "$name" skipped: $e');
    }
  }

  void setUserId(String userId) {
    _userId = userId;
    _analytics?.setUserId(id: userId);
  }

  void setSessionId(String sessionId) {
    _sessionId = sessionId;
  }

  Map<String, Object> _commonParams(String? levelId, int? world) {
    return {
      if (_userId != null) 'user_id': _userId!,
      if (_sessionId != null) 'session_id': _sessionId!,
      if (levelId != null) 'level_id': levelId,
      if (world != null) 'world': world,
    };
  }

  Future<void> logAppOpen({required bool firstOpen, required int daysSinceInstall}) async {
    await _analytics?.logEvent(
      name: 'app_open',
      parameters: {
        ..._commonParams(null, null),
        'first_open': firstOpen,
        'days_since_install': daysSinceInstall,
      },
    );
  }

  Future<void> logTutorialStep({required int step, required bool completed}) async {
    await _analytics?.logEvent(
      name: 'tutorial_step',
      parameters: {
        ..._commonParams(null, null),
        'step': step,
        'completed': completed,
      },
    );
  }

  Future<void> logLevelStart({
    required String levelId,
    required int world,
    required int attemptNo,
    required int moveLimit,
    int? timeLimit,
    required double difficulty,
    required int livesLeft,
    List<String>? boostersSelected,
  }) async {
    await _analytics?.logEvent(
      name: 'level_start',
      parameters: {
        ..._commonParams(levelId, world),
        'attempt_no': attemptNo,
        'move_limit': moveLimit,
        if (timeLimit != null) 'time_limit': timeLimit,
        'difficulty': difficulty,
        'lives_left': livesLeft,
        if (boostersSelected != null) 'boosters_selected': boostersSelected.join(','),
      },
    );
  }

  Future<void> logLevelComplete({
    required String levelId,
    required int world,
    required int attemptNo,
    required int movesUsed,
    required int movesLeft,
    required int stars,
    required int durationSec,
    List<String>? boostersUsed,
    required int continuesUsed,
  }) async {
    await _analytics?.logEvent(
      name: 'level_complete',
      parameters: {
        ..._commonParams(levelId, world),
        'attempt_no': attemptNo,
        'moves_used': movesUsed,
        'moves_left': movesLeft,
        'stars': stars,
        'duration_sec': durationSec,
        if (boostersUsed != null) 'boosters_used': boostersUsed.join(','),
        'continues_used': continuesUsed,
      },
    );
  }

  Future<void> logLevelFail({
    required String levelId,
    required int world,
    required int attemptNo,
    required String reason,
    required int blocksLeft,
    required int movesUsed,
    required int durationSec,
    required int optimalMoves,
  }) async {
    await _analytics?.logEvent(
      name: 'level_fail',
      parameters: {
        ..._commonParams(levelId, world),
        'attempt_no': attemptNo,
        'reason': reason,
        'blocks_left': blocksLeft,
        'moves_used': movesUsed,
        'duration_sec': durationSec,
        'optimal_moves': optimalMoves,
      },
    );
  }

  Future<void> logLevelQuit({
    required String levelId,
    required int world,
    required int movesUsed,
    required int durationSec,
  }) async {
    await _analytics?.logEvent(
      name: 'level_quit',
      parameters: {
        ..._commonParams(levelId, world),
        'moves_used': movesUsed,
        'duration_sec': durationSec,
      },
    );
  }

  Future<void> logContinueOfferShown({
    required String levelId,
    required int world,
    required String offerType,
    required String price,
    required int attemptNo,
    required int failCountInLevel,
  }) async {
    await _analytics?.logEvent(
      name: 'continue_offer_shown',
      parameters: {
        ..._commonParams(levelId, world),
        'offer_type': offerType,
        'price': price,
        'attempt_no': attemptNo,
        'fail_count_in_level': failCountInLevel,
      },
    );
  }

  Future<void> logContinueOfferResult({
    required String levelId,
    required int world,
    required String choice,
  }) async {
    await _analytics?.logEvent(
      name: 'continue_offer_result',
      parameters: {
        ..._commonParams(levelId, world),
        'choice': choice,
      },
    );
  }

  Future<void> logBoosterUsed({
    required String levelId,
    required int world,
    required String booster,
    required String source,
    required String moment,
  }) async {
    await _analytics?.logEvent(
      name: 'booster_used',
      parameters: {
        ..._commonParams(levelId, world),
        'booster': booster,
        'source': source,
        'moment': moment,
      },
    );
  }

  Future<void> logAdRewardedOffer({
    required String placement,
  }) async {
    await _analytics?.logEvent(
      name: 'ad_rv_offer',
      parameters: {
        ..._commonParams(null, null),
        'placement': placement,
      },
    );
  }

  Future<void> logAdRewardedStart({
    required String placement,
  }) async {
    await _analytics?.logEvent(
      name: 'ad_rv_start',
      parameters: {
        ..._commonParams(null, null),
        'placement': placement,
      },
    );
  }

  Future<void> logAdRewardedComplete({
    required String placement,
    required String reward,
  }) async {
    await _analytics?.logEvent(
      name: 'ad_rv_complete',
      parameters: {
        ..._commonParams(null, null),
        'placement': placement,
        'reward': reward,
      },
    );
  }

  Future<void> logAdInterstitialShown({
    required String placement,
    required int levelsSinceLastIs,
    required int secSinceLastIs,
  }) async {
    await _analytics?.logEvent(
      name: 'ad_is_shown',
      parameters: {
        ..._commonParams(null, null),
        'placement': placement,
        'levels_since_last_is': levelsSinceLastIs,
        'sec_since_last_is': secSinceLastIs,
      },
    );
  }

  Future<void> logCurrencyEarn({
    required int amount,
    required String source,
    required int balanceAfter,
  }) async {
    await _analytics?.logEvent(
      name: 'currency_earn',
      parameters: {
        ..._commonParams(null, null),
        'amount': amount,
        'source': source,
        'balance_after': balanceAfter,
      },
    );
  }

  Future<void> logCurrencySpend({
    required int amount,
    required String sink,
    required int balanceAfter,
  }) async {
    await _analytics?.logEvent(
      name: 'currency_spend',
      parameters: {
        ..._commonParams(null, null),
        'amount': amount,
        'sink': sink,
        'balance_after': balanceAfter,
      },
    );
  }

  Future<void> logLivesEmpty({
    required int nextLifeSec,
  }) async {
    await _analytics?.logEvent(
      name: 'lives_empty',
      parameters: {
        ..._commonParams(null, null),
        'next_life_sec': nextLifeSec,
      },
    );
  }

  Future<void> logSessionEnd({
    required int durationSec,
    required int levelsPlayed,
    required int levelsWon,
  }) async {
    await _analytics?.logEvent(
      name: 'session_end',
      parameters: {
        ..._commonParams(null, null),
        'duration_sec': durationSec,
        'levels_played': levelsPlayed,
        'levels_won': levelsWon,
      },
    );
  }

  Future<void> logAdRequest({
    required String adFormat,
    required String adUnitName,
    required String placement,
  }) =>
      _safeLog(AnalyticsEvents.adRequest, {
        'ad_format': adFormat,
        'ad_unit_name': adUnitName,
        'placement': placement,
      });

  Future<void> logAdLoadResult({
    required String adFormat,
    required String adUnitName,
    required String result,
    int? errorCode,
    int? latencyMs,
  }) =>
      _safeLog(AnalyticsEvents.adLoadResult, {
        'ad_format': adFormat,
        'ad_unit_name': adUnitName,
        'result': result,
        'error_code': errorCode,
        'latency_ms': latencyMs,
      });

  /// AdMob `onPaidEvent`. [valueMicros] is converted to major currency units.
  /// This is the BigQuery revenue event. Do not also log `ad_impression`.
  Future<void> logAdPaid({
    required String adFormat,
    required String adUnitName,
    required String placement,
    required double valueMicros,
    required String currencyCode,
    required String precision,
    String? adSource,
  }) {
    final currency = currencyCode.trim().toUpperCase();
    if (currency.length != 3) return Future.value();
    return _safeLog(AnalyticsEvents.adPaid, {
      'ad_platform': 'admob',
      'ad_source': (adSource == null || adSource.isEmpty) ? 'unknown' : adSource,
      'ad_format': adFormat,
      'ad_unit_name': adUnitName,
      'placement': placement,
      'value': valueMicros / 1000000.0,
      'currency': currency,
      'precision': precision,
    });
  }

  Future<void> logRewardedOfferShown({
    required String placement,
    String? levelId,
    required int rvToday,
    required int capRemaining,
  }) =>
      _safeLog(AnalyticsEvents.rewardedOfferShown, {
        'placement': placement,
        'level_id': levelId,
        'rv_today': rvToday,
        'cap_remaining': capRemaining,
      });

  Future<void> logRewardedUnavailable({
    required String placement,
    required String reason,
  }) =>
      _safeLog(AnalyticsEvents.rewardedUnavailable, {
        'placement': placement,
        'reason': reason,
      });

  Future<void> logRewardedStart({
    required String placement,
    String? levelId,
  }) =>
      _safeLog(AnalyticsEvents.rewardedStart, {
        'placement': placement,
        'level_id': levelId,
      });

  Future<void> logRewardedComplete({
    required String placement,
    required String rewardType,
    required int rewardAmount,
    String? levelId,
  }) =>
      _safeLog(AnalyticsEvents.rewardedComplete, {
        'placement': placement,
        'reward_type': rewardType,
        'reward_amount': rewardAmount,
        'level_id': levelId,
      });

  Future<void> logRewardedDismissed({
    required String placement,
  }) =>
      _safeLog(AnalyticsEvents.rewardedDismissed, {
        'placement': placement,
      });

  Future<void> logInterstitialShown({
    required String placement,
    required int levelNumber,
    required int levelsSinceLast,
    required int secondsSinceLast,
    required int shownToday,
    required int shownThisSession,
  }) =>
      _safeLog(AnalyticsEvents.interstitialShown, {
        'placement': placement,
        'level_number': levelNumber,
        'levels_since_last_is': levelsSinceLast,
        'sec_since_last_is': secondsSinceLast,
        'is_today': shownToday,
        'is_session': shownThisSession,
      });

  Future<void> logInterstitialSkipped({required String rule}) =>
      _safeLog(AnalyticsEvents.interstitialSkipped, {'rule': rule});

  Future<void> logStoreOpen({
    required String entryPoint,
    int? levelNumber,
  }) =>
      _safeLog(AnalyticsEvents.storeOpen, {
        'entry_point': entryPoint,
        'level_number': levelNumber,
      });

  Future<void> logIapOfferShown({
    required String productId,
    required String placement,
    required String trigger,
    required String priceLabel,
  }) =>
      _safeLog(AnalyticsEvents.iapOfferShown, {
        'product_id': productId,
        'placement': placement,
        'trigger': trigger,
        'price_label': priceLabel,
      });

  Future<void> logIapPurchaseStart({
    required String productId,
    required String placement,
    required String priceLabel,
  }) =>
      _safeLog(AnalyticsEvents.iapPurchaseStart, {
        'product_id': productId,
        'placement': placement,
        'price_label': priceLabel,
      });

  /// Context only. Revenue is the automatic `in_app_purchase` event.
  /// Must not include `value` or `currency`.
  Future<void> logIapPurchaseComplete({
    required String productId,
    required String placement,
    required bool isFirstPurchase,
  }) =>
      _safeLog(AnalyticsEvents.iapPurchaseComplete, {
        'product_id': productId,
        'placement': placement,
        'is_first_purchase': isFirstPurchase ? 1 : 0,
      });

  Future<void> logIapPurchaseFail({
    required String productId,
    required String placement,
    required String status,
    String? errorCode,
  }) =>
      _safeLog(AnalyticsEvents.iapPurchaseFail, {
        'product_id': productId,
        'placement': placement,
        'status': status,
        'error_code': errorCode,
      });

  Future<void> logIapRestore({
    required String result,
    required int restoredCount,
  }) =>
      _safeLog(AnalyticsEvents.iapRestore, {
        'result': result,
        'restored_count': restoredCount,
      });
}
