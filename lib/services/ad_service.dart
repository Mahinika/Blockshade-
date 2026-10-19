import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import 'ad_policy.dart';
import 'analytics_service.dart';
import 'remote_config_service.dart';

class RewardedShowResult {
  const RewardedShowResult({
    required this.granted,
    required this.messageSv,
    required this.reason,
  });

  final bool granted;
  final String messageSv;
  final RewardedBlockReason reason;
}

abstract class AdQuotaStore {
  Future<RewardedDayQuota> loadRewardedQuota(int maxPerDay);
  Future<void> saveRewardedQuota(RewardedDayQuota quota);
  Future<int> loadInterstitialsShown(String dayKey);
  Future<void> saveInterstitialsShown(String dayKey, int count);
}

class AdService {
  AdService(
    this._remoteConfig, {
    required this.analytics,
    required AdQuotaStore quotaStore,
    AdMobConfig? config,
    DateTime Function()? now,
    InterstitialPolicy? policy,
  })  : _quotaStore = quotaStore,
        _config = config ?? AdMobConfig.test,
        _now = now ?? DateTime.now,
        _policy = policy ?? const InterstitialPolicy();

  final RemoteConfigService _remoteConfig;
  final AnalyticsService analytics;
  final AdQuotaStore _quotaStore;
  final AdMobConfig _config;
  final DateTime Function() _now;
  final InterstitialPolicy _policy;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  bool _initialized = false;
  bool _adsAllowed = false;

  DateTime? _lastInterstitialShown;
  int _levelsCompletedSinceLastInterstitial = 0;
  bool _purchaseMadeInSession = false;
  bool _justFailedLevel = false;
  bool _justWatchedRewardedVideo = false;
  int _interstitialsThisSession = 0;
  String _rewardedPlacement = 'unknown';
  String _rewardedLevelId = '';

  String get interstitialUnitId => _config.interstitialUnitId;
  String get rewardedUnitId => _config.rewardedUnitId;
  String get privacyPolicyUrl => _config.privacyPolicyUrl;
  bool get isRewardedAdReady => _rewardedAd != null && _adsAllowed;
  bool get adsAllowed => _adsAllowed;

  void setAdsAllowed(bool allowed) {
    _adsAllowed = allowed;
    if (!allowed) {
      _interstitialAd?.dispose();
      _rewardedAd?.dispose();
      _interstitialAd = null;
      _rewardedAd = null;
    }
  }

  Future<void> init() async {
    if (!_adsAllowed) {
      _initialized = false;
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitialAd();
      _loadRewardedAd(placement: 'preload');
    } catch (e) {
      print('AdMob initialization failed: $e');
      _initialized = false;
    }
  }

  InterstitialPolicy get _activePolicy {
    final levels = _remoteConfig.levelsPerInterstitial < _policy.minCompletedLevelsBetween
        ? _policy.minCompletedLevelsBetween
        : _remoteConfig.levelsPerInterstitial;
    final seconds = _remoteConfig.minSecondsBetweenInterstitials < _policy.minSecondsBetween
        ? _policy.minSecondsBetween
        : _remoteConfig.minSecondsBetweenInterstitials;
    final minLevelToShow = _remoteConfig.minLevelForInterstitial < 6
        ? 6
        : _remoteConfig.minLevelForInterstitial;
    final firstLevels = minLevelToShow - 1;
    return InterstitialPolicy(
      levelsPerWorld: _policy.levelsPerWorld,
      minCompletedLevelsBetween: levels,
      minSecondsBetween: seconds,
      firstCampaignLevelsWithoutAds: firstLevels,
    );
  }

