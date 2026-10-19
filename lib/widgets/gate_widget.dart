import 'package:flutter/material.dart';
import '../models/models.dart';
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

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
