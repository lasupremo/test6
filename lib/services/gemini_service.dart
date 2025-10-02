import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  late final GenerativeModel _model;

  GeminiService() {
    if (_apiKey == null) {
      debugPrint("Gemini API key not found in .env file.");
      throw Exception("API key not found");
    }
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
  }

  /// Generates questions from note content with pre-checks and AI validation.
  /// Returns a map with the AI's response or an error message.
  Future<Map<String, dynamic>> generateQuestionsFromNote({
    required String noteContent,
    required BuildContext context,
  }) async {
    // 1. Client-Side Pre-Check for content length
    const int minWordCount = 25;
    if (noteContent.trim().split(RegExp(r'\s+')).length < minWordCount) {
      _showErrorDialog(context, "More Content Needed",
          "Please add more details to your note (at least $minWordCount words) to generate a meaningful assessment.");
      return {'error': 'local_validation_failed'};
    }

    // 2. Prepare the intelligent AI Prompt
    const int maxQuestions = 10;
    final prompt = """
    First, analyze the following text to determine if it contains clear, factual information suitable for creating educational questions.

    Text: "$noteContent"

    If the text is nonsensical, gibberish, too vague, or lacks sufficient substance to create at least one meaningful question, respond with ONLY the following JSON object:
    {
      "error": "insufficient_content"
    }

    If the text is suitable, generate a concise and descriptive title for an assessment based on it. Then, generate as many high-quality multiple-choice questions as the text can support, up to a maximum of $maxQuestions questions. Each question must have one correct answer and three plausible incorrect answers.

    Format the output as a single valid JSON object with the following structure:
    {
      "title": "Your Generated Assessment Title",
      "questions": [
        {
          "question_text": "...",
          "options": [
            {"text": "...", "is_correct": false},
            {"text": "...", "is_correct": true},
            {"text": "...", "is_correct": false},
            {"text": "...", "is_correct": false}
          ]
        }
      ]
    }
    """;

    // 3. Call the API and handle the response
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final cleanJsonString =
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = jsonDecode(cleanJsonString);

      // 4. Check for AI-driven validation error
      if (jsonResponse.containsKey('error') && jsonResponse['error'] == 'insufficient_content') {
        _showErrorDialog(context, "Could Not Generate Assessment",
            "We couldn't create an assessment from this note. Please try revising it for more clarity and factual detail.");
        return jsonResponse;
      }

      return jsonResponse;

    } catch (e) {
      _showErrorDialog(context, "An Error Occurred",
          "Something went wrong while generating the assessment. Please try again later.");
      return {'error': 'api_exception', 'details': e.toString()};
    }
  }

  void _showErrorDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}