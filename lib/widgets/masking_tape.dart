import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import '../theme/verkstad_tokens.dart';

/// UI-label som maskeringstejp med nål i hörnet.
class MaskingTape extends StatelessWidget {
  const MaskingTape({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.rotation = -0.02,
    this.showPin = true,
    this.width,
  });

  final Widget child;
  final EdgeInsets padding;
  final double rotation;
  final bool showPin;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        painter: _TapePainter(showPin: showPin),
        child: Container(
          width: width,
          padding: padding,
          child: DefaultTextStyle(
            style: TextStyle(
              color: VerkstadTokens.ink,
              fontWeight: FontWeight.w600,
              fontVariations: AppTypography.recursiveVariations(600),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TapePainter extends CustomPainter {
  _TapePainter({required this.showPin});

  final bool showPin;

  @override
  void paint(Canvas canvas, Size size) {
    final tape = Paint()..color = VerkstadTokens.maskingTape;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(2, 1);
    path.lineTo(w - 3, 0);
    path.lineTo(w - 1, h - 1);
    path.lineTo(4, h);
    path.close();
    canvas.drawPath(path, tape);

    canvas.drawShadow(
      path,
      VerkstadTokens.pencil.withValues(alpha: 0.15),
      1,
      false,
    );

    if (showPin) {
      final pinCenter = Offset(w - 10, 8);
      canvas.drawCircle(
        pinCenter.translate(0, 1),
        5,
        Paint()..color = VerkstadTokens.pencil.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        pinCenter,
        4.5,
        Paint()..color = VerkstadTokens.brassPin,
      );
      canvas.drawCircle(
        pinCenter.translate(-1, -1),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TapePainter oldDelegate) => false;
}

/// Dekorativ tejpbit med skuren kant.
class MaskingTapeButton extends StatelessWidget {
  const MaskingTapeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: VerkstadTokens.pencil.withValues(alpha: 0.08),
        child: MaskingTape(
          rotation: (math.Random(label.hashCode).nextDouble() - 0.5) * 0.06,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: VerkstadTokens.ink),
                const SizedBox(width: 6),
              ],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
