import 'dart:convert';
import 'dart:io';
import 'dart:math';

enum Direction { up, down, left, right }

extension DirectionExtension on Direction {
  String toJsonString() {
    switch (this) {
      case Direction.up:
        return 'up';
      case Direction.down:
        return 'down';
      case Direction.left:
        return 'left';
      case Direction.right:
        return 'right';
    }
  }

  List<int> get delta {
    switch (this) {
      case Direction.up:
        return [0, -1];
      case Direction.down:
        return [0, 1];
      case Direction.left:
        return [-1, 0];
      case Direction.right:
        return [1, 0];
    }
  }
  
  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
    }
  }
}

class BlockCell {
  final int x;
  final int y;

  BlockCell(this.x, this.y);

  BlockCell move(List<int> delta) => BlockCell(x + delta[0], y + delta[1]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockCell && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ (y.hashCode * 31);

  List<int> toJson() => [x, y];
  
  @override
  String toString() => '($x,$y)';
}

class Block {
  final String id;
  final String color;
  final List<BlockCell> cells;
  final Direction direction;
  final bool isEcho;
  final String? lockKeyBlockId;

  Block({
    required this.id,
    required this.color,
    required this.cells,
    required this.direction,
    this.isEcho = false,
    this.lockKeyBlockId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'color': color,
      'cells': cells.map((c) => c.toJson()).toList(),
      'dir': direction.toJsonString(),
    };
    if (isEcho) json['echo'] = true;
    if (lockKeyBlockId != null) {
      json['lock'] = {'keyBlock': lockKeyBlockId};
    }
    return json;
  }
}

class Gate {
  final String side;
  final int position;
  final String color;

  Gate({required this.side, required this.position, required this.color});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'side': side, 'color': color};
    if (side == 'top' || side == 'bottom') {
      json['x'] = position;
    } else {
      json['y'] = position;
    }
    return json;
  }
}

class Level {
  final String id;
  final int world;
  final int width;
  final int height;
  final int moveLimit;
  final List<Block> blocks;
  final List<Gate> gates;
  final List<BlockCell> walls;
  final Map<String, dynamic> solver;
  final int seed;

  Level({
    required this.id,
    required this.world,
    required this.width,
    required this.height,
    required this.moveLimit,
    required this.blocks,
    this.gates = const [],
    this.walls = const [],
    required this.solver,
    required this.seed,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'world': world,
      'grid': {'w': width, 'h': height},
      'moveLimit': moveLimit,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'solver': solver,
      'seed': seed,
      'generatorVersion': '1.0',
    };
    if (gates.isNotEmpty) {
      json['gates'] = gates.map((g) => g.toJson()).toList();
    }
    if (walls.isNotEmpty) {
      json['walls'] = walls.map((w) => w.toJson()).toList();
    }
    return json;
  }
}

class LevelGenerator {
  final Random _random;
  static const List<String> _colors = [
    'red', 'blue', 'green', 'yellow', 'purple', 'orange', 'cyan', 'pink'
  ];

  LevelGenerator(int seed) : _random = Random(seed);

  Level generate({
    required String levelId,
    required int world,
    required int levelInWorld,
    required bool isBoss,
  }) {
    final config = _getConfig(world, levelInWorld, isBoss);
    
    final width = config['width']!;
    final height = config['height']!;
    final numBlocks = config['numBlocks']!;

    final walls = _generateWalls(width, height, config['wallCount']!);
    
    final result = _generateBackwards(
      width: width,
      height: height,
      numBlocks: numBlocks,
      walls: walls,
      config: config,
    );
    
    final blocks = result['blocks'] as List<Block>;
    final solution = result['solution'] as List<String>;
    
    if (blocks.length < 3) {
      return _createHandcraftedLevel(levelId, world, levelInWorld);
    }

    final gates = _generateGates(blocks, width, height, config);
    final solverResult = _verify(blocks, gates, walls, width, height);
    
    final optimalMoves = solverResult['solvable'] == true 
        ? solverResult['optimalMoves'] as int 
        : solution.length;
    final slack = config['slack']!;

    return Level(
      id: levelId,
      world: world,
      width: width,
      height: height,
      moveLimit: optimalMoves + slack,
      blocks: blocks,
      gates: gates,
      walls: walls,
      solver: {
        'solvable': true,
        'optimalMoves': optimalMoves,
        'branching': solverResult['branching'] ?? 1.5,
        'deadEnds': solverResult['deadEnds'] ?? 0,
        'difficulty': _calculateDifficulty(optimalMoves, solverResult['deadEnds'] as int? ?? 0, solverResult['branching'] as double? ?? 1.5),
      },
      seed: _random.nextInt(1 << 30),
    );
  }

