import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerbalQuestion {
  final String question;
  final String correctAnswer;
  final String difficulty;
  final int num1;
  final int num2;
  final String operation;

  VerbalQuestion({
    required this.question,
    required this.correctAnswer,
    required this.difficulty,
    required this.num1,
    required this.num2,
    required this.operation,
  });
}

Future<List<VerbalQuestion>> generateVerbalQuestions(String userId, String courseName) async {
  final List<VerbalQuestion> questions = [];
  final random = Random();

  // Get user performance
  final performanceDoc = await FirebaseFirestore.instance
      .collection('skill_assessment')
      .doc(userId)
      .collection('TestScreenType.skillAssessment')
      .doc('TestScreenType.skillAssessment')
      .get();

  final overallScore = performanceDoc.data()?['overallScore'] as num? ?? 0;
  print('Debug: overallScore = $overallScore');
  
  String performance;
  if (overallScore >= 75) {
    performance = "hard";
  } else if (overallScore >= 40) {
    performance = "medium";
  } else {
    performance = "poor";
  }
  
  print('Debug: performance level = $performance');
  print('Debug: course name = $courseName');

  // Convert courseName to operation type
  String operation;
  switch (courseName.toUpperCase()) {
    case 'ADDITION':
    case 'ADD':
      operation = 'ADDITION';
      break;
    case 'SUBTRACTION':
    case 'SUBTRACT':
      operation = 'SUBTRACTION';
      break;
    case 'MULTIPLICATION':
    case 'MULTIPLY':
      operation = 'MULTIPLICATION';
      break;
    case 'DIVISION':
    case 'DIVIDE':
      operation = 'DIVISION';
      break;
    default:
      throw Exception('Invalid course name: $courseName');
  }

  // Generate questions based on performance and operation type
  switch (performance) {
    case "hard":
      questions.add(_generateQuestion("HARD", random, operation));
      break;
    case "medium":
      questions.add(_generateQuestion("MEDIUM", random, operation));
      questions.add(_generateQuestion("HARD", random, operation));
      break;
    case "poor":
      questions.add(_generateQuestion("EASY", random, operation));
      questions.add(_generateQuestion("MEDIUM", random, operation));
      questions.add(_generateQuestion("HARD", random, operation));
      break;
  }

  print('Debug: Generated ${questions.length} questions for $operation');
  return questions;
}

VerbalQuestion _generateQuestion(String difficulty, Random random, String operation) {
  int num1, num2;

  switch (difficulty) {
    case "EASY":
      switch (operation) {
        case 'ADDITION':
          do {
            num1 = random.nextInt(5) + 1;
            num2 = random.nextInt(5) + 1;
          } while (num1 + num2 > 5);
          return VerbalQuestion(
            question: 'What is $num1 plus $num2?',
            correctAnswer: (num1 + num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'SUBTRACTION':
          do {
            num1 = random.nextInt(5) + 1;
            num2 = random.nextInt(num1) + 1;
          } while (num1 - num2 < 0);
          return VerbalQuestion(
            question: 'What is $num1 minus $num2?',
            correctAnswer: (num1 - num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'MULTIPLICATION':
          num1 = random.nextInt(3) + 1;
          num2 = random.nextInt(3) + 1;
          return VerbalQuestion(
            question: 'What is $num1 times $num2?',
            correctAnswer: (num1 * num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'DIVISION':
          num2 = random.nextInt(2) + 1;  // divisor: 1 or 2
          num1 = num2 * (random.nextInt(2) + 1);  // ensure clean division
          return VerbalQuestion(
            question: 'What is $num1 divided by $num2?',
            correctAnswer: (num1 ~/ num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        default:
          throw Exception('Invalid operation type');
      }

    case "MEDIUM":
      switch (operation) {
        case 'ADDITION':
          do {
            num1 = random.nextInt(9) + 1;
            num2 = random.nextInt(9) + 1;
          } while (num1 + num2 <= 5 || num1 + num2 >= 15);
          return VerbalQuestion(
            question: 'What is the sum of $num1 and $num2?',
            correctAnswer: (num1 + num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'SUBTRACTION':
          do {
            num1 = random.nextInt(15) + 5;
            num2 = random.nextInt(10) + 1;
          } while (num1 - num2 < 0);
          return VerbalQuestion(
            question: 'Calculate $num1 minus $num2.',
            correctAnswer: (num1 - num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'MULTIPLICATION':
          num1 = random.nextInt(3) + 3;  // 3-5
          num2 = random.nextInt(3) + 3;  // 3-5
          return VerbalQuestion(
            question: 'Multiply $num1 by $num2.',
            correctAnswer: (num1 * num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'DIVISION':
          num2 = random.nextInt(3) + 2;  // divisor: 2-4
          num1 = num2 * (random.nextInt(3) + 2);  // ensure clean division
          return VerbalQuestion(
            question: 'Divide $num1 by $num2.',
            correctAnswer: (num1 ~/ num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        default:
          throw Exception('Invalid operation type');
      }

    case "HARD":
      switch (operation) {
        case 'ADDITION':
          do {
            num1 = random.nextInt(20) + 10;
            num2 = random.nextInt(20) + 10;
          } while (num1 + num2 > 50);
          return VerbalQuestion(
            question: 'Calculate the sum of $num1 and $num2.',
            correctAnswer: (num1 + num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'SUBTRACTION':
          do {
            num1 = random.nextInt(30) + 20;
            num2 = random.nextInt(20) + 10;
          } while (num1 - num2 < 0);
          return VerbalQuestion(
            question: 'What is the difference between $num1 and $num2?',
            correctAnswer: (num1 - num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'MULTIPLICATION':
          num1 = random.nextInt(4) + 6;  // 6-9
          num2 = random.nextInt(4) + 6;  // 6-9
          return VerbalQuestion(
            question: 'What is the product of $num1 and $num2?',
            correctAnswer: (num1 * num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        case 'DIVISION':
          num2 = random.nextInt(4) + 5;  // divisor: 5-8
          num1 = num2 * (random.nextInt(4) + 5);  // ensure clean division
          return VerbalQuestion(
            question: 'What is the quotient of $num1 divided by $num2?',
            correctAnswer: (num1 ~/ num2).toString(),
            difficulty: difficulty,
            num1: num1,
            num2: num2,
            operation: operation,
          );

        default:
          throw Exception('Invalid operation type');
      }

    default:
      throw Exception('Invalid difficulty level');
  }
}