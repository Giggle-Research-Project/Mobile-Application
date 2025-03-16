import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:giggle/core/widgets/custom_appbar.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';
import 'package:giggle/features/future_activity_screens/future_lesson_screen.dart';
import 'dart:ui';

import 'package:giggle/features/lessons/question_generate.dart';

class FutureCourses extends ConsumerStatefulWidget {
  final String userId;

  const FutureCourses({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _FutureCoursesState createState() => _FutureCoursesState();
}

class _FutureCoursesState extends ConsumerState<FutureCourses>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Map<String, List<Map<String, dynamic>>> questionsByOperation = {};
  bool isLoading = true;
  Map<String, String> difficultyLevels = {};

  Map<String, bool> unlockedOperations = {
    'Addition': true,
    'Subtraction': false,
    'Multiplication': false,
    'Division': false,
  };

  Map<String, bool> completedOperations = {
    'Addition': false,
    'Subtraction': false,
    'Multiplication': false,
    'Division': false,
  };

  final List<Map<String, dynamic>> mathOperations = [
    {
      'title': 'Addition',
      'subtitle': 'Learn to add numbers like a math wizard!',
      'icon': Icons.add_circle_outline,
      'color': const Color(0xFF30D158),
    },
    {
      'title': 'Subtraction',
      'subtitle': 'Subtract with speed and precision',
      'icon': Icons.remove_circle_outline,
      'color': const Color(0xFF5E5CE6),
    },
    {
      'title': 'Multiplication',
      'subtitle': 'Multiply your math superpowers',
      'icon': Icons.close,
      'color': const Color(0xFFFF9500),
    },
    {
      'title': 'Division',
      'subtitle': 'Master the art of fair sharing',
      'icon': Icons.pie_chart_outline,
      'color': const Color(0xFFFF3B30),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _fetchDifficultyLevels().then((_) {
      _checkUserProgress();
    });
  }

  String _getDifficultyFromPrediction(double prediction) {
    if (prediction < 40) {
      return "EASY";
    } else if (prediction < 70) {
      return "MEDIUM";
    } else {
      return "HARD";
    }
  }

  Future<void> _fetchDifficultyLevels() async {
    try {
      for (var operation in mathOperations) {
        String operationTitle = operation['title'];

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('operationData')
            .doc(widget.userId)
            .collection('operations')
            .doc(operationTitle)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Get prediction values
          double verbalPrediction = (data['verbalPrediction'] ?? 60).toDouble();
          double semanticPrediction =
              (data['semanticPrediction'] ?? 60).toDouble();
          double proceduralPrediction =
              (data['proceduralPrediction'] ?? 60).toDouble();

          // Set difficulty levels based on predictions
          difficultyLevels['${operationTitle}_Verbal'] =
              _getDifficultyFromPrediction(verbalPrediction);
          difficultyLevels['${operationTitle}_Semantic'] =
              _getDifficultyFromPrediction(semanticPrediction);
          difficultyLevels['${operationTitle}_Procedural'] =
              _getDifficultyFromPrediction(proceduralPrediction);
        } else {
          // Set default difficulty levels if data doesn't exist
          difficultyLevels['${operationTitle}_Verbal'] = "MEDIUM";
          difficultyLevels['${operationTitle}_Semantic'] = "MEDIUM";
          difficultyLevels['${operationTitle}_Procedural'] = "MEDIUM";
        }
      }

      print("Fetched difficulty levels: $difficultyLevels");
    } catch (e) {
      print("Error fetching difficulty levels: $e");
      // Set default difficulty levels in case of error
      for (var operation in mathOperations) {
        String operationTitle = operation['title'];
        difficultyLevels['${operationTitle}_Verbal'] = "MEDIUM";
        difficultyLevels['${operationTitle}_Semantic'] = "MEDIUM";
        difficultyLevels['${operationTitle}_Procedural'] = "MEDIUM";
      }
    }
  }

  Future<void> _checkUserProgress() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Check both paths for each operation
      await _checkOperationCompletion('Addition');

      if (completedOperations['Addition'] == true) {
        unlockedOperations['Subtraction'] = true;
        await _checkOperationCompletion('Subtraction');
      }

      if (completedOperations['Subtraction'] == true) {
        unlockedOperations['Multiplication'] = true;
        await _checkOperationCompletion('Multiplication');
      }

      if (completedOperations['Multiplication'] == true) {
        unlockedOperations['Division'] = true;
        await _checkOperationCompletion('Division');
      }
    } catch (e) {
      print("Error checking user progress: $e");
    }

