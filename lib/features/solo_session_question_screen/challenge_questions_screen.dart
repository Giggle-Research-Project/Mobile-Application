import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giggle/features/function%2002/solo_session.dart';
import 'package:giggle/features/function%2003/solo_session.dart';
import 'package:giggle/features/function%2004/solo_verbal_session.dart';
import 'dart:ui';

class ChallengeQuestionsScreen extends StatefulWidget {
  final String challengeId;
  final String courseName;
  final String userId;
  final String dyscalculiaType;
  final List<Map<String, dynamic>> questions;
  final Future<void> Function(int questionIndex, bool isCorrect, double timeElapsed) onQuestionCompleted;

  const ChallengeQuestionsScreen({
    Key? key,
    required this.challengeId,
    required this.courseName,
    required this.userId,
    required this.dyscalculiaType,
    required this.questions,
    required this.onQuestionCompleted,
  }) : super(key: key);

  String _getQuestionCollectionName() {
    switch (challengeId) {
      case '1':
        return 'questionOne';
      case '2':
        return 'questionTwo';
      case '3':
        return 'questionThree';
      default:
        return '';
    }
  }

  Future<void> updateQuestionStatus(int questionIndex, bool isCorrect, double timeElapsed) async {
    final String questionCollection = _getQuestionCollectionName();
    
    try {
      // Get reference to the base path
      final baseRef = FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(courseName)
          .doc(dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection(questionCollection);

      // Update individual question status in questionDetails
      await baseRef
          .doc('status')
          .collection('questionDetails')
          .doc('question-$questionIndex')
          .update({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'isCorrect': isCorrect,
        'timeElapsed': timeElapsed,
      });

      // Check if all 10 questions are completed
      final questionDetailsSnapshot = await baseRef
          .doc('status')
          .collection('questionDetails')
          .get();

      bool allQuestionsCompleted = questionDetailsSnapshot.docs
          .every((doc) => doc.data()['completed'] == true);

      // If all questions are completed, update the challenge status
      if (allQuestionsCompleted) {
        await baseRef
            .doc('status')
            .set({
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (error) {
      print('Error updating question status: $error');
    }
  }

  @override
  State<ChallengeQuestionsScreen> createState() => _ChallengeQuestionsScreenState();
}

class _ChallengeQuestionsScreenState extends State<ChallengeQuestionsScreen> {
  Map<int, bool> completedQuestions = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedQuestions();
  }

  Future<void> _loadCompletedQuestions() async {
    setState(() => isLoading = true);
    try {
      final questionCollection = widget._getQuestionCollectionName();
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(widget.userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection(questionCollection)
          .doc('status')
          .collection('questionDetails')
          .get();

      setState(() {
        for (var doc in questionsSnapshot.docs) {
          int index = int.tryParse(doc.id.split('-').last) ?? -1;
          if (index >= 0) {
            completedQuestions[index] = doc.data()['completed'] ?? false;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading completed questions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: CustomScrollView(
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
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.questions.length,
                    itemBuilder: (context, index) {
                      final question = widget.questions[index];
                      final difficulty = question['difficulty'] ?? 'Medium';
                      final isCompleted = completedQuestions[index] ?? false;
                      final isAvailable = _isQuestionAvailable(index);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: isAvailable ? 1.0 : 0.6,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Stack(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(difficulty).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isAvailable ? _getDifficultyIcon(difficulty) : Icons.lock,
                                        color: isAvailable 
                                          ? _getDifficultyColor(difficulty)
                                          : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  'Question ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      isAvailable 
                                        ? 'Difficulty: $difficulty'
                                        : 'Complete previous question to unlock',
                                      style: TextStyle(
                                        color: isAvailable 
                                          ? _getDifficultyColor(difficulty)
                                          : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  if (!isAvailable) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please complete the previous question first.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.black87,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(),
                                      ),
                                    );
                                  // } else if (isCompleted) {
                                  //   ScaffoldMessenger.of(context).showSnackBar(
                                  //     const SnackBar(
                                  //       content: Text(
                                  //         'This question has already been completed.',
                                  //         style: TextStyle(color: Colors.white),
                                  //       ),
                                  //       backgroundColor: Colors.black87,
                                  //       behavior: SnackBarBehavior.floating,
                                  //       shape: RoundedRectangleBorder(),
                                  //     ),
                                  //   );
                                  } else {
                                    _navigateToQuestionScreen(context, index, question);
                                  }
                                },
                              ),
                            ),
                            if (isCompleted)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
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
                      );
                    },
                  ),
          ),
        ],
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
                              'Challenge ${widget.challengeId} Questions',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1D1F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete all ${widget.questions.length} questions to finish the challenge',
                              style: const TextStyle(
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

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.star_outline;
      case 'medium':
        return Icons.star_half;
      case 'hard':
        return Icons.star;
      default:
        return Icons.star_half;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  bool _isQuestionAvailable(int index) {
    if (index == 0) return true;
    return completedQuestions[index - 1] ?? false;
  }

  void _navigateToQuestionScreen(BuildContext context, int index, Map<String, dynamic> question) async {
    // Ensure question is not null
    if (question == null) {
      print('Error: Question data is null');
      return;
    }

    Widget screen;
    
    if (widget.dyscalculiaType == 'Semantic Dyscalculia') {
      screen = SemanticSoloSessionScreen(
        index: '${widget.challengeId}-$index',
        courseName: widget.courseName,
        questions: [question], // Pass as a list with single question
        userId: widget.userId,
        onQuestionCompleted: () async {
          await widget.onQuestionCompleted(index, true, 0.0);
          setState(() {
            completedQuestions[index] = true;
          });
        },
      );
    } else if (widget.dyscalculiaType == 'Verbal Dyscalculia') {
      screen = SoloVerbalSessionScreen(
        courseName: widget.courseName,
        questions: [question],
        dyscalculiaType: widget.dyscalculiaType,
        index: '${widget.challengeId}-$index',
        userId: widget.userId,
        onQuestionCompleted: (bool isCorrect, double timeElapsed) {
          widget.onQuestionCompleted(index, isCorrect, timeElapsed);
          setState(() {
            completedQuestions[index] = true;
          });
        },
      );
    } else {
      screen = ProceduralSoloSession(
        courseName: widget.courseName,
        questions: [question],
        dyscalculiaType: widget.dyscalculiaType,
        index: '${widget.challengeId}-$index',
        userId: widget.userId,
        onQuestionCompleted: (bool isCorrect) async {
          await widget.onQuestionCompleted(index, isCorrect, 0.0);
          setState(() {
            completedQuestions[index] = true;
          });
        },
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // Refresh the questions list after returning
    await _loadCompletedQuestions();
  }
}
