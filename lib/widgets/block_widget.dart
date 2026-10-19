import 'package:flutter/material.dart';
import '../models/models.dart';
import '../painters/wood_block_painter.dart';
import '../utils/colors.dart';
import '../theme/verkstad_tokens.dart';

class BlockWidget extends StatefulWidget {
  final Block block;
  final double cellSize;
  final double offsetX;
  final double offsetY;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback? onPressDown;

  const BlockWidget({
    super.key,
    required this.block,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.isLocked,
    required this.onTap,
    this.onPressDown,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> with SingleTickerProviderStateMixin {
  double _lift = 0;
  double _bounceOffset = 0;
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.block.cells.isEmpty) return const SizedBox.shrink();

    final minX = widget.block.cells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = widget.block.cells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = widget.block.cells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = widget.block.cells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * widget.cellSize;
    final height = (maxY - minY + 1) * widget.cellSize;

    final baseColor = BlockColors.getBlockColor(widget.block.color);
    final textureSeed = woodTextureSeedForBlock(widget.block.id);

    return Positioned(
      left: minX * widget.cellSize + widget.offsetX,
      top: minY * widget.cellSize + widget.offsetY + _bounceOffset,
      child: GestureDetector(
        onTapDown: (_) {
          widget.onPressDown?.call();
          setState(() => _lift = 3);
        },
        onTapUp: (_) => setState(() => _lift = 0),
        onTapCancel: () => setState(() => _lift = 0),
        onTap: widget.isLocked ? null : widget.onTap,
        child: Transform.rotate(
          angle: _rotation,
          child: AnimatedContainer(
            duration: Duration(milliseconds: VerkstadTokens.pressMs),
            curve: VerkstadTokens.pressEase,
            width: width - 4,
            height: height - 4,
            margin: const EdgeInsets.all(2),
            child: CustomPaint(
              painter: WoodBlockPainter(
                fillColor: baseColor,
                colorName: widget.block.color,
                textureSeed: textureSeed,
                lift: _lift,
                directionAngle: _directionAngle(widget.block.direction),
              ),
              child: Stack(
                children: [
                  if (widget.isLocked)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(
                        Icons.lock_outline,
                        color: VerkstadTokens.pencil.withValues(alpha: 0.85),
                        size: widget.cellSize * 0.28,
                      ),
                    ),
                  if (widget.block.isEcho)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Icon(
                        Icons.blur_circular,
                        color: VerkstadTokens.pencil.withValues(alpha: 0.5),
                        size: widget.cellSize * 0.22,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _directionAngle(Direction direction) {
    switch (direction) {
      case Direction.up:
        return -1.5708;
      case Direction.down:
        return 1.5708;
      case Direction.left:
        return 3.1416;
      case Direction.right:
        return 0;
    }
  }

  void playBounce() {
    setState(() => _bounceOffset = -widget.cellSize * 0.15);
    Future.delayed(Duration(milliseconds: VerkstadTokens.bounceMs), () {
      if (mounted) setState(() => _bounceOffset = 0);
    });
  }

  void playExit() {
    setState(() => _rotation = 0.035);
    Future.delayed(Duration(milliseconds: VerkstadTokens.slideOutMs), () {
      if (mounted) setState(() => _rotation = 0);
    });
  }
}
