import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'daily_puzzle_generator.dart';

/// Deterministic daily puzzle from calendar date (works fully offline).
class DailyPuzzleService {
  static const String dailyLevelPrefix = 'daily-';

  static const String _cachedLevelKeyPrefix = 'daily_level_cache_';

  /// Hard caps so generation cannot run unbounded on device.
  static const int maxPrimaryAttempts = 25;
  static const int maxFallbackAttempts = 15;
  static const Duration generationTimeout = Duration(seconds: 3);

  SharedPreferences? _prefs;

  final Map<String, Level> _memoryCache = {};
  final Map<String, Future<Level>> _inFlight = {};

  Level? _bundledFallbackTemplate;

  Future<void> ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String dateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static int seedForDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.year * 10000 + local.month * 100 + local.day;
  }

  static String levelIdForDate(DateTime date) => '$dailyLevelPrefix${dateKey(date)}';

  static bool isDailyLevelId(String levelId) => levelId.startsWith(dailyLevelPrefix);

  static DateTime? dateFromLevelId(String levelId) {
    if (!isDailyLevelId(levelId)) return null;
    final key = levelId.substring(dailyLevelPrefix.length);
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Future<Level> getLevelForDate(DateTime date) async {
    final key = dateKey(date);
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }

    final inFlight = _inFlight[key];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _resolveLevelForDate(date, key);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<Level> _resolveLevelForDate(DateTime date, String key) async {
    await ensurePrefs();
    final prefs = _prefs!;
    final cached = prefs.getString('$_cachedLevelKeyPrefix$key');
    if (cached != null) {
      try {
        final level = Level.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        _memoryCache[key] = level;
        return level;
      } catch (_) {
        // Regenerate below.
      }
    }

    final levelId = levelIdForDate(date);
    final seed = seedForDate(date);
    Level level;

    try {
      final json = await Isolate.run(() {
        return generateDailyLevelInIsolate(
          DailyGenerationInput(
            levelId: levelId,
            seed: seed,
            maxPrimaryAttempts: maxPrimaryAttempts,
            maxFallbackAttempts: maxFallbackAttempts,
          ).toJson(),
        );
      }).timeout(generationTimeout);
      level = Level.fromJson(json);
    } catch (e) {
      // ignore: avoid_print
      print('Daily generation failed for $key: $e');
      level = await _loadBundledFallback(levelId);
    }

    _memoryCache[key] = level;
    unawaited(prefs.setString('$_cachedLevelKeyPrefix$key', level.toJsonString()));
    return level;
  }

  Future<Level> _loadBundledFallback(String levelId) async {
    _bundledFallbackTemplate ??= await _readBundledFallback();
    final template = _bundledFallbackTemplate!;
    final map = template.toJson();
    map['id'] = levelId;
    return Level.fromJson(map);
  }

  Future<Level> _readBundledFallback() async {
    final jsonString = await rootBundle.loadString('assets/levels/daily_fallback.json');
    return Level.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  void clearMemoryCache() {
    _memoryCache.clear();
  }

  /// Exposed for tests: bounded generation without persistence.
  Future<Level> generateForDateWithoutCache(DateTime date) async {
    final levelId = levelIdForDate(date);
    final seed = seedForDate(date);
    try {
      final json = await Isolate.run(() {
        return generateDailyLevelInIsolate(
          DailyGenerationInput(
            levelId: levelId,
            seed: seed,
            maxPrimaryAttempts: maxPrimaryAttempts,
            maxFallbackAttempts: maxFallbackAttempts,
          ).toJson(),
        );
      }).timeout(generationTimeout);
      return Level.fromJson(json);
    } catch (_) {
      return await _loadBundledFallback(levelId);
    }
  }
}
