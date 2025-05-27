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

  // Generate Verbal Questions for all operations
  final verbalQuestions = _generateVerbalQuestions(lessonType, verbalDifficulty);
  generatedQuestions.addAll(verbalQuestions);

  return generatedQuestions;
}

// Function to generate procedural questions
List<Map<String, dynamic>> _generateProceduralQuestions(
    String operation, String difficulty) {
  final List<Map<String, dynamic>> questions = [];

  // Generate 1 question for the specified operation and difficulty
  for (int i = 0; i < 1; i++) {
    Map<String, dynamic> question = {};

    switch (operation) {
      case 'ADDITION':
        question = _generateTwoDigitAdditionQuestion(difficulty);
        break;
      case 'SUBTRACTION':
        question = _generateTwoDigitSubtractionQuestion(difficulty);
        break;
      case 'MULTIPLICATION':
        question = _generateTwoDigitMultiplicationQuestion(difficulty);
        break;
      case 'DIVISION':
        question = _generateTwoDigitDivisionQuestion(difficulty);
        break;
    }

    if (question.isNotEmpty) {
      questions.add(question);
    }
  }

  return questions;
}

// Function to generate semantic questions (unchanged)
List<Map<String, dynamic>> _generateSemanticQuestions(
    String operation, String difficulty) {
  final List<Map<String, dynamic>> questions = [];

  // Generate 1 question for the specified operation and difficulty
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

// Modify the _generateVerbalQuestions function to allow all operations:
List<Map<String, dynamic>> _generateVerbalQuestions(
    String operation, String difficulty) {
  final List<Map<String, dynamic>> questions = [];
  Map<String, dynamic> question = {};

  // Generate verbal questions for all operations
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

  return questions;
}

// NEW: Two-digit Addition question generator for procedural type only
Map<String, dynamic> _generateTwoDigitAdditionQuestion(String difficulty) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // Generate two-digit numbers based on difficulty, ensuring answer is 2 digits (10-99)
  switch (difficulty) {
    case 'EASY':
      // For easy, use numbers like 10-20 + 10-20 to get 2-digit results
      num1 = random.nextInt(11) + 10; // 10-20
      num2 = random.nextInt(11) + 10; // 10-20
      // Ensure the sum doesn't exceed 99
      while (num1 + num2 > 99) {
        num1 = random.nextInt(11) + 10;
        num2 = random.nextInt(11) + 5;
      }
      break;
    case 'MEDIUM':
      // For medium, use numbers like 20-40 + 10-30
      num1 = random.nextInt(21) + 20; // 20-40
      num2 = random.nextInt(21) + 10; // 10-30
      // Ensure the sum doesn't exceed 99
      while (num1 + num2 > 99) {
        num1 = random.nextInt(21) + 20;
        num2 = random.nextInt(21) + 10;
      }
      break;
    case 'HARD':
      // For hard, use larger numbers like 30-60 + 20-40
      num1 = random.nextInt(31) + 30; // 30-60
      num2 = random.nextInt(21) + 20; // 20-40
      // Ensure the sum doesn't exceed 99
      while (num1 + num2 > 99) {
        num1 = random.nextInt(31) + 30;
        num2 = random.nextInt(21) + 20;
      }
      break;
    default:
      num1 = random.nextInt(21) + 20; // 20-40
      num2 = random.nextInt(21) + 10; // 10-30
      // Ensure the sum doesn't exceed 99
      while (num1 + num2 > 99) {
        num1 = random.nextInt(21) + 20;
        num2 = random.nextInt(21) + 10;
      }
  }

  correctAnswer = num1 + num2;
  question = 'What is $num1 + $num2?';
  options = _generateTwoDigitOptions(correctAnswer, difficulty);

  return {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer.toString(),
    'dyscalculia_type': 'PROCEDURAL',
    'lesson': 'ADDITION',
    'difficulty': difficulty,
    'num1': num1,
    'num2': num2,
  };
}

