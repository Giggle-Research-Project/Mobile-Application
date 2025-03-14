// Function to generate questions based on operation and difficulty levels
import 'dart:math';

List<Map<String, dynamic>> generatePersonalizedQuestions(
    String operation, Map<String, String>? difficultyLevels) {
  if (difficultyLevels == null) return [];

  // Convert operation to uppercase for consistency
  final lessonType = operation.toUpperCase();

  // Get the difficulty levels for each dyscalculia type
  final proceduralDifficulty = difficultyLevels['procedural'] ?? 'EASY';
  final semanticDifficulty = difficultyLevels['semantic'] ?? 'EASY';
  final verbalDifficulty = difficultyLevels['verbal'] ?? 'EASY';

  List<Map<String, dynamic>> generatedQuestions = [];

  // Generate Procedural Questions
  generatedQuestions
      .addAll(_generateProceduralQuestions(lessonType, proceduralDifficulty));

  // Generate Semantic Questions
  generatedQuestions
      .addAll(_generateSemanticQuestions(lessonType, semanticDifficulty));

  // Generate Verbal Questions
  generatedQuestions
      .addAll(_generateVerbalQuestions(lessonType, verbalDifficulty));

  return generatedQuestions;
}

// Function to generate procedural questions
List<Map<String, dynamic>> _generateProceduralQuestions(
    String operation, String difficulty) {
  final List<Map<String, dynamic>> questions = [];

  // Generate 3 questions for the specified operation and difficulty
  for (int i = 0; i < 1; i++) {
    Map<String, dynamic> question = {};

    switch (operation) {
      case 'ADDITION':
        question = _generateAdditionQuestion(difficulty, 'PROCEDURAL');
        break;
      case 'SUBTRACTION':
        question = _generateSubtractionQuestion(difficulty, 'PROCEDURAL');
        break;
      case 'MULTIPLICATION':
        question = _generateMultiplicationQuestion(difficulty, 'PROCEDURAL');
        break;
      case 'DIVISION':
        question = _generateDivisionQuestion(difficulty, 'PROCEDURAL');
        break;
    }

    if (question.isNotEmpty) {
      questions.add(question);
    }
  }

  return questions;
}

// Function to generate semantic questions
List<Map<String, dynamic>> _generateSemanticQuestions(
    String operation, String difficulty) {
  final List<Map<String, dynamic>> questions = [];

  // Generate 2 questions for the specified operation and difficulty
  for (int i = 0; i < 1; i++) {
    Map<String, dynamic> question = {};

    switch (operation) {
      case 'ADDITION':
        question = _generateAdditionQuestion(difficulty, 'SEMANTIC');
        break;
      case 'SUBTRACTION':
        question = _generateSubtractionQuestion(difficulty, 'SEMANTIC');
        break;
      case 'MULTIPLICATION':
        question = _generateMultiplicationQuestion(difficulty, 'SEMANTIC');
        break;
      case 'DIVISION':
        question = _generateDivisionQuestion(difficulty, 'SEMANTIC');
        break;
    }

    if (question.isNotEmpty) {
      questions.add(question);
    }
  }

  return questions;
}

// Function to generate verbal questions
List<Map<String, dynamic>> _generateVerbalQuestions(
    String operation, String difficulty) {
  final List<Map<String, dynamic>> questions = [];

  // Generate 1 verbal question if applicable
  if (difficulty != 'HARD' || operation == 'ADDITION') {
    Map<String, dynamic> question = {};

    switch (operation) {
      case 'ADDITION':
        question = _generateAdditionQuestion(difficulty, 'VERBAL');
        break;
      case 'SUBTRACTION':
        question = _generateSubtractionQuestion(difficulty, 'VERBAL');
        break;
      case 'MULTIPLICATION':
        question = _generateMultiplicationQuestion(difficulty, 'VERBAL');
        break;
      case 'DIVISION':
        question = _generateDivisionQuestion(difficulty, 'VERBAL');
        break;
    }

    if (question.isNotEmpty) {
      questions.add(question);
    }
  }

  return questions;
}