    _preloadQuestions();
  }

  Future<void> _checkOperationCompletion(String operation) async {
    try {
      bool isVerbalComplete = false;
      bool isSemanticComplete = false;
      bool isProceduralComplete = false;
      bool isVerbalCompleteFuture = false;
      bool isSemanticCompleteFuture = false;
      bool isProceduralCompleteFuture = false;

      // Check both paths for completion status

      // First path (futureActivities)
      try {
        final verbalDoc = await FirebaseFirestore.instance
            .collection('futureActivities')
            .doc(widget.userId)
            .collection(operation)
            .doc('Verbal Dyscalculia')
            .collection('solo_sessions')
            .doc('progress')
            .get();

        if (verbalDoc.exists && verbalDoc.data() != null) {
          isVerbalComplete = verbalDoc.data()!['completed'] == true;
        }

        final semanticDoc = await FirebaseFirestore.instance
            .collection('futureActivities')
            .doc(widget.userId)
            .collection(operation)
            .doc('Semantic Dyscalculia')
            .collection('solo_sessions')
            .doc('progress')
            .get();

        if (semanticDoc.exists && semanticDoc.data() != null) {
          isSemanticComplete = semanticDoc.data()!['completed'] == true;
        }

        final proceduralDoc = await FirebaseFirestore.instance
            .collection('futureActivities')
            .doc(widget.userId)
            .collection(operation)
            .doc('Procedural Dyscalculia')
            .collection('solo_sessions')
            .doc('progress')
            .get();

        if (proceduralDoc.exists && proceduralDoc.data() != null) {
          isProceduralComplete = proceduralDoc.data()!['completed'] == true;
        }
      } catch (e) {
        print("Error checking futureActivities: $e");
      }

      // Second path (functionActivities)
      try {
        final verbalDocFuture = await FirebaseFirestore.instance
            .collection('functionActivities')
            .doc(widget.userId)
            .collection(operation)
            .doc('Verbal Dyscalculia')
            .collection('solo_sessions')
            .doc('progress')
            .get();

        if (verbalDocFuture.exists && verbalDocFuture.data() != null) {
          isVerbalCompleteFuture = verbalDocFuture.data()!['completed'] == true;
        }

        final semanticDocFuture = await FirebaseFirestore.instance
            .collection('functionActivities')
            .doc(widget.userId)
            .collection(operation)
            .doc('Semantic Dyscalculia')
            .collection('solo_sessions')
            .doc('progress')
            .get();

        if (semanticDocFuture.exists && semanticDocFuture.data() != null) {
          isSemanticCompleteFuture =
              semanticDocFuture.data()!['completed'] == true;
        }

        final proceduralDocFuture = await FirebaseFirestore.instance
            .collection('functionActivities')
            .doc(widget.userId)
            .collection(operation)
            .doc('Procedural Dyscalculia')
            .collection('solo_sessions')
            .doc('progress')
            .get();

        if (proceduralDocFuture.exists && proceduralDocFuture.data() != null) {
          isProceduralCompleteFuture =
              proceduralDocFuture.data()!['completed'] == true;
        }
      } catch (e) {
        print("Error checking functionActivities: $e");
      }

      // Consider an operation completed if all dyscalculia types are completed in either path
      bool isVerbalDone = isVerbalCompleteFuture;
      bool isSemanticDone = isSemanticCompleteFuture;
      bool isProceduralDone = isProceduralCompleteFuture;

      // Update unlocked operations based on completion status
      if (operation == 'Addition' &&
          (isVerbalDone && isSemanticDone && isProceduralDone)) {
        unlockedOperations['Subtraction'] = true;
      } else if (operation == 'Subtraction' &&
          (isVerbalDone && isSemanticDone && isProceduralDone)) {
        unlockedOperations['Multiplication'] = true;
      } else if (operation == 'Multiplication' &&
          (isVerbalDone && isSemanticDone && isProceduralDone)) {
        unlockedOperations['Division'] = true;
      }

      // Mark operation as completed if all dyscalculia types are completed
      completedOperations[operation] =
          isVerbalDone && isSemanticDone && isProceduralDone;

      print(
          "Operation $operation completion status: ${completedOperations[operation]}");
      print(
          "Operation $operation unlock status: ${unlockedOperations[operation]}");
    } catch (e) {
      print("Error checking $operation completion: $e");
    }
  }

  void _preloadQuestions() async {
    questionsByOperation.clear();

    for (var operation in mathOperations) {
      String operationName = operation['title'];

      List<Map<String, dynamic>> questions =
          generatePersonalizedQuestions(operationName, difficultyLevels);

      questionsByOperation[operationName] = questions;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (AppUser? user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          body: Stack(
            children: [
              const BackgroundPattern(),
              CustomScrollView(
                slivers: [
                  const CustomAppBar(
                    title: "Math Future Courses",
                    subtitle: "Master one skill at a time",
                  ),
                  if (isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: mathOperations.length,
                          itemBuilder: (context, index) {
                            final operation = mathOperations[index];
                            final String operationTitle = operation['title'];
                            final bool isUnlocked =
                                unlockedOperations[operationTitle] ?? false;
                            final bool isCompleted =
                                completedOperations[operationTitle] ?? false;

                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildCourseCard(
                                operation,
                                isUnlocked: isUnlocked,
                                isCompleted: isCompleted,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Error: ${error.toString()}')),
      ),
    );
  }

  Widget _buildCourseCard(
    Map<String, dynamic> course, {
    required bool isUnlocked,
    required bool isCompleted,
  }) {
    final String title = course['title'];
    final Color baseColor = course['color'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            final operationQuestions = questionsByOperation[title] ?? [];

            Map<String, List<Map<String, dynamic>>> questionsByType = {};
            for (var question in operationQuestions) {
              String type = question['dyscalculia_type'];
              if (!questionsByType.containsKey(type)) {
                questionsByType[type] = [];
              }
              questionsByType[type]?.add(question);
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FutureLessonScreen(
                  difficultyLevels: difficultyLevels,
                  courseName: title,
                  questionsByType: questionsByType,
                  userId: widget.userId,
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? baseColor.withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        course['icon'],
                        color: isUnlocked ? baseColor : Colors.grey.shade400,
                        size: 32,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? const Color(0xFF1D1D1F)
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: isUnlocked
                            ? const Color(0xFF1D1D1F).withOpacity(0.6)
                            : Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${questionsByOperation[title]?.length ?? 0} questions",
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          isCompleted
                              ? 'Completed'
                              : isUnlocked
                                  ? 'Start Learning'
                                  : 'Locked',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? Colors.green
                                : isUnlocked
                                    ? baseColor
                                    : Colors.grey.shade400,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : isUnlocked
                                  ? Icons.arrow_forward
                                  : Icons.lock,
                          color: isCompleted
                              ? Colors.green
                              : isUnlocked
                                  ? baseColor
                                  : Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isUnlocked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Stack(
                      children: [
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.withOpacity(0.2),
                                Colors.grey.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        // Lock icon and text
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Locked",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isCompleted)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Completed",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
