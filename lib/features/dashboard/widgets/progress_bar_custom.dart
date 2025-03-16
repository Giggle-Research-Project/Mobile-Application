import 'package:flutter/material.dart';

class ProgressBarCustom extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String percentage;

  const ProgressBarCustom({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: const Color(0xFFF5F5F7),
          color: color,
          minHeight: 6,
        ),
      ],
    );
  }
}
