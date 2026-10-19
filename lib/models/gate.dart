enum GateSide { top, bottom, left, right }

extension GateSideExtension on GateSide {
  static GateSide fromString(String s) {
    switch (s.toLowerCase()) {
      case 'top':
        return GateSide.top;
      case 'bottom':
        return GateSide.bottom;
      case 'left':
        return GateSide.left;
      case 'right':
        return GateSide.right;
      default:
        throw ArgumentError('Unknown gate side: $s');
    }
  }

  String toJsonString() {
    switch (this) {
      case GateSide.top:
        return 'top';
      case GateSide.bottom:
        return 'bottom';
      case GateSide.left:
        return 'left';
      case GateSide.right:
        return 'right';
    }
  }
}

class Gate {
  final GateSide side;
  final int position;
  final String color;

  const Gate({
    required this.side,
    required this.position,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'side': side.toJsonString(),
        if (side == GateSide.top || side == GateSide.bottom) 'x': position,
        if (side == GateSide.left || side == GateSide.right) 'y': position,
        'color': color,
      };

  factory Gate.fromJson(Map<String, dynamic> json) {
    final side = GateSideExtension.fromString(json['side'] as String);
    final position = (side == GateSide.top || side == GateSide.bottom)
        ? json['x'] as int
        : json['y'] as int;
    return Gate(
      side: side,
      position: position,
      color: json['color'] as String,
    );
  }

  @override
  String toString() => 'Gate($side, pos: $position, color: $color)';
}