// NEW: Two-digit Subtraction question generator for procedural type only
Map<String, dynamic> _generateTwoDigitSubtractionQuestion(String difficulty) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // Generate two-digit numbers based on difficulty, ensuring answer is 2 digits (10-99)
  switch (difficulty) {
    case 'EASY':
      // For easy, start with a number between 30-50 and subtract 10-20
      num1 = random.nextInt(21) + 30; // 30-50
      num2 = random.nextInt(11) + 10; // 10-20
      // Ensure the difference is at least 10 (2 digits)
      while (num1 - num2 < 10) {
        num1 = random.nextInt(21) + 30;
        num2 = random.nextInt(11) + 10;
      }
      break;
    case 'MEDIUM':
      // For medium, start with a number between 40-70 and subtract 15-30
      num1 = random.nextInt(31) + 40; // 40-70
      num2 = random.nextInt(16) + 15; // 15-30
      // Ensure the difference is at least 10 and doesn't exceed 99
      while (num1 - num2 < 10 || num1 - num2 > 99) {
        num1 = random.nextInt(31) + 40;
        num2 = random.nextInt(16) + 15;
      }
      break;
    case 'HARD':
      // For hard, start with a number between 60-99 and subtract 20-50
      num1 = random.nextInt(40) + 60; // 60-99
      num2 = random.nextInt(31) + 20; // 20-50
      // Ensure the difference is at least 10 and doesn't exceed 99
      while (num1 - num2 < 10 || num1 - num2 > 99) {
        num1 = random.nextInt(40) + 60;
        num2 = random.nextInt(31) + 20;
      }
      break;
    default:
      num1 = random.nextInt(31) + 40; // 40-70
      num2 = random.nextInt(16) + 15; // 15-30
      // Ensure the difference is at least 10
      while (num1 - num2 < 10) {
        num1 = random.nextInt(31) + 40;
        num2 = random.nextInt(16) + 15;
      }
  }

  correctAnswer = num1 - num2;
  question = 'What is $num1 - $num2?';
  options = _generateTwoDigitOptions(correctAnswer, difficulty);

  return {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer.toString(),
    'dyscalculia_type': 'PROCEDURAL',
    'lesson': 'SUBTRACTION',
    'difficulty': difficulty,
    'num1': num1,
    'num2': num2,
  };
}

// NEW: Two-digit Multiplication question generator for procedural type only
Map<String, dynamic> _generateTwoDigitMultiplicationQuestion(
    String difficulty) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // Generate numbers based on difficulty, ensuring at least one 2-digit number
  // But the product must be 2 digits (10-99)
  switch (difficulty) {
    case 'EASY':
      // For easy, multiply a 2-digit number (10-15) by a single digit (1-4)
      num1 = random.nextInt(6) + 10; // 10-15
      num2 = random.nextInt(4) + 1; // 1-4
      // Ensure the product is 2 digits (10-99)
      while (num1 * num2 < 10 || num1 * num2 > 99) {
        num1 = random.nextInt(6) + 10;
        num2 = random.nextInt(4) + 1;
      }
      break;
    case 'MEDIUM':
      // For medium, multiply a 2-digit number (10-20) by a single digit (2-5)
      num1 = random.nextInt(11) + 10; // 10-20
      num2 = random.nextInt(4) + 2; // 2-5
      // Ensure the product is 2 digits (10-99)
      while (num1 * num2 < 10 || num1 * num2 > 99) {
        num1 = random.nextInt(11) + 10;
        num2 = random.nextInt(4) + 2;
      }
      break;
    case 'HARD':
      // For hard, we can use two-digit by single-digit with more challenging numbers
      num1 = random.nextInt(10) + 15; // 15-24
      num2 = random.nextInt(3) + 4; // 4-6
      // Ensure the product is 2 digits (10-99)
      while (num1 * num2 < 10 || num1 * num2 > 99) {
        num1 = random.nextInt(10) + 15;
        num2 = random.nextInt(3) + 4;
      }
      break;
    default:
      num1 = random.nextInt(11) + 10; // 10-20
      num2 = random.nextInt(4) + 2; // 2-5
      // Ensure the product is 2 digits (10-99)
      while (num1 * num2 < 10 || num1 * num2 > 99) {
        num1 = random.nextInt(11) + 10;
        num2 = random.nextInt(4) + 2;
      }
  }

  correctAnswer = num1 * num2;
  question = 'What is $num1 × $num2?';
  options = _generateTwoDigitOptions(correctAnswer, difficulty);

  return {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer.toString(),
    'dyscalculia_type': 'PROCEDURAL',
    'lesson': 'MULTIPLICATION',
    'difficulty': difficulty,
    'num1': num1,
    'num2': num2,
  };
}

