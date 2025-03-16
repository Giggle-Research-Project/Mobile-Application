import 'package:flutter/material.dart';

class InsightsSection extends StatelessWidget {
  final Map<String, dynamic> overallStats;

  InsightsSection({required this.overallStats});

  @override
  Widget build(BuildContext context) {
    return _buildInsightsCard();
  }

  Widget _buildInsightsCard() {
    final mostAccurateOp = overallStats['mostAccurateOperation'] as String;
    final fastestOp = overallStats['fastestOperation'] as String;
    final weakestOp = overallStats['weakestOperation'] as String;

    // Only show insights if we have data
    if (mostAccurateOp.isEmpty && fastestOp.isEmpty && weakestOp.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Learning Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              if (mostAccurateOp.isNotEmpty)
                _buildInsightItem(
                  Icons.verified,
                  const Color(0xFF30D158),
                  'Strongest Operation',
                  'You excel at $mostAccurateOp with the highest accuracy',
                ),
              if (fastestOp.isNotEmpty)
                _buildInsightItem(
                  Icons.speed,
                  const Color(0xFFFF9F0A),
                  'Fastest Responses',
                  'You respond quickest in $fastestOp exercises',
                ),
              if (weakestOp.isNotEmpty)
                _buildInsightItem(
                  Icons.trending_up,
                  const Color(0xFFFF375F),
                  'Growth Opportunity',
                  '$weakestOp needs more practice for improvement',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
      IconData icon, Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1D1D1F).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
