import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';
import 'dart:ui';

import 'package:giggle/features/lessons/lessons.dart';
import 'package:giggle/features/lessons/question_generate.dart';

class PersonalizedCourses extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;

  const PersonalizedCourses({
    Key? key,
    required this.difficultyLevels,
  }) : super(key: key);

  @override
  _PersonalizedCoursesState createState() => _PersonalizedCoursesState();
}

class _PersonalizedCoursesState extends ConsumerState<PersonalizedCourses>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Map<String, List<Map<String, dynamic>>> questionsByOperation = {};
  bool isLoading = true;

  Map<String, bool> unlockedOperations = {
    'Addition': true,
    'Subtraction': true,
    'Multiplication': true,
    'Division': true,
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

    _checkUserProgress();
  }

  Future<void> _checkUserProgress() async {
    setState(() {
      isLoading = true;
    });

    try {
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
    final user = ref.read(authProvider).value;
    if (user == null) return;
    print(operation);

    try {
      bool isVerbalComplete = false;
      bool isSemanticComplete = false;
      bool isProceduralComplete = false;

      final verbalDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(user.uid)
          .collection(operation)
          .doc('Verbal Dyscalculia')
          .collection('solo_sessions')
          .doc('progress')
          .get();

      if (verbalDoc.exists && verbalDoc.data() != null) {
        isVerbalComplete = verbalDoc.data()!['completed'] == true;
      }

      final semanticDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(user.uid)
          .collection(operation)
          .doc('Semantic Dyscalculia')
          .collection('solo_sessions')
          .doc('progress')
          .get();

      if (semanticDoc.exists && semanticDoc.data() != null) {
        isSemanticComplete = semanticDoc.data()!['completed'] == true;
      }

      final proceduralDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(user.uid)
          .collection(operation)
          .doc('Procedural Dyscalculia')
          .collection('solo_sessions')
          .doc('progress')
          .get();

      if (proceduralDoc.exists && proceduralDoc.data() != null) {
        isProceduralComplete = proceduralDoc.data()!['completed'] == true;
      }

      completedOperations[operation] =
          isVerbalComplete && isSemanticComplete && isProceduralComplete;
    } catch (e) {
      print("Error checking $operation completion: $e");
    }
  }

  void _preloadQuestions() async {
    if (widget.difficultyLevels == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    questionsByOperation.clear();

    for (var operation in mathOperations) {
      String operationName = operation['title'];

      List<Map<String, dynamic>> questions =
          generatePersonalizedQuestions(operationName, widget.difficultyLevels);

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
              SafeArea(
                child: Column(
                  children: [
                    const SubPageHeader(
                      title: "Math Courses",
                      desc: "Master one skill at a time",
                    ),
                    if (isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 0.75, // Changed from 0.85 to 0.75 to make cards taller
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
          onTap: isUnlocked && !isCompleted
              ? () {
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
                      builder: (context) => LessonsScreen(
                        difficultyLevels: widget.difficultyLevels,
                        courseName: title,
                        questionsByType: questionsByType,
                      ),
                    ),
                  );
                }
              : null,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16), // Reduced from 20 to 16
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), // Reduced from 12 to 10
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? baseColor.withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        course['icon'],
                        color: isUnlocked ? baseColor : Colors.grey.shade400,
                        size: 28, // Reduced from 32 to 28
                      ),
                    ),
                    const Spacer(flex: 1),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18, // Reduced from 20 to 18
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? const Color(0xFF1D1D1F)
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: isUnlocked
                            ? const Color(0xFF1D1D1F).withOpacity(0.6)
                            : Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${questionsByOperation[title]?.length ?? 0} questions",
                      style: TextStyle(
                        fontSize: 11,
                        color: isUnlocked
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                    const Spacer(flex: 1),
                    // Added more space at the bottom
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isCompleted
                                  ? 'Completed'
                                  : isUnlocked
                                      ? 'Start Learning'
                                      : 'Locked',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? Colors.green
                                    : isUnlocked
                                        ? baseColor
                                        : Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                            size: 18,
                          ),
                        ],
                      ),
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
                              vertical: 10,
                              horizontal: 18,
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
                                  size: 22,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Locked",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          size: 14,
                        ),
                        SizedBox(width: 3),
                        Text(
                          "Completed",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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