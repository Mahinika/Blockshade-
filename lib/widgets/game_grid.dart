import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../painters/wood_grain_painter.dart';
import '../theme/block_looks.dart';
import '../theme/move_arrows.dart';
import '../theme/verkstad_tokens.dart';
import '../utils/colors.dart';
import '../utils/gate_anim.dart';
import 'block_widget.dart';
import 'echo_shadow_widget.dart';
import 'gate_widget.dart';

class GameGrid extends StatefulWidget {
  final GameState gameState;
  final Function(String blockId) onBlockTap;
  final void Function(String blockId)? onBlockPress;
  final double cellSize;
  final int world;
  final String? pulsedBlockId;
  final int pulseSerial;
  final GateAnimEvent? gateAnim;

  const GameGrid({
    super.key,
    required this.gameState,
    required this.onBlockTap,
    this.onBlockPress,
    this.cellSize = 50,
    this.world = 1,
    this.pulsedBlockId,
    this.pulseSerial = 0,
    this.gateAnim,
  });

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> {
  String? _pressedBlockId;

  @override
  Widget build(BuildContext context) {
    final gameState = widget.gameState;
    final cellSize = widget.cellSize;
    final world = widget.world;
    final level = gameState.level;
    final gridWidth = level.grid.width * cellSize;
    final gridHeight = level.grid.height * cellSize;
    final gateThickness = math.max(GateGeom.minThickness, GateGeom.thicknessFactor * cellSize);
    final benchColor = VerkstadTokens.boardForWorld(world);

    return Center(
      child: SizedBox(
        width: gridWidth + gateThickness * 2,
        height: gridHeight + gateThickness * 2,
        child: Stack(
          children: [
            Positioned(
              left: gateThickness,
              top: gateThickness,
              child: _buildGrid(level, gridWidth, gridHeight, benchColor, cellSize, world),
            ),
            ...level.gates.map((gate) => GateWidget(
                  gate: gate,
                  cellSize: cellSize,
                  gridWidth: level.grid.width,
                  gridHeight: level.grid.height,
                  gateThickness: gateThickness,
                  world: world,
                  animEvent: widget.gateAnim != null &&
                          widget.gateAnim!.gate.side == gate.side &&
                          widget.gateAnim!.gate.position == gate.position &&
                          widget.gateAnim!.gate.color == gate.color
                      ? widget.gateAnim
                      : null,
                )),
            ...gameState.echoShadows.map(
              (shadow) => EchoShadowWidget(
                shadow: shadow,
                cellSize: cellSize,
                offset: gateThickness,
                world: world,
              ),
            ),
            if (_pressedBlockId != null) _buildGhost(gameState, cellSize, gateThickness),
            ...gameState.blocks.map((block) {
              final key = gameState.blockById(block.lockKeyBlockId);
              final pulseThis = widget.pulsedBlockId == block.id;
              final heads = arrowHeadsFor(gameState, block);
              return BlockWidget(
                key: ValueKey('block-${block.id}'),
                block: block,
                cellSize: cellSize,
                offsetX: gateThickness,
                offsetY: gateThickness,
                isLocked: gameState.isBlockLocked(block),
                keyReadyToExit: gameState.isKeyReadyToExit(block),
                keyColorName: key?.color,
                pulseSerial: pulseThis ? widget.pulseSerial : 0,
                horizontal: axisForDirection(block.direction) == MoveAxis.horizontal,
                negativeHead: heads.negativeOpen,
                positiveHead: heads.positiveOpen,
                world: world,
                onTap: () => widget.onBlockTap(block.id),
                onPressDown: () {
                  setState(() => _pressedBlockId = block.id);
                  widget.onBlockPress?.call(block.id);
                },
                onPressUp: () => setState(() => _pressedBlockId = null),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGhost(GameState gameState, double cellSize, double gateThickness) {
    Block? block;
    for (final candidate in gameState.blocks) {
      if (candidate.id == _pressedBlockId) {
        block = candidate;
        break;
      }
    }
    if (block == null) return const SizedBox.shrink();
    final cells = furthestSlideCells(gameState, block);
    if (cells == null) return const SizedBox.shrink();

    return Stack(
      children: cells.map((cell) {
        return Positioned(
          left: gateThickness + cell.x * cellSize + 3,
          top: gateThickness + cell.y * cellSize + 3,
          child: IgnorePointer(
            child: Container(
              width: cellSize - 6,
              height: cellSize - 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: VerkstadTokens.pencil.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(
    Level level,
    double gridWidth,
    double gridHeight,
    Color benchColor,
    double cellSize,
    int world,
  ) {
    final board = ClipRRect(
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

    if (world != 2) return board;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: VerkstadTokens.valvetRim,
          width: VerkstadTokens.valvetRimWidth,
        ),
      ),
      child: board,
    );
  }
}
