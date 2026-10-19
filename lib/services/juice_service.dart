import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/verkstad_tokens.dart';
import 'haptic_service.dart';
import 'sound_service.dart';

/// Partiklar och korta animationer utan att ändra spellogik.
class JuiceOverlay extends StatefulWidget {
  const JuiceOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<JuiceOverlay> createState() => JuiceOverlayState();
}

class JuiceOverlayState extends State<JuiceOverlay> {
  final List<_Particle> _particles = [];
  double _boardTilt = 0;

  void onBlockPress() {
    HapticService.instance.light();
  }

  Future<void> onMoveOutcome(MoveOutcome outcome, String colorName) async {
    switch (outcome.result) {
      case MoveResult.exit:
        await HapticService.instance.medium();
        await SoundService.instance.playWoodSlide();
        _spawnSawdust(outcome.block.color, 4);
      case MoveResult.bounce:
        await HapticService.instance.heavy();
        await SoundService.instance.playWoodKnock();
        _spawnDust(2);
      case MoveResult.blocked:
        await HapticService.instance.light();
    }
    setState(() {});
  }

  void onWin() {
    HapticService.instance.success();
    _spawnSawdust('yellow', 20);
    setState(() {});
  }

  void onFail() {
    HapticService.instance.error();
    _boardTilt = 0.017;
    setState(() {});
    Future.delayed(Duration(milliseconds: VerkstadTokens.failTiltMs), () {
      if (mounted) {
        setState(() => _boardTilt = 0);
      }
    });
  }

  void _spawnSawdust(String colorName, int count) {
    final rng = math.Random();
    final color = _colorForName(colorName);
    for (var i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: 0.5 + (rng.nextDouble() - 0.5) * 0.3,
        y: 0.5,
        vx: (rng.nextDouble() - 0.5) * 0.004,
        vy: -rng.nextDouble() * 0.006 - 0.002,
        color: color,
        life: 1,
        size: 2 + rng.nextDouble() * 3,
      ));
    }
    _tickParticles();
  }

  void _spawnDust(int count) {
    final rng = math.Random();
    for (var i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: 0.5,
        y: 0.5,
        vx: (rng.nextDouble() - 0.5) * 0.003,
        vy: (rng.nextDouble() - 0.5) * 0.003,
        color: VerkstadTokens.pencil.withValues(alpha: 0.4),
        life: 1,
        size: 1.5,
      ));
    }
    _tickParticles();
  }

  Color _colorForName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return VerkstadTokens.blockRed;
      case 'blue':
        return VerkstadTokens.blockBlue;
      case 'yellow':
        return VerkstadTokens.blockYellow;
      case 'green':
        return VerkstadTokens.blockGreen;
      case 'purple':
        return VerkstadTokens.blockPurple;
      default:
        return VerkstadTokens.maskingTape;
    }
  }

  void _tickParticles() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 32));
      if (!mounted) return false;
      setState(() {
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.0004;
          p.life -= 0.06;
        }
        _particles.removeWhere((p) => p.life <= 0);
      });
      return _particles.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _boardTilt,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          IgnorePointer(
            child: CustomPaint(
              painter: _ParticlePainter(_particles),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
    required this.size,
  });

  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double life;
  double size;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles);

  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: p.life.clamp(0, 1));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(p.x * size.width, p.y * size.height),
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
