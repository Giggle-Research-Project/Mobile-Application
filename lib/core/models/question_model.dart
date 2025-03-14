class Question {
  final String question;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    if (json['question'] is List) {
      final questionData = json['question'] as List;
      final questionText = questionData[0].toString();
      final answer = questionData[1].toString();

      final answerNum = int.tryParse(answer) ?? 0;
      final options = List<String>.generate(4, (index) {
        final offset = index - 1;
        return (answerNum + offset).toString();
      });

      if (!options.contains(answer)) {
        options[0] = answer;
      }
      options.shuffle();

      return Question(
        question: questionText,
        options: options,
        correctAnswer: answer,
      );
    }

    return Question(
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctAnswer: json['correctAnswer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }
}
