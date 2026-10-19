import 'package:flutter/material.dart';
import '../models/models.dart';
import '../painters/wood_block_painter.dart';
import '../theme/block_symbols.dart';
import '../utils/colors.dart';

class GateWidget extends StatelessWidget {
  final Gate gate;
  final double cellSize;
  final int gridWidth;
  final int gridHeight;
  final double gateThickness;

  const GateWidget({
    super.key,
    required this.gate,
    required this.cellSize,
    required this.gridWidth,
    required this.gridHeight,
    required this.gateThickness,
  });

  @override
  Widget build(BuildContext context) {
    final color = BlockColors.getBlockColor(gate.color);

    double left, top, width, height;

    switch (gate.side) {
      case GateSide.top:
        left = gate.position * cellSize + gateThickness;
        top = 0;
        width = cellSize;
        height = gateThickness;
        break;
      case GateSide.bottom:
        left = gate.position * cellSize + gateThickness;
        top = gridHeight * cellSize + gateThickness;
        width = cellSize;
        height = gateThickness;
        break;
      case GateSide.left:
        left = 0;
        top = gate.position * cellSize + gateThickness;
        width = gateThickness;
        height = cellSize;
        break;
      case GateSide.right:
        left = gridWidth * cellSize + gateThickness;
        top = gate.position * cellSize + gateThickness;
        width = gateThickness;
        height = cellSize;
        break;
    }

    final symbol = BlockSymbols.forColorName(gate.color);

    return Positioned(
      left: left,
      top: top,
      child: CustomPaint(
        size: Size(width, height),
        painter: WoodBlockPainter(
          fillColor: color,
          colorName: gate.color,
          textureSeed: gate.position + gate.color.hashCode,
          showDirection: false,
        ),
        child: symbol != null
            ? CustomPaint(
                painter: _GateSymbolPainter(gate.color),
              )
            : null,
      ),
    );
  }
}

class _GateSymbolPainter extends CustomPainter {
  _GateSymbolPainter(this.colorName);

  final String colorName;

  @override
  void paint(Canvas canvas, Size size) {
    final kind = BlockSymbols.forColorName(colorName);
    if (kind == null) return;
    BlockSymbols.paintSymbol(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      kind,
    );
  }

  @override
  bool shouldRepaint(covariant _GateSymbolPainter oldDelegate) => false;
}
