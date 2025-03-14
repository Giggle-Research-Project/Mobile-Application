import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';

class PerformanceResultScreen extends StatefulWidget {
  final double score;
  final String timeSpent;
  final int correctAnswers;
  final int totalQuestions;
  final Map<String, double> categoryLevels;
  final List<Map<String, dynamic>> allQuestions;
  final Map<String, int> proceduralQuestionCounts;
  final Map<String, int> proceduralCorrectCounts;
  final Map<String, int> semanticQuestionCounts;
  final Map<String, int> semanticCorrectCounts;
  final Map<String, int> verbalQuestionCounts;
  final Map<String, int> verbalCorrectCounts;

  const PerformanceResultScreen({
    Key? key,
    required this.score,
    required this.timeSpent,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.categoryLevels,
    required this.allQuestions,
    required this.proceduralQuestionCounts,
    required this.proceduralCorrectCounts,
    required this.semanticQuestionCounts,
    required this.semanticCorrectCounts,
    required this.verbalQuestionCounts,
    required this.verbalCorrectCounts,
  }) : super(key: key);

  @override
  _PerformanceResultScreenState createState() =>
      _PerformanceResultScreenState();
}

class _PerformanceResultScreenState extends State<PerformanceResultScreen> {
  late Map<String, Map<String, List<bool>>> groupedResults;

  @override
  void initState() {
    super.initState();
    groupedResults = _organizeQuestionResults();
  }

