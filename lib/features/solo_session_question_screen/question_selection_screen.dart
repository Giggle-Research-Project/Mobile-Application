import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:giggle/features/function%2002/solo_session.dart';
import 'package:giggle/features/function%2003/solo_session.dart';
import 'package:giggle/features/function%2004/solo_verbal_session.dart';
import 'package:giggle/features/lessons/question_generate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class SoloQuestionSelectionScreen extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String courseName;
  final String userId;
  final String dyscalculiaType;

  const SoloQuestionSelectionScreen({
    Key? key,
    required this.courseName,
    required this.difficultyLevels,
    required this.userId,
    required this.dyscalculiaType,
  }) : super(key: key);

  @override
  ConsumerState<SoloQuestionSelectionScreen> createState() =>
      _SoloQuestionSelectionScreenState();
}

class _SoloQuestionSelectionScreenState
    extends ConsumerState<SoloQuestionSelectionScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  // Track completion and lock status
  Map<String, bool> completionStatus = {
    'questionOne': false,
    'questionTwo': false,
    'questionThree': false,
  };

  // Track user answers
  Map<String, String> userAnswers = {
    'questionOne': '',
    'questionTwo': '',
    'questionThree': '',
  };

  // Animation controller
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _loadQuestionStatus();
    _generateQuestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isQuestionLocked(int index) {
    final String questionId = _getQuestionId(index);

    print('Checking lock status for question $index');
    print('Question ID: $questionId');
    print('Completion status: ${completionStatus[questionId]}');

    if (completionStatus[questionId] == true) {
      return true;
    }

    if (index == 0) return false;
    if (index == 1) return !(completionStatus['questionOne'] ?? false);
    if (index == 2) {
      return !(completionStatus['questionTwo'] ?? false) ||
          !(completionStatus['questionOne'] ?? false);
    }
    return true;
  }

  Future<void> _loadQuestionStatus() async {
    try {
      final questionOneSnapshot = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(widget.userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionOne')
          .doc('status')
          .get();

      final questionTwoSnapshot = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(widget.userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionTwo')
          .doc('status')
          .get();

      final questionThreeSnapshot = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(widget.userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionThree')
          .doc('status')
          .get();

      print(
          'Question One Snapshot: ${questionOneSnapshot.exists}, Data: ${questionOneSnapshot.data()}');
      print(
          'Question Two Snapshot: ${questionTwoSnapshot.exists}, Data: ${questionTwoSnapshot.data()}');
      print(
          'Question Three Snapshot: ${questionThreeSnapshot.exists}, Data: ${questionThreeSnapshot.data()}');

      setState(() {
        completionStatus['questionOne'] = questionOneSnapshot.exists &&
            questionOneSnapshot.data()?['completed'] == true;
        completionStatus['questionTwo'] = questionTwoSnapshot.exists &&
            questionTwoSnapshot.data()?['completed'] == true;
        completionStatus['questionThree'] = questionThreeSnapshot.exists &&
            questionThreeSnapshot.data()?['completed'] == true;

        print('Updated Completion Status: $completionStatus');
      });
    } catch (error) {
      print('Error loading question status: $error');
    }
  }

  Future<void> _markQuestionCompleted(String questionId) async {
    try {
      print('Marking question completed: $questionId');
      print('Current user ID: ${widget.userId}');
      print('Current course name: ${widget.courseName}');
      print('Current dyscalculia type: ${widget.dyscalculiaType}');

      // Update local state
      setState(() {
        completionStatus[questionId] = true;
        print(
            'Local completion status updated: ${completionStatus[questionId]}');
      });

      // Create the progress document
      await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(widget.userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'completed': (completionStatus['questionOne'] ?? false) &&
            (completionStatus['questionTwo'] ?? false) &&
            (completionStatus['questionThree'] ?? false),
      }, SetOptions(merge: true));

      // Update specific question status
      DocumentReference questionStatusRef = FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(widget.userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection(questionId)
          .doc('status');

      await questionStatusRef.set({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'userAnswer': userAnswers[questionId],
      });

      print('Question status document created successfully');
      print('Question status document ID: ${questionStatusRef.path}');

      // Verify the document was created correctly
      DocumentSnapshot verifySnapshot = await questionStatusRef.get();
      print('Verification snapshot exists: ${verifySnapshot.exists}');
      print('Verification snapshot data: ${verifySnapshot.data()}');

      // If all questions are completed, mark the whole session as completed
      if ((completionStatus['questionOne'] ?? false) &&
          (completionStatus['questionTwo'] ?? false) &&
          (completionStatus['questionThree'] ?? false)) {
        await FirebaseFirestore.instance
            .collection('functionActivities')
            .doc(widget.userId)
            .collection(widget.courseName)
            .doc(widget.dyscalculiaType)
            .collection('solo_sessions')
            .doc('progress')
            .set({
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (error) {
      print('Error marking question completed: $error');
    }
  }

  void _generateQuestions() {
    setState(() {
      isLoading = true;
    });

    String type = widget.dyscalculiaType.split(' ')[0].toUpperCase();
    List<Map<String, dynamic>> generatedQuestions = [];

    while (generatedQuestions.length < 3) {
      List<Map<String, dynamic>> batch = generatePersonalizedQuestions(
        widget.courseName,
        widget.difficultyLevels,
      );

      List<Map<String, dynamic>> filteredBatch =
          batch.where((q) => q['dyscalculia_type'] == type).toList();

      for (var question in filteredBatch) {
        print('Complete question object: $question');

        generatedQuestions.add(question);

        if (generatedQuestions.length >= 3) break;
      }
    }

    questions = generatedQuestions.sublist(0, 3);

    setState(() {
      isLoading = false;
    });
  }

  bool _isQuestionCompleted(int index) {
    switch (index) {
      case 0:
        return completionStatus['questionOne'] ?? false;
      case 1:
        return completionStatus['questionTwo'] ?? false;
      case 2:
        return completionStatus['questionThree'] ?? false;
      default:
        return false;
    }
  }

  String _getQuestionId(int index) {
    switch (index) {
      case 0:
        return 'questionOne';
      case 1:
        return 'questionTwo';
      case 2:
        return 'questionThree';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.dyscalculiaType);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Stack(
        children: [
          const BackgroundPattern(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(
                                questions.length,
                                (index) =>
                                    _buildQuestionCard(questions[index], index),
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
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final bool isLocked = _isQuestionLocked(index);
    final bool isCompleted = _isQuestionCompleted(index);

    final Color cardColor =
        isLocked ? Colors.white.withOpacity(0.6) : Colors.white;

    final Color accentColor = isCompleted
        ? Colors.green
        : isLocked
            ? Colors.grey
            : const Color(0xFFFF6D00);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isLocked
              ? Colors.grey.withOpacity(0.1)
              : accentColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked
              ? () {
                  String lockMessage = isCompleted
                      ? 'You have already completed this challenge.'
                      : 'Complete the previous ${index == 1 ? 'challenge' : 'challenges'} to unlock this challenge';

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lockMessage,
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
                  if (widget.dyscalculiaType == 'Semantic Dyscalculia') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SemanticSoloSessionScreen(
                          index: index.toString(),
                          courseName: widget.courseName,
                          questions: [question],
                        ),
                      ),
                    );
                  } else if (widget.dyscalculiaType == 'Verbal Dyscalculia') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SoloVerbalSessionScreen(
                          courseName: widget.courseName,
                          questions: [question],
                          dyscalculiaType: widget.dyscalculiaType,
                          index: index.toString(),
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProceduralSoloSession(
                          courseName: widget.courseName,
                          questions: [question],
                          dyscalculiaType: widget.dyscalculiaType,
                          index: index.toString(),
                        ),
                      ),
                    );
                  }
                },
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background gradient for visual interest (subtle)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Opacity(
                    opacity: isLocked ? 0.05 : 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor,
                            accentColor.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with icon and action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side with challenge number
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                accentColor.withOpacity(isLocked ? 0.05 : 0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: isCompleted
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: accentColor,
                                  size: 32,
                                )
                              : isLocked
                                  ? Icon(
                                      Icons.lock,
                                      color: accentColor.withOpacity(0.5),
                                      size: 32,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                      ),
                                    ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Challenge title
                    Text(
                      isCompleted
                          ? 'Completed Challenge ${index + 1}'
                          : isLocked
                              ? 'Locked Challenge'
                              : 'Challenge ${index + 1}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLocked && !isCompleted
                            ? const Color(0xFF1D1D1F).withOpacity(0.5)
                            : const Color(0xFF1D1D1F),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Challenge description
                    Text(
                      isCompleted
                          ? 'You have successfully completed this challenge.'
                          : isLocked
                              ? 'Complete the previous ${index == 1 ? 'challenge' : 'challenges'} to unlock this challenge.'
                              : 'Tap to start the challenge and test your skills.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isLocked && !isCompleted
                            ? const Color(0xFF1D1D1F).withOpacity(0.3)
                            : const Color(0xFF1D1D1F).withOpacity(0.7),
                      ),
                    ),

                    // Show completion message if completed
                    if (isCompleted) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Great job! Challenge completed. It is now locked.',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Add a "Start Challenge" button for unlocked, uncompleted challenges
                    if (!isLocked && !isCompleted) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            if (widget.dyscalculiaType ==
                                'Semantic Dyscalculia') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SemanticSoloSessionScreen(
                                    index: index.toString(),
                                    courseName: widget.courseName,
                                    questions: [question],
                                  ),
                                ),
                              );
                            } else if (widget.dyscalculiaType ==
                                'Verbal Dyscalculia') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SoloVerbalSessionScreen(
                                    courseName: widget.courseName,
                                    questions: [question],
                                    dyscalculiaType: widget.dyscalculiaType,
                                    index: index.toString(),
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProceduralSoloSession(
                                    courseName: widget.courseName,
                                    questions: [question],
                                    dyscalculiaType: widget.dyscalculiaType,
                                    index: index.toString(),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Start Challenge',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
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
                            '${widget.courseName} Challenges',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Progress through challenges one by one',
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
