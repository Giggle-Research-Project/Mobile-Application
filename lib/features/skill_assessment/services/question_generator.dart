import 'dart:math';
import 'package:flutter/material.dart';
import 'package:giggle/core/constants/apitude_question_constants.dart';
import 'package:giggle/core/data/question_request.dart';
import 'package:giggle/core/models/question_model.dart';

/// Handles generation of options for different question types
class OptionsGenerator {
  final Random _random = Random();

  // Helper method to ensure 2-digit numbers
  int _ensure2Digit(int number) {
    if (number < 10) {
      return number + 10 + _random.nextInt(80);
    } else if (number >= 100) {
      return 10 + _random.nextInt(89);
    }
    return number;
  }

  List<String> generateSequentialOptions(int correctNumber, int count) {
    correctNumber = _ensure2Digit(correctNumber);
    final options = <String>{correctNumber.toString()};

    while (options.length < count) {
      final offset = _random.nextInt(5) + 1;
      int option = correctNumber + (_random.nextBool() ? offset : -offset);
      option = _ensure2Digit(option);
      if (!options.contains(option.toString())) {
        options.add(option.toString());
      }
    }
    return options.toList()..shuffle();
  }

  List<String> generateOptions(String correctAnswer, int range) {
    final options = <String>{correctAnswer};
    int correctNum = int.parse(correctAnswer);
    correctNum = _ensure2Digit(correctNum);

    while (options.length < 4) {
      final offset = _random.nextInt(range) - (range ~/ 2);
      int option = correctNum + offset;
      option = _ensure2Digit(option);
      if (!options.contains(option.toString()) && option != correctNum) {
        options.add(option.toString());
      }
    }
    return options.toList()..shuffle();
  }

  List<String> generateMonthOptions(String correctMonth) {
    final options = <String>{correctMonth};
    while (options.length < 4) {
      final randomMonth = QuestionConstants.months[_random.nextInt(QuestionConstants.months.length)];
      if (!options.contains(randomMonth)) {
        options.add(randomMonth);
      }
    }
    return options.toList()..shuffle();
  }

  List<String> generateDayOptions(String correctDay) {
    final options = <String>{correctDay};
    while (options.length < 4) {
      final randomDay = QuestionConstants.days[_random.nextInt(QuestionConstants.days.length)];
      if (!options.contains(randomDay)) {
        options.add(randomDay);
      }
    }
    return options.toList()..shuffle();
  }

  List<String> generateTimeOptions(int correctHour) {
    return [
      '$correctHour:00',
      '${(correctHour % 12) + 1}:00',
      '${((correctHour + 1) % 12) + 1}:00',
      '${((correctHour + 2) % 12) + 1}:00',
    ]..shuffle();
  }

  List<String> generateNumberOptions(int correctNumber, int min, int max) {
    if (min >= 10 && max <= 99) {
      correctNumber = _ensure2Digit(correctNumber);
    }
    final options = <String>{correctNumber.toString()};
    while (options.length < 4) {
      int number = min >= 10 && max <= 99
          ? 10 + _random.nextInt(89)
          : min + _random.nextInt(max - min + 1);
      if (!options.contains(number.toString())) {
        options.add(number.toString());
      }
    }
    return options.toList()..shuffle();
  }
}

/// Generates verbal questions for different topics
class VerbalQuestionGenerator {
  final OptionsGenerator _optionsGenerator = OptionsGenerator();
  final Random _random = Random();

  Question generateVerbalQuestion(String lesson, String difficulty) {
    switch (lesson) {
      case 'NUMBERS':
        return _generateVerbalNumberQuestion(difficulty);
      case 'COMPARISON':
        return _generateVerbalComparisonQuestion(difficulty);
      case 'ODDEVEN':
        return _generateVerbalOddEvenQuestion(difficulty);
      case 'TIME':
        return _generateVerbalTimeQuestion(difficulty);
      case 'MATHWORDS':
        return _generateVerbalMathWordsQuestion(difficulty);
      default:
        throw ArgumentError('Unsupported verbal lesson type: $lesson');
    }
  }

