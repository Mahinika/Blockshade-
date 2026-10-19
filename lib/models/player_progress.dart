import 'dart:convert';

class LevelProgress {
  final String levelId;
  final int stars;
  final int bestMoves;
  final bool completed;

  const LevelProgress({
    required this.levelId,
    this.stars = 0,
    this.bestMoves = 0,
    this.completed = false,
  });

  LevelProgress copyWith({
    int? stars,
    int? bestMoves,
    bool? completed,
  }) {
    return LevelProgress(
      levelId: levelId,
      stars: stars ?? this.stars,
      bestMoves: bestMoves ?? this.bestMoves,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'stars': stars,
        'bestMoves': bestMoves,
        'completed': completed,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelId: json['levelId'] as String,
      stars: json['stars'] as int? ?? 0,
      bestMoves: json['bestMoves'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class PlayerProgress {
  final int coins;
  final int lives;
  final DateTime lastLifeRegenTime;
  final int undoBoostersOwned;
  final Map<String, LevelProgress> levelProgress;
  final bool adsRemoved;
  final bool starterPackPurchased;
  final int currentWorld;
  final String? currentLevelId;
  final int totalStars;
  final int dailyStreak;
  final String? lastDailyCompletedDate;
  final Map<String, int> dailyCompletions;

  static const int maxLives = 5;
  static const Duration lifeRegenDuration = Duration(minutes: 30);
  static const int initialCoins = 100;
  static const int initialUndoBoosters = 2;

  const PlayerProgress({
    this.coins = initialCoins,
    this.lives = maxLives,
    required this.lastLifeRegenTime,
    this.undoBoostersOwned = initialUndoBoosters,
    this.levelProgress = const {},
    this.adsRemoved = false,
    this.starterPackPurchased = false,
    this.currentWorld = 1,
    this.currentLevelId,
    this.totalStars = 0,
    this.dailyStreak = 0,
    this.lastDailyCompletedDate,
    this.dailyCompletions = const {},
  });

  factory PlayerProgress.initial() {
    return PlayerProgress(
      lastLifeRegenTime: DateTime.now(),
    );
  }

  int get currentLives {
    if (lives >= maxLives) return maxLives;
    
    final now = DateTime.now();
    final elapsed = now.difference(lastLifeRegenTime);
    final livesRegen = elapsed.inMinutes ~/ lifeRegenDuration.inMinutes;
    return (lives + livesRegen).clamp(0, maxLives);
  }

  Duration? get timeUntilNextLife {
    if (currentLives >= maxLives) return null;
    
    final now = DateTime.now();
    final elapsed = now.difference(lastLifeRegenTime);
    final minutesIntoCurrentCycle = elapsed.inMinutes % lifeRegenDuration.inMinutes;
    return Duration(minutes: lifeRegenDuration.inMinutes - minutesIntoCurrentCycle);
  }

  bool isLevelUnlocked(String levelId, List<String> allLevelIds) {
    final index = allLevelIds.indexOf(levelId);
    if (index <= 0) return true;
    
    final previousLevelId = allLevelIds[index - 1];
    return levelProgress[previousLevelId]?.completed ?? false;
  }

  bool isDailyCompletedOn(DateTime date) {
    final key = _dateOnlyKey(date);
    return dailyCompletions.containsKey(key);
  }

  static String _dateOnlyKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  PlayerProgress recordDailyCompletion(DateTime date, int stars) {
    final key = _dateOnlyKey(date);
    final today = DateTime(date.year, date.month, date.day);
    final newCompletions = Map<String, int>.from(dailyCompletions);
    final previousStars = newCompletions[key] ?? 0;
    newCompletions[key] = stars > previousStars ? stars : previousStars;

    var streak = dailyStreak;
    if (lastDailyCompletedDate == null) {
      streak = 1;
    } else {
      final last = DateTime.tryParse(lastDailyCompletedDate!);
      if (last != null) {
        final lastDay = DateTime(last.year, last.month, last.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 0) {
          streak = dailyStreak;
        } else if (diff == 1) {
          streak = dailyStreak + 1;
        } else {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    }

    return copyWith(
      dailyStreak: streak,
      lastDailyCompletedDate: key,
      dailyCompletions: newCompletions,
    );
  }

  int getStarsForWorld(int world) {
    int stars = 0;
    for (final progress in levelProgress.values) {
      if (progress.levelId.startsWith('w$world-')) {
        stars += progress.stars;
      }
    }
    return stars;
  }

  PlayerProgress updateLevelProgress(String levelId, int stars, int moves) {
    final existing = levelProgress[levelId];
    final newProgress = LevelProgress(
      levelId: levelId,
      stars: existing != null ? (stars > existing.stars ? stars : existing.stars) : stars,
      bestMoves: existing != null && existing.bestMoves > 0
          ? (moves < existing.bestMoves ? moves : existing.bestMoves)
          : moves,
      completed: true,
    );

    final newLevelProgress = Map<String, LevelProgress>.from(levelProgress);
    newLevelProgress[levelId] = newProgress;

    final newTotalStars = newLevelProgress.values.fold<int>(0, (sum, p) => sum + p.stars);

    return copyWith(
      levelProgress: newLevelProgress,
      totalStars: newTotalStars,
    );
  }

  PlayerProgress addCoins(int amount) {
    return copyWith(coins: coins + amount);
  }

  PlayerProgress spendCoins(int amount) {
    if (coins < amount) return this;
    return copyWith(coins: coins - amount);
  }

  PlayerProgress useLife() {
    final current = currentLives;
    if (current <= 0) return this;
    
    return copyWith(
      lives: current - 1,
      lastLifeRegenTime: current == maxLives ? DateTime.now() : lastLifeRegenTime,
    );
  }

  PlayerProgress addLives(int amount) {
    return copyWith(
      lives: (currentLives + amount).clamp(0, maxLives),
      lastLifeRegenTime: DateTime.now(),
    );
  }

  PlayerProgress useUndoBooster() {
    if (undoBoostersOwned <= 0) return this;
    return copyWith(undoBoostersOwned: undoBoostersOwned - 1);
  }

  PlayerProgress addUndoBoosters(int amount) {
    return copyWith(undoBoostersOwned: undoBoostersOwned + amount);
  }

  PlayerProgress removeAds() {
    return copyWith(adsRemoved: true);
  }

  PlayerProgress purchaseStarterPack() {
    return copyWith(
      starterPackPurchased: true,
      adsRemoved: true,
      coins: coins + 1500,
      undoBoostersOwned: undoBoostersOwned + 3,
    );
  }

  PlayerProgress copyWith({
    int? coins,
    int? lives,
    DateTime? lastLifeRegenTime,
    int? undoBoostersOwned,
    Map<String, LevelProgress>? levelProgress,
    bool? adsRemoved,
    bool? starterPackPurchased,
    int? currentWorld,
    String? currentLevelId,
    int? totalStars,
    int? dailyStreak,
    String? lastDailyCompletedDate,
    Map<String, int>? dailyCompletions,
  }) {
    return PlayerProgress(
      coins: coins ?? this.coins,
      lives: lives ?? this.lives,
      lastLifeRegenTime: lastLifeRegenTime ?? this.lastLifeRegenTime,
      undoBoostersOwned: undoBoostersOwned ?? this.undoBoostersOwned,
      levelProgress: levelProgress ?? this.levelProgress,
      adsRemoved: adsRemoved ?? this.adsRemoved,
      starterPackPurchased: starterPackPurchased ?? this.starterPackPurchased,
      currentWorld: currentWorld ?? this.currentWorld,
      currentLevelId: currentLevelId ?? this.currentLevelId,
      totalStars: totalStars ?? this.totalStars,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyCompletedDate: lastDailyCompletedDate ?? this.lastDailyCompletedDate,
      dailyCompletions: dailyCompletions ?? this.dailyCompletions,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'lives': lives,
        'lastLifeRegenTime': lastLifeRegenTime.toIso8601String(),
        'undoBoostersOwned': undoBoostersOwned,
        'levelProgress':
            levelProgress.map((k, v) => MapEntry(k, v.toJson())),
        'adsRemoved': adsRemoved,
        'starterPackPurchased': starterPackPurchased,
        'currentWorld': currentWorld,
        'currentLevelId': currentLevelId,
        'totalStars': totalStars,
        'dailyStreak': dailyStreak,
        if (lastDailyCompletedDate != null) 'lastDailyCompletedDate': lastDailyCompletedDate,
        'dailyCompletions': dailyCompletions,
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    final progressMap = <String, LevelProgress>{};
    if (json['levelProgress'] != null) {
      final map = json['levelProgress'] as Map<String, dynamic>;
      for (final entry in map.entries) {
        progressMap[entry.key] =
            LevelProgress.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    final dailyMap = <String, int>{};
    if (json['dailyCompletions'] != null) {
      final raw = json['dailyCompletions'] as Map<String, dynamic>;
      for (final e in raw.entries) {
        dailyMap[e.key] = e.value as int;
      }
    }

    return PlayerProgress(
      coins: json['coins'] as int? ?? initialCoins,
      lives: json['lives'] as int? ?? maxLives,
      lastLifeRegenTime: json['lastLifeRegenTime'] != null
          ? DateTime.parse(json['lastLifeRegenTime'] as String)
          : DateTime.now(),
      undoBoostersOwned: json['undoBoostersOwned'] as int? ?? initialUndoBoosters,
      levelProgress: progressMap,
      adsRemoved: json['adsRemoved'] as bool? ?? false,
      starterPackPurchased: json['starterPackPurchased'] as bool? ?? false,
      currentWorld: json['currentWorld'] as int? ?? 1,
      currentLevelId: json['currentLevelId'] as String?,
      totalStars: json['totalStars'] as int? ?? 0,
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      lastDailyCompletedDate: json['lastDailyCompletedDate'] as String?,
      dailyCompletions: dailyMap,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PlayerProgress.fromJsonString(String json) {
    return PlayerProgress.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
}