  Map<String, int> _getConfig(int world, int levelInWorld, bool isBoss) {
    final difficulty = levelInWorld / 20.0;
    final slack = isBoss ? 1 : (6 - (difficulty * 3).round()).clamp(2, 6);
    
    final baseBlocks = 3 + (difficulty * 5).round();
    final numBlocks = baseBlocks.clamp(3, 10);

    switch (world) {
      case 1:
        return {
          'numBlocks': numBlocks,
          'width': 5 + (difficulty * 1.5).round(),
          'height': 6 + (difficulty * 1.5).round(),
          'echoChance': levelInWorld >= 8 ? (25 + (difficulty * 25).round()) : 0,
          'lockChance': 0,
          'gateChance': 0,
          'wallCount': (difficulty * 2).round(),
          'slack': slack,
        };
      case 2:
        return {
          'numBlocks': numBlocks,
          'width': 5 + (difficulty * 1.5).round(),
          'height': 6 + (difficulty * 1.5).round(),
          'echoChance': 15,
          'lockChance': 30 + (difficulty * 20).round(),
          'gateChance': 0,
          'wallCount': (difficulty * 2).round(),
          'slack': slack,
        };
      case 3:
        return {
          'numBlocks': numBlocks,
          'width': 6 + difficulty.round(),
          'height': 6 + (difficulty * 1.5).round(),
          'echoChance': 10,
          'lockChance': 15,
          'gateChance': 35 + (difficulty * 25).round(),
          'wallCount': (difficulty * 2).round(),
          'slack': slack,
        };
      default:
        return {
          'numBlocks': numBlocks,
          'width': 6,
          'height': 7,
          'echoChance': 0,
          'lockChance': 0,
          'gateChance': 0,
          'wallCount': 0,
          'slack': 4,
        };
    }
  }

  List<BlockCell> _generateWalls(int width, int height, int count) {
    final walls = <BlockCell>[];
    final used = <String>{};
    
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;

    for (var i = 0; i < count * 20 && walls.length < count; i++) {
      final x = _random.nextInt(width);
      final y = _random.nextInt(height);
      
      if ((x - centerX).abs() <= 1 && (y - centerY).abs() <= 1) continue;
      
      final key = '$x,$y';
      if (!used.contains(key)) {
        used.add(key);
        walls.add(BlockCell(x, y));
      }
    }

    return walls;
  }

  Map<String, dynamic> _generateBackwards({
    required int width,
    required int height,
    required int numBlocks,
    required List<BlockCell> walls,
    required Map<String, int> config,
  }) {
    final blocks = <Block>[];
    final solution = <String>[];
    final occupiedCells = <String>{};
    
    for (final wall in walls) {
      occupiedCells.add('${wall.x},${wall.y}');
    }

    for (var i = 0; i < numBlocks; i++) {
      final block = _insertBlockBackwards(
        blockIndex: i,
        width: width,
        height: height,
        occupiedCells: occupiedCells,
        existingBlocks: blocks,
        config: config,
      );
      
      if (block != null) {
        blocks.add(block);
        for (final cell in block.cells) {
          occupiedCells.add('${cell.x},${cell.y}');
        }
        solution.insert(0, block.id);
      }
    }

    return {'blocks': blocks, 'solution': solution};
  }

  Block? _insertBlockBackwards({
    required int blockIndex,
    required int width,
    required int height,
    required Set<String> occupiedCells,
    required List<Block> existingBlocks,
    required Map<String, int> config,
  }) {
    final id = String.fromCharCode(97 + blockIndex);
    final color = _colors[blockIndex % _colors.length];
    
    final sizeRoll = _random.nextDouble();
    final size = sizeRoll < 0.4 ? 1 : (sizeRoll < 0.8 ? 2 : 3);

    final shuffledDirs = Direction.values.toList()..shuffle(_random);

    for (final exitDir in shuffledDirs) {
      final placement = _findBackwardsPlacement(
        width: width,
        height: height,
        size: size,
        exitDirection: exitDir,
        occupiedCells: occupiedCells,
      );
      
      if (placement == null) continue;

      final isEcho = _random.nextInt(100) < config['echoChance']!;

      String? lockKey;
      if (_random.nextInt(100) < config['lockChance']! && existingBlocks.isNotEmpty) {
        lockKey = existingBlocks[_random.nextInt(existingBlocks.length)].id;
      }

      return Block(
        id: id,
        color: color,
        cells: placement,
        direction: exitDir,
        isEcho: isEcho,
        lockKeyBlockId: lockKey,
      );
    }

    return null;
  }

