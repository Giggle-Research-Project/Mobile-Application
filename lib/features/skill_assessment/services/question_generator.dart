import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:giggle/core/constants/apitude_question_constants.dart';
import 'package:giggle/core/data/question_request.dart';
import 'package:giggle/core/models/question_model.dart';
import 'package:http/http.dart' as http;

/// Handles generation of options for different question types
class OptionsGenerator {
  final Random _random = Random();

  List<String> generateSequentialOptions(int correctNumber, int count) {
    final options = <String>{correctNumber.toString()};

    while (options.length < count) {
      final offset = _random.nextInt(5) + 1;
      final option =
          (correctNumber + (_random.nextBool() ? offset : -offset)).toString();
      if (!options.contains(option) && int.parse(option) > 0) {
        options.add(option);
      }
    }

    return options.toList()..shuffle();
  }

  List<String> generateOptions(String correctAnswer, int range) {
    final options = <String>{correctAnswer};
    final correctNum = int.parse(correctAnswer);

    while (options.length < 4) {
      final offset = _random.nextInt(range) - (range ~/ 2);
      final option = (correctNum + offset).toString();

      if (!options.contains(option) &&
          (option != correctAnswer) &&
          int.parse(option) > 0) {
        options.add(option);
      }
    }

    return options.toList()..shuffle();
  }

  List<String> generateMonthOptions(String correctMonth) {
    final options = <String>{correctMonth};
    while (options.length < 4) {
      final randomMonth = QuestionConstants
          .months[_random.nextInt(QuestionConstants.months.length)];
      if (!options.contains(randomMonth)) {
        options.add(randomMonth);
      }
    }
    return options.toList()..shuffle();
  }

  List<String> generateDayOptions(String correctDay) {
    final options = <String>{correctDay};
    while (options.length < 4) {
      final randomDay = QuestionConstants
          .days[_random.nextInt(QuestionConstants.days.length)];
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
    final options = <String>{correctNumber.toString()};

    while (options.length < 4) {
      final number = min + _random.nextInt(max - min + 1);
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
        options: _optionsGenerator.generateSequentialOptions(
            int.parse(correctAnswer), 4),
        correctAnswer: correctAnswer,
      );
    }
  }

