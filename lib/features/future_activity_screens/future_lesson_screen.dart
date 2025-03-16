import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giggle/features/future_activity_screens/question_selection_screen.dart';

class FutureLessonScreen extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String courseName;
  final Map<String, List<Map<String, dynamic>>>? questionsByType;
  final String userId;

  const FutureLessonScreen({
    Key? key,
    required this.difficultyLevels,
    required this.courseName,
    this.questionsByType,
    required this.userId,
  }) : super(key: key);

  @override
  _LessonsScreenState createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<FutureLessonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Track completion status
  bool semanticCompleted = false;
  bool proceduralCompleted = false;
  bool verbalCompleted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Check completion status from Firestore
    _checkCompletionStatus(widget.courseName);
  }

  Future<void> _checkCompletionStatus(String operation) async {
    setState(() {
      isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final userId = authState.value?.uid;

      if (userId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Check Semantic completion
      final semanticDoc = await FirebaseFirestore.instance
          .collection('futureActivities')
          .doc(userId)
          .collection(operation)
          .doc('Semantic Dyscalculia')
          .collection('solo_sessions')
          .doc('progress')
          .get();

      // Check Procedural completion
      final proceduralDoc = await FirebaseFirestore.instance
          .collection('futureActivities')
          .doc(userId)
          .collection(operation)
          .doc('Procedural Dyscalculia')
          .collection('solo_sessions')
          .doc('progress')
          .get();

      // Check Verbal completion
      final verbalDoc = await FirebaseFirestore.instance
          .collection('futureActivities')
          .doc(userId)
          .collection(operation)
          .doc('Verbal Dyscalculia')
          .collection('solo_sessions')
          .doc('progress')
          .get();

      setState(() {
        semanticCompleted =
            semanticDoc.exists && semanticDoc.data()?['completed'] == true;
        proceduralCompleted =
            proceduralDoc.exists && proceduralDoc.data()?['completed'] == true;
        verbalCompleted =
            verbalDoc.exists && verbalDoc.data()?['completed'] == true;
        isLoading = false;
      });
    } catch (error) {
      print('Error checking completion status: $error');
      setState(() {
        isLoading = false;
      });
    }
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

        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop();
            return false;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF2F4F8),
            body: Stack(
              children: [
                const BackgroundPattern(),
                isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildSliverAppBar(context),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    _buildLearningPaths(),
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

  Widget _buildLearningPaths() {
    final paths = [
      {
        'title': 'Semantic Dyscalculia',
        'description':
            'Understand the true meaning of numbers and mathematical concepts through visual and conceptual learning.',
        'icon': Icons.psychology,
        'color': const Color(0xFF30D158),
        'type': 'Semantic Dyscalculia',
        'isLocked': false,
        'isCompleted': semanticCompleted,
      },
      {
        'title': 'Procedural Dyscalculia',
        'description':
            'Learn step-by-step problem-solving techniques and mathematical procedures with guided support.',
        'icon': Icons.account_tree,
        'color': const Color(0xFF5E5CE6),
        'type': 'Procedural Dyscalculia',
        'isLocked': semanticCompleted ? false : true,
        'isCompleted': proceduralCompleted,
      },
      {
        'title': 'Verbal Dyscalculia',
        'description':
            'Improve mathematical language comprehension and communication skills through interactive lessons.',
        'icon': Icons.record_voice_over,
        'color': const Color(0xFFFF9F0A),
        'type': 'Verbal Dyscalculia',
        'isLocked': proceduralCompleted ? false : true,
        'isCompleted': verbalCompleted,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Learning Path',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 15),
        ...paths.map((path) {
          // Get questions for this dyscalculia type
          final typeQuestions = widget.questionsByType?[path['type']] ?? [];

          return _buildPathCard(
            path,
            questionCount: typeQuestions.length,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPathCard(
    Map<String, dynamic> path, {
    int questionCount = 0,
  }) {
    final bool isLocked = path['isLocked'] as bool;
    final bool isCompleted = path['isCompleted'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isLocked ? Colors.white.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          onTap: isLocked
              ? () {
                  // Show locked message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Complete the previous path to unlock ${path['title']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              : () {
                  final String dyscalculiaType = path['type'] as String;
                  final String dataKey =
                      dyscalculiaType.split(' ')[0].toUpperCase();

                  final List<Map<String, dynamic>> typeQuestions = widget
                          .questionsByType?[dataKey]
                          ?.cast<Map<String, dynamic>>() ??
                      [];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionSelectionScreen(
                        difficultyLevels: widget.difficultyLevels,
                        courseName: widget.courseName,
                        dyscalculiaType: path['type'] as String,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: path['color'].withOpacity(isLocked ? 0.05 : 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        path['icon'],
                        color: isLocked
                            ? path['color'].withOpacity(0.5)
                            : path['color'],
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            path['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? const Color(0xFF1D1D1F).withOpacity(0.5)
                                  : const Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            path['description'],
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isLocked
                                  ? const Color(0xFF1D1D1F).withOpacity(0.3)
                                  : const Color(0xFF1D1D1F).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isLocked ? Icons.lock : Icons.arrow_forward_ios,
                      color: isLocked
                          ? const Color(0xFF1D1D1F).withOpacity(0.2)
                          : const Color(0xFF1D1D1F).withOpacity(0.3),
                      size: 20,
                    ),
                  ],
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Completed',
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

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.courseName} Future Lessons',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Complete each path in sequence',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
