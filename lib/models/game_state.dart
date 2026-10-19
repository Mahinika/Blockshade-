import 'block.dart';
import 'gate.dart';
import 'level.dart';

enum MoveResult {
  exit,
  bounce,
  blocked,
}

class MoveOutcome {
  final MoveResult result;
  final Block block;
  final List<BlockCell>? newPosition;
  final EchoShadow? newShadow;

  const MoveOutcome({
    required this.result,
    required this.block,
    this.newPosition,
    this.newShadow,
  });
}

class GameState {
  final Level level;
  final List<Block> blocks;
  final List<EchoShadow> echoShadows;
  final Set<String> unlockedBlocks;
  final int movesUsed;
  final int movesLimit;
  final List<GameState> history;

  const GameState({
    required this.level,
    required this.blocks,
    required this.echoShadows,
    required this.unlockedBlocks,
    required this.movesUsed,
    required this.movesLimit,
    this.history = const [],
  });

  factory GameState.fromLevel(Level level, {int extraMoves = 0}) {
    final initiallyUnlocked = <String>{};
    for (final block in level.blocks) {
      if (block.lockKeyBlockId == null) {
        initiallyUnlocked.add(block.id);
      }
    }
    return GameState(
      level: level,
      blocks: List.from(level.blocks),
      echoShadows: [],
      unlockedBlocks: initiallyUnlocked,
      movesUsed: 0,
      movesLimit: level.moveLimit + extraMoves,
      history: [],
    );
  }

  int get movesRemaining => movesLimit - movesUsed;
  bool get isWon => blocks.isEmpty;
  bool get isLost => !isWon && movesRemaining <= 0;
  bool get isGameOver => isWon || isLost;

  int get stars {
    if (!isWon) return 0;
    final optimal = level.solver?.optimalMoves ?? movesLimit;
    final margin = movesUsed - optimal;
    if (margin <= 0) return 3;
    if (margin <= 2) return 2;
    return 1;
  }

  bool isBlockLocked(Block block) {
    if (block.lockKeyBlockId == null) return false;
    return blocks.any((b) => b.id == block.lockKeyBlockId);
  }

  Set<BlockCell> get occupiedCells {
    final cells = <BlockCell>{};
    for (final block in blocks) {
      cells.addAll(block.cells);
    }
    for (final shadow in echoShadows) {
      cells.addAll(shadow.cells);
    }
    cells.addAll(level.walls);
    return cells;
  }

  bool isCellOccupied(BlockCell cell, {String? excludeBlockId}) {
    for (final block in blocks) {
      if (block.id == excludeBlockId) continue;
      if (block.cells.contains(cell)) return true;
    }
    for (final shadow in echoShadows) {
      if (shadow.cells.contains(cell)) return true;
    }
    if (level.walls.contains(cell)) return true;
    return false;
  }

  bool isCellInBounds(BlockCell cell) {
    return cell.x >= 0 &&
        cell.x < level.grid.width &&
        cell.y >= 0 &&
        cell.y < level.grid.height;
  }

  bool canBlockPassGate(Block block, BlockCell exitCell, Direction dir) {
    if (level.gates.isEmpty) return true;

    GateSide? exitSide;
    int? exitPos;

    if (dir == Direction.up && exitCell.y < 0) {
      exitSide = GateSide.top;
      exitPos = exitCell.x;
    } else if (dir == Direction.down && exitCell.y >= level.grid.height) {
      exitSide = GateSide.bottom;
      exitPos = exitCell.x;
    } else if (dir == Direction.left && exitCell.x < 0) {
      exitSide = GateSide.left;
      exitPos = exitCell.y;
    } else if (dir == Direction.right && exitCell.x >= level.grid.width) {
      exitSide = GateSide.right;
      exitPos = exitCell.y;
    }

    if (exitSide == null) return true;

    for (final gate in level.gates) {
      if (gate.side == exitSide && gate.position == exitPos) {
        return gate.color == block.color;
      }
    }
    return true;
  }

  MoveOutcome? tryMoveBlock(String blockId) {
    final blockIndex = blocks.indexWhere((b) => b.id == blockId);
    if (blockIndex == -1) return null;

    final block = blocks[blockIndex];
    
    if (isBlockLocked(block)) {
      return MoveOutcome(result: MoveResult.blocked, block: block);
    }

    final dir = block.direction;
    final delta = dir.delta;
    var currentCells = block.cells;
    var steps = 0;

    while (true) {
      final nextCells = currentCells.map((c) => c + delta).toList();
      final allInBounds = nextCells.every(isCellInBounds);

      if (!allInBounds) {
        final canPass = nextCells.every((cell) {
          if (isCellInBounds(cell)) return true;
          return canBlockPassGate(block, cell, dir);
        });

        if (canPass && steps > 0) {
          EchoShadow? newShadow;
          if (block.isEcho) {
            newShadow = EchoShadow(cells: block.cells, remainingMoves: 2);
          }
          return MoveOutcome(
            result: MoveResult.exit,
            block: block,
            newShadow: newShadow,
          );
        }
        return MoveOutcome(result: MoveResult.bounce, block: block);
      }

      final hasCollision = nextCells.any((c) => isCellOccupied(c, excludeBlockId: blockId));
      if (hasCollision) {
        return MoveOutcome(result: MoveResult.bounce, block: block);
      }

      currentCells = nextCells;
      steps++;
    }
  }

  GameState applyMove(String blockId) {
    final outcome = tryMoveBlock(blockId);
    if (outcome == null || outcome.result == MoveResult.blocked) {
      return this;
    }

    var newBlocks = List<Block>.from(blocks);
    var newShadows = List<EchoShadow>.from(echoShadows);
    var newUnlocked = Set<String>.from(unlockedBlocks);
    final newHistory = [...history, this];

    newShadows = newShadows
        .map((s) => s.decrementMoves())
        .where((s) => !s.isExpired)
        .toList();

    if (outcome.result == MoveResult.exit) {
      newBlocks.removeWhere((b) => b.id == blockId);
      
      for (final block in newBlocks) {
        if (block.lockKeyBlockId == blockId) {
          newUnlocked.add(block.id);
        }
      }

      if (outcome.newShadow != null) {
        newShadows.add(outcome.newShadow!);
      }
    }

    return GameState(
      level: level,
      blocks: newBlocks,
      echoShadows: newShadows,
      unlockedBlocks: newUnlocked,
      movesUsed: movesUsed + 1,
      movesLimit: movesLimit,
      history: newHistory,
    );
  }

  GameState? undo() {
    if (history.isEmpty) return null;
    return history.last;
  }

  bool canUndo() => history.isNotEmpty;

  GameState addMoves(int extraMoves) {
    return GameState(
      level: level,
      blocks: blocks,
      echoShadows: echoShadows,
      unlockedBlocks: unlockedBlocks,
      movesUsed: movesUsed,
      movesLimit: movesLimit + extraMoves,
      history: history,
    );
  }

  @override
  String toString() =>
      'GameState(moves: $movesUsed/$movesLimit, blocks: ${blocks.length}, shadows: ${echoShadows.length})';
}
