import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/models/models.dart';
import 'package:blockshade/services/solver.dart';

void main() {
  group('Solver', () {
    test('solves simple level with one block', () {
      final level = Level(
        id: 'test-1',
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

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, true);
      expect(result.optimalMoves, 1);
      expect(result.solution, ['a']);
    });

    test('solves level with two non-blocking blocks', () {
      final level = Level(
        id: 'test-2',
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
          Block(
            id: 'b',
            color: 'blue',
            cells: [const BlockCell(0, 0)],
            direction: Direction.up,
          ),
        ],
      );

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, true);
      expect(result.optimalMoves, 2);
    });

    test('solves level with blocking blocks', () {
      final level = Level(
        id: 'test-3',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 10,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(1, 2)],
            direction: Direction.right,
          ),
          Block(
            id: 'b',
            color: 'blue',
            cells: [const BlockCell(3, 2)],
            direction: Direction.right,
          ),
        ],
      );

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, true);
      expect(result.optimalMoves, 2);
      expect(result.solution?.first, 'b');
    });

    test('handles locked blocks correctly', () {
      final level = Level(
        id: 'test-4',
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

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, true);
      expect(result.optimalMoves, 2);
      expect(result.solution, ['a', 'b']);
    });

    test('handles echo blocks with shadows', () {
      final level = Level(
        id: 'test-5',
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
        ],
      );

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, true);
      expect(result.optimalMoves, 2);
    });

    test('handles color gates', () {
      final level = Level(
        id: 'test-6',
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

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, true);
      expect(result.optimalMoves, 1);
    });

    test('blocks wrong color at gate', () {
      final level = Level(
        id: 'test-7',
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

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, false);
    });

    test('handles walls blocking movement', () {
      final level = Level(
        id: 'test-8',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 5,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(1, 2)],
            direction: Direction.right,
          ),
        ],
        walls: [const BlockCell(3, 2)],
      );

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, false);
    });

    test('empty level is already solved', () {
      final level = Level(
        id: 'test-9',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 0,
        blocks: [],
      );

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, true);
      expect(result.optimalMoves, 0);
    });

    test('calculates branching factor', () {
      final level = Level(
        id: 'test-10',
        world: 1,
        grid: const GridSize(5, 5),
        moveLimit: 10,
        blocks: [
          Block(
            id: 'a',
            color: 'red',
            cells: [const BlockCell(2, 0)],
            direction: Direction.up,
          ),
          Block(
            id: 'b',
            color: 'blue',
            cells: [const BlockCell(0, 2)],
            direction: Direction.left,
          ),
          Block(
            id: 'c',
            color: 'green',
            cells: [const BlockCell(4, 4)],
            direction: Direction.down,
          ),
        ],
      );

      final solver = Solver(level);
      final result = solver.solve();

      expect(result.solvable, true);
      expect(result.branching, greaterThan(1.0));
    });
  });
}
