import 'package:flutter/material.dart';

class OperationDetailScreen extends StatelessWidget {
  final String operationName;
  final Map<String, dynamic> operationData;
  final Color color;

  const OperationDetailScreen({
    Key? key,
    required this.operationName,
    required this.operationData,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          '$operationName Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF1D1D1F),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(),
            const SizedBox(height: 20),
            _buildPerformanceCard(),
            const SizedBox(height: 20),
            _buildTimeAnalysisCard(),
            const SizedBox(height: 20),
            _buildRecommendationsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final completedLessons = operationData['completedLessons'] as int;
    final totalLessons = operationData['totalLessons'] as int;
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

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
            'Lesson Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: const Color(0xFFF5F5F7),
                color: color,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Complete',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedLessons of $totalLessons lessons completed',
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
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final correctAnswers = operationData['correctAnswers'] as int;
    final totalQuestions = operationData['totalQuestions'] as int;
    final accuracy =
        totalQuestions > 0 ? correctAnswers / totalQuestions * 100 : 0.0;

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
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                'Accuracy',
                '${accuracy.toStringAsFixed(1)}%',
                Icons.check_circle,
                color,
              ),
              _buildMetricItem(
                'Questions',
                '$totalQuestions',
                Icons.question_answer,
                color,
              ),
              _buildMetricItem(
                'Correct',
                '$correctAnswers',
                Icons.thumb_up,
                color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAnalysisCard() {
    final avgTime = (operationData['averageTime'] ?? 0.0) as double;
    final List<dynamic> rawTimeValues = operationData['timeValues'] ?? [];
    final List<double> timeValues = rawTimeValues.map((value) => (value as num).toDouble()).toList();

    String timeTrend = 'Stable';
    if (timeValues.length >= 2) {
      final recentValues =
          timeValues.sublist(timeValues.length > 5 ? timeValues.length - 5 : 0);
      final firstValues =
          timeValues.sublist(0, timeValues.length > 5 ? 5 : timeValues.length);

      final recentAvg =
          recentValues.reduce((a, b) => a + b) / recentValues.length;
      final firstAvg = firstValues.reduce((a, b) => a + b) / firstValues.length;

      if (recentAvg < firstAvg * 0.9) {
        timeTrend = 'Improving';
      } else if (recentAvg > firstAvg * 1.1) {
        timeTrend = 'Slowing';
      }
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
            'Response Time Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                'Average',
                '${avgTime.toStringAsFixed(1)}s',
                Icons.timer,
                color,
              ),
              _buildMetricItem(
                'Trend',
                timeTrend,
                Icons.trending_up,
                color,
              ),
              _buildMetricItem(
                'Responses',
                '${timeValues.length}',
                Icons.analytics,
                color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context) {
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
            'Next Steps',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OperationScreen(
                    operation: operationName,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: color,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue Practice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF1D1D1F).withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class OperationScreen extends StatelessWidget {
  final String operation;

  const OperationScreen({
    Key? key,
    required this.operation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$operation Practice'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Practice screen for $operation',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
