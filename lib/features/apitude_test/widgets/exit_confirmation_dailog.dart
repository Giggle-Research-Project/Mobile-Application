import 'package:flutter/material.dart';
import 'package:giggle/features/apitude_test/widgets/progress_summary.dart';

class ExitConfirmationDialog extends StatelessWidget {
  final List<String?> answers;
  final List<Map<String, dynamic>> questions;
  final String formattedTime;

  const ExitConfirmationDialog({
    Key? key,
    required this.answers,
    required this.questions,
    required this.formattedTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Exit Test?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to exit? Your progress will be lost.',
          ),
          const SizedBox(height: 16),
          ProgressSummary(
            answers: answers,
            questions: questions,
            formattedTime: formattedTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF6E6E73)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text(
            'Exit',
            style: TextStyle(color: Color(0xFFFF3B30)),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Exit test screen
          },
        ),
      ],
    );
  }
}
