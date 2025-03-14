import 'package:flutter/material.dart';

class FocusIndicator extends StatelessWidget {
  final Color statusColor;
  final double concentrationScore;

  const FocusIndicator({
    Key? key,
    required this.statusColor,
    required this.concentrationScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            '${(concentrationScore * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
