import 'dart:collection';
import '../models/models.dart';

class SolverResult {
  final bool solvable;
  final int optimalMoves;
  final List<String>? solution;
  final double branching;
  final int deadEnds;
  final int statesExplored;

  const SolverResult({
    required this.solvable,
    required this.optimalMoves,
    this.solution,
    required this.branching,
    required this.deadEnds,
    required this.statesExplored,
  });

  double get difficulty {
    if (!solvable) return 1.0;
    final normOptimal = (optimalMoves / 20.0).clamp(0.0, 1.0);
    final normDeadEnds = (deadEnds / (statesExplored + 1)).clamp(0.0, 1.0);
    final branchFactor = (branching / 5.0).clamp(0.0, 1.0);
    return 0.35 * normOptimal + 0.25 * normDeadEnds + 0.2 * branchFactor + 0.2 * 0.5;
  }

  @override
  String toString() =>
      'SolverResult(solvable: $solvable, optimal: $optimalMoves, difficulty: ${difficulty.toStringAsFixed(2)})';
}

class _SolverState {
  final Set<String> remainingBlockIds;
  final Map<String, List<BlockCell>> blockPositions;
  final List<_EchoState> echoShadows;
  final Set<String> unlockedBlockIds;

  _SolverState({
    required this.remainingBlockIds,
    required this.blockPositions,
    required this.echoShadows,
    required this.unlockedBlockIds,
  });

  factory _SolverState.fromGameState(GameState state) {
    return _SolverState(
      remainingBlockIds: state.blocks.map((b) => b.id).toSet(),
      blockPositions: {for (final b in state.blocks) b.id: List.from(b.cells)},
      echoShadows: state.echoShadows
          .map((e) => _EchoState(cells: Set.from(e.cells), remaining: e.remainingMoves))
          .toList(),
      unlockedBlockIds: Set.from(state.unlockedBlocks),
    );
  }

  String get hash {
    final blockHash = remainingBlockIds.toList()..sort();
    final echoHash = echoShadows.map((e) => '${e.remaining}:${e.cells.length}').join(',');
    return '${blockHash.join(',')}|$echoHash';
  }

  bool get isWon => remainingBlockIds.isEmpty;
}

class _EchoState {
  final Set<BlockCell> cells;
  final int remaining;

  _EchoState({required this.cells, required this.remaining});

  _EchoState decrement() => _EchoState(cells: cells, remaining: remaining - 1);
  bool get isExpired => remaining <= 0;
}

class _SearchNode {
  final _SolverState state;
  final int moves;
  final List<String> path;

  _SearchNode(this.state, this.moves, this.path);
}

class Solver {
  final Level level;
  final Map<String, Block> _blockMap;
  final int maxStates;

  Solver(this.level, {this.maxStates = 100000})
      : _blockMap = {for (final b in level.blocks) b.id: b};

  SolverResult solve() {
    final initialState = GameState.fromLevel(level);
    final initial = _SolverState.fromGameState(initialState);

    if (initial.isWon) {
      return const SolverResult(
        solvable: true,
        optimalMoves: 0,
        solution: [],
        branching: 0,
        deadEnds: 0,
        statesExplored: 1,
      );
    }

    final visited = <String>{initial.hash};
    final queue = Queue<_SearchNode>();
    queue.add(_SearchNode(initial, 0, []));

    int statesExplored = 0;
    int deadEnds = 0;
    int totalBranches = 0;
    int branchCount = 0;

    while (queue.isNotEmpty && statesExplored < maxStates) {
      final node = queue.removeFirst();
      statesExplored++;

      final validMoves = _getValidMoves(node.state);
      totalBranches += validMoves.length;
      branchCount++;

      if (validMoves.isEmpty && !node.state.isWon) {
        deadEnds++;
        continue;
      }

      for (final blockId in validMoves) {
        final nextState = _applyMove(node.state, blockId);
        if (nextState == null) continue;

        final newPath = [...node.path, blockId];

        if (nextState.isWon) {
          return SolverResult(
            solvable: true,
            optimalMoves: node.moves + 1,
            solution: newPath,
            branching: branchCount > 0 ? totalBranches / branchCount : 0,
            deadEnds: deadEnds,
            statesExplored: statesExplored,
          );
        }

        final hash = nextState.hash;
        if (!visited.contains(hash)) {
          visited.add(hash);
          queue.add(_SearchNode(nextState, node.moves + 1, newPath));
        }
      }
    }

    return SolverResult(
      solvable: false,
      optimalMoves: -1,
      branching: branchCount > 0 ? totalBranches / branchCount : 0,
      deadEnds: deadEnds,
      statesExplored: statesExplored,
    );
  }

