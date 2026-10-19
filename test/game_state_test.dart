import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/models/models.dart';

void main() {
  group('GameState', () {
    late Level simpleLevel;

    setUp(() {
      simpleLevel = Level(
        id: 'test-level',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 10,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(2, 2)],
            direction: Direction.right,
          ),
          Block(
            id: 'b',
            color: 'blue',
            cells: [const BlockCell(0, 0)],
            direction: Direction.up,
          ),
        ],
      );
    });

    test('creates initial state from level', () {
      final state = GameState.fromLevel(simpleLevel);

      expect(state.blocks.length, 2);
      expect(state.movesUsed, 0);
      expect(state.movesRemaining, 10);
      expect(state.isWon, false);
      expect(state.isLost, false);
    });

    test('applies valid move and removes block', () {
      final state = GameState.fromLevel(simpleLevel);
      final newState = state.applyMove('a');

      expect(newState.blocks.length, 1);
      expect(newState.movesUsed, 1);
      expect(newState.blocks.any((b) => b.id == 'a'), false);
    });

    test('tracks move history for undo', () {
      final state = GameState.fromLevel(simpleLevel);
      final afterMove = state.applyMove('a');

      expect(afterMove.canUndo(), true);
      
      final undone = afterMove.undo();
      expect(undone, isNotNull);
      expect(undone!.blocks.length, 2);
      expect(undone.movesUsed, 0);
    });

    test('detects win condition', () {
      final singleBlockLevel = Level(
        id: 'win-test',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 5,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(2, 2)],
            direction: Direction.right,
          ),
        ],
      );

      final state = GameState.fromLevel(singleBlockLevel);
      final afterMove = state.applyMove('a');

      expect(afterMove.isWon, true);
      expect(afterMove.isGameOver, true);
    });

    test('detects loss condition', () {
      final tightLevel = Level(
        id: 'lose-test',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 1,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(2, 2)],
            direction: Direction.right,
          ),
          Block(
            id: 'b',
            color: 'blue',
            cells: [const BlockCell(0, 0)],
            direction: Direction.up,
          ),
        ],
      );

      final state = GameState.fromLevel(tightLevel);
      final afterMove = state.applyMove('a');

      expect(afterMove.isLost, true);
      expect(afterMove.isGameOver, true);
    });

    test('handles locked blocks', () {
      final lockedLevel = Level(
        id: 'locked-test',
        world: 2,
        grid: const GridSize(5, 5),
        moveLimit: 10,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(0, 2)],
            direction: Direction.left,
          ),
          Block(
            id: 'b',
            color: 'blue',
            cells: [const BlockCell(4, 2)],
            direction: Direction.right,
            lockKeyBlockId: 'a',
          ),
        ],
      );

      final state = GameState.fromLevel(lockedLevel);
      
      expect(state.isBlockLocked(state.blocks[1]), true);
      
      final outcome = state.tryMoveBlock('b');
      expect(outcome?.result, MoveResult.blocked);
      
      final afterUnlocking = state.applyMove('a');
      expect(afterUnlocking.isBlockLocked(afterUnlocking.blocks[0]), false);
    });

    test('key is ready to exit only when its path is clear, and the lock opens on that exit', () {
      final ready = Level(
        id: 'ready-lock',
        world: 2,
        grid: const GridSize(5, 5),
        moveLimit: 6,
        blocks: [
          Block(
            id: 'a',
            color: 'blue',
            cells: [const BlockCell(0, 1)],
            direction: Direction.up,
          ),
          Block(
            id: 'b',
            color: 'red',
            cells: [const BlockCell(3, 1)],
            direction: Direction.up,
            lockKeyBlockId: 'a',
          ),
        ],
      );
      final state = GameState.fromLevel(ready);
      final locked = state.blocks.firstWhere((block) => block.id == 'b');
      expect(state.isBlockLocked(locked), isTrue);
      expect(state.isKeyReadyToExit(locked), isTrue);
      expect(state.tryMoveBlock('b')?.result, MoveResult.blocked);
      expect(state.tryMoveBlock('a')?.result, MoveResult.exit);

      final opened = state.applyMove('a');
      final stillThere = opened.blocks.single;
      expect(stillThere.id, 'b');
      expect(opened.isBlockLocked(stillThere), isFalse);
      expect(opened.isKeyReadyToExit(stillThere), isFalse);

      final blockedPath = Level(
        id: 'blocked-key',
        world: 2,
        grid: const GridSize(5, 5),
        moveLimit: 6,
        blocks: [
          Block(
            id: 'a',
            color: 'blue',
            cells: [const BlockCell(0, 2)],
            direction: Direction.up,
          ),
          Block(
            id: 'c',
            color: 'green',
            cells: [const BlockCell(0, 0)],
            direction: Direction.left,
          ),
          Block(
            id: 'b',
            color: 'red',
            cells: [const BlockCell(3, 3)],
            direction: Direction.down,
            lockKeyBlockId: 'a',
          ),
        ],
      );
      final crowded = GameState.fromLevel(blockedPath);
      final waiting = crowded.blocks.firstWhere((block) => block.id == 'b');
      expect(crowded.tryMoveBlock('a')?.result, isNot(MoveResult.exit));
      expect(crowded.isKeyReadyToExit(waiting), isFalse);
      expect(crowded.tryMoveBlock('b')?.result, MoveResult.blocked);
    });

    test('creates echo shadows', () {
      final echoLevel = Level(
        id: 'echo-test',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 10,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(2, 2)],
            direction: Direction.right,
            isEcho: true,
          ),
        ],
      );

      final state = GameState.fromLevel(echoLevel);
      final afterMove = state.applyMove('a');

      expect(afterMove.echoShadows.length, 1);
      expect(afterMove.echoShadows[0].remainingMoves, 2);
      expect(afterMove.echoShadows[0].cells, contains(const BlockCell(2, 2)));
    });

    test('echo shadows decrement and expire', () {
      final echoLevel = Level(
        id: 'echo-decay-test',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 10,
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
            cells: [const BlockCell(0, 0)],
            direction: Direction.up,
          ),
          Block(
            id: 'c',
            color: 'green',
            cells: [const BlockCell(4, 4)],
            direction: Direction.down,
          ),
        ],
      );

      final state = GameState.fromLevel(echoLevel);
      final afterA = state.applyMove('a');
      expect(afterA.echoShadows[0].remainingMoves, 2);

      final afterB = afterA.applyMove('b');
      expect(afterB.echoShadows[0].remainingMoves, 1);

      final afterC = afterB.applyMove('c');
      expect(afterC.echoShadows.isEmpty, true);
    });

    test('calculates stars based on moves', () {
      final level = Level(
        id: 'stars-test',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 10,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(2, 2)],
            direction: Direction.right,
          ),
        ],
        solver: const LevelSolverData(
          solvable: true,
          optimalMoves: 1,
          branching: 1.0,
          deadEnds: 0,
          difficulty: 0.2,
        ),
      );

      final state = GameState.fromLevel(level);
      final won = state.applyMove('a');

      expect(won.isWon, true);
      expect(won.stars, 3);
    });

    test('addMoves increases move limit', () {
      final state = GameState.fromLevel(simpleLevel);
      expect(state.movesRemaining, 10);

      final extended = state.addMoves(5);
      expect(extended.movesRemaining, 15);
    });

    test('checks cell occupation correctly', () {
      final state = GameState.fromLevel(simpleLevel);

      expect(state.isCellOccupied(const BlockCell(2, 2)), true);
      expect(state.isCellOccupied(const BlockCell(0, 0)), true);
      expect(state.isCellOccupied(const BlockCell(3, 3)), false);
      expect(state.isCellOccupied(const BlockCell(2, 2), excludeBlockId: 'a'), false);
    });

    test('handles gate passage for correct color', () {
      final gateLevel = Level(
        id: 'gate-test',
        world: 3,
        grid: const GridSize(5, 5),
        moveLimit: 5,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(2, 2)],
            direction: Direction.right,
          ),
        ],
        gates: [
          Gate(side: GateSide.right, position: 2, color: 'red'),
        ],
      );

      final state = GameState.fromLevel(gateLevel);
      final outcome = state.tryMoveBlock('a');

      expect(outcome?.result, MoveResult.exit);
    });

    test('blocks wrong color at gate', () {
      final gateLevel = Level(
        id: 'gate-block-test',
        world: 3,
        grid: const GridSize(5, 5),
        moveLimit: 5,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(2, 2)],
            direction: Direction.right,
          ),
        ],
        gates: [
          Gate(side: GateSide.right, position: 2, color: 'blue'),
        ],
      );

      final state = GameState.fromLevel(gateLevel);
      final outcome = state.tryMoveBlock('a');

      expect(outcome?.result, MoveResult.bounce);
    });
  });

  group('Block', () {
    test('creates from JSON', () {
      final json = {
        'id': 'a',
        'color': 'red',
        'cells': [[1, 2], [1, 3]],
        'dir': 'right',
        'echo': true,
        'lock': {'keyBlock': 'b'},
      };

      final block = Block.fromJson(json);

      expect(block.id, 'a');
      expect(block.color, 'red');
      expect(block.cells.length, 2);
      expect(block.direction, Direction.right);
      expect(block.isEcho, true);
      expect(block.lockKeyBlockId, 'b');
    });

    test('serializes to JSON', () {
      final block = Block(
        id: 'a',
        color: 'red',
        cells: [const BlockCell(1, 2)],
        direction: Direction.up,
        isEcho: true,
        lockKeyBlockId: 'b',
      );

      final json = block.toJson();

      expect(json['id'], 'a');
      expect(json['color'], 'red');
      expect(json['dir'], 'up');
      expect(json['echo'], true);
      expect(json['lock']['keyBlock'], 'b');
    });
  });

  group('Level', () {
    test('creates from JSON', () {
      final json = {
        'id': 'w1-001',
        'world': 1,
        'grid': {'w': 5, 'h': 6},
        'moveLimit': 10,
        'blocks': [
          {'id': 'a', 'color': 'red', 'cells': [[2, 2]], 'dir': 'right'},
        ],
        'gates': [
          {'side': 'top', 'x': 2, 'color': 'blue'},
        ],
        'walls': [[1, 1]],
        'solver': {
          'solvable': true,
          'optimalMoves': 5,
          'branching': 1.5,
          'deadEnds': 2,
          'difficulty': 0.4,
        },
      };

      final level = Level.fromJson(json);

      expect(level.id, 'w1-001');
      expect(level.world, 1);
      expect(level.grid.width, 5);
      expect(level.grid.height, 6);
      expect(level.moveLimit, 10);
      expect(level.blocks.length, 1);
      expect(level.gates.length, 1);
      expect(level.walls.length, 1);
      expect(level.solver?.solvable, true);
    });
  });
}