  int _getBaseNumberForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'EASY':
        return _random.nextInt(50) + 1;
      case 'MEDIUM':
        return _random.nextInt(100) + 1;
      case 'HARD':
        return _random.nextInt(1000) + 1;
      default:
        return _random.nextInt(50) + 1;
    }
  }

  Question _generateVerbalComparisonQuestion(String difficulty) {
    final nums = _generateNumberPairForDifficulty(difficulty);
    final correctAnswer = nums.$1 > nums.$2
        ? 'greater than'
        : (nums.$1 < nums.$2 ? 'less than' : 'equal to');

    return Question(
      question:
          'Is ${nums.$1} greater than, less than, or equal to ${nums.$2}?',
      options: ['greater than', 'less than', 'equal to', 'none'],
      correctAnswer: correctAnswer,
    );
  }

  (int, int) _generateNumberPairForDifficulty(String difficulty) {
    final range = difficulty == 'EASY'
        ? 50
        : difficulty == 'MEDIUM'
            ? 100
            : 1000;
    return (_random.nextInt(range) + 1, _random.nextInt(range) + 1);
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
      question:
          'If someone says, "1 ${selectedOp['word']} 2", what operation is that?',
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
    final selectedMonth = QuestionConstants
        .months[_random.nextInt(QuestionConstants.months.length)];

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
    final selectedDay =
        QuestionConstants.days[_random.nextInt(QuestionConstants.days.length)];

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
    final questionTypes = [
      'duration',
      'next_hour',
      'previous_hour',
      'conversion'
    ];
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

/// Handles generation of procedural math questions
class ProceduralQuestionGenerator {
  final OptionsGenerator _optionsGenerator = OptionsGenerator();

  Question generateProceduralQuestion(
      List<dynamic> questionData, String lesson, String difficulty) {
    String correctAnswer;
    String questionText;
    List<String> options;

    final strData = questionData.map((e) => e.toString()).toList();

    switch (lesson) {
      case 'ADDITION':
        correctAnswer = strData[2];
        questionText = 'What is ${strData[0]} + ${strData[1]}?';
        options = _optionsGenerator.generateOptions(
            correctAnswer, _getDifficultyRange(difficulty));
        break;
      case 'SUBTRACTION':
        correctAnswer = strData[2];
        questionText = 'What is ${strData[0]} - ${strData[1]}?';
        options = _optionsGenerator.generateOptions(
            correctAnswer, _getDifficultyRange(difficulty));
        break;
      case 'MULTIPLICATION':
        correctAnswer = strData[2];
        questionText = 'What is ${strData[0]} × ${strData[1]}?';
        options = _optionsGenerator.generateOptions(
            correctAnswer, _getDifficultyRange(difficulty));
        break;
      case 'DIVISION':
        correctAnswer = strData[2];
        questionText = 'What is ${strData[0]} ÷ ${strData[1]}?';
        options = _optionsGenerator.generateOptions(
            correctAnswer, _getDifficultyRange(difficulty));
        break;
      default:
        throw ArgumentError('Unsupported lesson type: $lesson');
    }

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

/// Main question generator class that coordinates all other generators
class QuestionGenerator {
  final VerbalQuestionGenerator _verbalGenerator = VerbalQuestionGenerator();
  final CalendarQuestionGenerator _calendarGenerator =
      CalendarQuestionGenerator();
  final TimeQuestionGenerator _timeGenerator = TimeQuestionGenerator();
  final ProceduralQuestionGenerator _proceduralGenerator =
      ProceduralQuestionGenerator();

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

  Future<Question?> _generateSingleQuestion(Map<String, String> request) async {
    final mlIP = dotenv.env['MLIP']?.isEmpty ?? true
        ? dotenv.env['DEFAULT_MLIP']
        : dotenv.env['MLIP'];

    if (mlIP == null) {
      throw Exception('ML server IP not configured');
    }

    try {
      // Handle special question types
      if (request['lesson'] == 'MONTHS') {
        final question = _calendarGenerator
            .generateMonthQuestion(request['difficulty'] ?? 'EASY');
        _printQuestionDetails(request, question);
        return question;
      }
      if (request['lesson'] == 'DAYS') {
        final question = _calendarGenerator
            .generateDayQuestion(request['difficulty'] ?? 'EASY');
        _printQuestionDetails(request, question);
        return question;
      }
      if (request['lesson'] == 'TIME') {
        final question = _timeGenerator
            .generateTimeQuestion(request['difficulty'] ?? 'EASY');
        _printQuestionDetails(request, question);
        return question;
      }

      // Check for verbal questions
      if (request['dyscalculia_type'] == 'VERBAL') {
        final question = _verbalGenerator.generateVerbalQuestion(
          request['lesson'] ?? '',
          request['difficulty'] ?? 'EASY',
        );
        _printQuestionDetails(request, question);
        return question;
      }

      // For other types, use ML server
      final uri = Uri.parse('http://$mlIP:8000/generate-question');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        Question question;

        if (request['dyscalculia_type'] == 'PROCEDURAL') {
          question = _proceduralGenerator.generateProceduralQuestion(
            jsonResponse['question'],
            request['lesson']!,
            request['difficulty']!,
          );
        } else {
          question = Question.fromJson(jsonResponse);
        }

        _printQuestionDetails(request, question);
        return question;
      } else {
        print('Failed to generate question: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error generating question: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<Question>> generateQuestions(BuildContext context) async {
    List<Question> questions = [];

    for (var i = 0; i < questionRequests.length; i++) {
      if (!context.mounted) return questions;

      final question = await _generateSingleQuestion(questionRequests[i]);
      if (question != null) {
        questions.add(question);
      } else {
        throw Exception('Failed to generate question ${i + 1}');
      }
    }

    return questions;
  }
}
