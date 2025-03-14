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
import 'package:giggle/features/function%2003/widgets/writing_painter.dart';
import 'package:path_provider/path_provider.dart';

import 'widgets/f3_widets.dart';

class ProceduralInteractiveSession extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String dyscalculiaType;
  final String selectedTeacher;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String userId;

  const ProceduralInteractiveSession({
    Key? key,
    this.difficultyLevels,
    required this.dyscalculiaType,
    required this.selectedTeacher,
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

  late TeacherCharacter selectedTeacher;

  // Keys for each editable square
  final GlobalKey _firstDigitKey = GlobalKey();
  final GlobalKey _secondDigitKey = GlobalKey();
  final GlobalKey _thirdDigitKey = GlobalKey();
  final GlobalKey _fourthDigitKey = GlobalKey();
  final GlobalKey _answerFirstDigitKey = GlobalKey();
  final GlobalKey _answerSecondDigitKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _generateProblem();
    _initializeSquares();
    selectedTeacher = teachers.firstWhere(
      (teacher) => teacher.name == widget.selectedTeacher,
      orElse: () => teachers[0],
    );
  }

  void _generateProblem() {
    firstNumber = widget.questions[0]['num1'];
    secondNumber = widget.questions[0]['num2'];

    if (widget.courseName == 'Addition') {
      correctAnswer = firstNumber + secondNumber;
    } else if (widget.courseName == 'Subtraction') {
      correctAnswer = firstNumber - secondNumber;
    } else if (widget.courseName == 'Multiplication') {
      correctAnswer = firstNumber * secondNumber;
    } else if (widget.courseName == 'Division') {
      correctAnswer = firstNumber ~/ secondNumber;
    }

    validationResults = {
      'first_digit': true,
      'second_digit': true,
      'third_digit': true,
      'fourth_digit': true,
      'answer_first_digit': true,
      'answer_second_digit': true,
    };
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

      // Store the user inputs for validation
      userEnteredValues = {
        'first_digit': firstDigit,
        'second_digit': secondDigit,
        'third_digit': thirdDigit,
        'fourth_digit': fourthDigit,
        'answer_first_digit': answerFirstDigit,
        'answer_second_digit': answerSecondDigit,
      };

      print('First number: ${(firstDigit ?? '') + (secondDigit ?? '')}');
      print('Second number: ${(thirdDigit ?? '') + (fourthDigit ?? '')}');
      print(
          'User answer: ${(answerFirstDigit ?? '') + (answerSecondDigit ?? '')}');

      // Format the inputs correctly based on number of digits
      String formattedFirstNumber = "";
      String formattedSecondNumber = "";
      String formattedUserAnswer = "";

      // Handle first number (could be 1 or 2 digits)
      if (firstNumber < 10) {
        // Single digit number - should be in second position only
        formattedFirstNumber = (secondDigit ?? '');
      } else {
        // Double digit number
        formattedFirstNumber = (firstDigit ?? '') + (secondDigit ?? '');
      }

      // Handle second number (could be 1 or 2 digits)
      if (secondNumber < 10) {
        // Single digit number - should be in fourth position only
        formattedSecondNumber = (fourthDigit ?? '');
      } else {
        // Double digit number
        formattedSecondNumber = (thirdDigit ?? '') + (fourthDigit ?? '');
      }

      // Handle answer (could be 1, 2, or 3 digits)
      if (answerFirstDigit == '0' || answerFirstDigit == '') {
        formattedUserAnswer = (answerSecondDigit ?? '');
      } else {
        formattedUserAnswer =
            (answerFirstDigit ?? '') + (answerSecondDigit ?? '');
      }

      // Parse the formatted numbers
      int? userFirstNumber = int.tryParse(formattedFirstNumber);
      int? userSecondNumber = int.tryParse(formattedSecondNumber);
      int? userAnswer = int.tryParse(formattedUserAnswer);

      if (userFirstNumber == null ||
          userSecondNumber == null ||
          userAnswer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not recognize one or more digits. Please write more clearly.')),
          );
        }
        return;
      }

      // Validate if user wrote the correct numbers
      bool isOperandCorrect =
          userFirstNumber == firstNumber && userSecondNumber == secondNumber;
      bool isAnswerCorrect = userAnswer == correctAnswer;

      // Update validation results
      setState(() {
        // For first operand
        if (firstNumber < 10) {
          // Single digit
          validationResults['first_digit'] =
              firstDigit == '0' || firstDigit == '' || firstDigit == null;
          validationResults['second_digit'] =
              secondDigit == firstNumber.toString();
        } else {
          // Double digit
          validationResults['first_digit'] =
              firstDigit == firstNumber.toString()[0];
          validationResults['second_digit'] =
              secondDigit == firstNumber.toString()[1];
        }

        // For second operand
        if (secondNumber < 10) {
          // Single digit
          validationResults['third_digit'] =
              thirdDigit == '0' || thirdDigit == '' || thirdDigit == null;
          validationResults['fourth_digit'] =
              fourthDigit == secondNumber.toString();
        } else {
          // Double digit
          validationResults['third_digit'] =
              thirdDigit == secondNumber.toString()[0];
          validationResults['fourth_digit'] =
              fourthDigit == secondNumber.toString()[1];
        }

        // For answer
        if (correctAnswer < 10) {
          // Single digit answer
          validationResults['answer_first_digit'] = answerFirstDigit == '0' ||
              answerFirstDigit == '' ||
              answerFirstDigit == null;
          validationResults['answer_second_digit'] =
              answerSecondDigit == correctAnswer.toString();
        } else if (correctAnswer < 100) {
          // Double digit answer
          validationResults['answer_first_digit'] =
              answerFirstDigit == correctAnswer.toString()[0];
          validationResults['answer_second_digit'] =
              answerSecondDigit == correctAnswer.toString()[1];
        } else {
          // Triple digit answer - need to handle separately if needed
          validationResults['answer_first_digit'] =
              answerFirstDigit == correctAnswer.toString()[0];
          validationResults['answer_second_digit'] =
              answerSecondDigit == correctAnswer.toString()[1];
        }
      });

      if (mounted) {
        if (isOperandCorrect && isAnswerCorrect) {
          _showSuccessDialog();
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
          }, SetOptions(merge: true));
        } else {
          _showErrorDialog();
        }
      }
    } catch (e) {
      print('Error in _checkAnswer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  void _showSuccessDialog() {
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
              const Text(
                'You solved the problem correctly!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.courseName == 'Addition')
                Text(
                  '$firstNumber + $secondNumber = $correctAnswer',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.courseName == 'Subtraction')
                Text(
                  '$firstNumber - $secondNumber = $correctAnswer',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.courseName == 'Multiplication')
                Text(
                  '$firstNumber × $secondNumber = $correctAnswer',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.courseName == 'Division')
                Text(
                  '$firstNumber ÷ $secondNumber = $correctAnswer',
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
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Complete', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
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
              if (widget.courseName == 'Addition')
                Text(
                  'The correct problem is $firstNumber + $secondNumber = $correctAnswer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.courseName == 'Subtraction')
                Text(
                  'The correct problem is $firstNumber - $secondNumber = $correctAnswer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.courseName == 'Multiplication')
                Text(
                  'The correct problem is $firstNumber × $secondNumber = $correctAnswer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.courseName == 'Division')
                Text(
                  'The correct problem is $firstNumber ÷ $secondNumber = $correctAnswer',
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ],
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
                  desc: widget.courseName + " Exercise",
                ),
                const SizedBox(height: 20),
                TeacherAndTimerWidget(
                  selectedTeacher: selectedTeacher.name,
                  avatar: selectedTeacher.avatar,
                  timeRemaining: _timeElapsed,
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
      ),
    );
  }

  String _getExpectedValue(String position) {
    // For first number
    if (position == 'first_digit') {
      return firstNumber < 10 ? "" : firstNumber.toString()[0];
    } else if (position == 'second_digit') {
      return firstNumber < 10
          ? firstNumber.toString()
          : firstNumber.toString()[1];
    }

    // For second number
    else if (position == 'third_digit') {
      return secondNumber < 10 ? "" : secondNumber.toString()[0];
    } else if (position == 'fourth_digit') {
      return secondNumber < 10
          ? secondNumber.toString()
          : secondNumber.toString()[1];
    }

    // For answer
    else if (position == 'answer_first_digit') {
      return correctAnswer < 10 ? "" : correctAnswer.toString()[0];
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Clear All Button
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
            onPressed: () {
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
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Check Answer Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _checkAnswer,
            child: const Text(
              'Check Answer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
