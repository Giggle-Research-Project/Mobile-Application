import 'package:flutter/material.dart';

class CompletionBadge extends StatelessWidget {
  final String completionRate;

  const CompletionBadge(String operationCompletionRate,
      {Key? key, required this.completionRate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5E5CE6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$completionRate% Complete',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5E5CE6),
        ),
      ),
    );
  }
}