// NEW: Two-digit Division question generator for procedural type only
Map<String, dynamic> _generateTwoDigitDivisionQuestion(String difficulty) {
  final random = Random();
  int num1, num2, result;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // We'll ensure at least the dividend is 2 digits,
  // and the result (quotient) is between 10-99 (2 digits)

  switch (difficulty) {
    case 'EASY':
      // For easy, we'll aim for results between 10-20
      result = random.nextInt(11) + 10; // 10-20
      num2 = random.nextInt(3) + 2; // 2-4
      num1 = result * num2; // Guaranteed to be evenly divisible
      break;
    case 'MEDIUM':
      // For medium, we'll aim for results between 15-30
      result = random.nextInt(16) + 15; // 15-30
      num2 = random.nextInt(3) + 3; // 3-5
      num1 = result * num2; // Guaranteed to be evenly divisible
      break;
    case 'HARD':
      // For hard, we'll aim for results between 25-50
      result = random.nextInt(26) + 25; // 25-50
      num2 = random.nextInt(4) + 2; // 2-5
      num1 = result * num2; // Guaranteed to be evenly divisible
      break;
    default:
      result = random.nextInt(16) + 15; // 15-30
      num2 = random.nextInt(3) + 3; // 3-5
      num1 = result * num2; // Guaranteed to be evenly divisible
  }

  correctAnswer = result;
  question = 'What is $num1 ÷ $num2?';
  options = _generateTwoDigitOptions(correctAnswer, difficulty);

  return {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer.toString(),
    'dyscalculia_type': 'PROCEDURAL',
    'lesson': 'DIVISION',
    'difficulty': difficulty,
    'num1': num1,
    'num2': num2,
  };
}

// NEW: Helper function to generate options for two-digit answers
List<String> _generateTwoDigitOptions(
    dynamic correctAnswer, String difficulty) {
  final random = Random();
  int correctInt = correctAnswer is int
      ? correctAnswer
      : int.parse(correctAnswer.toString());

  // Determine range of wrong answers based on difficulty
  int range;
  switch (difficulty) {
    case 'EASY':
      range = 5;
      break;
    case 'MEDIUM':
      range = 8;
      break;
    case 'HARD':
      range = 12;
      break;
    default:
      range = 5;
  }

  // Generate options around the correct answer
  Set<int> optionSet = {correctInt};

  // Add wrong options that are close to the correct answer
  while (optionSet.length < 4) {
    int wrongOption =
        correctInt + (random.nextBool() ? 1 : -1) * (random.nextInt(range) + 1);

    // Ensure wrong options are within 10-99 range (2 digits)
    if (wrongOption >= 10 && wrongOption <= 99) {
      optionSet.add(wrongOption);
    }
  }

  // If we still don't have 4 options, add more within the valid range
  while (optionSet.length < 4) {
    int wrongOption = random.nextInt(90) + 10; // Random 2-digit number (10-99)
    if (wrongOption != correctInt) {
      optionSet.add(wrongOption);
    }
  }

  return optionSet.map((e) => e.toString()).toList()..shuffle();
}