// Helper function to generate random options around a correct answer
List<String> _generateOptions(dynamic correctAnswer, String difficulty) {
  final random = Random();
  int correctInt;

  if (correctAnswer is int) {
    correctInt = correctAnswer;
  } else if (correctAnswer is double) {
    return [
      (correctAnswer - 0.2).toStringAsFixed(1),
      correctAnswer.toStringAsFixed(1),
      (correctAnswer + 0.2).toStringAsFixed(1),
      (correctAnswer + 0.4).toStringAsFixed(1)
    ]..shuffle();
  } else {
    // For non-numeric answers, return predefined options
    return [
      correctAnswer.toString(),
      'Wrong Option 1',
      'Wrong Option 2',
      'Wrong Option 3'
    ]..shuffle();
  }

  // Determine range of wrong answers based on difficulty
  int range;
  switch (difficulty) {
    case 'EASY':
      range = 2;
      break;
    case 'MEDIUM':
      range = 3;
      break;
    case 'HARD':
      range = 5;
      break;
    default:
      range = 2;
  }

  // Generate options around the correct answer
  Set<int> optionSet = {correctInt};
  while (optionSet.length < 4) {
    // For small numbers, avoid negative numbers
    if (correctInt < 10) {
      optionSet.add(correctInt + random.nextInt(range * 2) - range + 1);
    } else {
      optionSet.add(correctInt + random.nextInt(range * 4) - range * 2);
    }
  }

  return optionSet.map((e) => e.toString()).toList()..shuffle();
}

// Addition question generator
Map<String, dynamic> _generateAdditionQuestion(String difficulty, String type) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  switch (difficulty) {
    case 'EASY':
      num1 = random.nextInt(10) + 1; // 1-10
      num2 = random.nextInt(10) + 1; // 1-10
      break;
    case 'MEDIUM':
      num1 = random.nextInt(30) + 10; // 10-39
      num2 = random.nextInt(30) + 10; // 10-39
      break;
    case 'HARD':
      num1 = random.nextInt(400) + 100; // 100-499
      num2 = random.nextInt(400) + 100; // 100-499
      break;
    default:
      num1 = 1;
      num2 = 1;
  }

  correctAnswer = num1 + num2;

  switch (type) {
    case 'PROCEDURAL':
      question = 'What is $num1 + $num2?';
      break;
    case 'SEMANTIC':
      final List<String> contexts = [
        'If you have $num1 apples and get $num2 oranges, how many fruits do you have in total?',
        'If $num1 apples are in a bucket and you add $num2 oranges, how many fruits are there in total?',
        'If you have $num1 apples and then get $num2 oranges, how many fruits do you have in total?',
        'If a store has $num1 apples and receives a shipment of $num2 oranges, how many fruits do they have now?'
      ];
      question = contexts[random.nextInt(contexts.length)];
      break;
    case 'VERBAL':
      if (difficulty == 'EASY') {
        final Map<int, String> numberWords = {
          1: 'one',
          2: 'two',
          3: 'three',
          4: 'four',
          5: 'five',
          6: 'six',
          7: 'seven',
          8: 'eight',
          9: 'nine',
          10: 'ten'
        };
        if (numberWords.containsKey(num1) && numberWords.containsKey(num2)) {
          question = 'What is ${numberWords[num1]} plus ${numberWords[num2]}?';
        } else {
          // Fallback for numbers not in the map
          question = 'What is $num1 plus $num2?';
        }
      } else if (difficulty == 'MEDIUM') {
        // For medium difficulty, use "plus" instead of "+"
        question = 'What is $num1 plus $num2?';
      } else {
        // For hard difficulty, use "sum"
        question = 'What is the sum of $num1 and $num2?';
      }
      break;
    default:
      question = 'What is $num1 + $num2?';
  }

  options = _generateOptions(correctAnswer, difficulty);

  return {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer.toString(),
    'dyscalculia_type': type,
    'lesson': 'ADDITION',
    'difficulty': difficulty,
    'num1': num1,
    'num2': num2,
  };
}

