import 'package:flutter/material.dart';
import '../models/models.dart';
import '../painters/gate_painter.dart';
import '../theme/block_looks.dart';
import '../theme/verkstad_tokens.dart';
import '../utils/gate_anim.dart';

class GateWidget extends StatefulWidget {
  final Gate gate;
  final double cellSize;
  final int gridWidth;
  final int gridHeight;
  final double gateThickness;
  final int world;
  final GateAnimEvent? animEvent;

  const GateWidget({
    super.key,
    required this.gate,
    required this.cellSize,
    required this.gridWidth,
    required this.gridHeight,
    required this.gateThickness,
    this.world = 1,
    this.animEvent,
  });

  @override
  State<GateWidget> createState() => _GateWidgetState();
}

class _GateWidgetState extends State<GateWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  GateAnimKind? _kind;
  int _lastSerial = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant GateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final event = widget.animEvent;
    if (event != null &&
        event.gate.side == widget.gate.side &&
        event.gate.position == widget.gate.position &&
        event.gate.color == widget.gate.color &&
        event.serial != _lastSerial) {
      _lastSerial = event.serial;
      _kind = event.kind;
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final ms = reduceMotion ? VerkstadTokens.reducedMotionCapMs : VerkstadTokens.bounceMs;
      if (event.kind == GateAnimKind.open) {
        _controller.duration = Duration(
          milliseconds: reduceMotion ? VerkstadTokens.reducedMotionCapMs : VerkstadTokens.slideOutMs,
        );
      } else {
        _controller.duration = Duration(milliseconds: ms);
      }
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.gate.color;
    final cellSize = widget.cellSize;
    final gateThickness = widget.gateThickness;

    double left, top, width, height;

    switch (widget.gate.side) {
      case GateSide.top:
        left = widget.gate.position * cellSize + gateThickness;
        top = 0;
        width = cellSize;
        height = gateThickness;
        break;
      case GateSide.bottom:
        left = widget.gate.position * cellSize + gateThickness;
        top = widget.gridHeight * cellSize + gateThickness;
        width = cellSize;
        height = gateThickness;
        break;
      case GateSide.left:
        left = 0;
        top = widget.gate.position * cellSize + gateThickness;
        width = gateThickness;
        height = cellSize;
        break;
      case GateSide.right:
        left = widget.gridWidth * cellSize + gateThickness;
        top = widget.gate.position * cellSize + gateThickness;
        width = gateThickness;
        height = cellSize;
        break;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        var slide = Offset.zero;
        var knock = Offset.zero;
        var edgeScale = 1.0;
        if (_kind == GateAnimKind.open) {
          final out = Curves.easeInCubic.transform(t);
          final back = t > 0.5 ? Curves.easeOutCubic.transform((t - 0.5) * 2) : 0.0;
          final amount = t < 0.5 ? out : 1 - back;
          slide = _slideOffset(amount);
        } else if (_kind == GateAnimKind.knock) {
          final amount = Curves.easeOutBack.transform(t) * (1 - t);
          knock = _knockOffset(amount);
          edgeScale = 1 + 0.5 * amount;
        }

        return Positioned(
          left: left + slide.dx + knock.dx,
          top: top + slide.dy + knock.dy,
          child: CustomPaint(
            size: Size(width, height),
            painter: GatePainter(
              colorName: color,
              cellSize: cellSize,
              world: widget.world,
              knock: 0,
              edgeScale: edgeScale,
            ),
          ),
        );
      },
    );
  }

  Offset _slideOffset(double amount) {
    final d = widget.gateThickness * amount;
    switch (widget.gate.side) {
      case GateSide.top:
        return Offset(0, -d);
      case GateSide.bottom:
        return Offset(0, d);
      case GateSide.left:
        return Offset(-d, 0);
      case GateSide.right:
        return Offset(d, 0);
    }
  }

  Offset _knockOffset(double amount) {
    final d = GateGeom.knock * widget.cellSize * amount;
    switch (widget.gate.side) {
      case GateSide.top:
        return Offset(0, d);
      case GateSide.bottom:
        return Offset(0, -d);
      case GateSide.left:
        return Offset(d, 0);
      case GateSide.right:
        return Offset(-d, 0);
    }
  }
}
