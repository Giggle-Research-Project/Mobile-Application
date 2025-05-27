import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';

class PerformanceResultScreen extends StatefulWidget {
  final double score;
  final String timeSpent;
  final int skillCorrectAnswers;
  final int skillTotalQuestions;
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
    required this.skillCorrectAnswers,
    required this.skillTotalQuestions,
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

  String _formatTimeDisplay(String timeSpent) {
    // Check if the timeSpent contains "min"
    if (timeSpent.contains("min")) {
      // Split the string to get minutes and seconds
      final parts = timeSpent.split(" ");
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[2].replaceAll("sec", "")) ?? 0;
      
      // If minutes is 0, only show seconds
      if (minutes == 0) {
        return "$seconds sec";
      }
      
      // Otherwise show both minutes and seconds
      return timeSpent;
    }
    
    // If only seconds, return as is
    return timeSpent;
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
          _buildPerformanceEmoji(),
          const SizedBox(height: 15),
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

  Widget _buildPerformanceEmoji() {
    final Color scoreColor = _getScoreColor();
    final String performanceLevel = _getPerformanceLevel();
    final String emoji = _getPerformanceEmoji();
    
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 64),
        ),
        const SizedBox(height: 10),
        Text(
          'Performance',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF1D1D1F).withOpacity(0.6),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            Text(
              '%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        Text(
          performanceLevel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: scoreColor.withOpacity(0.8),
          ),
        ),
      ],
    ).animate().scale(delay: 400.ms);
  }

  String _getPerformanceLevel() {
    if (widget.score >= 90) return 'Excellent';
    if (widget.score >= 80) return 'Great';
    if (widget.score >= 70) return 'Good';
    if (widget.score >= 60) return 'Fair';
    return 'Needs Improvement';
  }


  int _getStarCount() {
    if (widget.score >= 90) return 5;
    if (widget.score >= 80) return 4;
    if (widget.score >= 70) return 3;
    if (widget.score >= 60) return 2;
    return 1;
  }

  String _getPerformanceEmoji() {
    if (widget.score >= 90) return '🤩';
    if (widget.score >= 80) return '😊';
    if (widget.score >= 70) return '🙂';
    if (widget.score >= 60) return '🤔';
    return '😐';
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
            'Skill Assessment Statistics',
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
                value: _formatTimeDisplay(widget.timeSpent),
                color: const Color(0xFF5856D6),
              ),
              _buildStatItem(
                icon: Icons.check_circle_outline,
                label: 'Correct',
                value: widget.skillCorrectAnswers.toString(),
                color: const Color(0xFF34C759),
              ),
              _buildStatItem(
                icon: Icons.cancel_outlined,
                label: 'Incorrect',
                value: (widget.skillTotalQuestions - widget.skillCorrectAnswers).toString(),
                color: const Color(0xFFFF3B30),
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                label: 'Accuracy',
                value:
                    '${(widget.skillCorrectAnswers / widget.skillTotalQuestions * 100).toStringAsFixed(1)}%',
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
            'Category Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoryBar(
            'Procedural',
            widget.categoryLevels['procedural'] ?? 0,
            const Color(0xFF9CCC65),
          ),
          const SizedBox(height: 12),
          _buildCategoryBar(
            'Semantic',
            widget.categoryLevels['semantic'] ?? 0,
            const Color(0xFF4DD0E1),
          ),
          const SizedBox(height: 12),
          _buildCategoryBar(
            'Verbal',
            widget.categoryLevels['verbal'] ?? 0,
            const Color(0xFF4FC3F7),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: value / 100,
                            backgroundColor: color.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${value.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          _buildCategoryAnalysis('Procedural'),
          const SizedBox(height: 16),
          _buildCategoryAnalysis('Semantic'),
          const SizedBox(height: 16),
          _buildCategoryAnalysis('Verbal'),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysis(String category) {
    final Map<String, int> questionCounts;
    final Map<String, int> correctCounts;
    final Color categoryColor;

    // Assign the corresponding counts based on category
    switch (category.toUpperCase()) {
      case 'PROCEDURAL':
        questionCounts = widget.proceduralQuestionCounts;
        correctCounts = widget.proceduralCorrectCounts;
        categoryColor = const Color(0xFF9CCC65);
        break;
      case 'SEMANTIC':
        questionCounts = widget.semanticQuestionCounts;
        correctCounts = widget.semanticCorrectCounts;
        categoryColor = const Color(0xFF4DD0E1);
        break;
      case 'VERBAL':
        questionCounts = widget.verbalQuestionCounts;
        correctCounts = widget.verbalCorrectCounts;
        categoryColor = const Color(0xFF4FC3F7);
        break;
      default:
        return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDifficultyLevel('Easy', questionCounts, correctCounts, categoryColor),
            const SizedBox(width: 12),
            _buildDifficultyLevel('Medium', questionCounts, correctCounts, categoryColor),
            const SizedBox(width: 12),
            _buildDifficultyLevel('Hard', questionCounts, correctCounts, categoryColor),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyLevel(
    String difficulty, 
    Map<String, int> questionCounts, 
    Map<String, int> correctCounts,
    Color color,
  ) {
    final totalQuestions = questionCounts[difficulty.toUpperCase()] ?? 0;
    final correctAnswers = correctCounts[difficulty.toUpperCase()] ?? 0;
    final percentage = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
    final stars = (percentage / 20).round();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                difficulty,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: index < stars ? const Color(0xFFFFD700) : Colors.grey[400],
                  size: 16,
                ).animate(delay: (50 * index).ms).scale();
              }),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$correctAnswers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '/$totalQuestions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: 200.ms)
      .slideY(begin: 0.2, end: 0);
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
