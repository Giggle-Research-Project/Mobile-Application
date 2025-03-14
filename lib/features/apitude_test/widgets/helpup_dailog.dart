import 'package:flutter/material.dart';

class HelpUpDialog extends StatelessWidget {
  const HelpUpDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: Color(0xFF5E5CE6),
              ),
              const SizedBox(width: 8),
              const Text('Need Help?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                icon: Icons.check_circle_outline,
                title: 'Select One Answer',
                description: 'Choose the best answer for each question.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.timer_outlined,
                title: 'Time Management',
                description:
                    'Try to complete each question within the time limit.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.arrow_back,
                title: 'Navigation',
                description: 'You can go back to previous questions if needed.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.lightbulb_outline,
                title: 'Hints Available',
                description: 'Click the hint button if you need assistance.',
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Got it'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5E5CE6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF5E5CE6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF1D1D1F).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.help_outline,
        color: Color(0xFF6E6E73),
      ),
      onPressed: () => HelpUpDialog.show(context),
    );
  }
}
