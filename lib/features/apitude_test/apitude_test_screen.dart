import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/data/question_request.dart';
import 'package:giggle/core/enums/enums.dart';
import 'package:giggle/core/models/question_model.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/features/apitude_test/widgets/completion_dailog.dart';
import 'package:giggle/features/apitude_test/widgets/exit_confirmation_dailog.dart';
import 'package:giggle/features/apitude_test/widgets/test_header.dart';
import 'package:giggle/features/apitude_test/widgets/test_navigation_buttons.dart';
import 'package:giggle/features/apitude_test/widgets/timeup_dailog.dart';

class AptitudeTestScreen extends ConsumerStatefulWidget {
  final String userId;
  final String questionCount;
  final TestScreenType testType;
  final List<Question> questions;
  final int timeRemaining;

  const AptitudeTestScreen({
    Key? key,
    required this.userId,
    required this.testType,
    required this.questions,
    required this.timeRemaining,
    required this.questionCount,
  }) : super(key: key);

  @override
  _AptitudeTestScreenState createState() => _AptitudeTestScreenState();
}

class _AptitudeTestScreenState extends ConsumerState<AptitudeTestScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  late List<String?> answers;
  late Timer _timer;
  late PageController _pageController;
  late AnimationController _fadeController;
  bool _showHint = false;
  late int timeRemaining;
  late DateTime testStartTime;

  final Map<String, Map<String, int>> questionCounts = {
    'PROCEDURAL': {'EASY': 0, 'MEDIUM': 0, 'HARD': 0},
    'SEMANTIC': {'EASY': 0, 'MEDIUM': 0, 'HARD': 0},
    'VERBAL': {'EASY': 0, 'MEDIUM': 0, 'HARD': 0},
  };

  final Map<String, Map<String, int>> correctAnswerCounts = {
    'PROCEDURAL': {'EASY': 0, 'MEDIUM': 0, 'HARD': 0},
    'SEMANTIC': {'EASY': 0, 'MEDIUM': 0, 'HARD': 0},
    'VERBAL': {'EASY': 0, 'MEDIUM': 0, 'HARD': 0},
  };

  void _distributeQuestions() {
    for (var category in questionCounts.keys) {
      for (var difficulty in questionCounts[category]!.keys) {
        questionCounts[category]![difficulty] = 0;
        correctAnswerCounts[category]![difficulty] = 0;
      }
    }

    for (int i = 0; i < widget.questions.length; i++) {
      if (i >= questionRequests.length) break;

      String category = questionRequests[i]['dyscalculia_type'] ?? '';
      String difficulty = questionRequests[i]['difficulty'] ?? '';

      if (questionCounts.containsKey(category) &&
          questionCounts[category]!.containsKey(difficulty)) {
        questionCounts[category]![difficulty] =
            (questionCounts[category]![difficulty] ?? 0) + 1;
      }
    }
  }

  int _countCorrectAnswers() {
    int correctCount = 0;

    for (var category in correctAnswerCounts.keys) {
      for (var difficulty in correctAnswerCounts[category]!.keys) {
        correctAnswerCounts[category]![difficulty] = 0;
      }
    }

    for (int i = 0; i < widget.questions.length; i++) {
      if (i >= answers.length || answers[i] == null) continue;

      if (answers[i] == widget.questions[i].correctAnswer) {
        correctCount++;

        if (i < questionRequests.length) {
          String category = questionRequests[i]['dyscalculia_type'] ?? '';
          String difficulty = questionRequests[i]['difficulty'] ?? '';

          if (correctAnswerCounts.containsKey(category) &&
              correctAnswerCounts[category]!.containsKey(difficulty)) {
            correctAnswerCounts[category]![difficulty] =
                (correctAnswerCounts[category]![difficulty] ?? 0) + 1;
          }
        }
      }
    }

    return correctCount;
  }

  Map<String, double> calculateScorePercentages() {
    Map<String, double> scores = {};

    for (var category in questionCounts.keys) {
      int totalQuestions = 0;
      int totalCorrect = 0;

      for (var difficulty in questionCounts[category]!.keys) {
        totalQuestions += questionCounts[category]![difficulty] ?? 0;
        totalCorrect += correctAnswerCounts[category]![difficulty] ?? 0;
      }

      double percentage =
          totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

      scores[category] = percentage;
    }

    return scores;
  }

  void _handleSubmitTest(String userId) {
    int correctAnswers = _countCorrectAnswers();
    Map<String, double> scores = calculateScorePercentages();

    final actualElapsedSeconds =
        DateTime.now().difference(testStartTime).inSeconds;

    CompletionDialog(
      userId: userId,
      testType: widget.testType.toString(),
      answers: answers,
      questions: widget.questions.map((q) => q.toJson()).toList(),
      timeRemaining: timeRemaining,
      correctAnswers: correctAnswers,
      actualElapsedSeconds: actualElapsedSeconds,
      proceduralQuestionCounts: questionCounts['PROCEDURAL']!,
      proceduralCorrectCounts: correctAnswerCounts['PROCEDURAL']!,
      semanticQuestionCounts: questionCounts['SEMANTIC']!,
      semanticCorrectCounts: correctAnswerCounts['SEMANTIC']!,
      verbalQuestionCounts: questionCounts['VERBAL']!,
      verbalCorrectCounts: correctAnswerCounts['VERBAL']!,
    ).showCompletionDialog(context);
  }

  @override
  void initState() {
    super.initState();
    answers = List.filled(widget.questions.length, null);
    timeRemaining = widget.timeRemaining;
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    testStartTime = DateTime.now();
    _distributeQuestions();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          _timer.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  void _showTimeUpDialog() {
    int correctAnswers = _countCorrectAnswers();
    final actualElapsedSeconds =
        DateTime.now().difference(testStartTime).inSeconds;

    TimeUpDialog(
      context: context,
      testType: widget.testType.toString(),
      answers: answers,
      questions: widget.questions.map((q) => q.toJson()).toList(),
      timeRemaining: timeRemaining,
      correctAnswers: correctAnswers,
      actualElapsedSeconds: actualElapsedSeconds,
      proceduralQuestionCounts: questionCounts['PROCEDURAL']!,
      proceduralCorrectCounts: correctAnswerCounts['PROCEDURAL']!,
      semanticQuestionCounts: questionCounts['SEMANTIC']!,
      semanticCorrectCounts: correctAnswerCounts['SEMANTIC']!,
      verbalQuestionCounts: questionCounts['VERBAL']!,
      verbalCorrectCounts: correctAnswerCounts['VERBAL']!,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = timeRemaining ~/ 60;
    int seconds = timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleAnswer(String answer, String userId) {
    setState(() {
      answers[currentQuestionIndex] = answer;
      _showHint = false;

      if (currentQuestionIndex < widget.questions.length - 1) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          setState(() {
            currentQuestionIndex++;
          });
        });
      } else {
        _handleSubmitTest(userId);
      }
    });
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExitConfirmationDialog(
          answers: answers,
          questions: widget.questions.map((q) => q.toJson()).toList(),
          formattedTime: _formattedTime,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      loading: () => const Center(child: CircularProgressIndicator()),
      data: (AppUser? user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }
        return WillPopScope(
          onWillPop: () async {
            _showExitConfirmationDialog(context);
            return false;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F7),
            body: SafeArea(
              child: Column(
                children: [
                  TestHeader(
                    currentQuestionIndex: currentQuestionIndex,
                    questions: widget.questions.map((q) => q.toJson()).toList(),
                    formattedTime: _formattedTime,
                    timeRemaining: timeRemaining,
                    showHint: _showHint,
                    showExitConfirmationDialog: () =>
                        _showExitConfirmationDialog(context),
                    context: context,
                    answers: answers,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.questions.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentQuestionIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildQuestionPage(index, user.uid);
                      },
                    ),
                  ),
                  TestNavigationButtons(
                    userId: user.uid,
                    testType: widget.testType.toString(),
                    currentQuestionIndex: currentQuestionIndex,
                    questions: widget.questions.map((q) => q.toJson()).toList(),
                    answers: answers,
                    pageController: _pageController,
                    timeRemaining: timeRemaining,
                    correctAnswers: _countCorrectAnswers(),
                    actualElapsedSeconds:
                        DateTime.now().difference(testStartTime).inSeconds,
                    questionCounts: questionCounts,
                    correctAnswerCounts: correctAnswerCounts,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionPage(int index, String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.questions[index].question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(),
          const SizedBox(height: 32),
          ...List.generate(
            widget.questions[index].options.length,
            (optionIndex) => _buildEnhancedOptionButton(
              widget.questions[index].options[optionIndex],
              answers[index],
              optionIndex,
              userId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOptionButton(
      String option, String? selectedAnswer, int index, String userId) {
    final isSelected = option == selectedAnswer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF5E5CE6) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleAnswer(option, userId),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5E5CE6)
                            : const Color(0xFFE5E5EA),
                        width: 2,
                      ),
                      color:
                          isSelected ? const Color(0xFF5E5CE6) : Colors.white,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected
                            ? const Color(0xFF5E5CE6)
                            : const Color(0xFF1D1D1F),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX();
  }
}
