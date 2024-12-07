import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giggle/features/function%2002/solo_session.dart';

class ProceduralInteractiveSession extends StatefulWidget {
  const ProceduralInteractiveSession({Key? key}) : super(key: key);

  @override
  _ProceduralInteractiveSessionState createState() =>
      _ProceduralInteractiveSessionState();
}

class _ProceduralInteractiveSessionState
    extends State<ProceduralInteractiveSession> {
  int _currentQuestionIndex = 0;
  int _timeRemaining = 600; // 10 minutes
  Timer? _timer;
  List<List<Offset>> _writingPaths = [];
  Color _currentColor = Colors.blue;
  double _strokeWidth = 3.0;

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
        _writingPaths.clear(); // Clear previous writing
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _writingPaths.clear(); // Clear previous writing
      });
    }
  }

  void _clearWriting() {
    setState(() {
      _writingPaths.clear();
    });
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
            // Background Gradient
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

            // Writing Surface
            Positioned(
              bottom: 180,
              left: 16,
              right: 16,
              child: Container(
                height: 200,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GestureDetector(
                    onPanDown: (details) {
                      setState(() {
                        _writingPaths.add([details.localPosition]);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _writingPaths.last.add(details.localPosition);
                      });
                    },
                    child: CustomPaint(
                      painter: WritingPainter(paths: _writingPaths),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Question Dialog
            Positioned(
              bottom: 400,
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
                child: Text(
                  _questions[_currentQuestionIndex]['question'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Clear and Bottom Buttons
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Clear Button
                  ElevatedButton(
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
                    onPressed: _clearWriting,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Sole Session Button
                  ElevatedButton(
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
                      'Sole Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Writing Surface
class WritingPainter extends CustomPainter {
  final List<List<Offset>> paths;

  WritingPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    // Background lines to simulate notebook paper
    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        linePaint,
      );
    }

    // Drawing paths
    final paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var path in paths) {
      if (path.length > 1) {
        final drawPath = Path();
        drawPath.moveTo(path[0].dx, path[0].dy);

        for (int i = 1; i < path.length; i++) {
          drawPath.lineTo(path[i].dx, path[i].dy);
        }

        canvas.drawPath(drawPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
