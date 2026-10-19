import 'dart:ui';

enum Direction { up, down, left, right }

extension DirectionExtension on Direction {
  static Direction fromString(String s) {
    switch (s.toLowerCase()) {
      case 'up':
        return Direction.up;
      case 'down':
        return Direction.down;
      case 'left':
        return Direction.left;
      case 'right':
        return Direction.right;
      default:
        throw ArgumentError('Unknown direction: $s');
    }
  }

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

  Offset get delta {
    switch (this) {
      case Direction.up:
        return const Offset(0, -1);
      case Direction.down:
        return const Offset(0, 1);
      case Direction.left:
        return const Offset(-1, 0);
      case Direction.right:
        return const Offset(1, 0);
    }
  }
}

class BlockCell {
  final int x;
  final int y;

  const BlockCell(this.x, this.y);

  BlockCell operator +(Offset offset) {
    return BlockCell(x + offset.dx.toInt(), y + offset.dy.toInt());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockCell && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ (y.hashCode * 31);

  @override
  String toString() => 'BlockCell($x, $y)';

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory BlockCell.fromJson(List<dynamic> json) {
    return BlockCell(json[0] as int, json[1] as int);
  }
}

class Block {
  final String id;
  final String color;
  final List<BlockCell> cells;
  final Direction direction;
  final bool isEcho;
  final String? lockKeyBlockId;

  const Block({
    required this.id,
    required this.color,
    required this.cells,
    required this.direction,
    this.isEcho = false,
    this.lockKeyBlockId,
  });

  bool get isLocked => lockKeyBlockId != null;

  Block moveTo(List<BlockCell> newCells) {
    return Block(
      id: id,
      color: color,
      cells: newCells,
      direction: direction,
      isEcho: isEcho,
      lockKeyBlockId: lockKeyBlockId,
    );
  }

  Block unlock() {
    return Block(
      id: id,
      color: color,
      cells: cells,
      direction: direction,
      isEcho: isEcho,
      lockKeyBlockId: null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'color': color,
      'cells': cells.map((c) => [c.x, c.y]).toList(),
      'dir': direction.toJsonString(),
    };
    if (isEcho) json['echo'] = true;
    if (lockKeyBlockId != null) {
      json['lock'] = {'keyBlock': lockKeyBlockId};
    }
    return json;
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    final cellsList = (json['cells'] as List)
        .map((c) => BlockCell.fromJson(c as List))
        .toList();
    
    String? keyBlock;
    if (json['lock'] != null) {
      keyBlock = json['lock']['keyBlock'] as String?;
    }

    return Block(
      id: json['id'] as String,
      color: json['color'] as String,
      cells: cellsList,
      direction: DirectionExtension.fromString(json['dir'] as String),
      isEcho: json['echo'] as bool? ?? false,
      lockKeyBlockId: keyBlock,
    );
  }

  @override
  String toString() => 'Block($id, $color, $direction, cells: $cells)';
}

class EchoShadow {
  final List<BlockCell> cells;
  final int remainingMoves;

  const EchoShadow({
    required this.cells,
    required this.remainingMoves,
  });

  EchoShadow decrementMoves() {
    return EchoShadow(
      cells: cells,
      remainingMoves: remainingMoves - 1,
    );
  }

  bool get isExpired => remainingMoves <= 0;

  @override
  String toString() => 'EchoShadow(cells: $cells, remaining: $remainingMoves)';
}
