import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TestTimer extends StatefulWidget {
  final String formattedTime;
  final int timeRemaining;

  TestTimer({required this.formattedTime, required this.timeRemaining});
  @override
  _TestTimerState createState() => _TestTimerState();
}

class _TestTimerState extends State<TestTimer> {
  @override
  Widget build(BuildContext context) {
    return _buildTimer();
  }

  Widget _buildTimer() {
    final isLowTime = widget.timeRemaining < 300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLowTime ? const Color(0xFFFFEBEB) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color:
                isLowTime ? const Color(0xFFFF3B30) : const Color(0xFF6E6E73),
          ),
          const SizedBox(width: 4),
          Text(
            widget.formattedTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color:
                  isLowTime ? const Color(0xFFFF3B30) : const Color(0xFF6E6E73),
            ),
          ),
        ],
      ),
    ).animate(target: isLowTime ? 1 : 0).shake(delay: 300.ms);
  }
}
