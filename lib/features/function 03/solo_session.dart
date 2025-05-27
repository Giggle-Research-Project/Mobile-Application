import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/services/predict_handwriting.service.dart';
import 'package:giggle/core/widgets/bottom_navbar.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';
import 'package:flutter/foundation.dart';
import 'package:giggle/features/function%2003/widgets/writing_painter.dart';
import 'package:path_provider/path_provider.dart';

class ProceduralSoloSession extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String dyscalculiaType;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String index;

  const ProceduralSoloSession({
    Key? key,
    this.difficultyLevels,
    required this.dyscalculiaType,
    required this.courseName,
    required this.questions,
    required this.index, required Future<Null> Function(bool isCorrect) onQuestionCompleted, required String userId,
  }) : super(key: key);

  @override
  _ProceduralSoloSessionState createState() => _ProceduralSoloSessionState();
}

class _ProceduralSoloSessionState extends ConsumerState<ProceduralSoloSession> {
  int _timeElapsed = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _squares = [];
  int _currentQuestionIndex = 0;

  // Current question data
  late int firstNumber;
  late int secondNumber;
  late int correctAnswer;

  // To track user's entered values and show feedback
  Map<String, String?> userEnteredValues = {};
  Map<String, bool> validationResults = {};

  // Keys for each editable square
  final GlobalKey _firstDigitKey = GlobalKey();
  final GlobalKey _secondDigitKey = GlobalKey();
  final GlobalKey _thirdDigitKey = GlobalKey();
  final GlobalKey _fourthDigitKey = GlobalKey();
  final GlobalKey _answerFirstDigitKey = GlobalKey();
  final GlobalKey _answerSecondDigitKey = GlobalKey();

