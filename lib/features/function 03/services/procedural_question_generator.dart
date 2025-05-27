import 'dart:math';

class MathQuestion {
  final int num1;
  final int num2;
  final int answer;
  final String difficulty;

  MathQuestion({
    required this.num1,
    required this.num2,
    required this.answer,
    required this.difficulty,
  });
}

abstract class QuestionGenerator {
  static final Random _random = Random();
  
  static List<MathQuestion> generateQuestionSet(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'addition':
        return [
          AdditionQuestionGenerator._generateEasyQuestion(),
          AdditionQuestionGenerator._generateMediumQuestion(),
          AdditionQuestionGenerator._generateHardQuestion(),
        ];
      case 'subtraction':
        return [
          SubtractionQuestionGenerator._generateEasyQuestion(),
          SubtractionQuestionGenerator._generateMediumQuestion(),
          SubtractionQuestionGenerator._generateHardQuestion(),
        ];
      case 'multiplication':
        return [
          MultiplicationQuestionGenerator._generateEasyQuestion(),
          MultiplicationQuestionGenerator._generateMediumQuestion(),
          MultiplicationQuestionGenerator._generateHardQuestion(),
        ];
      case 'division':
        return [
          DivisionQuestionGenerator._generateEasyQuestion(),
          DivisionQuestionGenerator._generateMediumQuestion(),
          DivisionQuestionGenerator._generateHardQuestion(),
        ];
      default:
        throw ArgumentError('Unsupported operation type: $operationType');
    }
  }
}

class AdditionQuestionGenerator {
  static final Random _random = Random();

  static List<MathQuestion> generateAdditionQuestionSet() {
    return [
      _generateEasyQuestion(),
      _generateMediumQuestion(),
      _generateHardQuestion(),
    ];
  }

  static MathQuestion _generateEasyQuestion() {
    // Generate 1-digit numbers with sum not exceeding 9
    int num1 = _random.nextInt(8) + 1; // 1-8
    int num2 = _random.nextInt(9 - num1) + 1; // Ensures sum doesn't exceed 9
    
    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 + num2,
      difficulty: 'EASY',
    );
  }

  static MathQuestion _generateMediumQuestion() {
    // Generate 2-digit numbers with sum between 10-99 without borrowing
    int num1, num2, onesDigit1, onesDigit2;
    do {
      // Generate first number between 20-80
      num1 = _random.nextInt(61) + 20; // 20-80
      
      // Generate second number that won't require borrowing
      int maxSecond = 99 - num1; // Ensure sum doesn't exceed 99
      num2 = _random.nextInt(maxSecond - 10 + 1) + 10; // At least 2 digits
      
      // Check if it requires borrowing
      onesDigit1 = num1 % 10;
      onesDigit2 = num2 % 10;
    } while (onesDigit1 + onesDigit2 >= 10); // Regenerate if borrowing needed

    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 + num2,
      difficulty: 'MEDIUM',
    );
  }

  static MathQuestion _generateHardQuestion() {
    // Generate 2-digit numbers (50-90) with same digit numbers
    List<int> sameDigitNumbers = [11, 22, 33, 44, 55, 66, 77, 88];
    int num1, num2;
    
    do {
      num1 = sameDigitNumbers[_random.nextInt(sameDigitNumbers.length)];
      num2 = sameDigitNumbers[_random.nextInt(sameDigitNumbers.length)];
    } while (num1 == num2 || num1 + num2 >= 100); // Ensure different numbers and sum < 100

    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 + num2,
      difficulty: 'HARD',
    );
  }
}

class SubtractionQuestionGenerator {
  static final Random _random = Random();

  static MathQuestion _generateEasyQuestion() {
    int num1 = _random.nextInt(8) + 2; // 2-9
    int num2 = _random.nextInt(num1 - 1) + 1; // Ensures positive result
    
    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 - num2,
      difficulty: 'EASY',
    );
  }

  static MathQuestion _generateMediumQuestion() {
    int num1, num2;
    do {
      num1 = _random.nextInt(81) + 20; // 20-100
      num2 = _random.nextInt(num1 - 10) + 1; // Ensures positive result
    } while ((num1 % 10) < (num2 % 10)); // Avoid borrowing

    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 - num2,
      difficulty: 'MEDIUM',
    );
  }

  static MathQuestion _generateHardQuestion() {
    List<int> numbers = [55, 66, 77, 88, 99];
    int num1 = numbers[_random.nextInt(numbers.length)];
    int num2 = numbers[_random.nextInt(numbers.length)];
    
    while (num2 >= num1) {
      num2 = numbers[_random.nextInt(numbers.length)];
    }

    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 - num2,
      difficulty: 'HARD',
    );
  }
}

class MultiplicationQuestionGenerator {
  static final Random _random = Random();

  static MathQuestion _generateEasyQuestion() {
    int num1 = _random.nextInt(5) + 1; // 1-5
    int num2 = _random.nextInt(5) + 1; // 1-5
    
    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 * num2,
      difficulty: 'EASY',
    );
  }

  static MathQuestion _generateMediumQuestion() {
    int num1 = _random.nextInt(5) + 6; // 6-10
    int num2 = _random.nextInt(5) + 1; // 1-5
    
    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 * num2,
      difficulty: 'MEDIUM',
    );
  }

  static MathQuestion _generateHardQuestion() {
    int num1 = _random.nextInt(4) + 7; // 7-10
    int num2 = _random.nextInt(4) + 7; // 7-10
    
    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: num1 * num2,
      difficulty: 'HARD',
    );
  }
}

class DivisionQuestionGenerator {
  static final Random _random = Random();

  static MathQuestion _generateEasyQuestion() {
    int num2 = _random.nextInt(4) + 2; // divisor: 2-5
    int answer = _random.nextInt(5) + 1; // quotient: 1-5
    int num1 = num2 * answer; // dividend
    
    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: answer,
      difficulty: 'EASY',
    );
  }

  static MathQuestion _generateMediumQuestion() {
    int num2 = _random.nextInt(4) + 6; // divisor: 6-9
    int answer = _random.nextInt(5) + 1; // quotient: 1-5
    int num1 = num2 * answer; // dividend
    
    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: answer,
      difficulty: 'MEDIUM',
    );
  }

  static MathQuestion _generateHardQuestion() {
    int num2 = _random.nextInt(3) + 8; // divisor: 8-10
    int answer = _random.nextInt(3) + 8; // quotient: 8-10
    int num1 = num2 * answer; // dividend
    
    return MathQuestion(
      num1: num1,
      num2: num2,
      answer: answer,
      difficulty: 'HARD',
    );
  }
}