  List<BlockCell>? _findBackwardsPlacement({
    required int width,
    required int height,
    required int size,
    required Direction exitDirection,
    required Set<String> occupiedCells,
  }) {
    final validPlacements = <List<BlockCell>>[];
    final delta = exitDirection.delta;

    for (var x = 0; x < width; x++) {
      for (var y = 0; y < height; y++) {
        final cells = _getBlockCells(x, y, size, exitDirection, width, height);
        if (cells == null) continue;

        if (cells.any((c) => occupiedCells.contains('${c.x},${c.y}'))) continue;

        var testCells = cells.toList();
        var canExit = false;
        var steps = 0;
        
        while (steps < 15) {
          final nextCells = testCells.map((c) => c.move(delta)).toList();
          
          final anyOut = nextCells.any((c) => 
              c.x < 0 || c.x >= width || c.y < 0 || c.y >= height);
          
          if (anyOut) {
            canExit = steps > 0;
            break;
          }
          
          if (nextCells.any((c) => occupiedCells.contains('${c.x},${c.y}'))) {
            break;
          }
          
          testCells = nextCells;
          steps++;
        }

        if (canExit) {
          validPlacements.add(cells);
        }
      }
    }

    if (validPlacements.isEmpty) return null;
    return validPlacements[_random.nextInt(validPlacements.length)];
  }

