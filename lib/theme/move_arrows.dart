import '../models/models.dart';

/// Rörelseaxel för ett block (spelregler oförändrade – bara visning).
enum MoveAxis { horizontal, vertical }

MoveAxis axisForDirection(Direction direction) {
  switch (direction) {
    case Direction.left:
    case Direction.right:
      return MoveAxis.horizontal;
    case Direction.up:
    case Direction.down:
      return MoveAxis.vertical;
  }
}

/// Vilka pilspetsar som är öppna längs axeln (ett steg fritt).
class AxisArrowHeads {
  const AxisArrowHeads({
    required this.negativeOpen,
    required this.positiveOpen,
  });

  /// Vänster (horisontell) eller upp (vertikal).
  final bool negativeOpen;

  /// Höger (horisontell) eller ner (vertikal).
  final bool positiveOpen;
}

bool _sideOpen(GameState state, Block block, Direction direction) {
  final delta = direction.delta;
  final next = block.cells.map((c) => c + delta).toList();
  for (final cell in next) {
    if (!state.isCellInBounds(cell)) {
      if (!state.canBlockPassGate(block, cell, direction)) return false;
      continue;
    }
    if (state.isCellOccupied(cell, excludeBlockId: block.id)) return false;
  }
  return next.isNotEmpty;
}

AxisArrowHeads arrowHeadsFor(GameState state, Block block) {
  final axis = axisForDirection(block.direction);
  if (axis == MoveAxis.horizontal) {
    return AxisArrowHeads(
      negativeOpen: _sideOpen(state, block, Direction.left),
      positiveOpen: _sideOpen(state, block, Direction.right),
    );
  }
  return AxisArrowHeads(
    negativeOpen: _sideOpen(state, block, Direction.up),
    positiveOpen: _sideOpen(state, block, Direction.down),
  );
}

/// Sista rutorna blocket når längs sin spelriktning innan studs eller utgång.
List<BlockCell>? furthestSlideCells(GameState state, Block block) {
  if (state.isBlockLocked(block)) return null;

  final delta = block.direction.delta;
  var current = block.cells;
  List<BlockCell>? furthest;
  var steps = 0;

  while (true) {
    final next = current.map((c) => c + delta).toList();
    final allInBounds = next.every(state.isCellInBounds);
    if (!allInBounds) {
      return steps > 0 ? furthest : null;
    }
    final blocked = next.any((c) => state.isCellOccupied(c, excludeBlockId: block.id));
    if (blocked) {
      return steps > 0 ? furthest : null;
    }
    current = next;
    furthest = current;
    steps++;
    if (steps > state.level.grid.width + state.level.grid.height + 2) {
      return furthest;
    }
  }
}
