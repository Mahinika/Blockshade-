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
}