// Subtraction question generator
Map<String, dynamic> _generateSubtractionQuestion(
    String difficulty, String type) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  switch (difficulty) {
    case 'EASY':
      num1 = random.nextInt(10) + 5; // 5-14
      num2 = random.nextInt(num1); // 0 to num1-1
      break;
    case 'MEDIUM':
      num1 = random.nextInt(50) + 20; // 20-69
      num2 = random.nextInt(20) + 1; // 1-20
      break;
    case 'HARD':
      num1 = random.nextInt(500) + 200; // 200-699
      num2 = random.nextInt(200) + 50; // 50-249
      break;
    default:
      num1 = 5;
      num2 = 2;
  }

  correctAnswer = num1 - num2;

  switch (type) {
    case 'PROCEDURAL':
      question = 'What is $num1 - $num2?';
      break;
    case 'SEMANTIC':
      final List<String> contexts = [
        'If you have $num1 apples and give $num2 to a friend, how many do you have left?',
        'If there are $num1 apples on a tree and $num2 fall off, how many are left?',
        'If you have $num1 apples and eat $num2, how much apples do you have left?',
        'If a store has $num1 apples and $num2 are taken away, how many apples remain?'
      ];
      question = contexts[random.nextInt(contexts.length)];
      break;
    case 'VERBAL':
      if (difficulty == 'EASY') {
        final Map<int, String> numberWords = {
          1: 'one',
          2: 'two',
          3: 'three',
          4: 'four',
          5: 'five',
          6: 'six',
          7: 'seven',
          8: 'eight',
          9: 'nine',
          10: 'ten'
        };
        if (numberWords.containsKey(num1) && numberWords.containsKey(num2)) {
          question = 'What is ${numberWords[num1]} minus ${numberWords[num2]}?';
        } else {
          // Fallback for numbers not in the map
          question = 'What is $num1 minus $num2?';
        }
      } else if (difficulty == 'MEDIUM') {
        // For medium difficulty, use "minus" instead of "-"
        question = 'What is $num1 minus $num2?';
      } else {
        // For hard difficulty, use "difference"
        question = 'What is the difference between $num1 and $num2?';
      }
      break;
    default:
      question = 'What is $num1 - $num2?';
  }

  options = _generateOptions(correctAnswer, difficulty);

  return {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer.toString(),
    'dyscalculia_type': type,
    'lesson': 'SUBTRACTION',
    'difficulty': difficulty,
    'num1': num1,
    'num2': num2,
  };
}

// Multiplication question generator
Map<String, dynamic> _generateMultiplicationQuestion(
    String difficulty, String type) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  switch (difficulty) {
    case 'EASY':
      num1 = random.nextInt(5) + 1; // 1-5
      num2 = random.nextInt(5) + 1; // 1-5
      break;
    case 'MEDIUM':
      num1 = random.nextInt(7) + 3; // 3-9
      num2 = random.nextInt(7) + 3; // 3-9
      break;
    case 'HARD':
      num1 = random.nextInt(15) + 10; // 10-24
      num2 = random.nextInt(10) + 5; // 5-14
      break;
    default:
      num1 = 2;
      num2 = 3;
  }

  correctAnswer = num1 * num2;

  switch (type) {
    case 'PROCEDURAL':
      question = 'What is $num1 × $num2?';
      break;
    case 'SEMANTIC':
      final List<String> contexts = [
        'If you have $num1 baskets with $num2 apples in each, how many apples do you have in total?',
        'If there are $num1 rows with $num2 apple trees in each row, how many apple trees are there in total?',
        'If $num1 friends each have $num2 apples, how many apples do they have altogether?',
        'If a store has $num1 crates with $num2 apples in each crate, how many apples are there in total?'
      ];
      question = contexts[random.nextInt(contexts.length)];
      break;
    case 'VERBAL':
      if (difficulty == 'EASY') {
        final Map<int, String> numberWords = {
          1: 'one',
          2: 'two',
          3: 'three',
          4: 'four',
          5: 'five',
          6: 'six',
          7: 'seven',
          8: 'eight',
          9: 'nine',
          10: 'ten'
        };
        if (numberWords.containsKey(num1) && numberWords.containsKey(num2)) {
          question = 'What is ${numberWords[num1]} times ${numberWords[num2]}?';
        } else {
          // Fallback for numbers not in the map
          question = 'What is $num1 times $num2?';
        }
      } else if (difficulty == 'MEDIUM') {
        // For medium difficulty, use "times" instead of "×"
        question = 'What is $num1 times $num2?';
      } else {
        // For hard difficulty, use "product"
        question = 'What is the product of $num1 and $num2?';
      }
      break;
    default:
      question = 'What is $num1 × $num2?';
  }

  options = _generateOptions(correctAnswer, difficulty);

  return {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer.toString(),
    'dyscalculia_type': type,
    'lesson': 'MULTIPLICATION',
    'difficulty': difficulty,
    'num1': num1,
    'num2': num2,
  };
}

