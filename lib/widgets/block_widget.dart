import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/colors.dart';

class BlockWidget extends StatelessWidget {
  final Block block;
  final double cellSize;
  final double offsetX;
  final double offsetY;
  final bool isLocked;
  final VoidCallback onTap;

  const BlockWidget({
    super.key,
    required this.block,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (block.cells.isEmpty) return const SizedBox.shrink();

    final minX = block.cells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = block.cells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = block.cells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = block.cells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * cellSize;
    final height = (maxY - minY + 1) * cellSize;

    final baseColor = BlockColors.getBlockColor(block.color);
    final darkColor = BlockColors.getBlockColorDark(block.color);

    return Positioned(
      left: minX * cellSize + offsetX,
      top: minY * cellSize + offsetY,
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width - 4,
          height: height - 4,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, darkColor],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
            border: block.isEcho
                ? Border.all(color: Colors.white.withOpacity(0.7), width: 3)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: _buildArrow(),
              ),
              
              if (isLocked)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.lock,
                    color: Colors.white.withOpacity(0.9),
                    size: cellSize * 0.3,
                  ),
                ),
              
              if (block.isEcho)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.blur_on,
                      color: Colors.white,
                      size: cellSize * 0.25,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow() {
    final arrowSize = cellSize * 0.4;
    double rotation;
    
    switch (block.direction) {
      case Direction.up:
        rotation = -1.5708;
        break;
      case Direction.down:
        rotation = 1.5708;
        break;
      case Direction.left:
        rotation = 3.1416;
        break;
      case Direction.right:
        rotation = 0;
        break;
    }

    return Transform.rotate(
      angle: rotation,
      child: Icon(
        Icons.arrow_forward,
        color: Colors.white.withOpacity(0.9),
        size: arrowSize,
      ),
    );
  }
}
