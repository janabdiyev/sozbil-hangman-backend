import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HangmanPainter extends CustomPainter {
  final int wrongGuesses;

  const HangmanPainter({required this.wrongGuesses});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Always draw gallows
    _drawGallows(canvas, paint, w, h);

    if (wrongGuesses >= 1) _drawHead(canvas, paint, w, h);
    if (wrongGuesses >= 2) _drawBody(canvas, paint, w, h);
    if (wrongGuesses >= 3) _drawLeftArm(canvas, paint, w, h);
    if (wrongGuesses >= 4) _drawRightArm(canvas, paint, w, h);
    if (wrongGuesses >= 5) _drawLeftLeg(canvas, paint, w, h);
    if (wrongGuesses >= 6) _drawRightLeg(canvas, paint, w, h);
  }

  void _drawGallows(Canvas canvas, Paint paint, double w, double h) {
    // Base
    canvas.drawLine(Offset(w * 0.1, h * 0.95), Offset(w * 0.9, h * 0.95), paint);
    // Vertical post
    canvas.drawLine(Offset(w * 0.25, h * 0.95), Offset(w * 0.25, h * 0.05), paint);
    // Horizontal beam
    canvas.drawLine(Offset(w * 0.25, h * 0.05), Offset(w * 0.65, h * 0.05), paint);
    // Short support
    canvas.drawLine(Offset(w * 0.25, h * 0.18), Offset(w * 0.38, h * 0.05), paint);
    // Rope
    canvas.drawLine(Offset(w * 0.65, h * 0.05), Offset(w * 0.65, h * 0.18), paint);
  }

  void _drawHead(Canvas canvas, Paint paint, double w, double h) {
    canvas.drawCircle(Offset(w * 0.65, h * 0.25), w * 0.08, paint);
    // Face when lost (6 wrong)
    if (wrongGuesses >= 6) {
      final facePaint = Paint()
        ..color = AppColors.error
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      // X eyes
      final cx = w * 0.65;
      final cy = h * 0.25;
      const r = 0.025;
      canvas.drawLine(Offset(cx - w * 0.045, cy - h * r), Offset(cx - w * 0.02, cy + h * r), facePaint);
      canvas.drawLine(Offset(cx - w * 0.02, cy - h * r), Offset(cx - w * 0.045, cy + h * r), facePaint);
      canvas.drawLine(Offset(cx + w * 0.02, cy - h * r), Offset(cx + w * 0.045, cy + h * r), facePaint);
      canvas.drawLine(Offset(cx + w * 0.045, cy - h * r), Offset(cx + w * 0.02, cy + h * r), facePaint);
      // Sad mouth
      final path = Path()
        ..moveTo(cx - w * 0.04, cy + h * 0.04)
        ..quadraticBezierTo(cx, cy + h * 0.025, cx + w * 0.04, cy + h * 0.04);
      canvas.drawPath(path, facePaint);
    }
  }

  void _drawBody(Canvas canvas, Paint paint, double w, double h) {
    canvas.drawLine(Offset(w * 0.65, h * 0.33), Offset(w * 0.65, h * 0.62), paint);
  }

  void _drawLeftArm(Canvas canvas, Paint paint, double w, double h) {
    canvas.drawLine(Offset(w * 0.65, h * 0.40), Offset(w * 0.50, h * 0.52), paint);
  }

  void _drawRightArm(Canvas canvas, Paint paint, double w, double h) {
    canvas.drawLine(Offset(w * 0.65, h * 0.40), Offset(w * 0.80, h * 0.52), paint);
  }

  void _drawLeftLeg(Canvas canvas, Paint paint, double w, double h) {
    canvas.drawLine(Offset(w * 0.65, h * 0.62), Offset(w * 0.51, h * 0.78), paint);
  }

  void _drawRightLeg(Canvas canvas, Paint paint, double w, double h) {
    canvas.drawLine(Offset(w * 0.65, h * 0.62), Offset(w * 0.79, h * 0.78), paint);
  }

  @override
  bool shouldRepaint(HangmanPainter old) => old.wrongGuesses != wrongGuesses;
}
