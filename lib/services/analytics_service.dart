import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  FirebaseAnalytics? _analytics;
  String? _userId;
  String? _sessionId;

  Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      print('Analytics init error: $e');
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

  Future<void> logIapOfferShown({
    required String sku,
    required String placement,
    required String trigger,
  }) async {
    await _analytics?.logEvent(
      name: 'iap_offer_shown',
      parameters: {
        ..._commonParams(null, null),
        'sku': sku,
        'placement': placement,
        'trigger': trigger,
      },
    );
  }

  Future<void> logIapPurchaseComplete({
    required String sku,
    required String price,
    required String placement,
  }) async {
    await _analytics?.logEvent(
      name: 'iap_purchase_complete',
      parameters: {
        ..._commonParams(null, null),
        'sku': sku,
        'price': price,
        'placement': placement,
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
}
