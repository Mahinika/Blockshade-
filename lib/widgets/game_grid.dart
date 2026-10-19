import 'package:flutter/material.dart';
import '../models/models.dart';
import '../painters/wood_grain_painter.dart';
import '../theme/verkstad_tokens.dart';
import '../utils/colors.dart';
import 'block_widget.dart';
import 'echo_shadow_widget.dart';
import 'gate_widget.dart';

class GameGrid extends StatelessWidget {
  final GameState gameState;
  final Function(String blockId) onBlockTap;
  final void Function(String blockId)? onBlockPress;
  final double cellSize;
  final int world;
  final String? pulsedBlockId;
  final int pulseSerial;

  const GameGrid({
    super.key,
    required this.gameState,
    required this.onBlockTap,
    this.onBlockPress,
    this.cellSize = 50,
    this.world = 1,
    this.pulsedBlockId,
    this.pulseSerial = 0,
  });

  @override
  Widget build(BuildContext context) {
    final level = gameState.level;
    final gridWidth = level.grid.width * cellSize;
    final gridHeight = level.grid.height * cellSize;
    final gateThickness = 8.0;
    final benchColor = VerkstadTokens.benchForWorld(world);

    return Center(
      child: SizedBox(
        width: gridWidth + gateThickness * 2,
        height: gridHeight + gateThickness * 2,
        child: Stack(
          children: [
            Positioned(
              left: gateThickness,
              top: gateThickness,
              child: _buildGrid(level, gridWidth, gridHeight, benchColor),
            ),
            ...level.gates.map((gate) => GateWidget(
                  gate: gate,
                  cellSize: cellSize,
                  gridWidth: level.grid.width,
                  gridHeight: level.grid.height,
                  gateThickness: gateThickness,
                )),
            ...gameState.echoShadows.map(
              (shadow) => EchoShadowWidget(
                shadow: shadow,
                cellSize: cellSize,
                offset: gateThickness,
              ),
            ),
            ...gameState.blocks.map((block) {
              final key = gameState.blockById(block.lockKeyBlockId);
              final pulseThis = pulsedBlockId == block.id;
              return BlockWidget(
                key: ValueKey('block-${block.id}'),
                block: block,
                cellSize: cellSize,
                offsetX: gateThickness,
                offsetY: gateThickness,
                isLocked: gameState.isBlockLocked(block),
                keyReadyToExit: gameState.isKeyReadyToExit(block),
                keyColorName: key?.color,
                pulseSerial: pulseThis ? pulseSerial : 0,
                onTap: () => onBlockTap(block.id),
                onPressDown: () => onBlockPress?.call(block.id),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(Level level, double gridWidth, double gridHeight, Color benchColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: gridWidth,
        height: gridHeight,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(gridWidth, gridHeight),
              painter: WoodGrainPainter(
                baseColor: benchColor,
                seed: level.world * 13,
                showGrid: true,
                gridColumns: level.grid.width,
                gridRows: level.grid.height,
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
                      color: AppColors.wall.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
