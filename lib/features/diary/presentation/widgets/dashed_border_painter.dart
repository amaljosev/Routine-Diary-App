import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const dashWidth = 5.0;
    final space = gap;

    _drawDashedLine(canvas, const Offset(0, 0), Offset(size.width, 0), dashWidth, space, paint);
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(size.width, size.height), dashWidth, space, paint);
    _drawDashedLine(canvas, Offset(size.width, size.height), Offset(0, size.height), dashWidth, space, paint);
    _drawDashedLine(canvas, Offset(0, size.height), const Offset(0, 0), dashWidth, space, paint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    double dashWidth,
    double dashSpace,
    Paint paint,
  ) {
    final distance = (end - start).distance;
    if (distance <= 0) return;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    for (int i = 0; i <= dashCount; i++) {
      final tStart = i * (dashWidth + dashSpace) / distance;
      final tEnd = (i * (dashWidth + dashSpace) + dashWidth) / distance;
      if (tStart > 1.0) break;
      final p1 = Offset.lerp(start, end, tStart)!;
      final p2 = Offset.lerp(start, end, tEnd.clamp(0.0, 1.0))!;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}