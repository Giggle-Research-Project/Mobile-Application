import 'package:flutter/material.dart';
import 'package:giggle/features/monster_guide/monster_guide.dart';

class TipsCard extends StatelessWidget {
  final FeatureGuide feature;

  const TipsCard({required this.feature, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Tips',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 15),
          ...feature.tips.map((tip) => TipItem(tip: tip, color: feature.color)),
        ],
      ),
    );
  }
}
