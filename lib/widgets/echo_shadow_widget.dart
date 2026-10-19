import 'package:flutter/material.dart';
import '../models/models.dart';
import '../painters/hatch_shadow_painter.dart';
import '../theme/verkstad_tokens.dart';

class EchoShadowWidget extends StatefulWidget {
  const EchoShadowWidget({
    super.key,
    required this.shadow,
    required this.cellSize,
    required this.offset,
  });

  final EchoShadow shadow;
  final double cellSize;
  final double offset;

  @override
  State<EchoShadowWidget> createState() => _EchoShadowWidgetState();
}

class _EchoShadowWidgetState extends State<EchoShadowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _lastRemaining = 0;

  @override
  void initState() {
    super.initState();
    _lastRemaining = widget.shadow.remainingMoves;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: VerkstadTokens.echoDrawMs),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant EchoShadowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shadow.remainingMoves < _lastRemaining) {
      _lastRemaining = widget.shadow.remainingMoves;
      _controller
        ..reset()
        ..forward();
    } else if (widget.shadow.remainingMoves > _lastRemaining) {
      _lastRemaining = widget.shadow.remainingMoves;
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shadow.cells.isEmpty) return const SizedBox.shrink();

    final minX = widget.shadow.cells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = widget.shadow.cells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = widget.shadow.cells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = widget.shadow.cells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * widget.cellSize;
    final height = (maxY - minY + 1) * widget.cellSize;

    return Positioned(
      left: minX * widget.cellSize + widget.offset,
      top: minY * widget.cellSize + widget.offset,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(width, height),
            painter: HatchShadowPainter(
              progress: _controller.value,
              remainingMoves: widget.shadow.remainingMoves,
            ),
          );
        },
      ),
    );
  }
}
