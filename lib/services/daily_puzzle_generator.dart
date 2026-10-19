import '../models/models.dart';
import 'level_generator.dart';
import 'solver.dart';

/// Input for isolate-safe daily generation (JSON-serializable).
class DailyGenerationInput {
  final String levelId;
  final int seed;
  final int maxPrimaryAttempts;
  final int maxFallbackAttempts;

  const DailyGenerationInput({
    required this.levelId,
    required this.seed,
    this.maxPrimaryAttempts = 25,
    this.maxFallbackAttempts = 15,
  });

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'seed': seed,
        'maxPrimaryAttempts': maxPrimaryAttempts,
        'maxFallbackAttempts': maxFallbackAttempts,
      };

  factory DailyGenerationInput.fromJson(Map<String, dynamic> json) {
    return DailyGenerationInput(
      levelId: json['levelId'] as String,
      seed: json['seed'] as int,
      maxPrimaryAttempts: json['maxPrimaryAttempts'] as int? ?? 25,
      maxFallbackAttempts: json['maxFallbackAttempts'] as int? ?? 15,
    );
  }
}

/// Top-level entry for [Isolate.run] / [compute].
Map<String, dynamic> generateDailyLevelInIsolate(Map<String, dynamic> message) {
  final input = DailyGenerationInput.fromJson(message);
  final level = _generateVerifiedLevel(input);
  return level.toJson();
}

Level _generateVerifiedLevel(DailyGenerationInput input) {
  final generator = LevelGenerator(seed: input.seed);

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

  final level = generator.generate(
    input.levelId,
    config,
    maxAttempts: input.maxPrimaryAttempts,
  );
  if (level != null) {
    final solver = Solver(level);
    final result = solver.solve();
    if (result.solvable) {
      return level;
    }
  }

  return _fallbackDailyLevel(input);
}

Level _fallbackDailyLevel(DailyGenerationInput input) {
  final generator = LevelGenerator(seed: input.seed + 7);
  final config = GeneratorConfig.forWorld(1, levelInWorld: 12, isBoss: false);
  final level = generator.generate(
    input.levelId,
    config,
    maxAttempts: input.maxFallbackAttempts,
  );
  if (level != null) {
    return Level(
      id: input.levelId,
      world: 0,
      grid: level.grid,
      moveLimit: level.moveLimit,
      blocks: level.blocks,
      gates: level.gates,
      walls: level.walls,
      solver: level.solver,
      seed: input.seed,
      generatorVersion: level.generatorVersion,
    );
  }

  return Level(
    id: input.levelId,
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
    seed: input.seed,
    generatorVersion: 'daily-fallback-inline',
  );
}
