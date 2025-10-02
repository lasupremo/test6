import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assessment.dart';

class GeminiService {
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Question>> generateFlashcardQuestions(
      String notesContent, String topicId) async {
    if (_apiKey == null) {
      debugPrint("Gemini API key not found in .env file.");
      throw Exception("API key not found");
    }

    final model =
        GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
    final prompt =
        'Based on the following notes, create 5 multiple-choice questions suitable for flashcards. For each question, provide 4 options and indicate the correct answer. Format the output as a valid JSON array of objects, where each object has "question_text" (a string), "options" (an array of 4 strings), and "correct_answer" (a string matching one of the options):\n\n---\n\nNOTES:\n$notesContent';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final cleanJsonString =
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = json.decode(cleanJsonString);

      final List<Question> questions = [];

      for (final q in jsonResponse) {
        final questionText = q['question_text'];
        final correctAnswer = q['correct_answer'];
        final options = (q['options'] as List<dynamic>);

        // 1. Insert the question and get its new ID
        final questionResponse = await _supabase.from('question').insert({
          'question_text': questionText,
          'question_type': 'multiple_choice',
          'points': 1,
          'topic_id': topicId,
        }).select('id');

        final questionId = questionResponse[0]['id'];

        // 2. Prepare answer options with the new question_id
        final List<Map<String, dynamic>> answerOptionsToInsert = [];
        final List<AnswerOption> answerOptionsForModel = [];

        for (int i = 0; i < options.length; i++) {
          final optionText = options[i];
          final isCorrect = optionText == correctAnswer;
          
          answerOptionsToInsert.add({
            'question_id': questionId,
            'option_text': optionText,
            'is_correct': isCorrect,
            'order_index': i,
            'points': isCorrect ? 1 : 0,
          });

          answerOptionsForModel.add(AnswerOption(
            optionText: optionText,
            isCorrect: isCorrect,
          ));
        }
        
        // 3. Batch insert all answer options for this question
        await _supabase.from('answer_option').insert(answerOptionsToInsert);

        // 4. Add the complete question object to our return list
        questions.add(Question(
          id: questionId,
          questionText: questionText,
          options: answerOptionsForModel,
          correctAnswer: correctAnswer,
        ));
      }

      return questions;
    } catch (e) {
      debugPrint('Error during question generation or database insertion: $e');
      return [];
    }
  }
}