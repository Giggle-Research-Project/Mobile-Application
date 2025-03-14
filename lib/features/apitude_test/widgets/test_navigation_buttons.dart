import 'package:flutter/material.dart';
import 'package:giggle/features/apitude_test/widgets/completion_dailog.dart';

class TestNavigationButtons extends StatelessWidget {
  final String userId;
  final String testType;
  final int currentQuestionIndex;
  final List<Map<String, dynamic>> questions;
  final int _timeRemaining;
  final List<String?> answers;
  final PageController _pageController;
  final int correctAnswers;
  final int actualElapsedSeconds;

  // Added these maps to match what's needed in CompletionDialog
  final Map<String, Map<String, int>> questionCounts;
  final Map<String, Map<String, int>> correctAnswerCounts;

  TestNavigationButtons({
    required this.userId,
    required this.testType,
    required this.currentQuestionIndex,
    required this.questions,
    required this.answers,
    required PageController pageController,
    required int timeRemaining,
    required this.correctAnswers,
    required this.actualElapsedSeconds,
    required this.questionCounts,
    required this.correctAnswerCounts,
  })  : _pageController = pageController,
        _timeRemaining = timeRemaining;

  @override
  Widget build(BuildContext context) {
    return _buildNavigationButtons(context);
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentQuestionIndex > 0)
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            )
          else
            const SizedBox.shrink(),
          if (currentQuestionIndex < questions.length - 1)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
              onPressed: answers[currentQuestionIndex] != null
                  ? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E5CE6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
              onPressed: answers[currentQuestionIndex] != null
                  ? () => CompletionDialog(
                        userId: userId,
                        testType: testType,
                        answers: answers,
                        questions: questions,
                        timeRemaining: _timeRemaining,
                        correctAnswers: correctAnswers,
                        actualElapsedSeconds: actualElapsedSeconds,
                        proceduralQuestionCounts: {
                          'EASY': questionCounts['PROCEDURAL']!['EASY'] ?? 0,
                          'MEDIUM':
                              questionCounts['PROCEDURAL']!['MEDIUM'] ?? 0,
                          'HARD': questionCounts['PROCEDURAL']!['HARD'] ?? 0,
                        },
                        proceduralCorrectCounts: {
                          'EASY':
                              correctAnswerCounts['PROCEDURAL']!['EASY'] ?? 0,
                          'MEDIUM':
                              correctAnswerCounts['PROCEDURAL']!['MEDIUM'] ?? 0,
                          'HARD':
                              correctAnswerCounts['PROCEDURAL']!['HARD'] ?? 0,
                        },
                        semanticQuestionCounts: {
                          'EASY': questionCounts['SEMANTIC']!['EASY'] ?? 0,
                          'MEDIUM': questionCounts['SEMANTIC']!['MEDIUM'] ?? 0,
                          'HARD': questionCounts['SEMANTIC']!['HARD'] ?? 0,
                        },
                        semanticCorrectCounts: {
                          'EASY': correctAnswerCounts['SEMANTIC']!['EASY'] ?? 0,
                          'MEDIUM':
                              correctAnswerCounts['SEMANTIC']!['MEDIUM'] ?? 0,
                          'HARD': correctAnswerCounts['SEMANTIC']!['HARD'] ?? 0,
                        },
                        verbalQuestionCounts: {
                          'EASY': questionCounts['VERBAL']!['EASY'] ?? 0,
                          'MEDIUM': questionCounts['VERBAL']!['MEDIUM'] ?? 0,
                          'HARD': questionCounts['VERBAL']!['HARD'] ?? 0,
                        },
                        verbalCorrectCounts: {
                          'EASY': correctAnswerCounts['VERBAL']!['EASY'] ?? 0,
                          'MEDIUM':
                              correctAnswerCounts['VERBAL']!['MEDIUM'] ?? 0,
                          'HARD': correctAnswerCounts['VERBAL']!['HARD'] ?? 0,
                        },
                      ).showCompletionDialog(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E5CE6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
