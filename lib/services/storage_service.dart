import 'dart:convert';

import '../models/models.dart';
import 'ad_policy.dart';
import 'ad_service.dart';
import 'iap_service.dart';
import 'preferences_store.dart';

class StorageService implements AdQuotaStore, IapEntitlementStore {
  static const String _progressKey = 'player_progress';
  static const String _sessionIdKey = 'session_id';
  static const String _firstOpenKey = 'first_open';
  static const String _installDateKey = 'install_date';
  static const String _rewardedDayKey = 'rewarded_video_day';
  static const String _rewardedCountKey = 'rewarded_video_count';
  static const String _interstitialDayKey = 'interstitial_day';
  static const String _interstitialCountKey = 'interstitial_count';
  static const String _ownedProductsKey = 'iap_owned_products';
  static const String _processedPurchasesKey = 'iap_processed_purchase_ids';
  static const String _hasPurchasedKey = 'iap_has_completed_purchase';

  final PreferencesStore _prefs = PreferencesStore.instance;

  Future<void> init() async {
    await _prefs.ensureReady();
  }

  Future<PlayerProgress> loadProgress() async {
    await _prefs.ensureReady();
    final jsonString = await _prefs.getString(_progressKey);
    if (jsonString == null) {
      return PlayerProgress.initial();
    }
    try {
      return PlayerProgress.fromJsonString(jsonString);
    } catch (e) {
      print('Error loading progress: $e');
      return PlayerProgress.initial();
    }
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    await _prefs.ensureReady();
    await _prefs.setString(_progressKey, progress.toJsonString());
  }

  Future<String> getOrCreateSessionId() async {
    await _prefs.ensureReady();
    var sessionId = await _prefs.getString(_sessionIdKey);
    if (sessionId == null) {
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _prefs.setString(_sessionIdKey, sessionId);
    }
    return sessionId;
  }

  Future<void> resetSessionId() async {
    await _prefs.ensureReady();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    await _prefs.setString(_sessionIdKey, sessionId);
  }

  Future<bool> isFirstOpen() async {
    await _prefs.ensureReady();
    final isFirst = await _prefs.getBool(_firstOpenKey) ?? true;
    if (isFirst) {
      await _prefs.setBool(_firstOpenKey, false);
      await _prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }
    return isFirst;
  }

  Future<int> getDaysSinceInstall() async {
    await _prefs.ensureReady();
    final installDateStr = await _prefs.getString(_installDateKey);
    if (installDateStr == null) return 0;

    try {
      final installDate = DateTime.parse(installDateStr);
      return DateTime.now().difference(installDate).inDays;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  @override
  Future<RewardedDayQuota> loadRewardedQuota(int maxPerDay) async {
    await _prefs.ensureReady();
    final day = await _prefs.getString(_rewardedDayKey) ?? '';
    final count = int.tryParse(await _prefs.getString(_rewardedCountKey) ?? '') ?? 0;
    return RewardedDayQuota(dayKey: day, count: count, maxPerDay: maxPerDay);
  }

  @override
  Future<void> saveRewardedQuota(RewardedDayQuota quota) async {
    await _prefs.ensureReady();
    await _prefs.setString(_rewardedDayKey, quota.dayKey);
    await _prefs.setString(_rewardedCountKey, '${quota.count}');
  }

  @override
  Future<int> loadInterstitialsShown(String dayKey) async {
    await _prefs.ensureReady();
    final day = await _prefs.getString(_interstitialDayKey);
    if (day != dayKey) return 0;
    return int.tryParse(await _prefs.getString(_interstitialCountKey) ?? '') ?? 0;
  }

  @override
  Future<void> saveInterstitialsShown(String dayKey, int count) async {
    await _prefs.ensureReady();
    await _prefs.setString(_interstitialDayKey, dayKey);
    await _prefs.setString(_interstitialCountKey, '$count');
  }

  @override
  Future<Set<String>> loadOwnedProducts() async {
    final raw = await _prefs.getString(_ownedProductsKey);
    return _decodeStringSet(raw);
  }

  @override
  Future<void> saveOwnedProducts(Set<String> ids) async {
    await _prefs.setString(_ownedProductsKey, jsonEncode(ids.toList()));
  }

  @override
  Future<List<String>> loadProcessedPurchaseIds() async {
    final raw = await _prefs.getString(_processedPurchasesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> saveProcessedPurchaseIds(List<String> ids) async {
    await _prefs.setString(_processedPurchasesKey, jsonEncode(ids));
  }

  @override
  Future<bool> loadHasCompletedPurchase() async {
    return await _prefs.getBool(_hasPurchasedKey) ?? false;
  }

  @override
  Future<void> saveHasCompletedPurchase(bool value) async {
    await _prefs.setBool(_hasPurchasedKey, value);
  }

  Set<String> _decodeStringSet(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toSet();
    } catch (_) {}
    return {};
  }
}
