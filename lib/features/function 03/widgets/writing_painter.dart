import 'package:flutter/material.dart';

class WritingPainter extends CustomPainter {
  final List<List<Offset>> paths;
  final Color color;
  final double strokeWidth;

  WritingPainter({
    required this.paths,
    this.color = Colors.blue,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (var path in paths) {
      if (path.length > 1) {
        final drawPath = Path();
        drawPath.moveTo(path[0].dx, path[0].dy);

        for (int i = 1; i < path.length; i++) {
          drawPath.lineTo(path[i].dx, path[i].dy);
        }

        canvas.drawPath(drawPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
