import 'package:flutter/material.dart';
import 'package:giggle/core/enums/enums.dart';
import 'package:giggle/core/widgets/bottom_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompletionDialog extends StatelessWidget {
  final String userId;
  final String testType;
  final List<String?> answers;
  final List<Map<String, dynamic>> questions;
  final int timeRemaining;
  final int correctAnswers;
  final int actualElapsedSeconds;
  final Map<String, int> proceduralQuestionCounts;
  final Map<String, int> proceduralCorrectCounts;
  final Map<String, int> semanticQuestionCounts;
  final Map<String, int> semanticCorrectCounts;
  final Map<String, int> verbalQuestionCounts;
  final Map<String, int> verbalCorrectCounts;

  CompletionDialog({
    required this.userId,
    required this.testType,
    required this.answers,
    required this.questions,
    required this.timeRemaining,
    required this.correctAnswers,
    required this.actualElapsedSeconds,
    required this.proceduralQuestionCounts,
    required this.proceduralCorrectCounts,
    required this.semanticQuestionCounts,
    required this.semanticCorrectCounts,
    required this.verbalQuestionCounts,
    required this.verbalCorrectCounts,
  });

  void showCompletionDialog(BuildContext context) {
    final timeSpentInSeconds =
        actualElapsedSeconds > 0 ? actualElapsedSeconds : 0;
    final timeSpentInMinutes = timeSpentInSeconds ~/ 60;
    final remainingSeconds = timeSpentInSeconds % 60;
    final timeDisplay = remainingSeconds > 0
        ? '$timeSpentInMinutes min $remainingSeconds sec'
        : '$timeSpentInMinutes min';
    final categoryLevels = _calculateCategoryLevels();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Test Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Thank you for completing the assessment. Your results will be analyzed and shared soon.'),
              const SizedBox(height: 16),
              _buildCompletionStats(timeDisplay),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Complete'),
              onPressed: () {
                _saveDataToFirestore(categoryLevels, timeDisplay);

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => MainScreen(),
                  ),
                );
              },
            ),
            TextButton(
              child: const Text('Go Back'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // New method to save data to Firestore
  Future<void> _saveDataToFirestore(
      Map<String, double> categoryLevels, String timeDisplay) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final answeredQuestions =
          answers.where((answer) => answer != null).length;
      final completionRate =
          (answeredQuestions / questions.length * 100).round();
      final overallScore = _calculateOverallScore();

      final assessmentData = {
        'userId': userId,
        'timeRemaining': timeRemaining,
        'correctAnswers': correctAnswers,
        'totalQuestions': questions.length,
        'timeSpent': timeDisplay,
        'actualElapsedSeconds': actualElapsedSeconds,
        'overallScore': overallScore,
        'completionRate': completionRate,
        'answeredQuestions': answeredQuestions,
        'proceduralQuestionCounts': proceduralQuestionCounts,
        'proceduralCorrectCounts': proceduralCorrectCounts,
        'semanticQuestionCounts': semanticQuestionCounts,
        'semanticCorrectCounts': semanticCorrectCounts,
        'verbalQuestionCounts': verbalQuestionCounts,
        'verbalCorrectCounts': verbalCorrectCounts,
        'completed': true,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('skill_assessment')
          .doc(userId)
          .collection(testType)
          .doc(testType)
          .set(assessmentData);

      print('Assessment data saved successfully to Firestore');
    } catch (e) {
      print('Error saving assessment data to Firestore: $e');
    }
  }

  double _calculateOverallScore() {
    if (questions.isEmpty) return 0.0;
    return (correctAnswers / questions.length) * 100;
  }

  Map<String, double> _calculateCategoryLevels() {
    return {
      'procedural': _calculateCategoryScore(
          proceduralCorrectCounts, proceduralQuestionCounts),
      'semantic': _calculateCategoryScore(
          semanticCorrectCounts, semanticQuestionCounts),
      'verbal':
          _calculateCategoryScore(verbalCorrectCounts, verbalQuestionCounts),
    };
  }

  double _calculateCategoryScore(
      Map<String, int> correctCounts, Map<String, int> questionCounts) {
    int totalCorrect =
        correctCounts.values.fold(0, (sum, count) => sum + count);
    int totalQuestions =
        questionCounts.values.fold(0, (sum, count) => sum + count);
    if (totalQuestions == 0) return 0.0;
    return (totalCorrect / totalQuestions) * 100;
  }

  Widget _buildCompletionStats(String timeDisplay) {
    final answeredQuestions = answers.where((answer) => answer != null).length;
    final completionRate = (answeredQuestions / questions.length * 100).round();
    
    // Calculate percentages
    final correctPercentage = (correctAnswers / questions.length * 100).round();
    final incorrectAnswers = answeredQuestions - correctAnswers;
    final incorrectPercentage = (incorrectAnswers / questions.length * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (testType == TestScreenType.skillAssessment.toString()) ...[
            _buildStatRow('Questions Answered', '$answeredQuestions/${questions.length}'),
            const SizedBox(height: 8),
            _buildStatRow('Completion Rate', '$completionRate%'),
            const SizedBox(height: 8),
            _buildStatRow('Time Taken', timeDisplay),
            const SizedBox(height: 16),
            _buildAnswerStats(
              correct: correctAnswers,
              incorrect: incorrectAnswers,
              total: questions.length,
              correctPercentage: correctPercentage,
              incorrectPercentage: incorrectPercentage,
            ),
          ] else ...[
            _buildStatRow('Questions Answered', '$answeredQuestions/${questions.length}'),
            const SizedBox(height: 8),
            _buildStatRow('Completion Rate', '$completionRate%'),
            const SizedBox(height: 8),
            _buildStatRow('Time Taken', timeDisplay),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerStats({
    required int correct,
    required int incorrect,
    required int total,
    required int correctPercentage,
    required int incorrectPercentage,
  }) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildAnswerIndicator(
                label: 'Correct',
                count: correct,
                total: total,
                percentage: correctPercentage,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnswerIndicator(
                label: 'Incorrect',
                count: incorrect,
                total: total,
                percentage: incorrectPercentage,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerIndicator({
    required String label,
    required int count,
    required int total,
    required int percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6E6E73),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count/$total ($percentage%)',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
              color: Color(0xFF1D1D1F),
              fontSize: 14,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