  Question _generateVerbalNumberQuestion(String difficulty) {
    int baseNumber = _getBaseNumberForDifficulty(difficulty);
    if (_random.nextBool()) {
      final correctAnswer = (baseNumber + 1).toString();
      return Question(
        question: 'What number comes after "$baseNumber"?',
        options: _optionsGenerator.generateSequentialOptions(baseNumber + 1, 4),
        correctAnswer: correctAnswer,
      );
    } else {
      final step = _random.nextInt(3) + 2;
      final sequence = List.generate(3, (i) => baseNumber + (i * step));
      final correctAnswer = (baseNumber + (3 * step)).toString();
      return Question(
        question: 'What comes next in the sequence: ${sequence.join(", ")}?',
        options: _optionsGenerator.generateSequentialOptions(int.parse(correctAnswer), 4),
        correctAnswer: correctAnswer,
      );
    }
  }

  int _getBaseNumberForDifficulty(String difficulty) {
    return 10 + _random.nextInt(89);
  }

  Question _generateVerbalComparisonQuestion(String difficulty) {
    final nums = _generateNumberPairForDifficulty(difficulty);
    final correctAnswer = nums.$1 > nums.$2
        ? 'greater than'
        : (nums.$1 < nums.$2 ? 'less than' : 'equal to');
    return Question(
      question: 'Is ${nums.$1} greater than, less than, or equal to ${nums.$2}?',
      options: ['greater than', 'less than', 'equal to', 'none'],
      correctAnswer: correctAnswer,
    );
  }

  (int, int) _generateNumberPairForDifficulty(String difficulty) {
    if (_random.nextInt(10) < 3) {
      final number = 10 + _random.nextInt(89);
      return (number, number);
    } else {
      final num1 = 10 + _random.nextInt(89);
      int num2;
      do {
        num2 = 10 + _random.nextInt(89);
      } while (num1 == num2);
      return (num1, num2);
    }
  }

  Question _generateVerbalOddEvenQuestion(String difficulty) {
    final number = _getBaseNumberForDifficulty(difficulty);
    final correctAnswer = number % 2 == 0 ? 'even' : 'odd';
    return Question(
      question: 'Is $number an odd number or an even number?',
      options: ['odd', 'even', 'neither', 'both'],
      correctAnswer: correctAnswer,
    );
  }

  Question _generateVerbalTimeQuestion(String difficulty) {
    final hour = _random.nextInt(12) + 1;
    final previousHour = hour == 1 ? 12 : hour - 1;
    return Question(
      question: 'What time comes before $hour:00?',
      options: _optionsGenerator.generateTimeOptions(previousHour),
      correctAnswer: '$previousHour:00',
    );
  }

  Question _generateVerbalMathWordsQuestion(String difficulty) {
    final operations = [
      {'word': 'plus', 'operation': 'addition'},
      {'word': 'minus', 'operation': 'subtraction'},
      {'word': 'times', 'operation': 'multiplication'},
      {'word': 'divided by', 'operation': 'division'}
    ];
    final selectedOp = operations[_random.nextInt(operations.length)];
    return Question(
      question: 'If someone says, "1 ${selectedOp['word']} 2", what operation is that?',
      options: ['addition', 'subtraction', 'multiplication', 'division'],
      correctAnswer: selectedOp['operation'] ?? '',
    );
  }
}

/// Generates calendar-related questions (months and days)
class CalendarQuestionGenerator {
  final OptionsGenerator _optionsGenerator = OptionsGenerator();
  final Random _random = Random();

  Question generateMonthQuestion(String difficulty) {
    final questionTypes = ['after', 'before', 'between', 'days', 'position'];
    final questionType = questionTypes[_random.nextInt(questionTypes.length)];
    final selectedMonth = QuestionConstants.months[_random.nextInt(QuestionConstants.months.length)];
    switch (questionType) {
      case 'after':
        return _generateMonthAfterQuestion(selectedMonth);
      case 'before':
        return _generateMonthBeforeQuestion(selectedMonth);
      case 'between':
        return _generateMonthBetweenQuestion(selectedMonth);
      case 'days':
        return _generateMonthDaysQuestion(selectedMonth);
      case 'position':
        return _generateMonthPositionQuestion(selectedMonth);
      default:
        return generateMonthQuestion(difficulty);
    }
  }

  Question _generateMonthAfterQuestion(String selectedMonth) {
    final monthIndex = QuestionConstants.months.indexOf(selectedMonth);
    final nextMonth = QuestionConstants.months[(monthIndex + 1) % 12];
    return Question(
      question: 'What month comes after $selectedMonth?',
      options: _optionsGenerator.generateMonthOptions(nextMonth),
      correctAnswer: nextMonth,
    );
  }

