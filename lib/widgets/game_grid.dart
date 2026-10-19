import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/colors.dart';
import 'block_widget.dart';
import 'gate_widget.dart';

class GameGrid extends StatelessWidget {
  final GameState gameState;
  final Function(String blockId) onBlockTap;
  final double cellSize;

  const GameGrid({
    super.key,
    required this.gameState,
    required this.onBlockTap,
    this.cellSize = 50,
  });

  @override
  Widget build(BuildContext context) {
    final level = gameState.level;
    final gridWidth = level.grid.width * cellSize;
    final gridHeight = level.grid.height * cellSize;
    final gateThickness = 8.0;

    return Center(
      child: Container(
        width: gridWidth + gateThickness * 2,
        height: gridHeight + gateThickness * 2,
        child: Stack(
          children: [
            Positioned(
              left: gateThickness,
              top: gateThickness,
              child: _buildGrid(level, gridWidth, gridHeight),
            ),
            
            ...level.gates.map((gate) => GateWidget(
              gate: gate,
              cellSize: cellSize,
              gridWidth: level.grid.width,
              gridHeight: level.grid.height,
              gateThickness: gateThickness,
            )),
            
            ...gameState.echoShadows.map((shadow) => _buildEchoShadow(shadow)),
            
            ...gameState.blocks.map((block) => BlockWidget(
              block: block,
              cellSize: cellSize,
              offsetX: gateThickness,
              offsetY: gateThickness,
              isLocked: gameState.isBlockLocked(block),
              onTap: () => onBlockTap(block.id),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(Level level, double gridWidth, double gridHeight) {
    return Container(
      width: gridWidth,
      height: gridHeight,
      decoration: BoxDecoration(
        color: AppColors.gridCell,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gridBorder, width: 2),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size(gridWidth, gridHeight),
            painter: _GridPainter(
              columns: level.grid.width,
              rows: level.grid.height,
              cellSize: cellSize,
            ),
          ),
          
          ...level.walls.map((wall) => Positioned(
            left: wall.x * cellSize,
            top: wall.y * cellSize,
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: AppColors.wall,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEchoShadow(EchoShadow shadow) {
    if (shadow.cells.isEmpty) return const SizedBox.shrink();

    final minX = shadow.cells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = shadow.cells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = shadow.cells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = shadow.cells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * cellSize;
    final height = (maxY - minY + 1) * cellSize;

    return Positioned(
      left: minX * cellSize + 8,
      top: minY * cellSize + 8,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.6),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: Text(
            '${shadow.remainingMoves}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: cellSize * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int columns;
  final int rows;
  final double cellSize;

  _GridPainter({
    required this.columns,
    required this.rows,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridBorder.withOpacity(0.3)
      ..strokeWidth = 1;

    for (var i = 1; i < columns; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        paint,
      );
    }

    for (var i = 1; i < rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return columns != oldDelegate.columns ||
        rows != oldDelegate.rows ||
        cellSize != oldDelegate.cellSize;
  }
}
