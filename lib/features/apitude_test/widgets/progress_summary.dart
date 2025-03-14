import 'package:flutter/material.dart';

class ProgressSummary extends StatelessWidget {
  final List<String?> answers;
  final List<Map<String, dynamic>> questions;
  final String _formattedTime;

  ProgressSummary({
    required this.answers,
    required this.questions,
    required String formattedTime,
  }) : _formattedTime = formattedTime;

  @override
  Widget build(BuildContext context) {
    return _buildProgressSummary();
  }

  Widget _buildProgressSummary() {
    final answeredQuestions = answers.where((answer) => answer != null).length;
    final remainingQuestions = questions.length - answeredQuestions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressItem(
                icon: Icons.check_circle_outline,
                label: 'Answered',
                value: answeredQuestions.toString(),
                color: Color(0xFF34C759),
              ),
              _buildProgressItem(
                icon: Icons.pending_outlined,
                label: 'Remaining',
                value: remainingQuestions.toString(),
                color: Color(0xFFFF9500),
              ),
              _buildProgressItem(
                icon: Icons.timer_outlined,
                label: 'Time Left',
                value: _formattedTime,
                color: Color(0xFF5856D6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6E6E73),
          ),
        ),
      ],
    );
  }
}