  Question _generateMonthBeforeQuestion(String selectedMonth) {
    final monthIndex = QuestionConstants.months.indexOf(selectedMonth);
    final previousMonth = QuestionConstants.months[(monthIndex - 1 + 12) % 12];
    return Question(
      question: 'What month comes before $selectedMonth?',
      options: _optionsGenerator.generateMonthOptions(previousMonth),
      correctAnswer: previousMonth,
    );
  }

  Question _generateMonthBetweenQuestion(String selectedMonth) {
    final monthIndex = QuestionConstants.months.indexOf(selectedMonth);
    final nextMonth = QuestionConstants.months[(monthIndex + 2) % 12];
    final betweenMonth = QuestionConstants.months[(monthIndex + 1) % 12];
    return Question(
      question: 'Which month comes between $selectedMonth and $nextMonth?',
      options: _optionsGenerator.generateMonthOptions(betweenMonth),
      correctAnswer: betweenMonth,
    );
  }

  Question _generateMonthDaysQuestion(String selectedMonth) {
    final days = QuestionConstants.daysInMonth[selectedMonth]!;
    return Question(
      question: 'How many days are there in $selectedMonth?',
      options: _optionsGenerator.generateNumberOptions(days, 28, 31),
      correctAnswer: days.toString(),
    );
  }

  Question _generateMonthPositionQuestion(String selectedMonth) {
    final position = QuestionConstants.months.indexOf(selectedMonth) + 1;
    return Question(
      question: 'What is the position of $selectedMonth in a year?',
      options: _optionsGenerator.generateNumberOptions(position, 1, 12),
      correctAnswer: position.toString(),
    );
  }

  Question generateDayQuestion(String difficulty) {
    final questionTypes = ['after', 'before', 'between', 'position'];
    final questionType = questionTypes[_random.nextInt(questionTypes.length)];
    final selectedDay = QuestionConstants.days[_random.nextInt(QuestionConstants.days.length)];
    switch (questionType) {
      case 'after':
        return _generateDayAfterQuestion(selectedDay);
      case 'before':
        return _generateDayBeforeQuestion(selectedDay);
      case 'between':
        return _generateDayBetweenQuestion(selectedDay);
      case 'position':
        return _generateDayPositionQuestion(selectedDay);
      default:
        return generateDayQuestion(difficulty);
    }
  }

  Question _generateDayAfterQuestion(String selectedDay) {
    final dayIndex = QuestionConstants.days.indexOf(selectedDay);
    final nextDay = QuestionConstants.days[(dayIndex + 1) % 7];
    return Question(
      question: 'What day comes after $selectedDay?',
      options: _optionsGenerator.generateDayOptions(nextDay),
      correctAnswer: nextDay,
    );
  }

  Question _generateDayBeforeQuestion(String selectedDay) {
    final dayIndex = QuestionConstants.days.indexOf(selectedDay);
    final previousDay = QuestionConstants.days[(dayIndex - 1 + 7) % 7];
    return Question(
      question: 'What day comes before $selectedDay?',
      options: _optionsGenerator.generateDayOptions(previousDay),
      correctAnswer: previousDay,
    );
  }

  Question _generateDayBetweenQuestion(String selectedDay) {
    final dayIndex = QuestionConstants.days.indexOf(selectedDay);
    final nextDay = QuestionConstants.days[(dayIndex + 2) % 7];
    final betweenDay = QuestionConstants.days[(dayIndex + 1) % 7];
    return Question(
      question: 'Which day comes between $selectedDay and $nextDay?',
      options: _optionsGenerator.generateDayOptions(betweenDay),
      correctAnswer: betweenDay,
    );
  }

  Question _generateDayPositionQuestion(String selectedDay) {
    final position = QuestionConstants.days.indexOf(selectedDay) + 1;
    return Question(
      question: 'What is the position of $selectedDay in a week?',
      options: _optionsGenerator.generateNumberOptions(position, 1, 7),
      correctAnswer: position.toString(),
    );
  }
}

/// Generates time-related questions
class TimeQuestionGenerator {
  final OptionsGenerator _optionsGenerator = OptionsGenerator();
  final Random _random = Random();

