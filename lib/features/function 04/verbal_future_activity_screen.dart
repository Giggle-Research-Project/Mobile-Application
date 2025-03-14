import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VerbalDyscalculiaActivityScreen extends StatefulWidget {
  final String activityTitle;
  final String activityDescription;
  final List<Map<String, dynamic>> questions;
  final int timeLimit;

  const VerbalDyscalculiaActivityScreen({
    Key? key,
    required this.activityTitle,
    required this.activityDescription,
    required this.questions,
    required this.timeLimit,
  }) : super(key: key);

  @override
  _VerbalDyscalculiaActivityScreenState createState() =>
      _VerbalDyscalculiaActivityScreenState();
}

class _VerbalDyscalculiaActivityScreenState
    extends State<VerbalDyscalculiaActivityScreen> {
  int _timeRemaining = 0;
  Timer? _timer;
  int _currentQuestionIndex = 0;
  List<String> _userAnswers = [];
  bool _isCompleted = false;
  final FlutterTts _tts = FlutterTts();
  bool _showVisualAids = true;

  // Visual representation of numbers
  Map<String, String> _numberVisuals = {
    '1': '●',
    '2': '●●',
    '3': '●●●',
    '4': '●●●●',
    '5': '●●●●●',
    // Add more as needed
  };

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.timeLimit;
    _userAnswers = List.filled(widget.questions.length, '');
    _initializeTTS();
    _startTimer();
  }

  Future<void> _initializeTTS() async {
    await _tts.setLanguage('en-US');
    await _tts
        .setSpeechRate(0.8); // Slower speech rate for better comprehension
  }

  void _speakText(String text) async {
    await _tts.speak(text);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer?.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _timer?.cancel();
      _showResults();
    }
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content:
            const Text('Would you like to review your answers or try again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showResults();
            },
            child: const Text('Review Answers'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _timeRemaining = widget.timeLimit;
                _currentQuestionIndex = 0;
                _userAnswers = List.filled(widget.questions.length, '');
                _startTimer();
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showResults() {
    int correctAnswers = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (_userAnswers[i] == widget.questions[i]['correctAnswer']) {
        correctAnswers++;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Activity Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'You got $correctAnswers out of ${widget.questions.length} correct!'),
            const SizedBox(height: 16),
            Text(
              'Score: ${(correctAnswers / widget.questions.length * 100).round()}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _timeRemaining = widget.timeLimit;
                _currentQuestionIndex = 0;
                _userAnswers = List.filled(widget.questions.length, '');
                _startTimer();
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showVisualHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Number Visualization'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                  'assets/number_blocks.png'), // Add visual number blocks
              const SizedBox(height: 16),
              const Text(
                'Try using these visual aids to help you connect the number words with their quantities.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.activityTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Toggle visual aids
          IconButton(
            icon: Icon(
              _showVisualAids ? Icons.visibility : Icons.visibility_off,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _showVisualAids = !_showVisualAids;
              });
            },
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress and Support Tools
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Timer with visual countdown
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '${_timeRemaining ~/ 60}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Audio support
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () {
                      _speakText(
                          'Question ${_currentQuestionIndex + 1}: What number is ${widget.questions[_currentQuestionIndex]['numberWord']}?');
                    },
                    tooltip: 'Listen to question',
                  ),
                ],
              ),
            ),

            // Question Display with Visual Support
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.questions[_currentQuestionIndex]['numberWord'],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          _speakText(widget.questions[_currentQuestionIndex]
                              ['numberWord']);
                        },
                      ),
                    ],
                  ),
                  if (_showVisualAids) ...[
                    const SizedBox(height: 16),
                    // Visual representation (dots, blocks, or number line)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('= 1', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Answer Options with Visual Support
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: List.generate(
                  widget.questions[_currentQuestionIndex]['options'].length,
                  (index) {
                    final option = widget.questions[_currentQuestionIndex]
                        ['options'][index];
                    final isSelected =
                        _userAnswers[_currentQuestionIndex] == option;

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected ? Colors.blue : Colors.white,
                        foregroundColor:
                            isSelected ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: isSelected ? 8 : 2,
                      ),
                      onPressed: () {
                        _selectAnswer(option);
                        _speakText(option); // Speak the selected number
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (_showVisualAids) ...[
                            const SizedBox(height: 8),
                            Text(
                              '●' * int.parse(option),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.blue,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Support Tools
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: _showVisualHelp,
                    tooltip: 'Visual Help',
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () {
                      _speakText(
                          widget.questions[_currentQuestionIndex]['hint']);
                    },
                    tooltip: 'Listen to hint',
                  ),
                ],
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _userAnswers[_currentQuestionIndex] = '';
                      });
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                        _currentQuestionIndex < widget.questions.length - 1
                            ? 'Next'
                            : 'Finish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _userAnswers[_currentQuestionIndex].isNotEmpty
                        ? _nextQuestion
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }
}
