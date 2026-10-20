import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/models/models.dart';
import 'package:blockshade/widgets/game_grid.dart';

void main() {
  testWidgets('Verkstad game grid golden', (tester) async {
    final level = Level.fromJson({
      'id': 'golden-1',
      'world': 1,
      'grid': {'w': 4, 'h': 4},
      'moveLimit': 10,
      'blocks': [
        {
          'id': 'b1',
          'color': 'red',
          'direction': 'right',
          'cells': [
            [1, 1],
            [2, 1],
          ],
          'dir': 'right',
        },
        {
          'id': 'b2',
          'color': 'blue',
          'cells': [
            [0, 2],
          ],
          'dir': 'down',
          'echo': true,
        },
      ],
    });

    final state = GameState.fromLevel(level);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameGrid(
            gameState: state,
            cellSize: 48,
            world: 1,
            onBlockTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GameGrid),
      matchesGoldenFile('goldens/verkstad_grid.png'),
    );
  });

  testWidgets('Valvet game grid golden', (tester) async {
    final level = Level.fromJson({
      'id': 'golden-2',
      'world': 2,
      'grid': {'w': 4, 'h': 4},
      'moveLimit': 10,
      'blocks': [
        {
          'id': 'b1',
          'color': 'green',
          'direction': 'right',
          'cells': [
            [1, 1],
            [2, 1],
          ],
          'dir': 'right',
        },
      ],
    });

    final state = GameState.fromLevel(level);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameGrid(
            gameState: state,
            cellSize: 48,
            world: 2,
            onBlockTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GameGrid),
      matchesGoldenFile('goldens/verkstad_grid_valvet.png'),
    );
  });

  testWidgets('Hamnen game grid golden', (tester) async {
    final level = Level.fromJson({
      'id': 'golden-3',
      'world': 3,
      'grid': {'w': 4, 'h': 4},
      'moveLimit': 10,
      'gates': [
        {'side': 'top', 'x': 1, 'color': 'orange'},
      ],
      'blocks': [
        {
          'id': 'b1',
          'color': 'orange',
          'direction': 'up',
          'cells': [
            [1, 2],
          ],
          'dir': 'up',
        },
      ],
    });

    final state = GameState.fromLevel(level);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameGrid(
            gameState: state,
            cellSize: 48,
            world: 3,
            onBlockTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GameGrid),
      matchesGoldenFile('goldens/verkstad_grid_hamnen.png'),
    );
  });
}
