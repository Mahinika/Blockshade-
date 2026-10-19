import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/models/models.dart';
import 'package:blockshade/theme/move_arrows.dart';

void main() {
  test('arrow axis matches block orientation', () {
    expect(axisForDirection(Direction.left), MoveAxis.horizontal);
    expect(axisForDirection(Direction.right), MoveAxis.horizontal);
    expect(axisForDirection(Direction.up), MoveAxis.vertical);
    expect(axisForDirection(Direction.down), MoveAxis.vertical);
  });

  test('blocked side hides that arrowhead', () {
    final level = Level(
      id: 'arrow',
      world: 1,
      grid: const GridSize(4, 4),
      moveLimit: 5,
      blocks: const [
        Block(
          id: 'h',
          color: 'red',
          cells: [BlockCell(1, 1)],
          direction: Direction.right,
        ),
        Block(
          id: 'wallish',
          color: 'blue',
          cells: [BlockCell(0, 1)],
          direction: Direction.up,
        ),
      ],
    );
    final state = GameState.fromLevel(level);
    final horizontal = state.blocks.first;
    final heads = arrowHeadsFor(state, horizontal);

    expect(axisForDirection(horizontal.direction), MoveAxis.horizontal);
    expect(heads.negativeOpen, isFalse);
    expect(heads.positiveOpen, isTrue);
  });
}
