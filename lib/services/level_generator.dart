import 'dart:math';
import '../models/models.dart';
import 'solver.dart';

class GeneratorConfig {
  final int world;
  final int minBlocks;
  final int maxBlocks;
  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;
  final double echoBlockChance;
  final double lockedBlockChance;
  final double gateChance;
  final int wallCount;
  final int slack;

  const GeneratorConfig({
    required this.world,
    this.minBlocks = 4,
    this.maxBlocks = 10,
    this.minWidth = 5,
    this.maxWidth = 7,
    this.minHeight = 6,
    this.maxHeight = 8,
    this.echoBlockChance = 0.0,
    this.lockedBlockChance = 0.0,
    this.gateChance = 0.0,
    this.wallCount = 0,
    this.slack = 4,
  });

  factory GeneratorConfig.forWorld(int world, {required int levelInWorld, required bool isBoss}) {
    final difficulty = levelInWorld / 20.0;
    final slack = isBoss ? 1 : (6 - (difficulty * 4).round()).clamp(2, 6);

    switch (world) {
      case 1:
        return GeneratorConfig(
          world: 1,
          minBlocks: 3 + (difficulty * 4).round(),
          maxBlocks: 6 + (difficulty * 6).round(),
          minWidth: 5,
          maxWidth: 6 + (difficulty * 2).round(),
          minHeight: 6,
          maxHeight: 7 + (difficulty * 2).round(),
          echoBlockChance: levelInWorld >= 8 ? 0.2 + difficulty * 0.3 : 0.0,
          wallCount: (difficulty * 4).round(),
          slack: slack,
        );
      case 2:
        return GeneratorConfig(
          world: 2,
          minBlocks: 5 + (difficulty * 4).round(),
          maxBlocks: 8 + (difficulty * 5).round(),
          minWidth: 5,
          maxWidth: 7,
          minHeight: 6,
          maxHeight: 8,
          echoBlockChance: 0.15,
          lockedBlockChance: 0.25 + difficulty * 0.25,
          wallCount: (difficulty * 3).round(),
          slack: slack,
        );
      case 3:
        return GeneratorConfig(
          world: 3,
          minBlocks: 5 + (difficulty * 4).round(),
          maxBlocks: 9 + (difficulty * 4).round(),
          minWidth: 6,
          maxWidth: 8,
          minHeight: 6,
          maxHeight: 9,
          echoBlockChance: 0.1,
          lockedBlockChance: 0.1,
          gateChance: 0.3 + difficulty * 0.3,
          wallCount: (difficulty * 3).round(),
          slack: slack,
        );
      default:
        return GeneratorConfig(world: world, slack: slack);
    }
  }
}

class LevelGenerator {
  final Random _random;
  static const List<String> _colors = [
    'red', 'blue', 'green', 'yellow', 'purple', 'orange', 'cyan', 'pink'
  ];

  LevelGenerator({int? seed}) : _random = Random(seed);

