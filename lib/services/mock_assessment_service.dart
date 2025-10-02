import 'dart:convert';
import '../models/assessment.dart';

class MockAssessmentService {
  // You can customize these questions for your testing
  final String mockJsonResponse = '''
  [
    {
        "question_text": "In League of Legends, which champion says ❝ For my next trick, I'll make you disappear! ❞?",
        "options": ["Twisted Fate", "Leblanc", "Shaco", "Jhin"],
        "correct_answer": "Shaco"
    },
    {
        "question_text": "What game won the 2015 Game of the Year?",
        "options": ["Bloodborne", "Fallout 4", "Metal Gear Solid V: The Phantom Pain", "The Witcher 3: Wild Hunt"],
        "correct_answer": "The Witcher 3: Wild Hunt"
    },
    {
        "question_text": "In Valorant, which agent says ❝ Death is not an option. ❞? ",
        "options": ["Deadlock", "Omen", "Phoenix", "Viper"],
        "correct_answer": "Deadlock"
    },
    {
        "question_text": "In Flutter, what widget is used for basic layout structure?",
        "options": ["Text", "Column", "Container", "Scaffold"],
        "correct_answer": "Scaffold"
    },
    {
        "question_text": "What command fetches your Flutter project's dependencies?",
        "options": ["flutter run", "flutter create", "flutter pub get", "flutter doctor"],
        "correct_answer": "flutter pub get"
    }
  ]
  ''';

  Future<List<Question>> getMockQuestions() async {
    // This simulates a network delay, like a real API call
    await Future.delayed(const Duration(seconds: 1)); 
    
    final jsonResponse = json.decode(mockJsonResponse);
    return (jsonResponse as List)
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();
  }
}