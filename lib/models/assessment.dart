class Question {
  final String? id;
  final String questionText;
  final List<AnswerOption> options;
  final String correctAnswer;

  Question({
    this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var optionsList = (json['options'] as List)
        .map((option) => AnswerOption(
              optionText: option,
              isCorrect: option == json['correct_answer'],
            ))
        .toList();

    return Question(
      id: json['id'], // Add this line
      questionText: json['question_text'],
      options: optionsList,
      correctAnswer: json['correct_answer'],
    );
  }
}

class AnswerOption {
  final String optionText;
  final bool isCorrect;

  AnswerOption({
    required this.optionText,
    required this.isCorrect,
  });
}