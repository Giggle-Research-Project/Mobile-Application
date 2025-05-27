import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/constants/teachers_list_constants.dart';
import 'package:giggle/core/models/teacher_model.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/services/predict_handwriting.service.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';
import 'package:giggle/features/function%2003/services/procedural_question_generator.dart';
import 'package:giggle/features/function%2003/widgets/writing_painter.dart';
import 'package:path_provider/path_provider.dart';

import 'widgets/f3_widets.dart';

class ProceduralInteractiveSession extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String dyscalculiaType;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String userId;

  const ProceduralInteractiveSession({
    Key? key,
    this.difficultyLevels,
    required this.dyscalculiaType,
    required this.courseName,
    required this.questions,
    required this.userId,
  }) : super(key: key);

  @override
  _ProceduralInteractiveSessionState createState() =>
      _ProceduralInteractiveSessionState();
}

class _ProceduralInteractiveSessionState
    extends ConsumerState<ProceduralInteractiveSession> {
  int _timeElapsed = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _squares = [];

  // To generate a single addition problem
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

  // Add new state variables
  bool _isPredicting = false;
  Map<String, String> _predictedDigits = {};

  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questionSet = [];
  List<bool> _questionResults = [false, false, false];

  // Add these state variables
  bool _isLoading = true;
  String? _loadingError;

  // Add this as a class variable
  String _currentPerformance = 'poor';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeSession();
  }

  // Add new method to handle initialization
  Future<void> _initializeSession() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingError = null;
      });

      await _setupQuestions();
      _generateCurrentProblem();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing session: $e');
      setState(() {
        _isLoading = false;
        _loadingError = 'Failed to load questions. Please try again.';
      });
    }
  }

  // Update the _getUserPerformance method to store the performance
  Future<String> _getUserPerformance() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('skill_assessment')
          .doc(widget.userId)
          .collection('TestScreenType.skillAssessment')
          .doc('TestScreenType.skillAssessment')
          .get();

      if (!doc.exists) {
        _currentPerformance = 'poor';
        return 'poor';
      }

      final overallScore = doc.data()?['overallScore'] as num? ?? 0;

      if (overallScore >= 75) {
        _currentPerformance = 'hard';
        return 'hard';
      } else if (overallScore >= 40) {
        _currentPerformance = 'medium';
        return 'medium';
      } else {
        _currentPerformance = 'poor';
        return 'poor';
      }
    } catch (e) {
      print('Error getting user performance: $e');
      _currentPerformance = 'poor';
      return 'poor'; // Default to poor on error
    }
  }

  // Modify _setupQuestions to handle errors properly
  Future<void> _setupQuestions() async {
    try {
      final performance = await _getUserPerformance();
      List<MathQuestion> questions = QuestionGenerator.generateQuestionSet(widget.courseName);

      // Filter questions based on performance level
      switch (performance) {
        case 'hard':
          _questionSet = [_convertQuestionToMap(questions[2])]; // Only hard
          _questionResults = [false];
          break;
        case 'medium':
          _questionSet = [
            _convertQuestionToMap(questions[1]),
            _convertQuestionToMap(questions[2])
          ]; // Medium and hard
          _questionResults = [false, false];
          break;
        default:
          _questionSet = questions.map((q) => _convertQuestionToMap(q)).toList();
          _questionResults = List.filled(questions.length, false);
          break;
      }
    } catch (e) {
      print('Error in _setupQuestions: $e');
      throw Exception('Failed to setup questions: $e');
    }
  }

  // Helper method to convert MathQuestion to Map
  Map<String, dynamic> _convertQuestionToMap(MathQuestion question) {
    return {
      'num1': question.num1,
      'num2': question.num2,
      'answer': question.answer,
      'difficulty': question.difficulty,
    };
  }

  void _generateCurrentProblem() {
    final currentQuestion = _questionSet[_currentQuestionIndex];
    firstNumber = currentQuestion['num1'];
    secondNumber = currentQuestion['num2'];
    correctAnswer = currentQuestion['answer']; // Use pre-calculated answer

    _initializeSquares();

    // Validate the answer based on operation type
    assert(() {
      int expectedAnswer;
      switch (widget.courseName) {
        case 'Addition':
          expectedAnswer = firstNumber + secondNumber;
          break;
        case 'Subtraction':
          expectedAnswer = firstNumber - secondNumber;
          break;
        case 'Multiplication':
          expectedAnswer = firstNumber * secondNumber;
          break;
        case 'Division':
          expectedAnswer = firstNumber ~/ secondNumber;
          break;
        default:
          expectedAnswer = correctAnswer;
      }
      assert(correctAnswer == expectedAnswer, 
        'Answer mismatch for ${widget.courseName}: expected $expectedAnswer but got $correctAnswer');
      return true;
    }());
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
          }
        else if (widget.courseName == 'Subtraction')
          {
            'index': 2,
            'content': '-',
            'paths': <List<Offset>>[],
            'editable': false,
            'position': 'minus_sign'
          }
        else if (widget.courseName == 'Multiplication')
          {
            'index': 2,
            'content': '×',
            'paths': <List<Offset>>[],
            'editable': false,
            'position': 'times_sign'
          }
        else if (widget.courseName == 'Division')
          {
            'index': 2,
            'content': '÷',
            'paths': <List<Offset>>[],
            'editable': false,
            'position': 'divide_sign'
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

  void _clearAllWriting() {
    setState(() {
      for (var square in _squares) {
        if (square['editable'] == true) {
          square['paths'] = <List<Offset>>[];
        }
      }
      // Optionally reset validation results
      validationResults.updateAll((key, value) => true);
    });
  }

  Future<String?> captureAndPredictDigit(
      GlobalKey key, String identifier) async {
    final file = await captureSquare(key, identifier);
    if (file == null) return null;
    return await predictHandwriting(file, identifier);
  }

  void _checkAnswer() async {
    try {
      // Reset validation states
      setState(() {
        validationResults = {
          'first_digit': true,
          'second_digit': true,
          'third_digit': true,
          'fourth_digit': true,
          'answer_first_digit': true,
          'answer_second_digit': true,
        };
      });

      // Capture and predict all digits
      final firstDigit = await captureAndPredictDigit(_firstDigitKey, 'first_digit');
      final secondDigit = await captureAndPredictDigit(_secondDigitKey, 'second_digit');
      final thirdDigit = await captureAndPredictDigit(_thirdDigitKey, 'third_digit');
      final fourthDigit = await captureAndPredictDigit(_fourthDigitKey, 'fourth_digit');
      final answerFirstDigit = await captureAndPredictDigit(_answerFirstDigitKey, 'answer_first_digit');
      final answerSecondDigit = await captureAndPredictDigit(_answerSecondDigitKey, 'answer_second_digit');

      // Format the inputs correctly based on number of digits
      String formattedFirstNumber = firstNumber < 10 
          ? (secondDigit ?? '') 
          : (firstDigit ?? '') + (secondDigit ?? '');

      String formattedSecondNumber = secondNumber < 10 
          ? (fourthDigit ?? '') 
          : (thirdDigit ?? '') + (fourthDigit ?? '');

      String formattedUserAnswer = correctAnswer < 10 
          ? (answerSecondDigit ?? '') 
          : (answerFirstDigit ?? '') + (answerSecondDigit ?? '');

      // Parse the formatted numbers
      int? userFirstNumber = int.tryParse(formattedFirstNumber);
      int? userSecondNumber = int.tryParse(formattedSecondNumber);
      int? userAnswer = int.tryParse(formattedUserAnswer);

      if (userFirstNumber == null || userSecondNumber == null || userAnswer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not recognize one or more digits. Please write more clearly.'),
            ),
          );
        }
        return;
      }

      // Updated validation logic
      bool numbersCorrect = userFirstNumber == firstNumber && userSecondNumber == secondNumber;
      bool answerCorrect = userAnswer == correctAnswer;
      bool isOperationCorrect = _validateOperation(userFirstNumber, userSecondNumber, userAnswer);

      // Update validation results
      setState(() {
        // For first operand
        if (firstNumber < 10) {
          validationResults['first_digit'] = true;
          validationResults['second_digit'] = userFirstNumber == firstNumber;
        } else {
          validationResults['first_digit'] = firstDigit == firstNumber.toString()[0];
          validationResults['second_digit'] = secondDigit == firstNumber.toString()[1];
        }

        // For second operand
        if (secondNumber < 10) {
          validationResults['third_digit'] = true;
          validationResults['fourth_digit'] = userSecondNumber == secondNumber;
        } else {
          validationResults['third_digit'] = thirdDigit == secondNumber.toString()[0];
          validationResults['fourth_digit'] = fourthDigit == secondNumber.toString()[1];
        }

        // For answer
        if (correctAnswer < 10) {
          validationResults['answer_first_digit'] = true;
          validationResults['answer_second_digit'] = userAnswer == correctAnswer;
        } else {
          validationResults['answer_first_digit'] = answerFirstDigit == correctAnswer.toString()[0];
          validationResults['answer_second_digit'] = answerSecondDigit == correctAnswer.toString()[1];
        }
      });

      if (mounted) {
        if (numbersCorrect && answerCorrect && isOperationCorrect) {
          _showSuccessDialog();
        } else {
          _showErrorDialog();
        }
      }
    } catch (e) {
      print('Error in _checkAnswer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    }
  }

void _showSuccessDialog() {
  if (!mounted) return;

  final isLastQuestion = _currentQuestionIndex == _questionSet.length - 1;
  final nextDifficulty = _currentQuestionIndex == 0 ? 'Medium' : 'Hard';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(
          isLastQuestion ? 'Congratulations!' : 'Great job!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isLastQuestion ? Colors.green : Colors.blue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLastQuestion ? Icons.celebration : Icons.check_circle,
              color: isLastQuestion ? Colors.green : Colors.blue,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              isLastQuestion
                  ? 'You\'ve completed all questions!'
                  : 'Correct! Moving on to $nextDifficulty difficulty',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isLastQuestion ? Colors.green : Colors.blue,
            ),
            onPressed: () async {
              // Close the dialog
              Navigator.of(dialogContext).pop();

              if (isLastQuestion) {
                // Mark current question as complete
                setState(() {
                  _questionResults[_currentQuestionIndex] = true;
                });

                // Save completion status asynchronously but don't wait for it
                _saveCompletionStatus().then((_) {
                  if (mounted) {
                    // Navigate back to the previous screen
                    Navigator.of(context).pop(); // Pop first time
                  }
                }).catchError((e) {
                  print('Error saving completion status: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to save progress, but session completed.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    // Navigate even if saving fails
                    Navigator.of(context).pop(); // Pop first time
                  }
                });
              } else {
                // Move to next question
                setState(() {
                  _questionResults[_currentQuestionIndex] = true;
                  _currentQuestionIndex++;
                  _generateCurrentProblem();
                  _clearAllWriting();
                });
              }
            },
            child: Text(
              isLastQuestion ? 'Complete' : 'Next Question',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    },
  );
}

  Future<void> _saveCompletionStatus() async {
    try {
      // Check if all questions are answered correctly
      bool allQuestionsCorrect = 
          _questionResults.every((result) => result == true);

      if (allQuestionsCorrect) {
        await FirebaseFirestore.instance
            .collection('functionActivities')
            .doc(widget.userId)
            .collection(widget.courseName)
            .doc(widget.dyscalculiaType)
            .collection('interactive_session')
            .doc('progress')
            .set({
          'completed': true,
          'timeElapsed': _timeElapsed,
          'questionResults': _questionResults,
          'completedAt': FieldValue.serverTimestamp(),
          'totalQuestions': _questionSet.length, // Add total questions count
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete all questions correctly to save progress.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving completion status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save progress. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getOperatorSymbol() {
    switch (widget.courseName) {
      case 'Addition':
        return '+';
      case 'Subtraction':
        return '-';
      case 'Multiplication':
        return '×';
      case 'Division':
        return '÷';
      default:
        return '+';
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String operatorSymbol = _getOperatorSymbol();
        String problem = '$firstNumber $operatorSymbol $secondNumber = $correctAnswer';

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
              Text(
                'The correct problem is $problem',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _predictAllDigits() {
    // Format the numbers properly
    String firstNumStr = firstNumber.toString().padLeft(2, '0');
    String secondNumStr = secondNumber.toString().padLeft(2, '0');
    String answerStr = correctAnswer.toString().padLeft(2, '0');

    setState(() {
      _isPredicting = false;
      _predictedDigits = {
        'first_digit': firstNumStr[0],
        'second_digit': firstNumStr[1],
        'third_digit': secondNumStr[0],
        'fourth_digit': secondNumStr[1],
        'answer_first_digit': answerStr[0],
        'answer_second_digit': answerStr[1],
      };
    });

    _showPredictionResultDialog();
  }

  void _showPredictionResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PredictionResultsDialog(
          predictedDigits: _predictedDigits,
          firstNumber: firstNumber,
          secondNumber: secondNumber,
          correctAnswer: correctAnswer,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loadingError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _loadingError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeSession,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
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
                            desc:
                                "${widget.courseName} Exercise",
                          ),
                          const SizedBox(height: 20),
                          TeacherAndTimerWidget(
                            timeRemaining: _timeElapsed,
                            questions: _questionSet,
                            currentQuestionIndex:
                                _currentQuestionIndex, // Add this parameter
                            performance: _currentPerformance, // Add this parameter
                          ),
                          const SizedBox(height: 30),
                          const BuildQuestionWidget(),
                          const SizedBox(height: 20),
                          _buildAdditionGrid(),
                          const Spacer(),
                          _buildBottomButtons(themeColor),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String _getDifficultyText() {
    switch (_currentQuestionIndex) {
      case 0:
        return "Easy Level";
      case 1:
        return "Medium Level";
      case 2:
        return "Hard Level";
      default:
        return "Easy Level";
    }
  }

  Widget _buildAdditionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            if (widget.courseName == 'Addition')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Write $firstNumber + $secondNumber = ?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            if (widget.courseName == 'Subtraction')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Write $firstNumber - $secondNumber = ?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            if (widget.courseName == 'Multiplication')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Write $firstNumber × $secondNumber = ?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            if (widget.courseName == 'Division')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Write $firstNumber ÷ $secondNumber = ?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
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
              _buildEmptySquare(),
              _buildEditableSquare(
                  6, _answerFirstDigitKey, Colors.green, 'answer_first_digit'),
              _buildEditableSquare(7, _answerSecondDigitKey, Colors.green,
                  'answer_second_digit'),
              _buildEmptySquare(),
            ]),

            // Row 4: [empty, empty, empty, empty]
            _buildGridRow([
              _buildEmptySquare(),
              _buildEmptySquare(),
              _buildEmptySquare(),
              _buildEmptySquare(),
            ]),
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
            child: Stack(
              children: [
                ClipRect(
                  child: GestureDetector(
                    onPanDown: (details) {
                      if (_isWithinBounds(details.localPosition)) {
                        setState(() {
                          square['paths'].add([details.localPosition]);
                        });
                      }
                    },
                    onPanUpdate: (details) {
                      if (_isWithinBounds(details.localPosition)) {
                        setState(() {
                          if (square['paths'].isNotEmpty) {
                            square['paths'].last.add(details.localPosition);
                          }
                        });
                      }
                    },
                    onPanEnd: (details) {
                      if (square['paths'].isNotEmpty &&
                          square['paths'].last.length < 2) {
                        setState(() {
                          square['paths'].removeLast();
                        });
                      }
                    },
                    onDoubleTap: () {
                      _clearWriting(index);
                    },
                    child: CustomPaint(
                      painter: WritingPainter(
                        paths: square['paths'],
                        color: color,
                        strokeWidth: 4.5,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),

                // Show expected value if validation failed
                // Show expected value if validation failed
                if (!isValid && userEnteredValues[position] != null)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getExpectedValue(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  String _getExpectedValue(String position) {
    // For first number
    if (position == 'first_digit') {
      return firstNumber < 10 ? "0" : firstNumber.toString()[0];
    } else if (position == 'second_digit') {
      return firstNumber < 10
          ? firstNumber.toString()
          : firstNumber.toString()[1];
    }

    // For second number
    else if (position == 'third_digit') {
      return secondNumber < 10 ? "0" : secondNumber.toString()[0];
    } else if (position == 'fourth_digit') {
      return secondNumber < 10
          ? secondNumber.toString()
          : secondNumber.toString()[1];
    }

    // For answer
    else if (position == 'answer_first_digit') {
      return correctAnswer < 10 ? "0" : correctAnswer.toString()[0];
    } else if (position == 'answer_second_digit') {
      return correctAnswer < 10
          ? correctAnswer.toString()
          : correctAnswer.toString()[1];
    }

    return "";
  }

  bool _isWithinBounds(Offset position) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;

    final double squareSize = size.width / 4;

    return position.dx >= 0 &&
        position.dx <= squareSize &&
        position.dy >= 0 &&
        position.dy <= squareSize;
  }

  Widget _buildBottomButtons(Color themeColor) {
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
          // Predict Digits Button
          Expanded(
            child: ElevatedButton.icon(
              icon: _isPredicting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ))
                  : const Icon(Icons.precision_manufacturing,
                      color: Colors.white),
              onPressed: _isPredicting ? null : _predictAllDigits,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              label: Text(
                _isPredicting ? 'Predicting...' : 'Predict Digits',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Check Answer Button
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              label: const Text(
                'Check Answer',
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

  bool _validateOperation(int userFirstNumber, int userSecondNumber, int userAnswer) {
    switch (widget.courseName) {
      case 'Addition':
        return userAnswer == userFirstNumber + userSecondNumber;
      case 'Subtraction':
        return userAnswer == userFirstNumber - userSecondNumber;
      case 'Multiplication':
        return userAnswer == userFirstNumber * userSecondNumber;
      case 'Division':
        return userAnswer == userFirstNumber ~/ userSecondNumber;
      default:
        return false;
    }
  }
}

// Add at the end of the file

class PredictionResultsDialog extends StatelessWidget {
  final Map<String, String> predictedDigits;
  final int firstNumber;
  final int secondNumber;
  final int correctAnswer;

  const PredictionResultsDialog({
    Key? key,
    required this.predictedDigits,
    required this.firstNumber,
    required this.secondNumber,
    required this.correctAnswer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 12,
      child: Container(
        padding: const EdgeInsets.all(18),
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
            Text(
              'Digit Recognition',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildPredictionGrid(),
            const SizedBox(height: 24),
            Text(
              'These are the expected digits for the problem.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
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
        final digit = predictedDigits[position['key']] ?? '0';

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
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