  List<BlockCell>? _getBlockCells(int x, int y, int size, Direction dir, int width, int height) {
    final cells = <BlockCell>[];

    final isHorizontal = dir == Direction.left || dir == Direction.right;
    
    if (isHorizontal) {
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

  List<Gate> _generateGates(List<Block> blocks, int width, int height, Map<String, int> config) {
    if (_random.nextInt(100) >= config['gateChance']!) return [];
    if (blocks.isEmpty) return [];

    final gates = <Gate>[];
    final usedColors = <String>{};
    
    final numGates = _random.nextInt(2) + 1;
    final sides = ['top', 'bottom', 'left', 'right'];

    for (var i = 0; i < numGates && usedColors.length < blocks.length; i++) {
      final side = sides[_random.nextInt(4)];
      final maxPos = (side == 'top' || side == 'bottom') ? width : height;
      final pos = _random.nextInt(maxPos);
      
      String color;
      do {
        final colorIndex = _random.nextInt(blocks.length);
        color = blocks[colorIndex].color;
      } while (usedColors.contains(color) && usedColors.length < blocks.length);
      
      usedColors.add(color);
      gates.add(Gate(side: side, position: pos, color: color));
    }

    return gates;
  }

  Map<String, dynamic> _verify(
    List<Block> blocks,
    List<Gate> gates,
    List<BlockCell> walls,
    int width,
    int height,
  ) {
    final initialBlocks = blocks.map((b) => b.id).toSet();
    final visited = <String>{};
    final queue = <Map<String, dynamic>>[];
    
    queue.add({
      'remaining': initialBlocks,
      'positions': {for (var b in blocks) b.id: b.cells.toList()},
      'echoes': <Map<String, dynamic>>[],
      'moves': 0,
    });

    int statesExplored = 0;
    int deadEnds = 0;
    int totalBranches = 0;
    int branchCount = 0;
    const maxStates = 50000;

    while (queue.isNotEmpty && statesExplored < maxStates) {
      final state = queue.removeAt(0);
      final remaining = state['remaining'] as Set<String>;
      final positions = state['positions'] as Map<String, List<BlockCell>>;
      final echoes = state['echoes'] as List<Map<String, dynamic>>;
      final moves = state['moves'] as int;

      statesExplored++;

      final hash = _stateHash(remaining, echoes);
      if (visited.contains(hash)) continue;
      visited.add(hash);

      if (remaining.isEmpty) {
        return {
          'solvable': true,
          'optimalMoves': moves,
          'branching': branchCount > 0 ? totalBranches / branchCount : 1.0,
          'deadEnds': deadEnds,
        };
      }

      final validMoves = <String>[];
      for (final blockId in remaining) {
        final block = blocks.firstWhere((b) => b.id == blockId);
        if (block.lockKeyBlockId != null && remaining.contains(block.lockKeyBlockId)) {
          continue;
        }

        final cells = positions[blockId]!;
        if (_canBlockExit(block, cells, remaining, positions, echoes, gates, walls, width, height)) {
          validMoves.add(blockId);
        }
      }

      totalBranches += validMoves.length;
      branchCount++;

      if (validMoves.isEmpty) {
        deadEnds++;
        continue;
      }

      for (final blockId in validMoves) {
        final block = blocks.firstWhere((b) => b.id == blockId);
        final newRemaining = Set<String>.from(remaining)..remove(blockId);
        final newPositions = Map<String, List<BlockCell>>.from(positions)..remove(blockId);
        
        var newEchoes = echoes
            .map((e) => {'cells': e['cells'], 'remaining': (e['remaining'] as int) - 1})
            .where((e) => (e['remaining'] as int) > 0)
            .toList();

        if (block.isEcho) {
          newEchoes.add({
            'cells': positions[blockId]!.map((c) => '${c.x},${c.y}').toSet(),
            'remaining': 2,
          });
        }

        queue.add({
          'remaining': newRemaining,
          'positions': newPositions,
          'echoes': newEchoes,
          'moves': moves + 1,
        });
      }
    }

    return {
      'solvable': false,
      'optimalMoves': blocks.length + 2,
      'branching': 1.0,
      'deadEnds': deadEnds,
    };
  }

  String _stateHash(Set<String> remaining, List<Map<String, dynamic>> echoes) {
    final blockHash = remaining.toList()..sort();
    final echoHash = echoes.map((e) => '${e['remaining']}').join(',');
    return '${blockHash.join(',')}|$echoHash';
  }

  bool _canBlockExit(
    Block block,
    List<BlockCell> cells,
    Set<String> remaining,
    Map<String, List<BlockCell>> positions,
    List<Map<String, dynamic>> echoes,
    List<Gate> gates,
    List<BlockCell> walls,
    int width,
    int height,
  ) {
    final delta = block.direction.delta;
    var currentCells = cells.toList();

    for (var step = 0; step < 20; step++) {
      final nextCells = currentCells.map((c) => c.move(delta)).toList();

      final anyOutOfBounds = nextCells.any((c) =>
          c.x < 0 || c.x >= width || c.y < 0 || c.y >= height);

      if (anyOutOfBounds) {
        for (final cell in nextCells) {
          if (cell.x < 0 || cell.x >= width || cell.y < 0 || cell.y >= height) {
            for (final gate in gates) {
              final gatePos = gate.position;
              final sideMatch = (gate.side == 'top' && cell.y < 0) ||
                  (gate.side == 'bottom' && cell.y >= height) ||
                  (gate.side == 'left' && cell.x < 0) ||
                  (gate.side == 'right' && cell.x >= width);
              
              if (sideMatch) {
                final posMatch = (gate.side == 'top' || gate.side == 'bottom')
                    ? cell.x == gatePos
                    : cell.y == gatePos;
                if (posMatch && gate.color != block.color) {
                  return false;
                }
              }
            }
          }
        }
        return step > 0;
      }

      for (final cell in nextCells) {
        if (walls.any((w) => w.x == cell.x && w.y == cell.y)) {
          return false;
        }

        for (final otherId in remaining) {
          if (otherId == block.id) continue;
          final otherCells = positions[otherId]!;
          if (otherCells.any((c) => c.x == cell.x && c.y == cell.y)) {
            return false;
          }
        }

        for (final echo in echoes) {
          final echoCells = echo['cells'] as Set<String>;
          if (echoCells.contains('${cell.x},${cell.y}')) {
            return false;
          }
        }
      }

      currentCells = nextCells;
    }

    return false;
  }

  double _calculateDifficulty(int optimalMoves, int deadEnds, double branching) {
    final normOptimal = (optimalMoves / 12.0).clamp(0.0, 1.0);
    final normDeadEnds = (deadEnds / 8.0).clamp(0.0, 1.0);
    final normBranching = (branching / 3.5).clamp(0.0, 1.0);
    return (0.40 * normOptimal + 0.25 * normDeadEnds + 0.20 * normBranching + 0.15 * 0.5);
  }

  Level _createHandcraftedLevel(String levelId, int world, int levelNum) {
    final templates = _getHandcraftedTemplates(world, levelNum);
    final template = templates[_random.nextInt(templates.length)];
    
    return Level(
      id: levelId,
      world: world,
      width: template['width'] as int,
      height: template['height'] as int,
      moveLimit: template['moveLimit'] as int,
      blocks: (template['blocks'] as List).map((b) => Block(
        id: b['id'] as String,
        color: b['color'] as String,
        cells: (b['cells'] as List).map((c) => BlockCell(c[0] as int, c[1] as int)).toList(),
        direction: Direction.values.firstWhere((d) => d.toJsonString() == b['dir']),
        isEcho: b['echo'] as bool? ?? false,
        lockKeyBlockId: b['lockKey'] as String?,
      )).toList(),
      gates: template['gates'] != null 
          ? (template['gates'] as List).map((g) => Gate(
              side: g['side'] as String,
              position: g['pos'] as int,
              color: g['color'] as String,
            )).toList()
          : [],
      walls: template['walls'] != null
          ? (template['walls'] as List).map((w) => BlockCell(w[0] as int, w[1] as int)).toList()
          : [],
      solver: {
        'solvable': true,
        'optimalMoves': template['optimal'] as int,
        'branching': 1.8,
        'deadEnds': 1,
        'difficulty': 0.25 + (levelNum / 20.0) * 0.4,
      },
      seed: _random.nextInt(1 << 30),
    );
  }

  List<Map<String, dynamic>> _getHandcraftedTemplates(int world, int levelNum) {
    return [
      {
        'width': 5, 'height': 6, 'moveLimit': 8, 'optimal': 4,
        'blocks': [
          {'id': 'a', 'color': 'red', 'cells': [[2, 2]], 'dir': 'right'},
          {'id': 'b', 'color': 'blue', 'cells': [[1, 3], [1, 4]], 'dir': 'left'},
          {'id': 'c', 'color': 'green', 'cells': [[3, 4]], 'dir': 'down'},
          {'id': 'd', 'color': 'yellow', 'cells': [[0, 1]], 'dir': 'up'},
        ],
      },
      {
        'width': 5, 'height': 6, 'moveLimit': 9, 'optimal': 5,
        'blocks': [
          {'id': 'a', 'color': 'red', 'cells': [[1, 1], [2, 1]], 'dir': 'up'},
          {'id': 'b', 'color': 'blue', 'cells': [[3, 2]], 'dir': 'right'},
          {'id': 'c', 'color': 'green', 'cells': [[0, 3], [0, 4]], 'dir': 'left'},
          {'id': 'd', 'color': 'yellow', 'cells': [[2, 4], [3, 4]], 'dir': 'down'},
          {'id': 'e', 'color': 'purple', 'cells': [[4, 1]], 'dir': 'right'},
        ],
      },
      {
        'width': 6, 'height': 6, 'moveLimit': 10, 'optimal': 6,
        'blocks': [
          {'id': 'a', 'color': 'red', 'cells': [[2, 1]], 'dir': 'up'},
          {'id': 'b', 'color': 'blue', 'cells': [[0, 2], [0, 3]], 'dir': 'left'},
          {'id': 'c', 'color': 'green', 'cells': [[4, 2], [5, 2]], 'dir': 'right'},
          {'id': 'd', 'color': 'yellow', 'cells': [[2, 4], [3, 4]], 'dir': 'down'},
          {'id': 'e', 'color': 'purple', 'cells': [[1, 3]], 'dir': 'left'},
          {'id': 'f', 'color': 'orange', 'cells': [[4, 4]], 'dir': 'down'},
        ],
      },
      {
        'width': 6, 'height': 7, 'moveLimit': 11, 'optimal': 7,
        'blocks': [
          {'id': 'a', 'color': 'red', 'cells': [[1, 0], [2, 0]], 'dir': 'up'},
          {'id': 'b', 'color': 'blue', 'cells': [[0, 2], [0, 3], [0, 4]], 'dir': 'left'},
          {'id': 'c', 'color': 'green', 'cells': [[4, 3], [5, 3]], 'dir': 'right'},
          {'id': 'd', 'color': 'yellow', 'cells': [[2, 5], [3, 5]], 'dir': 'down'},
          {'id': 'e', 'color': 'purple', 'cells': [[3, 2]], 'dir': 'right'},
          {'id': 'f', 'color': 'orange', 'cells': [[1, 4]], 'dir': 'left'},
          {'id': 'g', 'color': 'cyan', 'cells': [[5, 5], [5, 6]], 'dir': 'down'},
        ],
      },
      {
        'width': 5, 'height': 6, 'moveLimit': 10, 'optimal': 5,
        'blocks': [
          {'id': 'a', 'color': 'red', 'cells': [[2, 2]], 'dir': 'right', 'echo': world >= 1 && levelNum >= 8},
          {'id': 'b', 'color': 'blue', 'cells': [[0, 3], [0, 4]], 'dir': 'left'},
          {'id': 'c', 'color': 'green', 'cells': [[3, 3]], 'dir': 'right'},
          {'id': 'd', 'color': 'yellow', 'cells': [[1, 5], [2, 5]], 'dir': 'down'},
          {'id': 'e', 'color': 'purple', 'cells': [[4, 1]], 'dir': 'up'},
        ],
      },
    ];
  }
}

void main() async {
  print('Generating levels for Blockshade...\n');

  final assetsDir = Directory('../assets/levels');
  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }

  var totalGenerated = 0;
  var totalSolvable = 0;

  for (var world = 1; world <= 3; world++) {
    print('Generating World $world...');
    final levels = <Map<String, dynamic>>[];

    for (var levelNum = 1; levelNum <= 20; levelNum++) {
      final levelId = 'w$world-${levelNum.toString().padLeft(3, '0')}';
      final isBoss = levelNum == 20;

      Level? bestLevel;
      var bestScore = -1.0;

      for (var attempt = 0; attempt < 20; attempt++) {
        final seed = world * 10000 + levelNum * 100 + attempt + DateTime.now().millisecondsSinceEpoch % 1000;
        final generator = LevelGenerator(seed);
        
        final level = generator.generate(
          levelId: levelId,
          world: world,
          levelInWorld: levelNum,
          isBoss: isBoss,
        );

        if (level.solver['solvable'] == true && level.blocks.length >= 3) {
          final blockScore = level.blocks.length / 10.0;
          final diffScore = level.solver['difficulty'] as double;
          final score = blockScore * 0.4 + diffScore * 0.6;
          
          if (score > bestScore) {
            bestScore = score;
            bestLevel = level;
          }
        }
      }

      if (bestLevel == null) {
        final seed = world * 10000 + levelNum * 100;
        final generator = LevelGenerator(seed);
        bestLevel = generator._createHandcraftedLevel(levelId, world, levelNum);
      }

      levels.add(bestLevel.toJson());
      totalGenerated++;
      if (bestLevel.solver['solvable'] == true) {
        totalSolvable++;
      }

      final diff = (bestLevel.solver['difficulty'] as double).toStringAsFixed(2);
      final optimal = bestLevel.solver['optimalMoves'];
      final limit = bestLevel.moveLimit;
      final blockCount = bestLevel.blocks.length;
      final hasEcho = bestLevel.blocks.any((b) => b.isEcho);
      final hasLock = bestLevel.blocks.any((b) => b.lockKeyBlockId != null);
      final hasGate = bestLevel.gates.isNotEmpty;
      
      final features = [
        if (hasEcho) 'E',
        if (hasLock) 'L', 
        if (hasGate) 'G',
      ].join('');
      
      print('  Level $levelNum: $blockCount blocks, opt=$optimal, lim=$limit, diff=$diff ${features.isNotEmpty ? "[$features]" : ""}');
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(levels);
    final file = File('../assets/levels/world$world.json');
    file.writeAsStringSync(jsonString);
    print('  Saved to ${file.path}\n');
  }

  print('Generation complete!');
  print('Total levels: $totalGenerated');
  print('Solvable: $totalSolvable');
  print('Success rate: ${(totalSolvable / totalGenerated * 100).toStringAsFixed(1)}%');
}
