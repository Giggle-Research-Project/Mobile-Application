import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:giggle/core/data/question_request.dart';
import 'package:giggle/core/data/questions_english.dart';
import 'package:giggle/core/enums/enums.dart';
import 'package:giggle/core/models/question_model.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/services/predict_f1_performance.service.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:giggle/core/widgets/custom_appbar.dart';
import 'package:giggle/features/apitude_test/apitude_test_screen.dart';
import 'package:giggle/features/index.dart';
import 'package:giggle/features/performance_result/performance_result_screen.dart';
import 'package:giggle/features/skill_assessment/services/question_generator.dart';
import 'package:giggle/features/skill_assessment/widgets/index.dart';

class TestSelectionScreen extends ConsumerStatefulWidget {
  final String userId;

  const TestSelectionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<TestSelectionScreen> createState() =>
      _TestSelectionScreenState();
}

class _TestSelectionScreenState extends ConsumerState<TestSelectionScreen>
    with SingleTickerProviderStateMixin {
  final QuestionGenerator _questionGenerator = QuestionGenerator();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool _skillAssessmentCompleted = false;
  bool _parentQuestionnaireCompleted = false;
  bool _isCheckingStatus = false;

  List<Question> get _parentQuestions =>
      parentQuestions.map((map) => Question.fromJson(map)).toList();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkCompletionStatus();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  Future<void> _checkCompletionStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      final skillAssessmentDoc = await firestore
          .collection('skill_assessment')
          .doc(widget.userId)
          .collection(TestScreenType.skillAssessment.toString())
          .doc(TestScreenType.skillAssessment.toString())
          .get();

      final parentQuestionnaireDoc = await firestore
          .collection('skill_assessment')
          .doc(widget.userId)
          .collection(TestScreenType.parentQuestionnaire.toString())
          .doc(TestScreenType.parentQuestionnaire.toString())
          .get();

      if (mounted) {
        setState(() {
          _skillAssessmentCompleted = skillAssessmentDoc.exists &&
              skillAssessmentDoc.data()?['completed'] == true;

          _parentQuestionnaireCompleted = parentQuestionnaireDoc.exists &&
              parentQuestionnaireDoc.data()?['completed'] == true;

          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      print('Error checking completion status: $e');
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToTest(BuildContext context, TestScreenType testType,
      String questionCount, [List<Map<String, dynamic>>? questions]) async {
    if (_isCheckingStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait, checking test status...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if ((testType == TestScreenType.skillAssessment &&
            _skillAssessmentCompleted) ||
        (testType == TestScreenType.parentQuestionnaire &&
            _parentQuestionnaireCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This assessment has already been completed.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (testType == TestScreenType.skillAssessment) {
      await _handleSkillAssessment(context, questionCount);
    } else if (testType == TestScreenType.parentQuestionnaire && questions != null) {
      _handleParentQuestionnaire(context, questionCount, questions);
    }
  }

  Future<void> _handleSkillAssessment(
      BuildContext context, String questionCount) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: const AnimatedLoadingDialog(),
      ),
    );

    try {
      final questionsFuture = _questionGenerator.generateQuestions(context);
      final timerFuture = Future.delayed(const Duration(seconds: 3));

      final rawQuestions = await questionsFuture;
      await timerFuture;

      if (!mounted) return;
      Navigator.of(context).pop();

      if (rawQuestions.isNotEmpty) {
        _launchTestScreen(context, TestScreenType.skillAssessment, rawQuestions,
            1800, questionCount);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (BuildContext errorContext) =>
            ErrorDialog(error: e.toString()),
      );
    }
  }

  void _handleParentQuestionnaire(BuildContext context, String questionCount,
      List<Map<String, dynamic>> questions) {
    _launchTestScreen(context, TestScreenType.parentQuestionnaire,
        questions.map((q) => Question.fromJson(q)).toList(), 1200, questionCount);
  }

  void _launchTestScreen(BuildContext context, TestScreenType testType,
      List<Question> questions, int timeRemaining, String questionCount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AptitudeTestScreen(
          testType: testType,
          questions: questions,
          timeRemaining: timeRemaining,
          questionCount: questionCount,
          userId: widget.userId,
        ),
      ),
    ).then((_) {
      _checkCompletionStatus();
    });
  }

  Future<void> _navigateToPerformanceScreen() async {
    try {
      setState(() {
        _isCheckingStatus = true;
      });

      final firestore = FirebaseFirestore.instance;

      // Get skill assessment data
      final skillAssessmentDoc = await firestore
          .collection('skill_assessment')
          .doc(widget.userId)
          .collection(TestScreenType.skillAssessment.toString())
          .doc(TestScreenType.skillAssessment.toString())
          .get();

      // Get parent questionnaire data
      final parentQuestionnaireDoc = await firestore
          .collection('skill_assessment')
          .doc(widget.userId)
          .collection(TestScreenType.parentQuestionnaire.toString())
          .doc(TestScreenType.parentQuestionnaire.toString())
          .get();

      if (!skillAssessmentDoc.exists || !parentQuestionnaireDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Assessment data not complete. Please complete both assessments.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isCheckingStatus = false;
        });
        return;
      }

      final skillData = skillAssessmentDoc.data()!;
      final parentData = parentQuestionnaireDoc.data()!;

      // Get correct answers and total questions
      final int skillCorrect = skillData['correctAnswers'] ?? 0;
      final int parentCorrect = parentData['correctAnswers'] ?? 0;
      final int skillTotal = skillData['totalQuestions'] ?? 0;
      final int parentTotal = parentData['totalQuestions'] ?? 0;

      // Parse time spent
      final String skillTimeSpent = skillData['timeSpent'] ?? "0 min 0 sec";
      final String parentTimeSpent = parentData['timeSpent'] ?? "0 min 0 sec";
      final RegExp timePattern = RegExp(r'(\d+) min (\d+) sec');
      final skillTimeMatch = timePattern.firstMatch(skillTimeSpent);
      final parentTimeMatch = timePattern.firstMatch(parentTimeSpent);

      // Calculate combined score
      final double skillScore = (skillData['overallScore'] is int) 
          ? (skillData['overallScore'] as int).toDouble() 
          : (skillData['overallScore'] as double? ?? 0.0);

      final double parentScore = (parentData['overallScore'] is int) 
          ? (parentData['overallScore'] as int).toDouble() 
          : (parentData['overallScore'] as double? ?? 0.0);

      final double combinedScore = (skillScore + parentScore) / 2;

      // Call the predict function with the variables now defined
      final String overallScore = await predictF1Performance(
          skillCorrect, skillTimeMatch, parentCorrect, parentTimeMatch);

      // Calculate combined time spent
      int totalMinutes = 0;
      int totalSeconds = 0;

      if (skillTimeMatch != null) {
        totalMinutes += int.parse(skillTimeMatch.group(1) ?? '0');
        totalSeconds += int.parse(skillTimeMatch.group(2) ?? '0');
      }

      if (parentTimeMatch != null) {
        totalMinutes += int.parse(parentTimeMatch.group(1) ?? '0');
        totalSeconds += int.parse(parentTimeMatch.group(2) ?? '0');
      }

      // Convert excess seconds to minutes
      totalMinutes += totalSeconds ~/ 60;
      totalSeconds = totalSeconds % 60;

      final String combinedTimeSpent = "$totalMinutes min $totalSeconds sec";

      // Combine correct answers and total questions
      final int combinedCorrectAnswers = skillCorrect + parentCorrect;
      final int combinedTotalQuestions = skillTotal + parentTotal;

      // Combine category levels (calculate averages)
      Map<String, double> categoryLevels = {
        'procedural': _calculateCategoryAverage(
            skillData,
            parentData,
            'procedural',
            'proceduralCorrectCounts',
            'proceduralQuestionCounts'),
        'semantic': _calculateCategoryAverage(skillData, parentData, 'semantic',
            'semanticCorrectCounts', 'semanticQuestionCounts'),
        'verbal': _calculateCategoryAverage(skillData, parentData, 'verbal',
            'verbalCorrectCounts', 'verbalQuestionCounts'),
      };

      // Combine all counts for detailed analysis
      final Map<String, int> proceduralQuestionCounts = _combineCounts(
          skillData['proceduralQuestionCounts'] as Map<String, dynamic>?,
          parentData['proceduralQuestionCounts'] as Map<String, dynamic>?);

      final Map<String, int> proceduralCorrectCounts = _combineCounts(
          skillData['proceduralCorrectCounts'] as Map<String, dynamic>?,
          parentData['proceduralCorrectCounts'] as Map<String, dynamic>?);

      final Map<String, int> semanticQuestionCounts = _combineCounts(
          skillData['semanticQuestionCounts'] as Map<String, dynamic>?,
          parentData['semanticQuestionCounts'] as Map<String, dynamic>?);

      final Map<String, int> semanticCorrectCounts = _combineCounts(
          skillData['semanticCorrectCounts'] as Map<String, dynamic>?,
          parentData['semanticCorrectCounts'] as Map<String, dynamic>?);

      final Map<String, int> verbalQuestionCounts = _combineCounts(
          skillData['verbalQuestionCounts'] as Map<String, dynamic>?,
          parentData['verbalQuestionCounts'] as Map<String, dynamic>?);

      final Map<String, int> verbalCorrectCounts = _combineCounts(
          skillData['verbalCorrectCounts'] as Map<String, dynamic>?,
          parentData['verbalCorrectCounts'] as Map<String, dynamic>?);

      // Generate placeholder questions
      List<Map<String, dynamic>> allQuestions = _generatePlaceholderQuestions(
          proceduralQuestionCounts,
          proceduralCorrectCounts,
          semanticQuestionCounts,
          semanticCorrectCounts,
          verbalQuestionCounts,
          verbalCorrectCounts);

      setState(() {
        _isCheckingStatus = false;
      });

      // Navigate to the performance screen with the combined data
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PerformanceResultScreen(
              score: double.tryParse(overallScore) ?? combinedScore,
              timeSpent: skillTimeSpent,
              skillCorrectAnswers: skillCorrect,
              skillTotalQuestions: skillTotal,
              correctAnswers: combinedCorrectAnswers,
              totalQuestions: combinedTotalQuestions,
              categoryLevels: categoryLevels,
              allQuestions: allQuestions,
              proceduralQuestionCounts: proceduralQuestionCounts,
              proceduralCorrectCounts: proceduralCorrectCounts,
              semanticQuestionCounts: semanticQuestionCounts,
              semanticCorrectCounts: semanticCorrectCounts,
              verbalQuestionCounts: verbalQuestionCounts,
              verbalCorrectCounts: verbalCorrectCounts,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to performance screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading performance data: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

// Helper method to calculate category averages
  double _calculateCategoryAverage(
      Map<String, dynamic> skillData,
      Map<String, dynamic> parentData,
      String category,
      String correctCountsKey,
      String questionCountsKey) {
    // Get the maps from both documents
    final Map<String, dynamic>? skillCorrectCounts =
        skillData[correctCountsKey] as Map<String, dynamic>?;
    final Map<String, dynamic>? skillQuestionCounts =
        skillData[questionCountsKey] as Map<String, dynamic>?;
    final Map<String, dynamic>? parentCorrectCounts =
        parentData[correctCountsKey] as Map<String, dynamic>?;
    final Map<String, dynamic>? parentQuestionCounts =
        parentData[questionCountsKey] as Map<String, dynamic>?;

    if (skillCorrectCounts == null ||
        skillQuestionCounts == null ||
        parentCorrectCounts == null ||
        parentQuestionCounts == null) {
      return 0.0;
    }

    // Calculate total correct and total questions across both assessments
    int totalCorrect = 0;
    int totalQuestions = 0;

    // Process skill assessment data
    skillCorrectCounts.forEach((difficulty, count) {
      totalCorrect += (count as num).toInt();
    });

    skillQuestionCounts.forEach((difficulty, count) {
      totalQuestions += (count as num).toInt();
    });

    // Process parent questionnaire data
    parentCorrectCounts.forEach((difficulty, count) {
      totalCorrect += (count as num).toInt();
    });

    parentQuestionCounts.forEach((difficulty, count) {
      totalQuestions += (count as num).toInt();
    });

    // Calculate and return percentage
    return totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;
  }

// Helper method to combine count maps
  Map<String, int> _combineCounts(
      Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    final result = <String, int>{};

    // Process the first map
    if (map1 != null) {
      map1.forEach((key, value) {
        result[key] = (value as num).toInt();
      });
    }

    // Add counts from the second map
    if (map2 != null) {
      map2.forEach((key, value) {
        final int count = (value as num).toInt();
        if (result.containsKey(key)) {
          result[key] = result[key]! + count;
        } else {
          result[key] = count;
        }
      });
    }

    return result;
  }

// Helper method to generate placeholder questions for the results screen
  List<Map<String, dynamic>> _generatePlaceholderQuestions(
      Map<String, int> proceduralQuestionCounts,
      Map<String, int> proceduralCorrectCounts,
      Map<String, int> semanticQuestionCounts,
      Map<String, int> semanticCorrectCounts,
      Map<String, int> verbalQuestionCounts,
      Map<String, int> verbalCorrectCounts) {
    final List<Map<String, dynamic>> placeholders = [];

    // For each category and difficulty, create placeholder questions
    ['PROCEDURAL', 'SEMANTIC', 'VERBAL'].forEach((type) {
      ['EASY', 'MEDIUM', 'HARD'].forEach((difficulty) {
        // Get the counts
        int questionCount = 0;
        int correctCount = 0;

        if (type == 'PROCEDURAL') {
          questionCount = proceduralQuestionCounts[difficulty] ?? 0;
          correctCount = proceduralCorrectCounts[difficulty] ?? 0;
        } else if (type == 'SEMANTIC') {
          questionCount = semanticQuestionCounts[difficulty] ?? 0;
          correctCount = semanticCorrectCounts[difficulty] ?? 0;
        } else if (type == 'VERBAL') {
          questionCount = verbalQuestionCounts[difficulty] ?? 0;
          correctCount = verbalCorrectCounts[difficulty] ?? 0;
        }

        // Create placeholder questions
        for (int i = 0; i < questionCount; i++) {
          placeholders.add({
            'dyscalculia_type': type,
            'difficulty': difficulty,
            'isCorrect': i < correctCount,
            'question_text': 'Question $i for $type-$difficulty',
            'answer': 'Answer $i',
          });
        }
      });
    });

    return placeholders;
  }

  void _navigateToPersonalizedCourses() {
    if (!_skillAssessmentCompleted || !_parentQuestionnaireCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete both assessments first.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isCheckingStatus = true;
    });

    // Get the assessment data asynchronously
    final firestore = FirebaseFirestore.instance;

    firestore
        .collection('skill_assessment')
        .doc(widget.userId)
        .collection(TestScreenType.skillAssessment.toString())
        .doc(TestScreenType.skillAssessment.toString())
        .get()
        .then((skillDoc) {
      firestore
          .collection('skill_assessment')
          .doc(widget.userId)
          .collection(TestScreenType.parentQuestionnaire.toString())
          .doc(TestScreenType.parentQuestionnaire.toString())
          .get()
          .then((parentDoc) {
        if (skillDoc.exists && parentDoc.exists) {
          final skillData = skillDoc.data()!;
          final parentData = parentDoc.data()!;

          // Calculate performance for each category
          Map<String, double> categoryPerformance = {
            'procedural': _calculateCategoryAverage(
                skillData,
                parentData,
                'procedural',
                'proceduralCorrectCounts',
                'proceduralQuestionCounts'),
            'semantic': _calculateCategoryAverage(skillData, parentData,
                'semantic', 'semanticCorrectCounts', 'semanticQuestionCounts'),
            'verbal': _calculateCategoryAverage(skillData, parentData, 'verbal',
                'verbalCorrectCounts', 'verbalQuestionCounts'),
          };

          // Determine appropriate difficulty levels based on performance
          Map<String, String> difficultyLevels =
              _determineDifficultyLevels(categoryPerformance);

          // Navigate to the personalized courses screen with calculated difficulty levels
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalizedCourses(
                  difficultyLevels: difficultyLevels,
                ),
              ),
            );
          }
        } else {
          _showAssessmentDataError();
        }

        setState(() {
          _isCheckingStatus = false;
        });
      }).catchError((error) {
        print('Error getting parent questionnaire data: $error');
        _showAssessmentDataError();
        setState(() {
          _isCheckingStatus = false;
        });
      });
    }).catchError((error) {
      print('Error getting skill assessment data: $error');
      _showAssessmentDataError();
      setState(() {
        _isCheckingStatus = false;
      });
    });
  }