// Division question generator
Map<String, dynamic> _generateDivisionQuestion(String difficulty, String type) {
  final random = Random();
  int num1, num2, result;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // We'll generate the result first, then multiply to get num1
  // This ensures clean division without remainders
  switch (difficulty) {
    case 'EASY':
      result = random.nextInt(5) + 1; // 1-5
      num2 = random.nextInt(4) + 2; // 2-5
      num1 = result * num2;
      break;
    case 'MEDIUM':
      result = random.nextInt(7) + 3; // 3-9
      num2 = random.nextInt(6) + 4; // 4-9
      num1 = result * num2;
      break;
    case 'HARD':
      result = random.nextInt(12) + 8; // 8-19
      num2 = random.nextInt(10) + 6; // 6-15
      num1 = result * num2;
      break;
    default:
      result = 2;
      num2 = 3;
      num1 = result * num2;
  }

  correctAnswer = result;

  switch (type) {
    case 'PROCEDURAL':
      question = 'What is $num1 ÷ $num2?';
      break;
    case 'SEMANTIC':
      final List<String> contexts = [
        'If $num1 apples are shared equally among $num2 friends, how many apples does each friend get?',
        'If $num1 apples are arranged in $num2 equal rows, how many apples will be in each row?',
        'If you have $num1 apples and each basket holds $num2 apples, how many baskets do you need?',
        'If a teacher has $num1 apples to distribute among $num2 students equally, how many apples will each student receive?'
      ];
      question = contexts[random.nextInt(contexts.length)];
      break;
    case 'VERBAL':
      if (difficulty == 'EASY') {
        final Map<int, String> numberWords = {
          1: 'one',
          2: 'two',
          3: 'three',
          4: 'four',
          5: 'five',
          6: 'six',
          7: 'seven',
          8: 'eight',
          9: 'nine',
          10: 'ten'
        };
        if (numberWords.containsKey(num1) && numberWords.containsKey(num2)) {
          question =
              'What is ${numberWords[num1]} divided by ${numberWords[num2]}?';
        } else {
          // Fallback for numbers not in the map
          question = 'What is $num1 divided by $num2?';
        }
      } else if (difficulty == 'MEDIUM') {
        // For medium difficulty, use "divided by" instead of "÷"
        question = 'What is $num1 divided by $num2?';
      } else {
        // For hard difficulty, use "quotient"
        question = 'What is the quotient when $num1 is divided by $num2?';
      }
      break;
    default:
      question = 'What is $num1 ÷ $num2?';
  }

  options = _generateOptions(correctAnswer, difficulty);

  return {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer.toString(),
    'dyscalculia_type': type,
    'lesson': 'DIVISION',
    'difficulty': difficulty,
    'num1': num1,
    'num2': num2,
  };
}
