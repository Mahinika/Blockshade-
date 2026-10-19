import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../painters/wood_block_painter.dart';
import '../services/haptic_service.dart';
import '../theme/move_arrows.dart';
import '../utils/colors.dart';
import '../utils/localization.dart';
import '../theme/verkstad_tokens.dart';
import 'padlock_painter.dart';

class BlockWidget extends StatefulWidget {
  final Block block;
  final double cellSize;
  final double offsetX;
  final double offsetY;
  final bool isLocked;
  final bool keyReadyToExit;
  final String? keyColorName;
  final int pulseSerial;
  final VoidCallback onTap;
  final VoidCallback? onPressDown;
  final VoidCallback? onPressUp;
  final bool horizontal;
  final bool negativeHead;
  final bool positiveHead;

  const BlockWidget({
    super.key,
    required this.block,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.isLocked,
    this.keyReadyToExit = false,
    this.keyColorName,
    this.pulseSerial = 0,
    required this.onTap,
    this.onPressDown,
    this.onPressUp,
    this.horizontal = true,
    this.negativeHead = true,
    this.positiveHead = true,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> with TickerProviderStateMixin {
  double _lift = 0;
  double _bounceOffset = 0;
  double _rotation = 0;
  bool _showLock = false;
  bool _reduceMotion = false;
  String? _keyColorName;
  int _wobbleSwings = 2;

  late final AnimationController _shake;
  late final AnimationController _wobble;
  late final AnimationController _open;
  late final AnimationController _fade;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _showLock = widget.isLocked;
    _keyColorName = widget.keyColorName;
    _shake = AnimationController(vsync: this, duration: Duration(milliseconds: VerkstadTokens.bounceMs));
    _wobble = AnimationController(vsync: this, duration: Duration(milliseconds: VerkstadTokens.bounceMs * 2));
    _open = AnimationController(vsync: this, duration: Duration(milliseconds: VerkstadTokens.lockOpenMs));
    _fade = AnimationController(vsync: this, duration: Duration(milliseconds: VerkstadTokens.echoEraseMs));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _open.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_reduceMotion) {
        _fade.forward(from: 0);
      }
    });
    _fade.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showLock = false);
      }
    });
    if (widget.isLocked && widget.keyReadyToExit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playReadyWobble();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyColorName != null) {
      _keyColorName = widget.keyColorName;
    }
    if (!oldWidget.isLocked && widget.isLocked) {
      _showLock = true;
      _open.value = 0;
      _fade.value = 0;
    } else if (oldWidget.isLocked && !widget.isLocked && _showLock) {
      _playOpen();
    } else if (widget.isLocked && widget.keyReadyToExit && !oldWidget.keyReadyToExit) {
      _playReadyWobble();
    }
    if (widget.pulseSerial != oldWidget.pulseSerial && widget.pulseSerial > 0) {
      _pulse.duration = Duration(milliseconds: _reduceMotion ? VerkstadTokens.reducedMotionCapMs : 360);
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _wobble.dispose();
    _open.dispose();
    _fade.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _playReadyWobble() {
    HapticService.instance.light();
    if (_reduceMotion) return;
    _wobbleSwings = 2;
    _wobble.duration = Duration(milliseconds: VerkstadTokens.bounceMs * 2);
    _wobble.forward(from: 0);
  }

  void _playOpen() {
    HapticService.instance.medium();
    HapticService.instance.light();
    final reduce = MediaQuery.disableAnimationsOf(context);
    _reduceMotion = reduce;
    if (reduce) {
      _open.value = 0;
      _fade.duration = const Duration(milliseconds: VerkstadTokens.reducedMotionCapMs);
      _fade.forward(from: 0);
      return;
    }
    _open.duration = Duration(milliseconds: VerkstadTokens.lockOpenMs);
    _fade.duration = Duration(milliseconds: VerkstadTokens.echoEraseMs);
    _open.forward(from: 0);
  }

  void _rejectTap() {
    HapticService.instance.error();
    if (_reduceMotion) return;
    _shake.duration = Duration(milliseconds: VerkstadTokens.bounceMs);
    _shake.forward(from: 0);
    _wobbleSwings = 1;
    _wobble.duration = Duration(milliseconds: VerkstadTokens.bounceMs);
    _wobble.forward(from: 0);
  }

  double _wobbleAngle(double t) {
    if (_reduceMotion) return 0;
    final curved = Curves.easeOutBack.transform(t);
    return math.sin(curved * math.pi * 2 * _wobbleSwings) * (4 * math.pi / 180);
  }

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
    final l10n = AppLocalizations.of(context);
    final lockedLabel = widget.isLocked && _keyColorName != null
        ? l10n.lockKeyFirst(_keyColorName!)
        : null;

    return Positioned(
      left: minX * widget.cellSize + widget.offsetX,
      top: minY * widget.cellSize + widget.offsetY + _bounceOffset,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shake, _pulse]),
        builder: (context, _) {
          final shakeT = _shake.value;
          final dx = _reduceMotion ? 0.0 : math.sin(shakeT * math.pi * 4) * (1 - shakeT) * 7;
          final pulse = math.sin(_pulse.value * math.pi);
          final scale = _reduceMotion || _pulse.value == 0 ? 1.0 : 1 + pulse * 0.06;
          final showPulse = _pulse.value > 0 && _pulse.value < 1;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: scale,
              child: Semantics(
                button: true,
                label: lockedLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    widget.onPressDown?.call();
                    if (!widget.isLocked) setState(() => _lift = 3);
                  },
                  onTapUp: (_) {
                    widget.onPressUp?.call();
                    setState(() => _lift = 0);
                  },
                  onTapCancel: () {
                    widget.onPressUp?.call();
                    setState(() => _lift = 0);
                  },
                  onTap: () {
                    if (widget.isLocked) _rejectTap();
                    widget.onTap();
                  },
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
                          textureSeed: textureSeed + notchCountForColor(widget.block.color) * 17,
                          lift: _lift,
                          horizontal: widget.horizontal,
                          negativeHead: widget.negativeHead,
                          positiveHead: widget.positiveHead,
                          notchCount: notchCountForColor(widget.block.color),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (showPulse)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    key: const Key('key-pulse'),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: VerkstadTokens.maskingTape.withValues(alpha: 0.45 * pulse),
                                      border: Border.all(color: VerkstadTokens.maskingTape, width: 3),
                                    ),
                                  ),
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
                            if (_showLock && _keyColorName != null) _padlock(width - 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _padlock(double blockWidth) {
    final c = widget.cellSize;
    final extent = 0.72 * c;
    return Positioned(
      left: blockWidth - 0.20 * c - extent / 2,
      top: 0.20 * c - extent / 2,
      width: extent,
      height: extent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_wobble, _open, _fade]),
        builder: (context, _) {
          final openT = _reduceMotion ? 0.0 : Curves.easeInOutBack.transform(_open.value);
          final fadeT = Curves.easeOutQuad.transform(_fade.value);
          return Opacity(
            opacity: (1 - fadeT).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 1 - 0.4 * fadeT,
              child: Transform.rotate(
                angle: _wobbleAngle(_wobble.value),
                child: CustomPaint(
                  key: ValueKey('padlock-${widget.block.id}'),
                  painter: PadlockPainter(
                    cellSize: c,
                    keyColorName: _keyColorName!,
                    plateStrokeFactor: widget.keyReadyToExit ? 2 : 1,
                    openAmount: openT.clamp(0.0, 1.2),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
