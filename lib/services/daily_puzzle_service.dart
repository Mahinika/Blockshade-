import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'level_generator.dart';
import 'solver.dart';

/// Deterministic daily puzzle from calendar date (works fully offline).
class DailyPuzzleService {
  static const String dailyLevelPrefix = 'daily-';

  static const String _cachedLevelKeyPrefix = 'daily_level_cache_';

  SharedPreferences? _prefs;

  final Map<String, Level> _memoryCache = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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

    final prefs = _prefs ?? await SharedPreferences.getInstance();
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

    final level = _generateVerifiedLevel(date);
    _memoryCache[key] = level;
    await prefs.setString('$_cachedLevelKeyPrefix$key', level.toJsonString());
    return level;
  }

  Level _generateVerifiedLevel(DateTime date) {
    final seed = seedForDate(date);
    final levelId = levelIdForDate(date);
    final generator = LevelGenerator(seed: seed);

    final config = GeneratorConfig(
      world: 2,
      minBlocks: 6,
      maxBlocks: 9,
      minWidth: 5,
      maxWidth: 7,
      minHeight: 6,
      maxHeight: 8,
      echoBlockChance: 0.35,
      lockedBlockChance: 0.15,
      gateChance: 0.0,
      wallCount: 2,
      slack: 4,
    );

    final level = generator.generate(levelId, config, maxAttempts: 200);
    if (level != null) {
      final solver = Solver(level);
      final result = solver.solve();
      if (result.solvable) {
        return level;
      }
    }

    return _fallbackDailyLevel(levelId, seed);
  }

  Level _fallbackDailyLevel(String levelId, int seed) {
    final generator = LevelGenerator(seed: seed + 7);
    final config = GeneratorConfig.forWorld(1, levelInWorld: 12, isBoss: false);
    final level = generator.generate(levelId, config, maxAttempts: 150);
    if (level != null) {
      return Level(
        id: levelId,
        world: 0,
        grid: level.grid,
        moveLimit: level.moveLimit,
        blocks: level.blocks,
        gates: level.gates,
        walls: level.walls,
        solver: level.solver,
        seed: seed,
        generatorVersion: level.generatorVersion,
      );
    }

    return Level(
      id: levelId,
      world: 0,
      grid: const GridSize(5, 6),
      moveLimit: 12,
      blocks: [
        Block(
          id: 'a',
          color: 'red',
          cells: [const BlockCell(2, 2)],
          direction: Direction.right,
          isEcho: true,
        ),
        Block(
          id: 'b',
          color: 'blue',
          cells: [const BlockCell(1, 3), const BlockCell(1, 4)],
          direction: Direction.left,
        ),
      ],
      solver: const LevelSolverData(
        solvable: true,
        optimalMoves: 4,
        branching: 1.2,
        deadEnds: 0,
        difficulty: 0.35,
      ),
      seed: seed,
      generatorVersion: 'daily-fallback',
    );
  }

  void clearMemoryCache() {
    _memoryCache.clear();
  }
}