  void _loadInterstitialAd() {
    if (!_initialized || !_adsAllowed || _isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;
    final started = _now();
    analytics.logAdRequest(
      adFormat: 'interstitial',
      adUnitName: 'interstitial',
      placement: 'level_transition',
    );
    try {
      InterstitialAd.load(
        adUnitId: interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _attachPaid(ad, adFormat: 'interstitial', adUnitName: 'interstitial');
            _interstitialAd = ad;
            _isInterstitialLoading = false;
            analytics.logAdLoadResult(
              adFormat: 'interstitial',
              adUnitName: 'interstitial',
              result: 'loaded',
              latencyMs: _now().difference(started).inMilliseconds,
            );
          },
          onAdFailedToLoad: (error) {
            print('Interstitial ad failed to load: $error');
            _isInterstitialLoading = false;
            analytics.logAdLoadResult(
              adFormat: 'interstitial',
              adUnitName: 'interstitial',
              result: 'failed',
              errorCode: error.code,
              latencyMs: _now().difference(started).inMilliseconds,
            );
          },
        ),
      );
    } catch (e) {
      print('Interstitial ad load error: $e');
      _isInterstitialLoading = false;
    }
  }

  void _loadRewardedAd({required String placement}) {
    if (!_initialized || !_adsAllowed || _isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;
    final started = _now();
    analytics.logAdRequest(
      adFormat: 'rewarded',
      adUnitName: 'rewarded',
      placement: placement,
    );
    try {
      RewardedAd.load(
        adUnitId: rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _attachPaid(ad, adFormat: 'rewarded', adUnitName: 'rewarded');
            _rewardedAd = ad;
            _isRewardedLoading = false;
            analytics.logAdLoadResult(
              adFormat: 'rewarded',
              adUnitName: 'rewarded',
              result: 'loaded',
              latencyMs: _now().difference(started).inMilliseconds,
            );
          },
          onAdFailedToLoad: (error) {
            print('Rewarded ad failed to load: $error');
            _isRewardedLoading = false;
            analytics.logAdLoadResult(
              adFormat: 'rewarded',
              adUnitName: 'rewarded',
              result: 'failed',
              errorCode: error.code,
              latencyMs: _now().difference(started).inMilliseconds,
            );
          },
        ),
      );
    } catch (e) {
      print('Rewarded ad load error: $e');
      _isRewardedLoading = false;
    }
  }

  void _attachPaid(AdWithoutView ad, {required String adFormat, required String adUnitName}) {
    ad.onPaidEvent = (Ad paidAd, double valueMicros, PrecisionType precision, String currencyCode) {
      final placement = adFormat == 'rewarded' ? _rewardedPlacement : 'level_transition';
      analytics.logAdPaid(
        adFormat: adFormat,
        adUnitName: adUnitName,
        placement: placement,
        valueMicros: valueMicros,
        currencyCode: currencyCode,
        precision: precision.name,
        adSource: paidAd.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
      );
    };
  }

  void preloadRewarded({String placement = 'preload'}) {
    _loadRewardedAd(placement: placement);
  }

  Future<void> noteRewardedOfferVisible({
    required String placement,
    String? levelId,
  }) async {
    final quota = (await _loadQuota()).rolledTo(_now());
    if (!_adsAllowed || _rewardedAd == null || !quota.canWatch) return;
    await analytics.logRewardedOfferShown(
      placement: placement,
      levelId: levelId,
      rvToday: quota.count,
      capRemaining: quota.remaining,
    );
  }

  Future<RewardedShowResult> showRewarded({
    required String placement,
    required String rewardType,
    required int rewardAmount,
    String? levelId,
  }) async {
    final quota = await _loadQuota();
    final availability = RewardedAvailability.decide(
      consentAllowsAds: _adsAllowed && _initialized,
      adLoaded: _rewardedAd != null,
      quota: quota,
      now: _now(),
    );
    if (!availability.canShow) {
      if (availability.reason == RewardedBlockReason.notLoaded ||
          availability.reason == RewardedBlockReason.noConsent) {
        preloadRewarded(placement: placement);
      }
      await analytics.logRewardedUnavailable(
        placement: placement,
        reason: _unavailableReason(availability.reason),
      );
      return RewardedShowResult(
        granted: false,
        messageSv: availability.messageSv,
        reason: availability.reason,
      );
    }

    final ad = _rewardedAd!;
    _rewardedPlacement = placement;
    _rewardedLevelId = levelId ?? '';
    final earned = Completer<bool>();
    var rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        analytics.logRewardedStart(placement: placement, levelId: _rewardedLevelId);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(placement: placement);
        if (!rewarded) {
          analytics.logRewardedDismissed(placement: placement);
        }
        if (!earned.isCompleted) earned.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(placement: placement);
        if (!earned.isCompleted) earned.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          rewarded = true;
          if (!earned.isCompleted) earned.complete(true);
        },
      );
    } catch (e) {
      print('Rewarded show failed: $e');
      _rewardedAd = null;
      _loadRewardedAd(placement: placement);
      await analytics.logRewardedUnavailable(placement: placement, reason: 'not_loaded');
      return const RewardedShowResult(
        granted: false,
        messageSv: 'Ingen video är laddad just nu. Försök igen om en stund.',
        reason: RewardedBlockReason.notLoaded,
      );
    }

    final didEarn = await earned.future;
    if (!didEarn) {
      return const RewardedShowResult(
        granted: false,
        messageSv: '',
        reason: RewardedBlockReason.none,
      );
    }

    final updated = quota.consume(_now());
    if (updated == null) {
      return RewardedShowResult(
        granted: false,
        messageSv: 'Du har tittat på dagens ${quota.maxPerDay} videor. Kom tillbaka imorgon.',
        reason: RewardedBlockReason.dailyCap,
      );
    }
    try {
      await _quotaStore.saveRewardedQuota(updated);
    } catch (e) {
      print('Failed to persist rewarded quota: $e');
    }
    _justWatchedRewardedVideo = true;
    await analytics.logRewardedComplete(
      placement: placement,
      rewardType: rewardType,
      rewardAmount: rewardAmount,
      levelId: levelId,
    );
    return const RewardedShowResult(
      granted: true,
      messageSv: '',
      reason: RewardedBlockReason.none,
    );
  }

  Future<InterstitialDecision> evaluateInterstitial({
    required int world,
    required int levelInWorld,
    required bool adsRemoved,
  }) async {
    if (!_adsAllowed && !adsRemoved) {
      const blocked = InterstitialDecision(
        show: false,
        skipRule: 'no_consent',
        campaignLevel: 0,
        levelsSinceLast: 0,
        secondsSinceLast: 0,
      );
      await analytics.logInterstitialSkipped(rule: 'no_consent');
      return blocked;
    }
    final decision = _activePolicy.evaluate(
      world: world,
      levelInWorld: levelInWorld,
      adsRemoved: adsRemoved,
      adLoaded: _interstitialAd != null,
      completedLevelsSinceLastAd: _levelsCompletedSinceLastInterstitial,
      lastShownAt: _lastInterstitialShown,
      now: _now(),
      justFailedLevel: _justFailedLevel,
      justWatchedRewarded: _justWatchedRewardedVideo,
      purchaseMadeInSession: _purchaseMadeInSession,
    );
    _justWatchedRewardedVideo = false;
    _justFailedLevel = false;
    if (!decision.show && decision.skipRule != null) {
      await analytics.logInterstitialSkipped(rule: decision.skipRule!);
    }
    return decision;
  }

  Future<void> showInterstitial({
    required void Function() onAdDismissed,
    void Function(String)? onAdFailedToShow,
    required int levelNumber,
  }) async {
    final ad = _interstitialAd;
    if (ad == null) {
      onAdFailedToShow?.call('No ad loaded');
      _loadInterstitialAd();
      return;
    }

    final levelsSince = _levelsCompletedSinceLastInterstitial;
    final secondsSince = _lastInterstitialShown == null
        ? 0
        : _now().difference(_lastInterstitialShown!).inSeconds;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _interstitialsThisSession += 1;
        _recordInterstitialShown(
          levelNumber: levelNumber,
          levelsSince: levelsSince,
          secondsSince: secondsSince,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdFailedToShow?.call(error.message);
      },
    );

    try {
      await ad.show();
      _lastInterstitialShown = _now();
      _levelsCompletedSinceLastInterstitial = 0;
      _justWatchedRewardedVideo = false;
    } catch (e) {
      print('Interstitial show failed: $e');
      _interstitialAd = null;
      _loadInterstitialAd();
      onAdFailedToShow?.call(e.toString());
    }
  }

  Future<void> _recordInterstitialShown({
    required int levelNumber,
    required int levelsSince,
    required int secondsSince,
  }) async {
    final day = RewardedDayQuota.dayKeyFor(_now());
    var shownToday = _interstitialsThisSession;
    try {
      final stored = await _quotaStore.loadInterstitialsShown(day);
      shownToday = stored + 1;
      await _quotaStore.saveInterstitialsShown(day, shownToday);
    } catch (e) {
      print('Failed to persist interstitial count: $e');
    }
    await analytics.logInterstitialShown(
      placement: 'level_transition',
      levelNumber: levelNumber,
      levelsSinceLast: levelsSince,
      secondsSinceLast: secondsSince,
      shownToday: shownToday,
      shownThisSession: _interstitialsThisSession,
    );
  }

  void onLevelCompleted() {
    _levelsCompletedSinceLastInterstitial++;
    _justFailedLevel = false;
  }

  void onLevelFailed() {
    _justFailedLevel = true;
    _justWatchedRewardedVideo = false;
  }

  void onPurchaseMade() {
    _purchaseMadeInSession = true;
  }

  void onSessionStart() {
    _purchaseMadeInSession = false;
    _justFailedLevel = false;
    _justWatchedRewardedVideo = false;
    _interstitialsThisSession = 0;
  }

  Future<RewardedDayQuota> _loadQuota() {
    return _quotaStore.loadRewardedQuota(_remoteConfig.maxRewardedVideosPerDay);
  }

  String _unavailableReason(RewardedBlockReason reason) {
    switch (reason) {
      case RewardedBlockReason.notLoaded:
        return 'not_loaded';
      case RewardedBlockReason.dailyCap:
        return 'cap_reached';
      case RewardedBlockReason.noConsent:
        return 'no_consent';
      case RewardedBlockReason.none:
        return 'not_loaded';
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
