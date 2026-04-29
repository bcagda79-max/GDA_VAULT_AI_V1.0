// lib/features/add_document/widgets/scanner_frame_painter.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';

/// Custom painter for the scanner edge detection frame with corner brackets.
class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent mask for the area outside the document frame
    final Paint maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    final double frameLeft = size.width * 0.1;
    final double frameTop = size.height * 0.15;
    final double frameRight = size.width * 0.9;
    final double frameBottom = size.height * 0.78;
    const double cornerLen = 24.0;

    // Draw the mask (top, bottom, left, right)
    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, frameTop), maskPaint);
    // Bottom
    canvas.drawRect(Rect.fromLTRB(0, frameBottom, size.width, size.height), maskPaint);
    // Left
    canvas.drawRect(Rect.fromLTRB(0, frameTop, frameLeft, frameBottom), maskPaint);
    // Right
    canvas.drawRect(Rect.fromLTRB(frameRight, frameTop, size.width, frameBottom), maskPaint);

    // Draw corner brackets
    final Paint cornerPaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(Offset(frameLeft, frameTop + cornerLen), 
                    Offset(frameLeft, frameTop), cornerPaint);
    canvas.drawLine(Offset(frameLeft, frameTop), 
                    Offset(frameLeft + cornerLen, frameTop), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(frameRight - cornerLen, frameTop),
                    Offset(frameRight, frameTop), cornerPaint);
    canvas.drawLine(Offset(frameRight, frameTop),
                    Offset(frameRight, frameTop + cornerLen), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(frameLeft, frameBottom - cornerLen),
                    Offset(frameLeft, frameBottom), cornerPaint);
    canvas.drawLine(Offset(frameLeft, frameBottom),
                    Offset(frameLeft + cornerLen, frameBottom), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(frameRight - cornerLen, frameBottom),
                    Offset(frameRight, frameBottom), cornerPaint);
    canvas.drawLine(Offset(frameRight, frameBottom),
                    Offset(frameRight, frameBottom - cornerLen), cornerPaint);

    // Thin frame border
    final Paint framePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(
      Rect.fromLTRB(frameLeft, frameTop, frameRight, frameBottom),
      framePaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
