import 'package:rekindle/models/topic.dart';

// Represents a single assessment, which is a collection of questions.
class Assessment {
  final String id;
  final String topicId;
  final String title;
  final DateTime createdAt;
  DateTime? due;
  final Topic topic;
  final int questionCount;
  final String status; // ✅ FIX: Added the status property

  Assessment({
    required this.id,
    required this.topicId,
    required this.title,
    required this.createdAt,
    this.due,
    required this.topic,
    this.questionCount = 0,
    required this.status, // ✅ FIX: Added to the constructor
  });

  factory Assessment.fromMap(Map<String, dynamic> map, Topic topic) {
    final questions = map['question'] as List?;
    final count = questions?.length ?? 0;

    return Assessment(
      id: map['id'],
      topicId: map['topic_id'],
      title: map['title'] ?? 'Untitled Assessment',
      createdAt: DateTime.parse(map['created_at']),
      due: map['due'] != null ? DateTime.parse(map['due']) : null,
      topic: topic,
      questionCount: count,
      status: map['status'] ?? 'Pending', // ✅ FIX: Read status from the map
    );
  }
}

// ... (Rest of the file remains the same)
class Question {
  final String? id;
  final String questionText;
  final List<AnswerOption> options;

  Question({
    this.id,
    required this.questionText,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var optionsList = (json['options'] as List)
        .map((optionJson) => AnswerOption.fromJson(optionJson))
        .toList();
    optionsList.shuffle();
    return Question(
      questionText: json['question_text'],
      options: optionsList,
    );
  }
}

class AnswerOption {
  final String? id;
  final String optionText;
  final bool isCorrect;

  AnswerOption({
    this.id,
    required this.optionText,
    required this.isCorrect,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      optionText: json['text'],
      isCorrect: json['is_correct'],
    );
  }
}