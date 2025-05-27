import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherAndTimerWidget extends ConsumerStatefulWidget {
  final int timeRemaining;
  final List<Map<String, dynamic>> questions;
  final int currentQuestionIndex;
  final String performance; // Add this new property

  const TeacherAndTimerWidget({
    Key? key,
    required this.timeRemaining,
    required this.questions,
    required this.currentQuestionIndex,
    required this.performance, // Add this parameter
  }) : super(key: key);

  @override
  ConsumerState<TeacherAndTimerWidget> createState() => _TeacherAndTimerWidgetState();
}

class _TeacherAndTimerWidgetState extends ConsumerState<TeacherAndTimerWidget> {
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String getDifficultyText() {
    switch (widget.performance) {
      case 'hard':
        return 'Hard';
      case 'medium':
        return 'Medium';
      default:
        return 'Easy';
    }
  }

  Color getDifficultyColor() {
    switch (widget.performance) {
      case 'hard':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData getDifficultyIcon() {
    switch (widget.performance) {
      case 'hard':
        return Icons.star;
      case 'medium':
        return Icons.star_half;
      default:
        return Icons.star_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Difficulty Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: getDifficultyColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: getDifficultyColor().withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getDifficultyIcon(),
                  size: 14,
                  color: getDifficultyColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  getDifficultyText(),
                  style: TextStyle(
                    color: getDifficultyColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatTime(widget.timeRemaining),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