  Question generateTimeQuestion(String difficulty) {
    final questionTypes = ['duration', 'next_hour', 'previous_hour', 'conversion'];
    final questionType = questionTypes[_random.nextInt(questionTypes.length)];
    switch (questionType) {
      case 'duration':
        return _generateTimeDurationQuestion();
      case 'next_hour':
        return _generateNextHourQuestion();
      case 'previous_hour':
        return _generatePreviousHourQuestion();
      case 'conversion':
        return _generateTimeConversionQuestion();
      default:
        return generateTimeQuestion(difficulty);
    }
  }

  Question _generateTimeDurationQuestion() {
    final hour = _random.nextInt(12) + 1;
    final nextHour = (hour % 12) + 1;
    return Question(
      question: 'How much time is there between $hour:00 and $nextHour:00?',
      options: ['1 hour', '2 hours', '30 minutes', '45 minutes'],
      correctAnswer: '1 hour',
    );
  }

  Question _generateNextHourQuestion() {
    final hour = _random.nextInt(12) + 1;
    final nextHour = (hour % 12) + 1;
    return Question(
      question: 'What time comes after $hour:00?',
      options: _optionsGenerator.generateTimeOptions(nextHour),
      correctAnswer: '$nextHour:00',
    );
  }

  Question _generatePreviousHourQuestion() {
    final hour = _random.nextInt(12) + 1;
    final prevHour = ((hour - 2 + 12) % 12) + 1;
    return Question(
      question: 'What time comes before $hour:00?',
      options: _optionsGenerator.generateTimeOptions(prevHour),
      correctAnswer: '$prevHour:00',
    );
  }

  Question _generateTimeConversionQuestion() {
    return Question(
      question: 'How many minutes are in a quarter of an hour?',
      options: ['5 minutes', '10 minutes', '15 minutes', '20 minutes'],
      correctAnswer: '15 minutes',
    );
  }
}

/// Generates procedural math questions
class ProceduralQuestionGenerator {
  final OptionsGenerator _optionsGenerator = OptionsGenerator();
  final Random _random = Random();

  int _ensure2Digit(int number) {
    if (number < 10) {
      return number + 10 + _random.nextInt(80);
    } else if (number >= 100) {
      return 10 + _random.nextInt(89);
    }
    return number;
  }

  Question generateProceduralQuestion(String lesson, String difficulty) {
    String questionText;
    List<String> options;
    int num1 = 10 + _random.nextInt(40); // 10-49
    int num2 = 10 + _random.nextInt(40); // 10-49
    int correctNum;

    switch (lesson) {
      case 'ADDITION':
        correctNum = num1 + num2;
        if (correctNum >= 100) {
          num1 = _random.nextInt(40) + 10;
          num2 = _random.nextInt(40) + 10;
          correctNum = num1 + num2;
        }
        questionText = 'What is $num1 + $num2?';
        break;
      case 'SUBTRACTION':
        if (num1 <= num2) {
          int temp = num1;
          num1 = num2;
          num2 = temp;
        }
        correctNum = num1 - num2;
        if (correctNum < 10) {
          num1 = 50 + _random.nextInt(40);
          num2 = 10 + _random.nextInt(30);
          correctNum = num1 - num2;
        }
        questionText = 'What is $num1 - $num2?';
        break;
      case 'MULTIPLICATION':
        num1 = 2 + _random.nextInt(7);
        num2 = 5 + _random.nextInt(6);
        correctNum = num1 * num2;
        questionText = 'What is $num1 × $num2?';
        break;
      case 'DIVISION':
        num2 = 2 + _random.nextInt(5);
        correctNum = 10 + _random.nextInt(90 ~/ num2);
        num1 = correctNum * num2;
        questionText = 'What is $num1 ÷ $num2?';
        break;
      default:
        throw ArgumentError('Unsupported lesson type: $lesson');
    }

    String correctAnswer = correctNum.toString();
    options = _optionsGenerator.generateOptions(correctAnswer, _getDifficultyRange(difficulty));

    return Question(
      question: questionText,
      options: options,
      correctAnswer: correctAnswer,
    );
  }

  int _getDifficultyRange(String difficulty) {
    switch (difficulty) {
      case 'EASY':
        return 10;
      case 'MEDIUM':
        return 20;
      case 'HARD':
        return 30;
      default:
        return 20;
    }
  }
}

