import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'remote_config_service.dart';

class AdService {
  // TODO: Replace with real AdMob IDs before release
  // Test IDs for development (from Google's documentation)
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // TODO: Production AdMob IDs - replace before release
  // static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  // static const String _prodRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  static const bool _useTestAds = true; // TODO: Set to false for production

  String get interstitialAdUnitId => _useTestAds ? _testInterstitialAdUnitId : _testInterstitialAdUnitId;
  String get rewardedAdUnitId => _useTestAds ? _testRewardedAdUnitId : _testRewardedAdUnitId;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;

  DateTime? _lastInterstitialShown;
  int _levelsPlayedSinceLastInterstitial = 0;
  bool _purchaseMadeInSession = false;
  bool _justFailedLevel = false;
  bool _justWatchedRewardedVideo = false;
  DateTime? _sessionStartTime;

  final RemoteConfigService _remoteConfig;

  AdService(this._remoteConfig);

  bool _initialized = false;

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _sessionStartTime = DateTime.now();
      _loadInterstitialAd();
      _loadRewardedAd();
    } catch (e) {
      print('AdMob initialization failed: $e');
      _initialized = false;
    }
  }

  void _loadInterstitialAd() {
    if (!_initialized || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    try {
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialLoading = false;
          },
          onAdFailedToLoad: (error) {
            print('Interstitial ad failed to load: $error');
            _isInterstitialLoading = false;
          },
        ),
      );
    } catch (e) {
      print('Interstitial ad load error: $e');
      _isInterstitialLoading = false;
    }
  }

  void _loadRewardedAd() {
    if (!_initialized || _isRewardedLoading) return;
    _isRewardedLoading = true;

    try {
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedLoading = false;
          },
          onAdFailedToLoad: (error) {
            print('Rewarded ad failed to load: $error');
            _isRewardedLoading = false;
          },
        ),
      );
    } catch (e) {
      print('Rewarded ad load error: $e');
      _isRewardedLoading = false;
    }
  }

  static const int _neverInterstitialBelowLevel = 3;

  bool shouldShowInterstitial(int currentLevel, bool adsRemoved) {
    if (adsRemoved) return false;
    if (currentLevel <= _neverInterstitialBelowLevel) return false;
    if (currentLevel < _remoteConfig.minLevelForInterstitial) return false;
    if (_purchaseMadeInSession) return false;
    if (_justFailedLevel) return false;
    if (_justWatchedRewardedVideo) return false;

    if (_lastInterstitialShown != null) {
      final secSinceLastAd = DateTime.now().difference(_lastInterstitialShown!).inSeconds;
      if (secSinceLastAd < _remoteConfig.minSecondsBetweenInterstitials) return false;
    }

    if (_sessionStartTime != null) {
      final secInSession = DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (secInSession < 180 && _lastInterstitialShown == null) return false;
    }

    if (_levelsPlayedSinceLastInterstitial < _remoteConfig.levelsPerInterstitial) {
      return false;
    }

    return _interstitialAd != null;
  }

  Future<void> showInterstitial({
    required Function() onAdDismissed,
    Function(String)? onAdFailedToShow,
  }) async {
    if (_interstitialAd == null) {
      onAdFailedToShow?.call('No ad loaded');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
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

    await _interstitialAd!.show();
    _lastInterstitialShown = DateTime.now();
    _levelsPlayedSinceLastInterstitial = 0;
    _justWatchedRewardedVideo = false;
  }

  bool get isRewardedAdReady => _rewardedAd != null;

  Future<void> showRewardedAd({
    required Function(int amount) onRewarded,
    required Function() onAdDismissed,
    Function(String)? onAdFailedToShow,
  }) async {
    if (_rewardedAd == null) {
      onAdFailedToShow?.call('No ad loaded');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onAdFailedToShow?.call(error.message);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        _justWatchedRewardedVideo = true;
        onRewarded(reward.amount.toInt());
      },
    );
  }

  void onLevelCompleted() {
    _levelsPlayedSinceLastInterstitial++;
    _justFailedLevel = false;
    _justWatchedRewardedVideo = false;
  }

  void onLevelFailed() {
    _justFailedLevel = true;
    _justWatchedRewardedVideo = false;
  }

  void onPurchaseMade() {
    _purchaseMadeInSession = true;
  }

  void onSessionStart() {
    _sessionStartTime = DateTime.now();
    _purchaseMadeInSession = false;
    _justFailedLevel = false;
    _justWatchedRewardedVideo = false;
  }

  void resetAfterLevelStart() {
    _justFailedLevel = false;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