// Calculate appropriate difficulty level based on performance
  Map<String, String> _determineDifficultyLevels(
      Map<String, double> categoryPerformance) {
    Map<String, String> difficultyLevels = {};

    // For each category, determine the appropriate difficulty
    categoryPerformance.forEach((category, performance) {
      if (performance < 40) {
        // If performance is poor, assign easy difficulty
        difficultyLevels[category] = 'EASY';
      } else if (performance < 75) {
        // If performance is moderate, assign medium difficulty
        difficultyLevels[category] = 'MEDIUM';
      } else {
        // If performance is good, assign hard difficulty
        difficultyLevels[category] = 'HARD';
      }
    });

    return difficultyLevels;
  }

  void _showAssessmentDataError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error retrieving assessment data. Please try again.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

// Helper method for default navigation
  void _navigateWithDefaultDifficulties() {
    Map<String, String> defaultDifficulties = {
      'procedural': 'EASY',
      'verbal': 'HARD',
      'semantic': 'EASY'
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PersonalizedCourses(
          difficultyLevels: defaultDifficulties,
        ),
      ),
    );
  }

  void _showAssessmentGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const AssessmentGuideSheet(),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;
    final bool bothAssessmentsCompleted =
        _skillAssessmentCompleted && _parentQuestionnaireCompleted;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          const BackgroundPattern(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const CustomAppBar(
                  title: 'Skill Assessment',
                  subtitle: 'Choose your assessment path'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        if (bothAssessmentsCompleted)
                          CompletedAssessmentsNavigationCard(
                            themeColor: themeColor,
                            onViewPerformance: _navigateToPerformanceScreen,
                            onViewCourses: _navigateToPersonalizedCourses,
                          ),
                        const SizedBox(height: 20),
                        AssessmentGuide(
                          themeColor: themeColor,
                          onPressed: _showAssessmentGuide,
                        ),
                        const SizedBox(height: 25),
                        FeaturedAssessmentCard(
                          themeColor: themeColor,
                          duration: '30 mins',
                          questions: '${questionRequests.length} questions',
                          isCompleted: _skillAssessmentCompleted,
                          onTap: () => _navigateToTest(
                              context,
                              TestScreenType.skillAssessment,
                              questionRequests.length.toString()),
                        ),
                        const SizedBox(height: 32),
                        OtherAssessmentsSection(
                          themeColor: themeColor,
                          isParentQuestionnaireCompleted:
                              _parentQuestionnaireCompleted,
                          onTap: (testType, questions) => _navigateToTest(
                            context,
                            testType,
                            parentQuestions.length.toString(),
                            questions,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showHelpDialog,
        backgroundColor: themeColor,
        child: const Icon(
          Icons.help_outline,
          color: Colors.white,
        ),
      ),
    );
  }
}