/// Generates semantic questions
class SemanticQuestionGenerator {
  final OptionsGenerator _optionsGenerator = OptionsGenerator();
  final Random _random = Random();

  Question generateSemanticQuestion(String lesson, String difficulty) {
    switch (lesson) {
      case 'ADDITION':
      case 'SUBTRACTION':
      case 'MULTIPLICATION':
      case 'DIVISION':
        return _generateSemanticMathQuestion(lesson, difficulty);
      case 'NUMBERS':
        return _generateSemanticNumberQuestion(difficulty);
      case 'COMPARISON':
        return _generateSemanticComparisonQuestion(difficulty);
      case 'ODDEVEN':
        return _generateSemanticOddEvenQuestion(difficulty);
      case 'DAYS':
        return _generateSemanticDayQuestion(difficulty);
      case 'MONTHS':
        return _generateSemanticMonthQuestion(difficulty);
      case 'FRACTION':
        return _generateSemanticFractionQuestion(difficulty);
      default:
        throw ArgumentError('Unsupported semantic lesson type: $lesson');
    }
  }

  Question _generateSemanticMathQuestion(String lesson, String difficulty) {
    int num1 = 10 + _random.nextInt(40);
    int num2 = 10 + _random.nextInt(40);
    int correctNum;
    String operation;
    switch (lesson) {
      case 'ADDITION':
        correctNum = num1 + num2;
        operation = 'added to';
        break;
      case 'SUBTRACTION':
        if (num1 < num2) {
          int temp = num1;
          num1 = num2;
          num2 = temp;
        }
        correctNum = num1 - num2;
        operation = 'taken from';
        break;
      case 'MULTIPLICATION':
        num1 = 2 + _random.nextInt(7);
        num2 = 5 + _random.nextInt(6);
        correctNum = num1 * num2;
        operation = 'multiplied by';
        break;
      case 'DIVISION':
        num2 = 2 + _random.nextInt(5);
        correctNum = 10 + _random.nextInt(90 ~/ num2);
        num1 = correctNum * num2;
        operation = 'divided by';
        break;
      default:
        throw ArgumentError('Invalid lesson');
    }
    final questionText = 'If $num2 is $operation $num1, what is the result?';
    return Question(
      question: questionText,
      options: _optionsGenerator.generateOptions(correctNum.toString(), _getDifficultyRange(difficulty)),
      correctAnswer: correctNum.toString(),
    );
  }

  Question _generateSemanticNumberQuestion(String difficulty) {
    final baseNumber = 10 + _random.nextInt(89);
    final correctAnswer = baseNumber.toString();
    return Question(
      question: 'Which number is represented by "$baseNumber"?',
      options: _optionsGenerator.generateOptions(correctAnswer, _getDifficultyRange(difficulty)),
      correctAnswer: correctAnswer,
    );
  }

  Question _generateSemanticComparisonQuestion(String difficulty) {
    final nums = _generateNumberPair();
    final correctAnswer = nums.$1 > nums.$2 ? 'more' : (nums.$1 < nums.$2 ? 'less' : 'same');
    return Question(
      question: 'Does ${nums.$1} represent more, less, or the same as ${nums.$2}?',
      options: ['more', 'less', 'same', 'none'],
      correctAnswer: correctAnswer,
    );
  }

  Question _generateSemanticOddEvenQuestion(String difficulty) {
    final number = 10 + _random.nextInt(89);
    final correctAnswer = number % 2 == 0 ? 'even' : 'odd';
    return Question(
      question: 'The number $number is:',
      options: ['odd', 'even', 'prime', 'composite'],
      correctAnswer: correctAnswer,
    );
  }

  Question _generateSemanticDayQuestion(String difficulty) {
    final selectedDay = QuestionConstants.days[_random.nextInt(QuestionConstants.days.length)];
    final dayIndex = QuestionConstants.days.indexOf(selectedDay);
    final nextDay = QuestionConstants.days[(dayIndex + 1) % 7];
    return Question(
      question: 'The day after $selectedDay is:',
      options: _optionsGenerator.generateDayOptions(nextDay),
      correctAnswer: nextDay,
    );
  }

