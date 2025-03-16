import 'package:flutter/material.dart';

class DashboardSectionTitle extends StatelessWidget {
  final String title;

  const DashboardSectionTitle({Key? key, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D1D1F),
        ),
      ),
    );
  }
}
