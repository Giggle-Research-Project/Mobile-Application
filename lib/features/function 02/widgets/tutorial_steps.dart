import 'package:flutter/material.dart';

class TutorialStep extends StatelessWidget {
  final String number;
  final String text;
  final IconData icon;

  const TutorialStep({
    Key? key,
    required this.number,
    required this.text,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF5E5CE6),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ),
        Icon(icon, color: const Color(0xFF5E5CE6)),
      ],
    );
  }
}
