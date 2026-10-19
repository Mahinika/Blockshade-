import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  static const Map<String, dynamic> _defaults = {
    'min_level_for_interstitial': 6,
    'levels_per_interstitial': 3,
    'min_seconds_between_interstitials': 90,
    'max_rewarded_videos_per_day': 6,
    'extra_moves_coin_cost': 900,
    'extra_moves_coin_cost_second': 1900,
    'starter_pack_duration_hours': 72,
    'level_slack_easy': 6,
    'level_slack_normal': 4,
    'level_slack_hard': 2,
    'level_slack_boss': 1,
    'coins_per_star': 5,
    'coins_base_win': 10,
    'show_starter_pack_from_level': 8,
  };

  int get minLevelForInterstitial =>
      _remoteConfig?.getInt('min_level_for_interstitial') ?? _defaults['min_level_for_interstitial'] as int;

  int get levelsPerInterstitial =>
      _remoteConfig?.getInt('levels_per_interstitial') ?? _defaults['levels_per_interstitial'] as int;

  int get minSecondsBetweenInterstitials =>
      _remoteConfig?.getInt('min_seconds_between_interstitials') ??
      _defaults['min_seconds_between_interstitials'] as int;

  int get maxRewardedVideosPerDay =>
      _remoteConfig?.getInt('max_rewarded_videos_per_day') ?? _defaults['max_rewarded_videos_per_day'] as int;

  int get extraMovesCoinCost =>
      _remoteConfig?.getInt('extra_moves_coin_cost') ?? _defaults['extra_moves_coin_cost'] as int;

  int get extraMovesCoinCostSecond =>
      _remoteConfig?.getInt('extra_moves_coin_cost_second') ?? _defaults['extra_moves_coin_cost_second'] as int;

  int get starterPackDurationHours =>
      _remoteConfig?.getInt('starter_pack_duration_hours') ?? _defaults['starter_pack_duration_hours'] as int;

  int get levelSlackEasy =>
      _remoteConfig?.getInt('level_slack_easy') ?? _defaults['level_slack_easy'] as int;

  int get levelSlackNormal =>
      _remoteConfig?.getInt('level_slack_normal') ?? _defaults['level_slack_normal'] as int;

  int get levelSlackHard =>
      _remoteConfig?.getInt('level_slack_hard') ?? _defaults['level_slack_hard'] as int;

  int get levelSlackBoss =>
      _remoteConfig?.getInt('level_slack_boss') ?? _defaults['level_slack_boss'] as int;

  int get coinsPerStar =>
      _remoteConfig?.getInt('coins_per_star') ?? _defaults['coins_per_star'] as int;

  int get coinsBaseWin =>
      _remoteConfig?.getInt('coins_base_win') ?? _defaults['coins_base_win'] as int;

  int get showStarterPackFromLevel =>
      _remoteConfig?.getInt('show_starter_pack_from_level') ?? _defaults['show_starter_pack_from_level'] as int;

  Future<void> init() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig!.setDefaults(_defaults.map((k, v) => MapEntry(k, v)));

      await _remoteConfig!.fetchAndActivate();
      _initialized = true;
    } catch (e) {
      print('Remote config init error: $e');
    }
  }

  Future<void> refresh() async {
    try {
      await _remoteConfig?.fetchAndActivate();
    } catch (e) {
      print('Remote config refresh error: $e');
    }
  }
}
