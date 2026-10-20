import '../models/models.dart';

enum GateAnimKind { open, knock }

class GateAnimEvent {
  const GateAnimEvent({
    required this.gate,
    required this.kind,
    required this.serial,
  });

  final Gate gate;
  final GateAnimKind kind;
  final int serial;
}

GateAnimEvent? gateAnimForOutcome(GameState state, MoveOutcome outcome, int serial) {
  final gate = _gateForBlockMove(state, outcome.block);
  if (gate == null) return null;
  switch (outcome.result) {
    case MoveResult.exit:
      if (gate.color == outcome.block.color) {
        return GateAnimEvent(gate: gate, kind: GateAnimKind.open, serial: serial);
      }
      return null;
    case MoveResult.bounce:
      if (gate.color != outcome.block.color) {
        return GateAnimEvent(gate: gate, kind: GateAnimKind.knock, serial: serial);
      }
      return null;
    case MoveResult.blocked:
      return null;
  }
}

Gate? _gateForBlockMove(GameState state, Block block) {
  final delta = block.direction.delta;
  final next = block.cells.map((c) => c + delta).toList();
  if (next.every(state.isCellInBounds)) return null;

  for (final cell in next) {
    if (state.isCellInBounds(cell)) continue;
    final side = _exitSide(cell, block.direction);
    final pos = _exitPosition(cell, block.direction);
    if (side == null || pos == null) continue;
    for (final gate in state.level.gates) {
      if (gate.side == side && gate.position == pos) {
        return gate;
      }
    }
  }
  return null;
}

GateSide? _exitSide(BlockCell cell, Direction dir) {
  if (dir == Direction.up) return GateSide.top;
  if (dir == Direction.down) return GateSide.bottom;
  if (dir == Direction.left) return GateSide.left;
  if (dir == Direction.right) return GateSide.right;
  return null;
}

int? _exitPosition(BlockCell cell, Direction dir) {
  if (dir == Direction.up || dir == Direction.down) return cell.x;
  if (dir == Direction.left || dir == Direction.right) return cell.y;
  return null;
}