// The original helper function for generating options (unchanged)
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
    if (correctInt < 10) {
      optionSet.add(correctInt + random.nextInt(range * 2) - range + 1);
    } else {
      optionSet.add(correctInt + random.nextInt(range * 4) - range * 2);
    }
    optionSet.removeWhere((e) => e < 0);
  }

  // If we couldn't get 4 options, add more until we do
  while (optionSet.length < 4) {
    optionSet.add(correctInt + random.nextInt(10) + 1);
  }

  return optionSet.map((e) => e.toString()).toList()..shuffle();
}

// Original Addition question generator (unchanged)
Map<String, dynamic> _generateAdditionQuestion(String difficulty, String type) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // Special handling for verbal questions
  if (type == 'VERBAL') {
    switch (difficulty) {
      case 'EASY':
        // For easy: numbers 1-5, sum ≤ 5
        do {
          num1 = random.nextInt(5) + 1; // 1-5
          num2 = random.nextInt(5) + 1; // 1-5
        } while (num1 + num2 > 5);
        break;
      case 'MEDIUM':
        // For medium: numbers 1-9, 5 < sum < 9
        do {
          num1 = random.nextInt(9) + 1; // 1-9
          num2 = random.nextInt(9) + 1; // 1-9
        } while (num1 + num2 <= 5 || num1 + num2 >= 9);
        break;
      case 'HARD':
        // For hard: numbers 5-9, 9 < sum < 20
        do {
          num1 = random.nextInt(5) + 5; // 5-9
          num2 = random.nextInt(5) + 5; // 5-9
        } while (num1 + num2 <= 9 || num1 + num2 >= 20);
        break;
      default:
        num1 = random.nextInt(5) + 1;
        num2 = random.nextInt(5) + 1;
    }
  } else {
    // Original logic for non-verbal questions
    switch (difficulty) {
      case 'EASY':
        num1 = random.nextInt(5) + 1; // 1-5
        num2 = random.nextInt(5) + 1; // 1-5
        break;
      case 'MEDIUM':
        num1 = random.nextInt(5) + 5; // 5-9
        num2 = random.nextInt(5) + 1; // 1-5
        break;
      case 'HARD':
        num1 = random.nextInt(4) + 6; // 6-9
        num2 = random.nextInt(4) + 6; // 6-9
        break;
      default:
        num1 = random.nextInt(9) + 1; // 1-9
        num2 = random.nextInt(9) + 1; // 1-9
    }
  }

  correctAnswer = num1 + num2;

  // Rest of the function remains the same
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
      final Map<int, String> numberWords = {
        1: 'one',
        2: 'two',
        3: 'three',
        4: 'four',
        5: 'five',
        6: 'six',
        7: 'seven',
        8: 'eight',
        9: 'nine'
      };

      if (difficulty == 'EASY') {
        question = 'What is ${numberWords[num1]} plus ${numberWords[num2]}?';
      } else if (difficulty == 'MEDIUM') {
        question = 'What is $num1 plus $num2?';
      } else {
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

// Original Subtraction question generator (unchanged)
Map<String, dynamic> _generateSubtractionQuestion(
    String difficulty, String type) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // Ensure single-digit numbers but guarantee num1 >= num2
  switch (difficulty) {
    case 'EASY':
      num1 = random.nextInt(5) + 5; // 5-9
      num2 = random.nextInt(5) + 1; // 1-5 (smaller than num1)
      break;
    case 'MEDIUM':
      num1 = random.nextInt(4) + 6; // 6-9
      num2 = random.nextInt(4) + 2; // 2-5
      break;
    case 'HARD':
      num1 = random.nextInt(3) + 7; // 7-9
      num2 = random.nextInt(5) + 2; // 2-6
      break;
    default:
      num1 = random.nextInt(5) + 5; // 5-9
      num2 = random.nextInt(5) + 1; // 1-5
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
        'If you have $num1 apples and eat $num2, how many apples do you have left?',
        'If a store has $num1 apples and $num2 are taken away, how many apples remain?'
      ];
      question = contexts[random.nextInt(contexts.length)];
      break;
    case 'VERBAL':
      final Map<int, String> numberWords = {
        1: 'one',
        2: 'two',
        3: 'three',
        4: 'four',
        5: 'five',
        6: 'six',
        7: 'seven',
        8: 'eight',
        9: 'nine'
      };

      if (difficulty == 'EASY') {
        question = 'What is ${numberWords[num1]} minus ${numberWords[num2]}?';
      } else if (difficulty == 'MEDIUM') {
        question = 'What is $num1 minus $num2?';
      } else {
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

// Original Multiplication question generator (unchanged)
Map<String, dynamic> _generateMultiplicationQuestion(
    String difficulty, String type) {
  final random = Random();
  int num1, num2;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // Ensure single-digit numbers
  switch (difficulty) {
    case 'EASY':
      num1 = random.nextInt(3) + 1; // 1-3
      num2 = random.nextInt(3) + 1; // 1-3
      break;
    case 'MEDIUM':
      num1 = random.nextInt(3) + 3; // 3-5
      num2 = random.nextInt(3) + 2; // 2-4
      break;
    case 'HARD':
      num1 = random.nextInt(4) + 6; // 6-9
      num2 = random.nextInt(3) + 3; // 3-5
      break;
    default:
      num1 = random.nextInt(5) + 1; // 1-5
      num2 = random.nextInt(5) + 1; // 1-5
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
      final Map<int, String> numberWords = {
        1: 'one',
        2: 'two',
        3: 'three',
        4: 'four',
        5: 'five',
        6: 'six',
        7: 'seven',
        8: 'eight',
        9: 'nine'
      };

      if (difficulty == 'EASY') {
        question = 'What is ${numberWords[num1]} times ${numberWords[num2]}?';
      } else if (difficulty == 'MEDIUM') {
        question = 'What is $num1 times $num2?';
      } else {
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

// Original Division question generator (unchanged)
Map<String, dynamic> _generateDivisionQuestion(String difficulty, String type) {
  final random = Random();
  int num1, num2, result;
  String question;
  dynamic correctAnswer;
  List<String> options;

  // We'll generate the result first (as a single digit), then multiply to get num1
  // This ensures clean division without remainders
  switch (difficulty) {
    case 'EASY':
      result = random.nextInt(3) + 1; // 1-3
      num2 = random.nextInt(3) + 2; // 2-4
      num1 = result * num2;
      break;
    case 'MEDIUM':
      result = random.nextInt(4) + 2; // 2-5
      num2 = random.nextInt(2) + 2; // 2-3
      num1 = result * num2;
      break;
    case 'HARD':
      result = random.nextInt(4) + 2; // 2-5
      num2 = random.nextInt(4) +
          6; // 6-9 (this might make num1 > 9, but result will be single-digit)
      num1 = result * num2;
      break;
    default:
      result = random.nextInt(3) + 1; // 1-3
      num2 = random.nextInt(3) + 2; // 2-4
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
      final Map<int, String> numberWords = {
        1: 'one',
        2: 'two',
        3: 'three',
        4: 'four',
        5: 'five',
        6: 'six',
        7: 'seven',
        8: 'eight',
        9: 'nine'
      };

      // Special handling for num1 that might be > 9 in hard division
      String num1Word =
          num1 <= 9 ? numberWords[num1] ?? num1.toString() : num1.toString();
      String num2Word = numberWords[num2] ?? num2.toString();

      if (difficulty == 'EASY') {
        question = 'What is $num1Word divided by $num2Word?';
      } else if (difficulty == 'MEDIUM') {
        question = 'What is $num1 divided by $num2?';
      } else {
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