  Question _generateSemanticMonthQuestion(String difficulty) {
    final selectedMonth = QuestionConstants.months[_random.nextInt(QuestionConstants.months.length)];
    final days = QuestionConstants.daysInMonth[selectedMonth]!;
    return Question(
      question: 'How many days are in $selectedMonth?',
      options: _optionsGenerator.generateNumberOptions(days, 28, 31),
      correctAnswer: days.toString(),
    );
  }

  Question _generateSemanticFractionQuestion(String difficulty) {
    final denominator = 2 + _random.nextInt(5);
    final numerator = 1 + _random.nextInt(denominator - 1);
    final correctAnswer = '$numerator/$denominator';
    return Question(
      question: 'What fraction represents $numerator out of $denominator equal parts?',
      options: _generateFractionOptions(correctAnswer),
      correctAnswer: correctAnswer,
    );
  }

  List<String> _generateFractionOptions(String correctAnswer) {
    final options = <String>{correctAnswer};
    while (options.length < 4) {
      final denominator = 2 + _random.nextInt(5);
      final numerator = 1 + _random.nextInt(denominator - 1);
      final fraction = '$numerator/$denominator';
      if (!options.contains(fraction)) {
        options.add(fraction);
      }
    }
    return options.toList()..shuffle();
  }

  (int, int) _generateNumberPair() {
    if (_random.nextInt(10) < 3) {
      final number = 10 + _random.nextInt(89);
      return (number, number);
    } else {
      final num1 = 10 + _random.nextInt(89);
      int num2;
      do {
        num2 = 10 + _random.nextInt(89);
      } while (num1 == num2);
      return (num1, num2);
    }
  }

  int _getDifficultyRange(String difficulty) {
    switch (difficulty) {
      case 'EASY':
        return 10;
      case 'MEDIUM':
        return 20;
      case 'HARD':
        return 30;
      default:
        return 20;
    }
  }
}

/// Main question generator class that coordinates all other generators
class QuestionGenerator {
  final VerbalQuestionGenerator _verbalGenerator = VerbalQuestionGenerator();
  final CalendarQuestionGenerator _calendarGenerator = CalendarQuestionGenerator();
  final TimeQuestionGenerator _timeGenerator = TimeQuestionGenerator();
  final ProceduralQuestionGenerator _proceduralGenerator = ProceduralQuestionGenerator();
  final SemanticQuestionGenerator _semanticGenerator = SemanticQuestionGenerator();

  void _printQuestionDetails(Map<String, String> request, Question question) {
    print('Generated Question:');
    print('Type: ${request['dyscalculia_type']}');
    print('Lesson: ${request['lesson']}');
    print('Difficulty: ${request['difficulty']}');
    print('Question: ${question.question}');
    print('Options: ${question.options}');
    print('Correct Answer: ${question.correctAnswer}');
    print('-------------------');
  }

  Question? _generateSingleQuestion(Map<String, String> request) {
    try {
      final dyscalculiaType = request['dyscalculia_type'];
      final lesson = request['lesson'] ?? '';
      final difficulty = request['difficulty'] ?? 'EASY';

      Question question;

      if (lesson == 'MONTHS') {
        question = _calendarGenerator.generateMonthQuestion(difficulty);
      } else if (lesson == 'DAYS') {
        question = _calendarGenerator.generateDayQuestion(difficulty);
      } else if (lesson == 'TIME' && dyscalculiaType != 'VERBAL') {
        question = _timeGenerator.generateTimeQuestion(difficulty);
      } else if (dyscalculiaType == 'VERBAL') {
        question = _verbalGenerator.generateVerbalQuestion(lesson, difficulty);
      } else if (dyscalculiaType == 'PROCEDURAL') {
        question = _proceduralGenerator.generateProceduralQuestion(lesson, difficulty);
      } else if (dyscalculiaType == 'SEMANTIC') {
        question = _semanticGenerator.generateSemanticQuestion(lesson, difficulty);
      } else {
        throw ArgumentError('Unsupported question type: $dyscalculiaType');
      }

      _printQuestionDetails(request, question);
      return question;
    } catch (e) {
      print('Error generating question: $e');
      return null;
    }
  }

  Future<List<Question>> generateQuestions(BuildContext context) async {
    List<Question> questions = [];

    for (var request in questionRequests) {
      if (!context.mounted) return questions;

      final question = _generateSingleQuestion(request);
      if (question != null) {
        questions.add(question);
      } else {
        throw Exception('Failed to generate question for request: $request');
      }
    }

    return questions;
  }
}