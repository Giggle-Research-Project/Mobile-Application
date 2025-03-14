import 'package:flutter/material.dart';

class PerformanceCards extends StatelessWidget {
  const PerformanceCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSessionCard(
            title: 'Teaching Sessions',
            value: '3/5',
            color: Colors.blue.shade300,
            icon: Icons.school,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSessionCard(
            title: 'Solo Sessions',
            value: '12/15',
            color: Colors.green.shade300,
            icon: Icons.person,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSessionCard(
            title: 'Interactive',
            value: '2/4',
            color: Colors.orange.shade300,
            icon: Icons.group,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
