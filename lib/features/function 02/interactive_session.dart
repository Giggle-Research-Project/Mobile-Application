// Interactive Session Screen
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:giggle/features/function%2002/solo_session.dart';

class InteractiveSessionScreen extends StatefulWidget {
  const InteractiveSessionScreen({Key? key}) : super(key: key);

  @override
  _InteractiveSessionScreenState createState() =>
      _InteractiveSessionScreenState();
}

class _InteractiveSessionScreenState extends State<InteractiveSessionScreen> {
  int _currentQuestionIndex = 0;
  int _timeRemaining = 600; // 10 minutes
  Timer? _timer;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What does the number 5 represent?',
      'type': 'dialog',
    },
    {
      'question': 'How would you show the quantity of 3?',
      'type': 'dialog',
    },
    // Add more questions
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer?.cancel();
          // Handle timer completion
        }
      });
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // AR Environment Placeholder
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.purple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Timer and Navigation
            Positioned(
              top: 20,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Timer Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_timeRemaining ~/ 60}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Question Navigation
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _previousQuestion,
                      ),
                      Text(
                        '${_currentQuestionIndex + 1}/${_questions.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _nextQuestion,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Question Dialog
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
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
                    Text(
                      _questions[_currentQuestionIndex]['question'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Add answer input or interaction method
                  ],
                ),
              ),
            ),

            // Bottom Button to Sole Session
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoleSessionScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Go to Sole Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
