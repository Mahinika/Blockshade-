import 'package:flutter/material.dart';
import 'verkstad_tokens.dart';

/// Färgblindhetssäkra symboler präglade i block (● ▲ ■ ✚ ◆).
enum BlockSymbolKind {
  circle,
  triangle,
  square,
  plus,
  diamond,
}

abstract final class BlockSymbols {
  static BlockSymbolKind? forColorName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return BlockSymbolKind.circle;
      case 'blue':
        return BlockSymbolKind.triangle;
      case 'yellow':
        return BlockSymbolKind.square;
      case 'green':
        return BlockSymbolKind.plus;
      case 'purple':
        return BlockSymbolKind.diamond;
      default:
        return null;
    }
  }

  static void paintSymbol(
    Canvas canvas,
    Rect bounds,
    BlockSymbolKind kind, {
    Color color = VerkstadTokens.pencil,
    double irregularity = 0.08,
    double opacity = 0.85,
  }) {
    final center = bounds.center;
    final size = bounds.shortestSide * 0.38;
    final fill = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    switch (kind) {
      case BlockSymbolKind.circle:
        canvas.drawCircle(center, size * 0.45, fill);
      case BlockSymbolKind.triangle:
        final path = Path();
        path.moveTo(center.dx, center.dy - size * 0.5);
        path.lineTo(center.dx + size * 0.48, center.dy + size * 0.38);
        path.lineTo(center.dx - size * 0.48, center.dy + size * 0.38);
        path.close();
        canvas.drawPath(path, fill);
      case BlockSymbolKind.square:
        final r = Rect.fromCenter(center: center, width: size * 0.82, height: size * 0.82);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(1.5)),
          fill,
        );
      case BlockSymbolKind.plus:
        final w = size * 0.22;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: w, height: size * 0.9),
            Radius.circular(w / 2),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: size * 0.9, height: w),
            Radius.circular(w / 2),
          ),
          fill,
        );
      case BlockSymbolKind.diamond:
        final path = Path();
        path.moveTo(center.dx, center.dy - size * 0.5);
        path.lineTo(center.dx + size * 0.42, center.dy);
        path.lineTo(center.dx, center.dy + size * 0.5);
        path.lineTo(center.dx - size * 0.42, center.dy);
        path.close();
        canvas.drawPath(path, fill);
    }

    // Lätt oregelbundenhet – handbränd känsla
    if (irregularity > 0) {
      final jitter = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(center.dx - size * 0.1, center.dy + size * 0.2),
        Offset(center.dx + size * 0.12, center.dy + size * 0.22),
        jitter,
      );
    }
  }
}
