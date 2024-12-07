import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:giggle/core/data/questions.dart';
import 'package:giggle/features/performance_result/performance_result_screen.dart';

enum TestType { skillAssessment, parentQuestionnaire }

class AptitudeTestScreen extends StatefulWidget {
  final TestType testType;

  const AptitudeTestScreen({
    Key? key,
    required this.testType,
  }) : super(key: key);

  @override
  _AptitudeTestScreenState createState() => _AptitudeTestScreenState();
}

class _AptitudeTestScreenState extends State<AptitudeTestScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  late List<String?> answers;
  bool isLoading = false;
  late Timer _timer;
  int _timeRemaining = 1500; // 25 minutes in seconds
  late PageController _pageController;
  late AnimationController _fadeController;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    answers = List.filled(questions.length, null);
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _timeRemaining ~/ 60;
    int seconds = _timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleAnswer(String answer) {
    setState(() {
      answers[currentQuestionIndex] = answer;
      _showHint = false;

      // Animate to next question after a brief delay
      if (currentQuestionIndex < questions.length - 1) {
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
        _showCompletionDialog();
      }
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Time\'s Up!'),
          content: const Text(
            'Your time has expired. Your answers will be submitted automatically.',
          ),
          actions: [
            TextButton(
              child: const Text('View Results'),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => PerformanceResultScreen(),
                  ),
                );
                _submitTest();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Test Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thank you for completing the assessment. Your results will be analyzed and shared soon.',
              ),
              const SizedBox(height: 16),
              // Add completion statistics
              _buildCompletionStats(),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('View Results'),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => PerformanceResultScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletionStats() {
    final answeredQuestions = answers.where((answer) => answer != null).length;
    final completionRate = (answeredQuestions / questions.length * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Questions Answered',
            '$answeredQuestions/${questions.length}',
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            'Completion Rate',
            '$completionRate%',
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            'Time Taken',
            '${25 - (_timeRemaining ~/ 60)} minutes',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6E6E73),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _submitTest() {
    // Add submission logic here
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentQuestionIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildQuestionPage(index);
                  },
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _showExitConfirmationDialog(),
              ),
              Expanded(
                child: Container(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / questions.length,
                      backgroundColor: const Color(0xFFE5E5EA),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF5E5CE6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildTimer(),
              const SizedBox(width: 8),
              _buildHelpButton(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestionIndex + 1}/${questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_showHint)
                TextButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Show Hint'),
                  onPressed: () {
                    // Show hint logic
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questions[index]['question'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(),
          const SizedBox(height: 32),
          ...List.generate(
            questions[index]['options'].length,
            (optionIndex) => _buildEnhancedOptionButton(
              questions[index]['options'][optionIndex],
              answers[index],
              optionIndex,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOptionButton(
      String option, String? selectedAnswer, int index) {
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
            onTap: () => _handleAnswer(option),
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

  Widget _buildTimer() {
    final isLowTime = _timeRemaining < 300; // Last 5 minutes

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLowTime ? const Color(0xFFFFEBEB) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color:
                isLowTime ? const Color(0xFFFF3B30) : const Color(0xFF6E6E73),
          ),
          const SizedBox(width: 4),
          Text(
            _formattedTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color:
                  isLowTime ? const Color(0xFFFF3B30) : const Color(0xFF6E6E73),
            ),
          ),
        ],
      ),
    ).animate(target: isLowTime ? 1 : 0).shake(delay: 300.ms);
  }

  Widget _buildNavigationButtons() {
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
                  ? () => _showCompletionDialog()
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

  Widget _buildHelpButton() {
    return IconButton(
      icon: const Icon(
        Icons.help_outline,
        color: Color(0xFF6E6E73),
      ),
      onPressed: _showHelpDialog,
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: Color(0xFF5E5CE6),
              ),
              const SizedBox(width: 8),
              const Text('Need Help?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                icon: Icons.check_circle_outline,
                title: 'Select One Answer',
                description: 'Choose the best answer for each question.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.timer_outlined,
                title: 'Time Management',
                description:
                    'Try to complete each question within the time limit.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.arrow_back,
                title: 'Navigation',
                description: 'You can go back to previous questions if needed.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.lightbulb_outline,
                title: 'Hints Available',
                description: 'Click the hint button if you need assistance.',
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Got it'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Exit Test?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to exit? Your progress will be lost.',
              ),
              const SizedBox(height: 16),
              _buildProgressSummary(),
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6E6E73)),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Exit',
                style: TextStyle(color: Color(0xFFFF3B30)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit test screen
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressSummary() {
    final answeredQuestions = answers.where((answer) => answer != null).length;
    final remainingQuestions = questions.length - answeredQuestions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressItem(
                icon: Icons.check_circle_outline,
                label: 'Answered',
                value: answeredQuestions.toString(),
                color: Color(0xFF34C759),
              ),
              _buildProgressItem(
                icon: Icons.pending_outlined,
                label: 'Remaining',
                value: remainingQuestions.toString(),
                color: Color(0xFFFF9500),
              ),
              _buildProgressItem(
                icon: Icons.timer_outlined,
                label: 'Time Left',
                value: _formattedTime,
                color: Color(0xFF5856D6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6E6E73),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5E5CE6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF5E5CE6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF1D1D1F).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
