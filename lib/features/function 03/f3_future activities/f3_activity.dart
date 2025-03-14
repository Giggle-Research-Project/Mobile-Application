import 'dart:async';
import 'package:flutter/material.dart';

class ProceduralDyscalculiaHandwritingScreen extends StatefulWidget {
  final String activityTitle;
  final String activityDescription;

  const ProceduralDyscalculiaHandwritingScreen({
    Key? key,
    required this.activityTitle,
    required this.activityDescription,
  }) : super(key: key);

  @override
  _ProceduralDyscalculiaHandwritingScreenState createState() =>
      _ProceduralDyscalculiaHandwritingScreenState();
}

class _ProceduralDyscalculiaHandwritingScreenState
    extends State<ProceduralDyscalculiaHandwritingScreen> {
  int _timeRemaining = 900; // 15 minutes
  Timer? _timer;
  List<List<Offset>> _writingPaths = [];
  int _currentStep = 0;
  bool _isCompleted = false;

  final List<Map<String, dynamic>> _steps = [
    {
      'instruction': 'Write the first number (24)',
      'tip': 'Take your time to write clearly',
    },
    {
      'instruction': 'Write the plus sign (+)',
      'tip': 'Place it next to the first number',
    },
    {
      'instruction': 'Write the second number (15)',
      'tip': 'Keep the numbers aligned',
    },
    {
      'instruction': 'Draw a line under both numbers',
      'tip': "Make sure it's straight",
    },
    {
      'instruction': 'Write the final answer (39)',
      'tip': 'Double-check your calculation',
    },
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
          _showTimeUpDialog();
        }
      });
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Time's Up!"),
        content: const Text('Would you like to try again or review your work?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _timeRemaining = 900;
                _writingPaths.clear();
                _currentStep = 0;
                _isCompleted = false;
                _startTimer();
              });
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      setState(() {
        _isCompleted = true;
      });
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great Job!'),
        content: const Text('You\'ve completed all the steps!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Return to Activities'),
          ),
        ],
      ),
    );
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer and Progress
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
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
                  // Progress
                  Text(
                    'Step ${_currentStep + 1}/${_steps.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Current Step Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _steps[_currentStep]['instruction'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _steps[_currentStep]['tip'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Writing Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
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

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Clear Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
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
                  ),
                  // Next Step Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_currentStep < _steps.length - 1
                        ? 'Next Step'
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
                    onPressed: _nextStep,
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

class WritingPainter extends CustomPainter {
  final List<List<Offset>> paths;

  WritingPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    // Background grid lines
    final gridPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        gridPaint,
      );
    }

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        gridPaint,
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
