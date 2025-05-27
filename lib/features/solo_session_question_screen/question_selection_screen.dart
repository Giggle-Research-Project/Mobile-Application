import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:giggle/features/function%2002/solo_session.dart';
import 'package:giggle/features/function%2003/solo_session.dart';
import 'package:giggle/features/function%2004/solo_verbal_session.dart';
import 'package:giggle/features/lessons/question_generate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:giggle/features/solo_session_question_screen/challenge_questions_screen.dart';

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
  List<List<Map<String, dynamic>>> challengeQuestions = [[], [], []];
  bool isLoading = true;
  bool isRefreshing = false;

  // Track completion status
  Map<String, bool> completionStatus = {
    'questionOne': false,
    'questionTwo': false,
    'questionThree': false,
  };

  // Animation controller
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Load questions and status
    _loadQuestionStatusAndQuestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadQuestionStatusAndQuestions() async {
    setState(() {
      isLoading = true;
    });

    await _loadQuestionStatus();
    
    // Generate or load questions for each challenge
    for (int challengeIndex = 0; challengeIndex < 3; challengeIndex++) {
      final questionId = _getQuestionId(challengeIndex);
      final questionDetailsCollection = FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(widget.userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection(questionId)
          .doc('status')
          .collection('questionDetails');

      // Check if questions exist in Firestore
      final existingQuestions = await questionDetailsCollection.get();
      if (existingQuestions.docs.isEmpty) {
        // Generate new questions if none exist
        await _generateQuestionsForChallenge(challengeIndex);
      } else {
        // Load existing questions
        List<Map<String, dynamic>> loadedQuestions = [];
        for (var doc in existingQuestions.docs) {
          loadedQuestions.add(doc.data());
        }
        setState(() {
          challengeQuestions[challengeIndex] = loadedQuestions;
        });
      }
    }

    setState(() {
      isLoading = false;
    });

    _controller.forward();
  }

  Future<void> _generateQuestionsForChallenge(int challengeIndex) async {
    String type = widget.dyscalculiaType.split(' ')[0].toUpperCase();
    List<String> difficulties = ['EASY', 'MEDIUM', 'HARD'];
    String difficulty = difficulties[challengeIndex];

    List<Map<String, dynamic>> generatedQuestions = [];
    while (generatedQuestions.length < 10) {
      List<Map<String, dynamic>> batch = generatePersonalizedQuestions(
        widget.courseName,
        {
          'procedural': difficulty,
          'semantic': difficulty,
          'verbal': difficulty,
        },
      );

      List<Map<String, dynamic>> filteredBatch = batch
          .where((q) =>
              q['dyscalculia_type'] == type && q['difficulty'] == difficulty)
          .toList();

      generatedQuestions.addAll(filteredBatch);
    }

    // Take only 10 questions
    generatedQuestions = generatedQuestions.take(10).toList();

    // Store questions in Firestore
    final questionId = _getQuestionId(challengeIndex);
    final questionDetailsCollection = FirebaseFirestore.instance
        .collection('functionActivities')
        .doc(widget.userId)
        .collection(widget.courseName)
        .doc(widget.dyscalculiaType)
        .collection('solo_sessions')
        .doc('progress')
        .collection(questionId)
        .doc('status')
        .collection('questionDetails');

    for (int i = 0; i < generatedQuestions.length; i++) {
      await questionDetailsCollection.doc('question-$i').set({
        ...generatedQuestions[i],
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      challengeQuestions[challengeIndex] = generatedQuestions;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      isRefreshing = true;
    });

    await _loadQuestionStatus();

    setState(() {
      isRefreshing = false;
    });
  }

  Future<void> _loadQuestionStatus() async {
    try {
      for (String questionId in ['questionOne', 'questionTwo', 'questionThree']) {
        final statusDoc = await FirebaseFirestore.instance
            .collection('functionActivities')
            .doc(widget.userId)
            .collection(widget.courseName)
            .doc(widget.dyscalculiaType)
            .collection('solo_sessions')
            .doc('progress')
            .collection(questionId)
            .doc('status')
            .get();

        setState(() {
          completionStatus[questionId] =
              statusDoc.exists && statusDoc.data()?['completed'] == true;
        });
      }
    } catch (error) {
      print('Error loading question status: $error');
    }
  }

  bool _isQuestionLocked(int index) {
    final String questionId = _getQuestionId(index);

    if (completionStatus[questionId] == true) {
      return true;
    }

    if (index == 0) return false;
    if (index == 1) return !(completionStatus['questionOne'] ?? false);
    if (index == 2) {
      return !(completionStatus['questionOne'] ?? false) ||
          !(completionStatus['questionTwo'] ?? false);
    }
    return true;
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

  void _navigateToQuestionScreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeQuestionsScreen(
          challengeId: (index + 1).toString(),
          courseName: widget.courseName,
          userId: widget.userId,
          dyscalculiaType: widget.dyscalculiaType,
          questions: challengeQuestions[index],
          onQuestionCompleted: (questionIndex, isCorrect, timeElapsed) async {
            try {
              // Mark question as completed in questionOne/status
              await FirebaseFirestore.instance
                  .collection('functionActivities')
                  .doc(widget.userId)
                  .collection(widget.courseName)
                  .doc(widget.dyscalculiaType)
                  .collection('solo_sessions')
                  .doc('progress')
                  .collection('questionOne')
                  .doc('status')
                  .collection('questionDetails')
                  .doc('question-$questionIndex')
                  .update({
                'completed': true,
              });

              // Check if all questions in the challenge are completed
              final questionDetailsSnapshot = await FirebaseFirestore.instance
                  .collection('functionActivities')
                  .doc(widget.userId)
                  .collection(widget.courseName)
                  .doc(widget.dyscalculiaType)
                  .collection('solo_sessions')
                  .doc('progress')
                  .collection(_getQuestionId(index))
                  .doc('status')
                  .collection('questionDetails')
                  .get();

              bool allCompleted = questionDetailsSnapshot.docs
                  .every((doc) => doc.data()['completed'] == true);

              if (allCompleted) {
                // Update challenge status
                await FirebaseFirestore.instance
                    .collection('functionActivities')
                    .doc(widget.userId)
                    .collection(widget.courseName)
                    .doc(widget.dyscalculiaType)
                    .collection('solo_sessions')
                    .doc('progress')
                    .collection(_getQuestionId(index))
                    .doc('status')
                    .set({
                  'completed': true,
                  'completedAt': FieldValue.serverTimestamp(),
                });

                // Force refresh of completion status
                setState(() {
                  completionStatus[_getQuestionId(index)] = true;
                });
              }

              // Refresh the UI to show updated status
              await _refreshData();
            } catch (error) {
              print('Error updating completion status: $error');
            }
          },
        ),
      ),
    );
  }

  TextStyle _getTextStyle({
    required double fontSize,
    required bool isLocked,
    required bool isCompleted,
    double opacity = 1.0,
    FontWeight weight = FontWeight.normal,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
      color: isLocked && !isCompleted
          ? const Color(0xFF1D1D1F).withOpacity(opacity * 0.5)
          : const Color(0xFF1D1D1F).withOpacity(opacity),
    );
  }

  BoxDecoration _getCardDecoration({
    required bool isLocked,
    required bool isCompleted,
    required Color accentColor,
  }) {
    return BoxDecoration(
      color: isLocked ? Colors.white.withOpacity(0.6) : Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Stack(
          children: [
            const BackgroundPattern(),
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                                  3,
                                  (index) => _buildQuestionCard(index),
                                ),
                                const SizedBox(height: 20),
                                if (isRefreshing)
                                  const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
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
  }

  Widget _buildQuestionCard(int index) {
    final bool isLocked = _isQuestionLocked(index);
    final bool isCompleted = completionStatus[_getQuestionId(index)] ?? false;

    final Color cardColor =
        isLocked ? Colors.white.withOpacity(0.6) : Colors.white;

    final Color accentColor = isCompleted
        ? Colors.green
        : isLocked
            ? Colors.grey
            : const Color(0xFFFF6D00);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: _getCardDecoration(
        isLocked: isLocked,
        isCompleted: isCompleted,
        accentColor: accentColor,
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
              : () => _navigateToQuestionScreen(index),
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                    Text(
                      'Challenge ${index + 1}',
                      style: _getTextStyle(
                        fontSize: 20,
                        isLocked: isLocked,
                        isCompleted: isCompleted,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isCompleted
                          ? 'You have successfully completed this challenge.'
                          : isLocked
                              ? 'Complete the previous ${index == 1 ? 'challenge' : 'challenges'} to unlock this challenge.'
                              : 'Tap to start the challenge and test your skills.',
                      style: _getTextStyle(
                        fontSize: 16,
                        isLocked: isLocked,
                        isCompleted: isCompleted,
                        opacity: 0.7,
                        height: 1.5,
                      ),
                    ),
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
                    if (!isLocked && !isCompleted) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _navigateToQuestionScreen(index),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.courseName} Challenges',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1D1F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Complete 10 questions per challenge',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                          ],
                        ),
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