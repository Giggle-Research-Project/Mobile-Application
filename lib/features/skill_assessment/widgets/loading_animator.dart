import 'dart:math' show pi;
import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedLoadingDialog extends StatefulWidget {
  const AnimatedLoadingDialog({Key? key}) : super(key: key);

  @override
  State<AnimatedLoadingDialog> createState() => _AnimatedLoadingDialogState();
}

class _AnimatedLoadingDialogState extends State<AnimatedLoadingDialog>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _scaleController;
  late Animation<double> _spinAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeInOutCubic,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _spinController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading spinner
              ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: RotationTransition(
                    turns: _spinAnimation,
                    child: CustomPaint(
                      painter: _LoadingPainter(
                        color: const Color(0xFF5E5CE6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Generating Questions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              const Text(
                'Preparing your assessment',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6E6E73),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final Color color;

  _LoadingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final double startAngle = -90 * (pi / 180);
    const double sweepAngle = 300 * (pi / 180);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
