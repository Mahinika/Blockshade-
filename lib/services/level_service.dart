import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

class LevelService {
  List<Level>? _cachedLevels;

  Future<List<Level>> loadAllLevels() async {
    if (_cachedLevels != null) return _cachedLevels!;

    final levels = <Level>[];

    for (var world = 1; world <= 3; world++) {
      try {
        final jsonString = await rootBundle.loadString('assets/levels/world$world.json');
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        for (final json in jsonList) {
          levels.add(Level.fromJson(json as Map<String, dynamic>));
        }
      } catch (e) {
        print('Error loading world $world: $e');
      }
    }

    _cachedLevels = levels;
    return levels;
  }

  Future<List<Level>> loadWorldLevels(int world) async {
    final allLevels = await loadAllLevels();
    return allLevels.where((l) => l.world == world).toList();
  }

  Future<Level?> loadLevel(String levelId) async {
    final allLevels = await loadAllLevels();
    try {
      return allLevels.firstWhere((l) => l.id == levelId);
    } catch (_) {
      return null;
    }
  }

  Future<Level?> getNextLevel(String currentLevelId) async {
    final allLevels = await loadAllLevels();
    final currentIndex = allLevels.indexWhere((l) => l.id == currentLevelId);
    if (currentIndex < 0 || currentIndex >= allLevels.length - 1) {
      return null;
    }
    return allLevels[currentIndex + 1];
  }

  Future<List<String>> getAllLevelIds() async {
    final allLevels = await loadAllLevels();
    return allLevels.map((l) => l.id).toList();
  }

  Future<int> getTotalLevels() async {
    final allLevels = await loadAllLevels();
    return allLevels.length;
  }

  void clearCache() {
    _cachedLevels = null;
  }
}
