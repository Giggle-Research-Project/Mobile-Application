import 'package:flutter/material.dart';
import 'package:giggle/features/apitude_test/widgets/helpup_dailog.dart';
import 'package:giggle/features/apitude_test/widgets/test_timer.dart';

class TestHeader extends StatelessWidget {
  final int currentQuestionIndex;
  final List questions;
  final String formattedTime;
  final int timeRemaining;
  final bool showHint;
  final Function showExitConfirmationDialog;
  final BuildContext context;
  final List answers;

  TestHeader({
    required this.currentQuestionIndex,
    required this.questions,
    required this.formattedTime,
    required this.timeRemaining,
    required this.showHint,
    required this.showExitConfirmationDialog,
    required this.context,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => showExitConfirmationDialog(
                  context,
                  answers,
                  questions,
                  formattedTime,
                ),
              ),
              Expanded(
                child: Container(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / questions.length,
                      backgroundColor: const Color(0xFFE5E5EA),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF5E5CE6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TestTimer(
                formattedTime: formattedTime,
                timeRemaining: timeRemaining,
              ),
              const SizedBox(width: 8),
              HelpUpDialog(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestionIndex + 1}/${questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showHint)
                TextButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Show Hint'),
                  onPressed: () {
                    // Show hint logic
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
