import 'package:flutter/material.dart';

class BuildQuestionWidget extends StatelessWidget {
  final String question;

  const BuildQuestionWidget({
    Key? key,
    this.question =
        'Add the numbers in the squares and write your answer below',
  }) : super(key: key);

  Widget _buildQuestion() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            // Added Expanded widget here
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildQuestion();
  }
}
