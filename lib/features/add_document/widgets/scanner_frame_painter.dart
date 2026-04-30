import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';

/// Draws the animated document detection frame (CamScanner style)
/// with corner brackets, mask overlay, and optional grid lines.
class ScannerFramePainter extends CustomPainter {
  final bool documentDetected;
  final bool showGrid;

  const ScannerFramePainter({
    this.documentDetected = true,
    this.showGrid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double frameLeft   = size.width  * 0.05;
    final double frameTop    = size.height * 0.08;
    final double frameRight  = size.width  * 0.95;
    final double frameBottom = size.height * 0.82;
    const double cornerLen   = 28.0;
    const double cornerWidth = 3.5;

    // ── Dark mask outside frame ──
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, frameTop), maskPaint);
    canvas.drawRect(Rect.fromLTRB(0, frameBottom, size.width, size.height), maskPaint);
    canvas.drawRect(Rect.fromLTRB(0, frameTop, frameLeft, frameBottom), maskPaint);
    canvas.drawRect(Rect.fromLTRB(frameRight, frameTop, size.width, frameBottom), maskPaint);

    // ── Corner bracket paint ──
    final cornerColor = documentDetected ? AppColors.gold : Colors.white;
    final cornerPaint = Paint()
      ..color    = cornerColor
      ..strokeWidth = cornerWidth
      ..style    = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(frameLeft, frameTop + cornerLen), Offset(frameLeft, frameTop), cornerPaint);
    canvas.drawLine(Offset(frameLeft, frameTop), Offset(frameLeft + cornerLen, frameTop), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(frameRight - cornerLen, frameTop), Offset(frameRight, frameTop), cornerPaint);
    canvas.drawLine(Offset(frameRight, frameTop), Offset(frameRight, frameTop + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(frameLeft, frameBottom - cornerLen), Offset(frameLeft, frameBottom), cornerPaint);
    canvas.drawLine(Offset(frameLeft, frameBottom), Offset(frameLeft + cornerLen, frameBottom), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(frameRight - cornerLen, frameBottom), Offset(frameRight, frameBottom), cornerPaint);
    canvas.drawLine(Offset(frameRight, frameBottom), Offset(frameRight, frameBottom - cornerLen), cornerPaint);

    // ── Thin frame border ──
    final framePaint = Paint()
      ..color = cornerColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTRB(frameLeft, frameTop, frameRight, frameBottom),
      framePaint,
    );

    // ── Optional grid lines (rule of thirds) ──
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 0.6;
      final fw = frameRight - frameLeft;
      final fh = frameBottom - frameTop;
      // Vertical thirds
      canvas.drawLine(Offset(frameLeft + fw / 3, frameTop), Offset(frameLeft + fw / 3, frameBottom), gridPaint);
      canvas.drawLine(Offset(frameLeft + fw * 2 / 3, frameTop), Offset(frameLeft + fw * 2 / 3, frameBottom), gridPaint);
      // Horizontal thirds
      canvas.drawLine(Offset(frameLeft, frameTop + fh / 3), Offset(frameRight, frameTop + fh / 3), gridPaint);
      canvas.drawLine(Offset(frameLeft, frameTop + fh * 2 / 3), Offset(frameRight, frameTop + fh * 2 / 3), gridPaint);
    }
  }

  @override
  bool shouldRepaint(ScannerFramePainter oldDelegate) =>
    oldDelegate.documentDetected != documentDetected ||
    oldDelegate.showGrid != showGrid;
}

/// Animating scan line painter
class ScanLinePainter extends CustomPainter {
  final double progress;  // 0.0 to 1.0
  final double frameTop;
  final double frameBottom;
  final double frameLeft;
  final double frameRight;

  const ScanLinePainter({
    required this.progress,
    required this.frameTop,
    required this.frameBottom,
    required this.frameLeft,
    required this.frameRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = frameTop + (frameBottom - frameTop) * progress;
    final lineWidth = frameRight - frameLeft;

    // Glow below
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.gold.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(frameLeft, y, lineWidth, 48));
    canvas.drawRect(Rect.fromLTWH(frameLeft, y, lineWidth, 48), glowPaint);

    // Main line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.gold.withValues(alpha: 0.8),
          AppColors.gold,
          AppColors.gold.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(frameLeft, y, lineWidth, 2))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(frameLeft, y), Offset(frameRight, y), linePaint);
  }

  @override
  bool shouldRepaint(ScanLinePainter old) => old.progress != progress;
}

/// Perspective quad border painter (draggable crop handles)
class QuadBorderPainter extends CustomPainter {
  final Offset tl, tr, bl, br;

  const QuadBorderPainter(this.tl, this.tr, this.bl, this.br);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();
    canvas.drawPath(path, borderPaint);

    final dotPaint = Paint()..color = AppColors.gold;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final pt in [tl, tr, bl, br]) {
      canvas.drawCircle(pt, 6, shadowPaint);
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 5, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(QuadBorderPainter old) => true;
}