  bool _isPredicting = false;
  Map<String, String> _predictedDigits = {};
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadQuestion();
    _initializeSquares();
  }

  void _loadQuestion() {
    try {
      if (widget.questions.isEmpty) {
        _setDefaultQuestion();
        return;
      }

      final questionData = widget.questions[_currentQuestionIndex];
      final difficulty = questionData['difficulty']?.toString() ?? 'medium';

      Map<String, int> numbers;
      switch (widget.courseName.toLowerCase()) {
        case 'addition':
          numbers = NumberRangeGenerator.generateAdditionNumbers(difficulty);
          break;
        case 'subtraction':
          numbers = NumberRangeGenerator.generateSubtractionNumbers(difficulty);
          break;
        case 'multiplication':
          numbers = NumberRangeGenerator.generateMultiplicationNumbers(difficulty);
          break;
        case 'division':
          numbers = NumberRangeGenerator.generateDivisionNumbers(difficulty);
          break;
        default:
          numbers = {'num1': 5, 'num2': 3};
      }

      firstNumber = numbers['num1']!;
      secondNumber = numbers['num2']!;

      // Calculate correct answer based on operation
      switch (widget.courseName.toLowerCase()) {
        case 'addition':
          correctAnswer = firstNumber + secondNumber;
          break;
        case 'subtraction':
          correctAnswer = firstNumber - secondNumber;
          break;
        case 'multiplication':
          correctAnswer = firstNumber * secondNumber;
          break;
        case 'division':
          correctAnswer = firstNumber ~/ secondNumber;
          break;
        default:
          correctAnswer = firstNumber + secondNumber;
      }

      // Reset validation state
      validationResults = {
        'first_digit': true,
        'second_digit': true,
        'third_digit': true,
        'fourth_digit': true,
        'answer_first_digit': true,
        'answer_second_digit': true,
      };
    } catch (e) {
      print('Error in _loadQuestion: $e');
      _setDefaultQuestion();
    }
  }

  void _setDefaultQuestion() {
    // Safe default values
    firstNumber = 5;
    secondNumber = 7;
    correctAnswer = 12;
    print(
        'Using default question: $firstNumber + $secondNumber = $correctAnswer');
  }

  void _initializeSquares() {
    setState(() {
      _squares = [
        {
          'index': 0,
          'content': '',
          'paths': <List<Offset>>[],
          'editable': true,
          'position': 'first_digit'
        },
        {
          'index': 1,
          'content': '',
          'paths': <List<Offset>>[],
          'editable': true,
          'position': 'second_digit'
        },
        if (widget.courseName == 'Addition')
          {
            'index': 2,
            'content': '+',
            'paths': <List<Offset>>[],
            'editable': false,
            'position': 'plus_sign'
          },
        if (widget.courseName == 'Subtraction')
          {
            'index': 2,
            'content': '-',
            'paths': <List<Offset>>[],
            'editable': false,
            'position': 'minus_sign'
          },
        if (widget.courseName == 'Multiplication')
          {
            'index': 2,
            'content': 'x',
            'paths': <List<Offset>>[],
            'editable': false,
            'position': 'times_sign'
          },
        if (widget.courseName == 'Division')
          {
            'index': 2,
            'content': '÷',
            'paths': <List<Offset>>[],
            'editable': false,
            'position': 'division_sign'
          },
        {
          'index': 3,
          'content': '',
          'paths': <List<Offset>>[],
          'editable': true,
          'position': 'third_digit'
        },
        {
          'index': 4,
          'content': '',
          'paths': <List<Offset>>[],
          'editable': true,
          'position': 'fourth_digit'
        },
        {
          'index': 5,
          'content': '=',
          'paths': <List<Offset>>[],
          'editable': false,
          'position': 'equals_sign'
        },
        {
          'index': 6,
          'content': '',
          'paths': <List<Offset>>[],
          'editable': true,
          'position': 'answer_first_digit'
        },
        {
          'index': 7,
          'content': '',
          'paths': <List<Offset>>[],
          'editable': true,
          'position': 'answer_second_digit'
        },
      ];
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeElapsed++;
      });
    });
  }

  void _clearWriting(int index) {
    if (!mounted) return;
    setState(() {
      _squares[index]['paths'] = <List<Offset>>[];

      // Also clear validation for this square
      String position = _squares[index]['position'];
      if (validationResults.containsKey(position)) {
        validationResults[position] = true;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showPredictionResultDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PredictionResultsDialog(
          predictedDigits: _predictedDigits,
        );
      },
    );
  }

  Future<File?> captureSquare(GlobalKey key, String squareIdentifier) async {
    try {
      final context = key.currentContext;
      if (context == null) {
        print('Error: No context found for $squareIdentifier');
        return null;
      }

      RenderRepaintBoundary boundary =
          context.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();

        // Use getTemporaryDirectory() instead of hardcoding path
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$squareIdentifier.png');
        print('File path: ${file.path}');

        // Write the file
        await file.writeAsBytes(bytes);
        return file;
      }
      return null;
    } catch (e) {
      print('Error capturing screenshot: $e');
      return null;
    }
  }

  Future<String?> captureAndPredictDigit(
      GlobalKey key, String identifier) async {
    try {
      final file = await captureSquare(key, identifier);
      if (file == null) return null;
      final result = await predictHandwriting(file, identifier);
      print('Prediction for $identifier: $result');
      return result;
    } catch (e) {
      print('Error in captureAndPredictDigit for $identifier: $e');
      return null;
    }
  }

  void _showCorrectAnswerDialog(String userId, bool isLastQuestion) {
    try {
      // Store values locally to prevent null issues if state changes
      final int safeFirstNumber = firstNumber;
      final int safeSecondNumber = secondNumber;
      final int safeCorrectAnswer = correctAnswer;
      print(
          'Dialog values: $safeFirstNumber + $safeSecondNumber = $safeCorrectAnswer');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Great job!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  isLastQuestion
                      ? 'You completed all the exercises!'
                      : 'You solved the problem correctly!',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '$safeFirstNumber + $safeSecondNumber = $safeCorrectAnswer',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
                onPressed: () {
                  if (isLastQuestion) {
                    _saveProgressToFirestore(userId).then((_) {
                      if (mounted) {
                        Navigator.of(context).pop();
                        Future.delayed(Duration(milliseconds: 100), () {
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(),
                              ),
                            );
                          }
                        });
                      }
                    }).catchError((error) {
                      if (mounted) {
                        print("Error saving progress: $error");
                      }
                    });
                  } else {
                    if (mounted) {
                      setState(() {
                        _currentQuestionIndex++;
                        _loadQuestion();
                        _clearAllWriting();
                      });
                    }
                  }
                },
                child: Text(
                  isLastQuestion ? 'Complete' : 'Next Question',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Dialog creation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  Future<void> _saveProgressToFirestore(String userId) async {
    if (userId.isEmpty) {
      print('Warning: userId is empty, cannot save to Firestore');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(widget.courseName)
          .doc('Procedural Dyscalculia')
          .collection('solo_sessions')
          .doc('progress')
          .set({
            'completed': true,
            'timestamp': FieldValue.serverTimestamp(),
            'timeTaken': _timeElapsed,
          }, SetOptions(merge: true));

      print('Progress saved to Firestore');
    } catch (e) {
      print('Firestore operation error: $e');
    }
  }

  void _showErrorDialog() {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your answer was incorrect. Check the highlighted digits and try again.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'The correct problem is $firstNumber + $secondNumber = $correctAnswer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Try Again', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing error dialog: $e');
    }
  }

  void _clearAllWriting() {
    setState(() {
      for (var square in _squares) {
        if (square['editable'] == true) {
          square['paths'] = <List<Offset>>[];
        }
      }
      // Reset validation
      validationResults = {
        'first_digit': true,
        'second_digit': true,
        'third_digit': true,
        'fourth_digit': true,
        'answer_first_digit': true,
        'answer_second_digit': true,
      };
    });
  }

  Future<void> _predictAllDigits() async {
    setState(() {
      _isPredicting = true;
      _predictedDigits.clear();
    });

    try {
      final firstDigit =
          await captureAndPredictDigit(_firstDigitKey, 'first_digit');
      final secondDigit =
          await captureAndPredictDigit(_secondDigitKey, 'second_digit');
      final thirdDigit =
          await captureAndPredictDigit(_thirdDigitKey, 'third_digit');
      final fourthDigit =
          await captureAndPredictDigit(_fourthDigitKey, 'fourth_digit');
      final answerFirstDigit = await captureAndPredictDigit(
          _answerFirstDigitKey, 'answer_first_digit');
      final answerSecondDigit = await captureAndPredictDigit(
          _answerSecondDigitKey, 'answer_second_digit');

      setState(() {
        _predictedDigits = {
          'first_digit': firstDigit ?? 'N/A',
          'second_digit': secondDigit ?? 'N/A',
          'third_digit': thirdDigit ?? 'N/A',
          'fourth_digit': fourthDigit ?? 'N/A',
          'answer_first_digit': answerFirstDigit ?? 'N/A',
          'answer_second_digit': answerSecondDigit ?? 'N/A',
        };
        _isPredicting = false;
      });

      _showPredictionResultDialog();
    } catch (e) {
      print('Error in prediction: $e');
      setState(() {
        _isPredicting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prediction failed. Please try again.')),
      );
    }
  }

  Widget _buildPredictionRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value ?? 'N/A',
            style: TextStyle(
              color: value == 'N/A' ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _submitAnswer(String userId) async {
    try {
      // Perform answer checking logic (similar to _checkAnswer)
      // Format the inputs correctly based on number of digits
      String formattedFirstNumber = "";
      String formattedSecondNumber = "";
      String formattedUserAnswer = "";

      // Handle first number (could be 1 or 2 digits)
      if (firstNumber < 10) {
        formattedFirstNumber = (_predictedDigits['second_digit'] ?? '').trim();
      } else {
        formattedFirstNumber = (_predictedDigits['first_digit'] ?? '') +
            (_predictedDigits['second_digit'] ?? '');
      }

      // Handle second number (could be 1 or 2 digits)
      if (secondNumber < 10) {
        formattedSecondNumber = (_predictedDigits['fourth_digit'] ?? '').trim();
      } else {
        formattedSecondNumber = (_predictedDigits['third_digit'] ?? '') +
            (_predictedDigits['fourth_digit'] ?? '');
      }

      // Handle answer (could be 1, 2, or 3 digits)
      if (_predictedDigits['answer_first_digit'] == null ||
          _predictedDigits['answer_first_digit'] == '0' ||
          _predictedDigits['answer_first_digit']!.trim().isEmpty) {
        formattedUserAnswer =
            (_predictedDigits['answer_second_digit'] ?? '').trim();
      } else {
        formattedUserAnswer = (_predictedDigits['answer_first_digit'] ?? '') +
            (_predictedDigits['answer_second_digit'] ?? '');
      }

      // Parse the formatted numbers
      int? userFirstNumber = int.tryParse(formattedFirstNumber);
      int? userSecondNumber = int.tryParse(formattedSecondNumber);
      int? userAnswer = int.tryParse(formattedUserAnswer);

      // Validate if user wrote the correct numbers
      bool isOperandCorrect =
          userFirstNumber == firstNumber && userSecondNumber == secondNumber;
      bool isAnswerCorrect = userAnswer == correctAnswer;

      // Show result dialog
      _showSubmitResultDialog(
        _timeElapsed,
        userId,
        isOperandCorrect,
        isAnswerCorrect,
      );
    } catch (e) {
      print('Error in submit answer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  void _showSubmitResultDialog(int timeTaken, String userId, bool isOperandCorrect, bool isAnswerCorrect) {
    String getQuestionKey(String index) {
      // Parse out the challenge number and question number
      final parts = index.split('-');
      if (parts.length == 2) {
        // For challenge-specific questions (e.g., "1-0")
        switch (parts[0]) {
          case '1':
            return 'questionOne';
          case '2':
            return 'questionTwo';
          case '3':
            return 'questionThree';
          default:
            return 'questionOne';
        }
      } else {
        // For legacy format
        switch (index) {
          case '0':
            return 'questionOne';
          case '1':
            return 'questionTwo';
          case '2':
            return 'questionThree';
          default:
            return index;
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Time Taken',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '$timeTaken seconds',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final parts = widget.index.split('-');
                  final challengeNumber = parts[0];
                  final questionNumber = parts[1];
                  final questionKey = getQuestionKey(widget.index);

                  // Get reference to base path
                  final baseRef = FirebaseFirestore.instance
                      .collection('functionActivities')
                      .doc(userId)
                      .collection(widget.courseName)
                      .doc('Procedural Dyscalculia')
                      .collection('solo_sessions')
                      .doc('progress');

                  // Save individual question progress
                  await baseRef
                      .collection(questionKey)
                      .doc('status')
                      .collection('questionDetails')
                      .doc('question-$questionNumber')
                      .set({
                        'completed': true,
                        'isCorrect': isOperandCorrect && isAnswerCorrect,
                        'timeTaken': _timeElapsed,
                        'timestamp': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                  // If this is question 9, mark the challenge as completed
                  if (int.parse(questionNumber) == 9) {
                    await baseRef
                        .collection(questionKey)
                        .doc('status')
                        .set({
                          'completed': true,
                          'completedAt': FieldValue.serverTimestamp(),
                          'challengeNumber': challengeNumber,
                        }, SetOptions(merge: true));

                    // Check if all challenges are completed
                    final challenge1Status = await baseRef
                        .collection('questionOne')
                        .doc('status')
                        .get();
                    
                    final challenge2Status = await baseRef
                        .collection('questionTwo')
                        .doc('status')
                        .get();
                    
                    final challenge3Status = await baseRef
                        .collection('questionThree')
                        .doc('status')
                        .get();

                    // If all challenges are completed, update the progress document
                    if (challenge1Status.exists && 
                        challenge2Status.exists && 
                        challenge3Status.exists) {
                      await baseRef.set({
                        'completed': true,
                        'timeElapsed': _timeElapsed,
                      }, SetOptions(merge: true));
                    }
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                } catch (error) {
                  print('Error saving progress: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save progress')),
                  );
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Add these methods after the state class declaration
  String _getDifficultyText() {
    // Get difficulty from the question if available
    final difficulty = widget.questions[0]['difficulty']?.toString().toLowerCase() ?? 'normal';
    
    // Map difficulty to display text
    switch (difficulty) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return 'Normal';
    }
  }

  Color _getDifficultyColor() {
    // Get difficulty from the question if available
    final difficulty = widget.questions[0]['difficulty']?.toString().toLowerCase() ?? 'normal';
    
    // Map difficulty to colors
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;
    final authState = ref.watch(authProvider);

    debugPrint('Questions length: ${widget.questions.length}');

    return authState.when(
      data: (AppUser? user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColor.withOpacity(0.1),
                      Colors.green.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    SubPageHeader(
                      title: widget.courseName,
                      desc: "${widget.courseName} Exercise",
                    ),
                    const SizedBox(height: 10),
                    _buildProgressIndicator(),
                    const SizedBox(height: 10),
                    _buildQuestionWidget(),
                    const SizedBox(height: 20),
                    _buildAdditionGrid(),
                    const Spacer(),
                    _buildBottomButtons(
                      themeColor,
                      user.uid,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
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

  Widget _buildBottomButtons(Color themeColor, String userId) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        // Clear All Button
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearAllWriting,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            label: const Text(
              'Clear All',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Check Answer Button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            icon: _isPredicting 
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check_circle, color: Colors.white),
            onPressed: _isPredicting ? null : () => _checkAnswer(userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            label: Text(
              _isPredicting ? 'Submitting...' : 'Submit Answer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// Update the _checkAnswer method to ensure loading state is shown correctly
Future<void> _checkAnswer(String userId) async {
  if (_isPredicting) return;

  setState(() {
    _isPredicting = true;
  });

  try {
    // Predict all digits first
    final firstDigit = await captureAndPredictDigit(_firstDigitKey, 'first_digit');
    final secondDigit = await captureAndPredictDigit(_secondDigitKey, 'second_digit');
    final thirdDigit = await captureAndPredictDigit(_thirdDigitKey, 'third_digit');
    final fourthDigit = await captureAndPredictDigit(_fourthDigitKey, 'fourth_digit');
    final answerFirstDigit = await captureAndPredictDigit(_answerFirstDigitKey, 'answer_first_digit');
    final answerSecondDigit = await captureAndPredictDigit(_answerSecondDigitKey, 'answer_second_digit');

    if (!mounted) return;

    setState(() {
      _predictedDigits = {
        'first_digit': firstDigit ?? 'N/A',
        'second_digit': secondDigit ?? 'N/A',
        'third_digit': thirdDigit ?? 'N/A',
        'fourth_digit': fourthDigit ?? 'N/A',
        'answer_first_digit': answerFirstDigit ?? 'N/A',
        'answer_second_digit': answerSecondDigit ?? 'N/A',
      };
    });

    // Now submit the answer
    _submitAnswer(userId);
  } catch (e) {
    print('Error checking answer: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prediction failed. Please try again.')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isPredicting = false;
      });
    }
  }
}
  Widget _buildProgressIndicator() {
    final totalQuestions = widget.questions.length;
    final currentQuestion = _timeElapsed + 1;

    final minutes = _timeElapsed ~/ 60;
    final seconds = _timeElapsed % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Time: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _timeElapsed > 180
                      ? Colors.red
                      : Colors.black, // Highlight if over 3 minutes
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentQuestion / totalQuestions,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.courseName == 'Addition')
                  Text(
                    'Solve the addition problem: $firstNumber + $secondNumber = ?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (widget.courseName == 'Subtraction')
                  if (firstNumber < secondNumber)
                    Text(
                      'Solve the subtraction problem: $secondNumber - $firstNumber = ?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                if (widget.courseName == 'Subtraction')
                  if (firstNumber > secondNumber)
                    Text(
                      'Solve the subtraction problem: $firstNumber - $secondNumber = ?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                if (widget.courseName == 'Multiplication')
                  Text(
                    'Solve the multiplication problem: $firstNumber x $secondNumber = ?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (widget.courseName == 'Division')
                  Text(
                    'Solve the division problem: $firstNumber ÷ $secondNumber = ?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                const Text(
                  'Write your answer in the boxes below.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDifficultyColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getDifficultyColor().withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 14,
                      color: _getDifficultyColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDifficultyText(),
                      style: TextStyle(
                        color: _getDifficultyColor(),
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
    );
  }

  Widget _buildAdditionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Row 1: [empty, first digit, second digit, empty]
            _buildGridRow([
              _buildEmptySquare(),
              _buildEditableSquare(
                  0, _firstDigitKey, Colors.blue, 'first_digit'),
              _buildEditableSquare(
                  1, _secondDigitKey, Colors.blue, 'second_digit'),
              _buildEmptySquare(),
            ]),

            // Row 2: [+, third digit, fourth digit, empty]
            _buildGridRow([
              _buildNonEditableSquare(2), // '+'
              _buildEditableSquare(
                  3, _thirdDigitKey, Colors.red, 'third_digit'),
              _buildEditableSquare(
                  4, _fourthDigitKey, Colors.red, 'fourth_digit'),
              _buildEmptySquare(),
            ]),

            // Row 3: [empty, answer first digit, answer second digit, empty]
            _buildGridRow([
              _buildNonEditableSquare(5), // '='
              _buildEditableSquare(
                  6, _answerFirstDigitKey, Colors.green, 'answer_first_digit'),
              _buildEditableSquare(7, _answerSecondDigitKey, Colors.green,
                  'answer_second_digit'),
              _buildEmptySquare(),
            ]),

            // Instructions row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Double-tap any box to clear it',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridRow(List<Widget> widgets) {
    return Row(
      children: widgets.map((w) => Expanded(child: w)).toList(),
    );
  }

  Widget _buildEmptySquare() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        ),
      ),
    );
  }

  Widget _buildNonEditableSquare(int index) {
    final square = _squares[index];
    Color textColor = Colors.black;
    double fontSize = 42;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Center(
          child: Text(
            square['content'],
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableSquare(
      int index, GlobalKey key, Color color, String position) {
    final square = _squares[index];
    final isValid = validationResults[position] ?? true;

    return RepaintBoundary(
      key: key,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isValid ? Colors.blue.withOpacity(0.3) : Colors.red,
              width: isValid ? 1 : 2,
            ),
            color: isValid ? Colors.white : Colors.red.withOpacity(0.1),
          ),
          child: GestureDetector(
            onPanDown: (details) {
              setState(() {
                // Create a new path starting with this position
                _squares[index]['paths'].add([details.localPosition]);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                // Add to the current path as the user drags
                if (_squares[index]['paths'].isNotEmpty) {
                  _squares[index]['paths'].last.add(details.localPosition);
                }
              });
            },
            onDoubleTap: () {
              _clearWriting(index);
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: WritingPainter(
                paths: List<List<Offset>>.from(square['paths']),
                color: color,
                strokeWidth: 3.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PredictionResultsDialog extends StatelessWidget {
  final Map<String, String> predictedDigits;

  const PredictionResultsDialog({
    Key? key,
    required this.predictedDigits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 12,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Digit Recognition',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),

            // Prediction Grid
            _buildPredictionGrid(),

            const SizedBox(height: 24),

            // Description
            Text(
              'These are the digits recognized by our AI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 16),

            // Close Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Understood',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionGrid() {
    // Define the order and labels for digits
    final digitPositions = [
      {'key': 'first_digit', 'label': 'First Digit'},
      {'key': 'second_digit', 'label': 'Second Digit'},
      {'key': 'third_digit', 'label': 'Third Digit'},
      {'key': 'fourth_digit', 'label': 'Fourth Digit'},
      {'key': 'answer_first_digit', 'label': 'Answer First Digit'},
      {'key': 'answer_second_digit', 'label': 'Answer Second Digit'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: digitPositions.length,
      itemBuilder: (context, index) {
        final position = digitPositions[index];
        final digit = predictedDigits[position['key']] ?? 'N/A';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                position['label']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                digit,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: digit == 'N/A'
                      ? Colors.red.shade300
                      : Colors.blue.shade800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Add this helper class at the top of the file
class NumberRangeGenerator {
  static Map<String, int> generateAdditionNumbers(String difficulty) {
    final random = Random();
    switch (difficulty.toLowerCase()) {
      case 'easy':
        // 1-digit numbers with sum not exceeding 9
        final num1 = random.nextInt(8) + 1; // 1-8
        final num2 = random.nextInt(9 - num1) + 1; // ensures sum <= 9
        return {'num1': num1, 'num2': num2};
        
      case 'medium':
        // 2-digit numbers without borrowing, sum between 10-99
        final num1 = random.nextInt(90) + 10; // 10-99
        final maxNum2 = 99 - num1; // ensure sum <= 99
        final num2 = random.nextInt(maxNum2) + 1;
        return {'num1': num1, 'num2': num2};
        
      case 'hard':
        // 2-digit numbers between 50-90 with same digits, ensuring sum < 90
        final baseDigit = random.nextInt(4) + 1; // 1-4 (to keep sum < 90)
        final num1 = baseDigit * 11; // creates numbers like 11,22,33,44
        // Calculate maximum allowed second number to keep sum < 90
        final maxSecondNum = ((89 - num1) ~/ 11) + 1;
        final num2 = (random.nextInt(maxSecondNum)) * 11; // another double digit
        return {'num1': num1, 'num2': num2};
        
      default:
        return {'num1': 5, 'num2': 3};
    }
  }

  static Map<String, int> generateSubtractionNumbers(String difficulty) {
    final random = Random();
    switch (difficulty.toLowerCase()) {
      case 'easy':
        // 1-digit numbers, result positive
        final num1 = random.nextInt(9) + 1; // 1-9
        final num2 = random.nextInt(num1) + 1; // ensures positive result
        return {'num1': num1, 'num2': num2};
        
      case 'medium':
        // 2-digit numbers without borrowing
        final num1 = random.nextInt(90) + 10; // 10-99
        final num2 = random.nextInt(num1 - 1) + 1; // ensures positive result
        return {'num1': num1, 'num2': num2};
        
      case 'hard':
        // 2-digit numbers with borrowing
        final num1 = random.nextInt(40) + 50; // 50-90
        final num2 = random.nextInt(40) + 10; // 10-50
        return {'num1': num1, 'num2': num2};
        
      default:
        return {'num1': 8, 'num2': 3};
    }
  }

  static Map<String, int> generateMultiplicationNumbers(String difficulty) {
    final random = Random();
    switch (difficulty.toLowerCase()) {
      case 'easy':
        // 1-digit numbers, product not exceeding 20
        final num1 = random.nextInt(5) + 1; // 1-5
        final num2 = random.nextInt(4) + 1; // 1-4
        return {'num1': num1, 'num2': num2};
        
      case 'medium':
        // 1-digit number times 1-digit number
        final num1 = random.nextInt(9) + 1; // 1-9
        final num2 = random.nextInt(9) + 1; // 1-9
        return {'num1': num1, 'num2': num2};
        
      case 'hard':
        // 2-digit number times 1-digit number
        final num1 = random.nextInt(90) + 10; // 10-99
        final num2 = random.nextInt(9) + 1; // 1-9
        return {'num1': num1, 'num2': num2};
        
      default:
        return {'num1': 4, 'num2': 3};
    }
  }

  static Map<String, int> generateDivisionNumbers(String difficulty) {
    final random = Random();
    switch (difficulty.toLowerCase()) {
      case 'easy':
        // Simple divisions with no remainder
        final num2 = random.nextInt(5) + 1; // 1-5 (divisor)
        final product = num2 * (random.nextInt(5) + 1); // ensures clean division
        return {'num1': product, 'num2': num2};
        
      case 'medium':
        // Divisions with single-digit divisor
        final num2 = random.nextInt(9) + 1; // 1-9 (divisor)
        final product = num2 * (random.nextInt(10) + 1); // ensures clean division
        return {'num1': product, 'num2': num2};
        
      case 'hard':
        // Divisions with two-digit dividend and single-digit divisor
        final num2 = random.nextInt(9) + 1; // 1-9 (divisor)
        final product = num2 * (random.nextInt(9) + 2); // ensures clean division
        return {'num1': product, 'num2': num2};
        
      default:
        return {'num1': 12, 'num2': 3};
    }
  }
}
