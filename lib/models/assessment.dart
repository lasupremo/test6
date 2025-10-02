import 'package:rekindle/models/topic.dart';

// Represents a single assessment, which is a collection of questions.
class Assessment {
  final String id;
  final String topicId;
  final String? title; // The new AI-generated title
  final DateTime createdAt;
  final DateTime? dueDate; // The earliest due date from its associated cards
  final Topic topic; // The associated Topic object

  Assessment({
    required this.id,
    required this.topicId,
    this.title,
    required this.createdAt,
    this.dueDate,
    required this.topic,
  });

  /// Creates an Assessment instance from a map, typically from a Supabase query.
  /// This factory is designed to work with the 'get_assessments_with_due_dates' RPC call.
  factory Assessment.fromMap(Map<String, dynamic> map, Topic topic) {
    return Assessment(
      id: map['id'],
      topicId: map['topic_id'],
      title: map['title'],
      createdAt: DateTime.parse(map['created_at']),
      // The 'due' field comes from the RPC function
      dueDate: map['due'] != null ? DateTime.parse(map['due']) : null,
      topic: topic,
    );
  }
}

// Represents a single question within an assessment.
class Question {
  final String? id;
  final String questionText;
  // Options are now fetched separately based on question_id
  final List<AnswerOption> options;

  Question({
    this.id,
    required this.questionText,
    required this.options,
  });

  /// Creates a Question instance from the JSON object provided by the Gemini API.
  factory Question.fromJson(Map<String, dynamic> json) {
    var optionsList = (json['options'] as List)
        .map((optionJson) => AnswerOption.fromJson(optionJson))
        .toList();

    // Shuffle the options so the correct answer isn't always in the same place
    optionsList.shuffle();

    return Question(
      questionText: json['question_text'],
      options: optionsList,
    );
  }
}

// Represents a single answer option for a question.
class AnswerOption {
  final String? id;
  final String optionText;
  final bool isCorrect;

  AnswerOption({
    this.id,
    required this.optionText,
    required this.isCorrect,
  });

  /// Creates an AnswerOption from the JSON object provided by the Gemini API.
  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      optionText: json['text'],
      isCorrect: json['is_correct'],
    );
  }
}