  Map<String, Map<String, List<bool>>> _organizeQuestionResults() {
    Map<String, Map<String, List<bool>>> organized = {
      'PROCEDURAL': {'EASY': [], 'MEDIUM': [], 'HARD': []},
      'SEMANTIC': {'EASY': [], 'MEDIUM': [], 'HARD': []},
      'VERBAL': {'EASY': [], 'MEDIUM': [], 'HARD': []},
    };

    for (var question in widget.allQuestions) {
      final type = question['dyscalculia_type'] as String;
      final difficulty = question['difficulty'] as String;
      final isCorrect = question['isCorrect'] as bool? ?? false;

      // Add the result to the appropriate list
      if (organized.containsKey(type) &&
          organized[type]!.containsKey(difficulty)) {
        organized[type]![difficulty]!.add(isCorrect);
      }
    }

    return organized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Stack(
        children: [
          const BackgroundPattern(),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SubPageHeader(
                    title: 'Performance Result',
                    desc: 'Review your performance and statistics below.',
                  ),
                  const SizedBox(height: 20),
                  _buildTitle(),
                  const SizedBox(height: 30),
                  _buildScoreCard(),
                  const SizedBox(height: 20),
                  _buildDetailedStats(),
                  const SizedBox(height: 20),
                  _buildCategoryLevelsPieChart(),
                  const SizedBox(height: 20),
                  _buildEvaluationTable(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Here\'s how you performed in your dyscalculia assessment',
        style: TextStyle(
          fontSize: 16,
          color: const Color(0xFF1D1D1F).withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E5CE6).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildScoreRing(),
          const SizedBox(height: 24),
          Text(
            _getPerformanceMessage(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getPerformanceDescription(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF1D1D1F).withOpacity(0.7),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildScoreRing() {
    final Color scoreColor = _getScoreColor();
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: widget.score / 100,
            strokeWidth: 12,
            backgroundColor: const Color(0xFFE5E5EA),
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.score.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              'Score',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF1D1D1F).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    ).animate().scale(delay: 400.ms);
  }

  Widget _buildDetailedStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            'Detailed Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.timer_outlined,
                label: 'Time Taken',
                value: widget.timeSpent,
                color: const Color(0xFF5856D6),
              ),
              _buildStatItem(
                icon: Icons.check_circle_outline,
                label: 'Correct',
                value: '${widget.correctAnswers}/${widget.totalQuestions}',
                color: const Color(0xFF34C759),
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                label: 'Accuracy',
                value:
                    '${(widget.correctAnswers / widget.totalQuestions * 100).toStringAsFixed(1)}%',
                color: const Color(0xFFFF9500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6E6E73),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryLevelsPieChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            'Evaluation Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: const Color(0xFF9CCC65),
                        value: widget.categoryLevels['procedural'] ?? 0,
                        title: 'Procedural',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: const Color(0xFF4DD0E1),
                        value: widget.categoryLevels['semantic'] ?? 0,
                        title: 'Semantic',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: const Color(0xFF4FC3F7),
                        value: widget.categoryLevels['verbal'] ?? 0,
                        title: 'Verbal',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
                Center(
                  child: Text(
                    'Category\nLevel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Procedural', const Color(0xFF9CCC65)),
              _buildLegendItem('Semantic', const Color(0xFF4DD0E1)),
              _buildLegendItem('Verbal', const Color(0xFF4FC3F7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            'Performance Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          Table(
            border: TableBorder.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                ),
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Difficulty Level',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Procedural',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Semantic',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Verbal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              ...['EASY', 'MEDIUM', 'HARD'].map((difficulty) {
                return TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          difficulty.toLowerCase().capitalize(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    _buildDetailedTableCell('PROCEDURAL', difficulty),
                    _buildDetailedTableCell('SEMANTIC', difficulty),
                    _buildDetailedTableCell('VERBAL', difficulty),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTableCell(String type, String difficulty) {
    // Get counts for this type and difficulty
    int totalQuestions = 0;
    int correctAnswers = 0;

    if (type == 'PROCEDURAL') {
      totalQuestions = widget.proceduralQuestionCounts[difficulty] ?? 0;
      correctAnswers = widget.proceduralCorrectCounts[difficulty] ?? 0;
    } else if (type == 'SEMANTIC') {
      totalQuestions = widget.semanticQuestionCounts[difficulty] ?? 0;
      correctAnswers = widget.semanticCorrectCounts[difficulty] ?? 0;
    } else if (type == 'VERBAL') {
      totalQuestions = widget.verbalQuestionCounts[difficulty] ?? 0;
      correctAnswers = widget.verbalCorrectCounts[difficulty] ?? 0;
    }

    // Calculate percentage
    double percentage =
        totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
    final color = _getPerformanceColor(percentage);

    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              '$correctAnswers/$totalQuestions',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String type, String difficulty) {
    double percentage = 0.0;

    // Get counts for this type and difficulty
    int totalQuestions = 0;
    int correctAnswers = 0;

    if (type == 'PROCEDURAL') {
      if (widget.proceduralQuestionCounts.containsKey(difficulty)) {
        totalQuestions = widget.proceduralQuestionCounts[difficulty] ?? 0;
        correctAnswers = widget.proceduralCorrectCounts[difficulty] ?? 0;
      }
    } else if (type == 'SEMANTIC') {
      if (widget.semanticQuestionCounts.containsKey(difficulty)) {
        totalQuestions = widget.semanticQuestionCounts[difficulty] ?? 0;
        correctAnswers = widget.semanticCorrectCounts[difficulty] ?? 0;
      }
    } else if (type == 'VERBAL') {
      if (widget.verbalQuestionCounts.containsKey(difficulty)) {
        totalQuestions = widget.verbalQuestionCounts[difficulty] ?? 0;
        correctAnswers = widget.verbalCorrectCounts[difficulty] ?? 0;
      }
    }

    // Calculate percentage
    percentage =
        totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

    final color = _getPerformanceColor(percentage);

    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Map<String, Map<String, double>> _calculateAverages() {
    Map<String, Map<String, double>> averages = {
      'PROCEDURAL': {'EASY': 0.0, 'MEDIUM': 0.0, 'HARD': 0.0},
      'SEMANTIC': {'EASY': 0.0, 'MEDIUM': 0.0, 'HARD': 0.0},
      'VERBAL': {'EASY': 0.0, 'MEDIUM': 0.0, 'HARD': 0.0},
    };

    // Calculate averages for each type and difficulty
    for (var type in groupedResults.keys) {
      for (var difficulty in groupedResults[type]!.keys) {
        final results = groupedResults[type]![difficulty]!;
        if (results.isNotEmpty) {
          final correctCount = results.where((result) => result).length;
          averages[type]![difficulty] = (correctCount / results.length) * 100;
        }
      }
    }

    return averages;
  }

  Color _getPerformanceColor(double value) {
    if (value >= 90) return const Color(0xFF34C759);
    if (value >= 80) return const Color(0xFF30D158);
    if (value >= 70) return const Color(0xFFFF9500);
    if (value >= 60) return const Color(0xFFFF3B30);
    return const Color(0xFFFF2D55);
  }

  String _getPerformanceMessage() {
    if (widget.score >= 90) return 'Excellent!';
    if (widget.score >= 80) return 'Great Job!';
    if (widget.score >= 70) return 'Good Progress!';
    if (widget.score >= 60) return 'Keep Going!';
    return 'Room for Improvement';
  }

  String _getPerformanceDescription() {
    if (widget.score >= 90) {
      return 'You\'ve mastered this topic! Ready for more challenges!';
    }
    if (widget.score >= 80) {
      return 'You\'re showing strong understanding of the concepts!';
    }
    if (widget.score >= 70) {
      return 'You\'re on the right track! Keep practicing!';
    }
    if (widget.score >= 60) {
      return 'You\'re making progress! Let\'s review and try again!';
    }
    return 'Don\'t worry! Let\'s practice more and improve together!';
  }

  Color _getScoreColor() {
    if (widget.score >= 90) return const Color(0xFF34C759);
    if (widget.score >= 80) return const Color(0xFF30D158);
    if (widget.score >= 70) return const Color(0xFFFF9500);
    if (widget.score >= 60) return const Color(0xFFFF3B30);
    return const Color(0xFFFF2D55);
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