  List<String> _getValidMoves(_SolverState state) {
    final moves = <String>[];
    for (final blockId in state.remainingBlockIds) {
      final block = _blockMap[blockId];
      if (block == null) continue;

      if (block.lockKeyBlockId != null &&
          state.remainingBlockIds.contains(block.lockKeyBlockId)) {
        continue;
      }

      final canMove = _canBlockMove(state, blockId);
      if (canMove) {
        moves.add(blockId);
      }
    }
    return moves;
  }

  bool _canBlockMove(_SolverState state, String blockId) {
    final block = _blockMap[blockId];
    if (block == null) return false;

    final cells = state.blockPositions[blockId];
    if (cells == null) return false;

    final delta = block.direction.delta;
    final nextCells = cells.map((c) => c + delta).toList();

    for (final cell in nextCells) {
      if (!_isCellInBounds(cell)) {
        if (!_canPassGate(block, cell)) {
          return false;
        }
        continue;
      }

      if (_isCellOccupied(state, cell, excludeBlockId: blockId)) {
        return false;
      }
    }

    return true;
  }

  bool _isCellInBounds(BlockCell cell) {
    return cell.x >= 0 &&
        cell.x < level.grid.width &&
        cell.y >= 0 &&
        cell.y < level.grid.height;
  }

  bool _isCellOccupied(_SolverState state, BlockCell cell, {String? excludeBlockId}) {
    for (final blockId in state.remainingBlockIds) {
      if (blockId == excludeBlockId) continue;
      final cells = state.blockPositions[blockId];
      if (cells != null && cells.contains(cell)) return true;
    }

    for (final shadow in state.echoShadows) {
      if (shadow.cells.contains(cell)) return true;
    }

    if (level.walls.contains(cell)) return true;

    return false;
  }

  bool _canPassGate(Block block, BlockCell exitCell) {
    if (level.gates.isEmpty) return true;

    final dir = block.direction;
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

  _SolverState? _applyMove(_SolverState state, String blockId) {
    final block = _blockMap[blockId];
    if (block == null) return null;

    final cells = state.blockPositions[blockId];
    if (cells == null) return null;

    final delta = block.direction.delta;
    var currentCells = cells.toList();

    while (true) {
      final nextCells = currentCells.map((c) => c + delta).toList();
      final allInBounds = nextCells.every(_isCellInBounds);

      if (!allInBounds) {
        final canExit = nextCells.every((cell) {
          if (_isCellInBounds(cell)) return true;
          return _canPassGate(block, cell);
        });

        if (canExit) {
          final newRemaining = Set<String>.from(state.remainingBlockIds)..remove(blockId);
          final newPositions = Map<String, List<BlockCell>>.from(state.blockPositions)
            ..remove(blockId);

          var newShadows = state.echoShadows
              .map((s) => s.decrement())
              .where((s) => !s.isExpired)
              .toList();

          if (block.isEcho) {
            newShadows.add(_EchoState(cells: Set.from(cells), remaining: 2));
          }

          return _SolverState(
            remainingBlockIds: newRemaining,
            blockPositions: newPositions,
            echoShadows: newShadows,
            unlockedBlockIds: state.unlockedBlockIds,
          );
        }
        return null;
      }

      final hasCollision =
          nextCells.any((c) => _isCellOccupied(state, c, excludeBlockId: blockId));
      if (hasCollision) {
        return null;
      }

      currentCells = nextCells;
    }
  }
}