  Level? generate(String levelId, GeneratorConfig config, {int maxAttempts = 100}) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final level = _generateCandidate(levelId, config);
      if (level != null) {
        final solver = Solver(level);
        final result = solver.solve();
        if (result.solvable && result.optimalMoves >= 3) {
          return Level(
            id: level.id,
            world: level.world,
            grid: level.grid,
            moveLimit: result.optimalMoves + config.slack,
            timeLimitSec: level.timeLimitSec,
            blocks: level.blocks,
            gates: level.gates,
            walls: level.walls,
            solver: LevelSolverData(
              solvable: true,
              optimalMoves: result.optimalMoves,
              branching: result.branching,
              deadEnds: result.deadEnds,
              difficulty: result.difficulty,
            ),
            seed: _random.nextInt(1 << 30),
            generatorVersion: '1.0',
          );
        }
      }
    }
    return null;
  }

  Level? _generateCandidate(String levelId, GeneratorConfig config) {
    final width = _random.nextInt(config.maxWidth - config.minWidth + 1) + config.minWidth;
    final height = _random.nextInt(config.maxHeight - config.minHeight + 1) + config.minHeight;
    final numBlocks = _random.nextInt(config.maxBlocks - config.minBlocks + 1) + config.minBlocks;

    final walls = _generateWalls(width, height, config.wallCount);
    final occupiedCells = <BlockCell>{...walls};
    final blocks = <Block>[];
    final exitedBlockIds = <String>[];

    for (var i = 0; i < numBlocks; i++) {
      final block = _placeBlockBackwards(
        blockIndex: i,
        width: width,
        height: height,
        occupiedCells: occupiedCells,
        exitedBlockIds: exitedBlockIds,
        config: config,
      );
      if (block == null) continue;

      blocks.add(block);
      occupiedCells.addAll(block.cells);
      exitedBlockIds.add(block.id);
    }

    if (blocks.length < config.minBlocks) return null;

    final gates = _generateGates(blocks, width, height, config);

    return Level(
      id: levelId,
      world: config.world,
      grid: GridSize(width, height),
      moveLimit: 20,
      blocks: blocks,
      gates: gates,
      walls: walls.toList(),
    );
  }

  List<BlockCell> _generateWalls(int width, int height, int count) {
    if (count <= 0) return [];

    final walls = <BlockCell>[];
    final attempts = count * 10;

    for (var i = 0; i < attempts && walls.length < count; i++) {
      final x = _random.nextInt(width);
      final y = _random.nextInt(height);
      final cell = BlockCell(x, y);
      
      if (!walls.contains(cell)) {
        walls.add(cell);
      }
    }

    return walls;
  }

  Block? _placeBlockBackwards({
    required int blockIndex,
    required int width,
    required int height,
    required Set<BlockCell> occupiedCells,
    required List<String> exitedBlockIds,
    required GeneratorConfig config,
  }) {
    final id = String.fromCharCode(97 + blockIndex);
    final color = _colors[blockIndex % _colors.length];
    final size = _random.nextDouble() < 0.3 ? 1 : (_random.nextDouble() < 0.6 ? 2 : 3);

    final directions = Direction.values.toList()..shuffle(_random);

    for (final dir in directions) {
      final cells = _findPlacementWithExit(
        width: width,
        height: height,
        size: size,
        direction: dir,
        occupiedCells: occupiedCells,
      );
      if (cells == null) continue;

      final isEcho = config.echoBlockChance > 0 && _random.nextDouble() < config.echoBlockChance;

      String? lockKeyBlock;
      if (config.lockedBlockChance > 0 &&
          exitedBlockIds.isNotEmpty &&
          _random.nextDouble() < config.lockedBlockChance) {
        lockKeyBlock = exitedBlockIds[_random.nextInt(exitedBlockIds.length)];
      }

      return Block(
        id: id,
        color: color,
        cells: cells,
        direction: dir,
        isEcho: isEcho,
        lockKeyBlockId: lockKeyBlock,
      );
    }

    return null;
  }

  List<BlockCell>? _findPlacementWithExit({
    required int width,
    required int height,
    required int size,
    required Direction direction,
    required Set<BlockCell> occupiedCells,
  }) {
    final positions = <List<BlockCell>>[];

    for (var x = 0; x < width; x++) {
      for (var y = 0; y < height; y++) {
        final cells = _getCellsForBlock(x, y, size, direction, width, height);
        if (cells == null) continue;

        if (cells.any(occupiedCells.contains)) continue;

        if (_hasExitPath(cells, direction, width, height, occupiedCells)) {
          positions.add(cells);
        }
      }
    }

    if (positions.isEmpty) return null;
    return positions[_random.nextInt(positions.length)];
  }

  List<BlockCell>? _getCellsForBlock(int x, int y, int size, Direction dir, int width, int height) {
    final cells = <BlockCell>[];

    if (dir == Direction.left || dir == Direction.right) {
      if (y + size > height) return null;
      for (var i = 0; i < size; i++) {
        cells.add(BlockCell(x, y + i));
      }
    } else {
      if (x + size > width) return null;
      for (var i = 0; i < size; i++) {
        cells.add(BlockCell(x + i, y));
      }
    }

    return cells;
  }

  bool _hasExitPath(
    List<BlockCell> cells,
    Direction direction,
    int width,
    int height,
    Set<BlockCell> occupiedCells,
  ) {
    final delta = direction.delta;
    var currentCells = cells.toList();

    while (true) {
      final nextCells = currentCells.map((c) => c + delta).toList();

      final anyOutOfBounds = nextCells.any((c) =>
          c.x < 0 || c.x >= width || c.y < 0 || c.y >= height);

      if (anyOutOfBounds) {
        return true;
      }

      if (nextCells.any(occupiedCells.contains)) {
        return false;
      }

      currentCells = nextCells;
    }
  }

  List<Gate> _generateGates(List<Block> blocks, int width, int height, GeneratorConfig config) {
    if (config.gateChance <= 0 || _random.nextDouble() > config.gateChance) {
      return [];
    }

    final gates = <Gate>[];
    final usedPositions = <String>{};
    final numGates = _random.nextInt(2) + 1;

    for (var i = 0; i < numGates; i++) {
      final side = GateSide.values[_random.nextInt(4)];
      final maxPos = (side == GateSide.top || side == GateSide.bottom) ? width : height;
      final pos = _random.nextInt(maxPos);
      final posKey = '${side.toJsonString()}-$pos';

      if (usedPositions.contains(posKey)) continue;
      usedPositions.add(posKey);

      final colorIndex = _random.nextInt(min(blocks.length, _colors.length));
      final color = blocks.isNotEmpty ? blocks[colorIndex].color : _colors[colorIndex];

      gates.add(Gate(side: side, position: pos, color: color));
    }

    return gates;
  }
}

class LevelBatchGenerator {
  final LevelGenerator _generator;

  LevelBatchGenerator({int? seed}) : _generator = LevelGenerator(seed: seed);

  List<Level> generateWorld(int world, int levelCount) {
    final levels = <Level>[];

    for (var i = 1; i <= levelCount; i++) {
      final levelId = 'w$world-${i.toString().padLeft(3, '0')}';
      final isBoss = i == levelCount;
      final config = GeneratorConfig.forWorld(world, levelInWorld: i, isBoss: isBoss);

      final level = _generator.generate(levelId, config);
      if (level != null) {
        levels.add(level);
      } else {
        final fallbackLevel = _createFallbackLevel(levelId, world, i);
        levels.add(fallbackLevel);
      }
    }

    return levels;
  }

  Level _createFallbackLevel(String levelId, int world, int levelNum) {
    final width = 5;
    final height = 6;
    final blocks = [
      Block(
        id: 'a',
        color: 'red',
        cells: [const BlockCell(2, 2)],
        direction: Direction.right,
      ),
      Block(
        id: 'b',
        color: 'blue',
        cells: [const BlockCell(1, 3), const BlockCell(1, 4)],
        direction: Direction.left,
      ),
    ];

    return Level(
      id: levelId,
      world: world,
      grid: GridSize(width, height),
      moveLimit: 10,
      blocks: blocks,
      solver: const LevelSolverData(
        solvable: true,
        optimalMoves: 2,
        branching: 1.0,
        deadEnds: 0,
        difficulty: 0.1,
      ),
    );
  }
}
