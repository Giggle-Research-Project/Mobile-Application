import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giggle/features/solo_session_question_screen/question_selection_screen.dart';
import 'package:giggle/features/teacher_selection/teacher_selection_screen.dart';
import 'package:giggle/features/teaching_sessions/teaching_session.dart';

class UserProgressScreen extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String dyscalculiaType;
  final String courseName;
  final List<Map<String, dynamic>> questions;

  const UserProgressScreen({
    Key? key,
    required this.dyscalculiaType,
    required this.difficultyLevels,
    required this.courseName,
    required this.questions,
  }) : super(key: key);

  @override
  _UserProgressScreenState createState() => _UserProgressScreenState();
}

class _UserProgressScreenState extends ConsumerState<UserProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Track completion status for each path individually
  Map<String, bool> completionStatus = {
    'video': false,
    'interactive sessions': false,
    'solo sessions': false,
  };

  // Track loading status for each path individually
  Map<String, bool> loadingStatus = {
    'video': true,
    'interactive sessions': true,
    'solo sessions': true,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Function to check status for a specific path type
  Future<void> _checkPathCompletionStatus(
      String pathType, String userId) async {
    try {
      String collectionName;

      switch (pathType) {
        case 'video':
          collectionName = 'video_lesson';
          break;
        case 'interactive sessions':
          collectionName = 'interactive_session';
          break;
        case 'solo sessions':
          collectionName = 'solo_sessions';
          break;
        default:
          collectionName = '';
      }

      if (collectionName.isEmpty) {
        setState(() {
          loadingStatus[pathType] = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection(collectionName)
          .doc('progress')
          .get();

      setState(() {
        completionStatus[pathType] =
            snapshot.exists && snapshot.data()?['completed'] == true;
        loadingStatus[pathType] = false;
      });
    } catch (error) {
      print('Error checking completion status for $pathType: $error');
      setState(() {
        loadingStatus[pathType] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    print(widget.difficultyLevels);
    print(widget.courseName);
    print(widget.dyscalculiaType);

    print(widget.questions);

    return authState.when(
      data: (AppUser? user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        // Start loading each path's status independently
        // Only initiate these checks if they haven't been started yet
        if (loadingStatus['video'] == true) {
          _checkPathCompletionStatus('video', user.uid);
        }
        if (loadingStatus['interactive sessions'] == true) {
          _checkPathCompletionStatus('interactive sessions', user.uid);
        }
        if (loadingStatus['solo sessions'] == true) {
          _checkPathCompletionStatus('solo sessions', user.uid);
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
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(context),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildLearningPaths(user.uid),
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

  Widget _buildLearningPaths(String userId) {
    final paths = [
      {
        'title': 'Interactive Video Learning',
        'description':
            'Watch engaging videos to understand mathematical concepts through visual examples and clear explanations.',
        'icon': Icons.play_circle_filled_rounded,
        'color': const Color(0xFF00C853),
        'type': 'video',
        'isLocked': false,
        'isCompleted': completionStatus['video'] ?? false,
        'isLoading': loadingStatus['video'] ?? true,
      },
      {
        'title': 'Guided Practice Sessions',
        'description':
            'Apply what you\'ve learned with step-by-step interactive exercises and receive immediate feedback.',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF2979FF),
        'type': 'interactive sessions',
        'isLocked': false,
        'isCompleted': completionStatus['interactive sessions'] ?? false,
        'isLoading': loadingStatus['interactive sessions'] ?? true,
      },
      {
        'title': 'Independent Mastery Quiz',
        'description':
            'Test your understanding with independent problem-solving exercises to solidify your learning.',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFFFF6D00),
        'type': 'solo sessions',
        'isLocked': !(completionStatus['interactive sessions'] ?? false) ||
            (completionStatus['solo sessions'] ?? false),
        'isCompleted': completionStatus['solo sessions'] ?? false,
        'isLoading': loadingStatus['solo sessions'] ?? true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Learning Journey',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Complete each module to unlock the next step',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6E6E73),
          ),
        ),
        const SizedBox(height: 24),
        ...paths.map((path) => _buildPathCard(path, userId: userId)).toList(),
      ],
    );
  }

  Widget _buildPathCard(
    Map<String, dynamic> path, {
    required String userId,
  }) {
    final bool isLocked = path['isLocked'] as bool;
    final bool isCompleted = path['isCompleted'] as bool;
    final bool isLoading = path['isLoading'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
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
              : path['color'].withOpacity(0.2),
          width: 1.5,
        ),
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
                  final String pathType = path['type'] as String;

                  // Navigate to different screens based on path type
                  switch (pathType) {
                    case 'video':
                      // Navigate to video learning screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeachingSessionScreen(
                            isCompleted:
                                completionStatus['interactive sessions'] ??
                                    false,
                            difficultyLevels: widget.difficultyLevels,
                            courseName: widget.courseName,
                            dyscalculiaType: widget.dyscalculiaType,
                            questions: widget.questions,
                            userId: userId,
                          ),
                        ),
                      );
                      break;
                    case 'interactive sessions':
                      // Navigate to interactive sessions screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherSelectionScreen(
                            courseName: widget.courseName,
                            dyscalculiaType: widget.dyscalculiaType,
                            questions: widget.questions,
                            userId: userId,
                          ),
                        ),
                      );
                      break;
                    case 'solo sessions':
                      // Navigate to solo practice screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SoloQuestionSelectionScreen(
                            userId: userId,
                            difficultyLevels: widget.difficultyLevels,
                            dyscalculiaType: widget.dyscalculiaType,
                            courseName: widget.courseName,
                          ),
                        ),
                      );
                      break;
                    default:
                      // Default fallback to teaching session
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeachingSessionScreen(
                            isCompleted:
                                completionStatus['interactive sessions'] ??
                                    false,
                            userId: userId,
                            difficultyLevels: widget.difficultyLevels,
                            courseName: widget.courseName,
                            dyscalculiaType: widget.dyscalculiaType,
                            questions: widget.questions,
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
                            path['color'],
                            path['color'].withOpacity(0.3),
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
                        // Left side with icon
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: path['color']
                                .withOpacity(isLocked ? 0.05 : 0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            path['icon'],
                            color: isLocked
                                ? path['color'].withOpacity(0.5)
                                : path['color'],
                            size: 32,
                          ),
                        ),

                        // Right side with loading indicator or action button
                        isLoading
                            ? Container(
                                height: 40,
                                width: 40,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey),
                                ),
                              )
                            : Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? Colors.grey.withOpacity(0.1)
                                      : path['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isLocked
                                      ? Icons.lock
                                      : Icons.arrow_forward_rounded,
                                  color: isLocked
                                      ? Colors.grey.withOpacity(0.4)
                                      : path['color'],
                                  size: 22,
                                ),
                              ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Title
                    Text(
                      path['title'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLocked
                            ? const Color(0xFF1D1D1F).withOpacity(0.5)
                            : const Color(0xFF1D1D1F),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Description
                    Text(
                      path['description'],
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isLocked
                            ? const Color(0xFF1D1D1F).withOpacity(0.3)
                            : const Color(0xFF1D1D1F).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge (only if not loading)
              if (isCompleted && !isLoading)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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
                            '${widget.courseName} Lessons',
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
