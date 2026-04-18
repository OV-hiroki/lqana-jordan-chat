import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PurpleChatBackground
//  Paints the same candy / geometric tiled
//  pattern visible in the Lgana screenshot.
//  Uses a CustomPainter so no asset is needed.
// ─────────────────────────────────────────────

class PurpleChatBackground extends StatelessWidget {
  final Widget child;

  const PurpleChatBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFCE93D8), // purple[200]
                const Color(0xFFAB47BC), // purple[400]
              ],
            ),
          ),
        ),
        // Tiled pattern on top
        Positioned.fill(
          child: CustomPaint(painter: _CandyPatternPainter()),
        ),
        // Content
        child,
      ],
    );
  }
}

class _CandyPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.10)
          ..style = PaintingStyle.fill;

    const tileSize = 60.0;
    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = c * tileSize + (r.isEven ? 0 : tileSize / 2);
        final cy = r * tileSize;
        _drawCandy(canvas, paint, Offset(cx, cy));
      }
    }
  }

  void _drawCandy(Canvas canvas, Paint paint, Offset center) {
    // small circle (candy dot)
    canvas.drawCircle(center, 6, paint);
    // small diamond
    final path =
        Path()
          ..moveTo(center.dx + 14, center.dy)
          ..lineTo(center.dx + 20, center.dy + 6)
          ..lineTo(center.dx + 14, center.dy + 12)
          ..lineTo(center.dx + 8, center.dy + 6)
          ..close();
    canvas.drawPath(path, paint);
    // small star-like cross
    final crossPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx + 32, center.dy + 2),
      Offset(center.dx + 32, center.dy + 10),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 28, center.dy + 6),
      Offset(center.dx + 36, center.dy + 6),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(_CandyPatternPainter old) => false;
}
