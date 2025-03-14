import 'package:flutter/material.dart';

class LessonInfo extends StatefulWidget {
  final String dyscalculiaType;
  final String courseName;
  final double concentrationScore;

  const LessonInfo({
    Key? key,
    required this.dyscalculiaType,
    required this.courseName,
    required this.concentrationScore,
  }) : super(key: key);

  @override
  _LessonInfoState createState() => _LessonInfoState();
}

class _LessonInfoState extends State<LessonInfo> {
  @override
  Widget build(BuildContext context) {
    return _buildLessonInfo();
  }

  Widget _buildLessonInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lesson Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.category, 'Type', widget.dyscalculiaType),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.book, 'Course', widget.courseName),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.access_time, 'Duration', '15 minutes'),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.show_chart, 'Average Focus',
              '${(widget.concentrationScore * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF5E5CE6),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF1D1D1F).withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }
}
