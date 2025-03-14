import 'package:flutter/material.dart';
import 'package:giggle/core/data/question_request.dart';
import 'package:giggle/features/performance_result/performance_result_screen.dart';

class TimeUpDialog extends StatelessWidget {
  final String testType;
  final List<String?> answers;
  final List<Map<String, dynamic>> questions;
  final int timeRemaining;
  final int correctAnswers;
  final int actualElapsedSeconds;

  // Added new parameters for category breakdowns
  final Map<String, int> proceduralQuestionCounts;
  final Map<String, int> proceduralCorrectCounts;
  final Map<String, int> semanticQuestionCounts;
  final Map<String, int> semanticCorrectCounts;
  final Map<String, int> verbalQuestionCounts;
  final Map<String, int> verbalCorrectCounts;
  final BuildContext context;

  TimeUpDialog({
    required this.context,
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

  double _calculateOverallScore() {
    if (questions.isEmpty) return 0.0;
    return (correctAnswers / questions.length) * 100;
  }

  Map<String, double> _calculateCategoryLevels() {
    // Calculate performance percentage for each category
    double proceduralScore = _calculateCategoryScore(
        proceduralCorrectCounts, proceduralQuestionCounts);
    double semanticScore =
        _calculateCategoryScore(semanticCorrectCounts, semanticQuestionCounts);
    double verbalScore =
        _calculateCategoryScore(verbalCorrectCounts, verbalQuestionCounts);

    return {
      'procedural': proceduralScore,
      'semantic': semanticScore,
      'verbal': verbalScore,
    };
  }

  double _calculateCategoryScore(
      Map<String, int> correctCounts, Map<String, int> questionCounts) {
    // Sum up the total correct answers and total questions
    int totalCorrect = 0;
    int totalQuestions = 0;

    // Loop through each difficulty level
    for (String difficulty in correctCounts.keys) {
      totalCorrect += correctCounts[difficulty] ?? 0;
      totalQuestions += questionCounts[difficulty] ?? 0;
    }

    // Avoid division by zero
    if (totalQuestions == 0) return 0.0;

    // Calculate percentage (correct out of total)
    return (totalCorrect / totalQuestions) * 100;
  }

  void _showTimeUpDialog() {
    final timeSpentInSeconds =
        actualElapsedSeconds > 0 ? actualElapsedSeconds : 0;

    final timeSpentInMinutes = timeSpentInSeconds ~/ 60;
    final remainingSeconds = timeSpentInSeconds % 60;

    final timeDisplay = remainingSeconds > 0
        ? '$timeSpentInMinutes min $remainingSeconds sec'
        : '$timeSpentInMinutes min';

    final Map<String, double> categoryLevels = _calculateCategoryLevels();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Time\'s Up!'),
          content: const Text(
            'Your time has expired. Your answers will be submitted automatically.',
          ),
          actions: [
            TextButton(
              child: const Text('View Results'),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => PerformanceResultScreen(
                            score: _calculateOverallScore(),
                            timeSpent: timeDisplay,
                            correctAnswers: correctAnswers,
                            totalQuestions: questions.length,
                            categoryLevels: categoryLevels,
                            allQuestions: questionRequests,
                            // Pass the question counts and correct answer counts
                            proceduralQuestionCounts: proceduralQuestionCounts,
                            proceduralCorrectCounts: proceduralCorrectCounts,
                            semanticQuestionCounts: semanticQuestionCounts,
                            semanticCorrectCounts: semanticCorrectCounts,
                            verbalQuestionCounts: verbalQuestionCounts,
                            verbalCorrectCounts: verbalCorrectCounts,
                          )),
                );
                _submitTest();
              },
            ),
          ],
        );
      },
    );
  }

  void _submitTest() {
    // Add submission logic here
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
