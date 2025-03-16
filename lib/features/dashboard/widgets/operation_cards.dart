import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:giggle/features/dashboard/widgets/common_card.dart';
import 'package:giggle/features/dashboard/widgets/progress_bar_custom.dart';

class OperationCards extends StatelessWidget {
  final Map<String, dynamic> operation;
  final Map<String, Map<String, dynamic>> _operationData;
  final Function(String, Map<String, dynamic>, Color)
      _navigateToOperationDetail;
  final String Function(DateTime) _formatLastActivity;

  OperationCards({
    required this.operation,
    required Map<String, Map<String, dynamic>> operationData,
    required Function(String, Map<String, dynamic>, Color)
        navigateToOperationDetail,
    required String Function(DateTime) formatLastActivity,
  })  : _operationData = operationData,
        _navigateToOperationDetail = navigateToOperationDetail,
        _formatLastActivity = formatLastActivity;

  Widget _buildOperationCard(Map<String, dynamic> operation) {
    final title = operation['title'] as String;
    final icon = operation['icon'] as IconData;
    final color = operation['color'] as Color;

    // Get operation data
    final data = _operationData[title]!;
    final completedLessons = data['completedLessons'] as int;
    final totalLessons = data['totalLessons'] as int;
    final correctAnswers = data['correctAnswers'] as int;
    final totalQuestions = data['totalQuestions'] as int;

    // Calculate metrics
    final lessonProgress =
        totalLessons > 0 ? completedLessons / totalLessons : 0.0;
    final accuracy =
        totalQuestions > 0 ? correctAnswers / totalQuestions * 100 : 0.0;
    final lastActivity = data['lastActivityDate'] != null
        ? _formatLastActivity((data['lastActivityDate'] as Timestamp).toDate())
        : 'Not started';

    // Check if we have prediction data
    final hasPredictionData = title == 'Addition' &&
            (data.containsKey('semanticPrediction') ||
                data.containsKey('verbalPrediction')) ||
        title == 'Subtraction' && data.containsKey('proceduralPrediction');

    return GestureDetector(
      onTap: () => _navigateToOperationDetail(title, data, color),
      child: CommonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasPredictionData)
                  Icon(
                    Icons.auto_graph,
                    size: 16,
                    color: color.withOpacity(0.8),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ProgressBarCustom(
              label: 'Lessons',
              value: lessonProgress,
              color: color,
              percentage: '$completedLessons/$totalLessons',
            ),
            const SizedBox(height: 12),
            ProgressBarCustom(
              label: 'Accuracy',
              value: accuracy / 100,
              color: color,
              percentage: '${accuracy.toStringAsFixed(1)}%',
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Last activity: $lastActivity',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1D1D1F).withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF1D1D1F).withOpacity(0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildOperationCard(operation);
  }
}
