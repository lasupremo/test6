import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rekindle/models/assessment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'topic.dart';

class TopicDatabase extends ChangeNotifier {
  final SupabaseClient _supabase;
  String? _profileId;
  final List<Topic> currentTopics = [];
  
  // This Timer will now be our reliable refresher.
  Timer? _pollingTimer;

  int _dueAssessmentsCount = 0;
  int get dueAssessmentsCount => _dueAssessmentsCount;

  TopicDatabase()
      : _supabase = Supabase.instance.client,
        _profileId = Supabase.instance.client.auth.currentUser?.id {
    // Start our new polling mechanism.
    _startPolling();
  }

  TopicDatabase.test(SupabaseClient mockClient, {String dummyUserId = "test-user"})
      : _supabase = mockClient,
        _profileId = dummyUserId;

  // --- NEW POLLING MECHANISM ---
  void _startPolling() {
    // Immediately fetch the count when the app starts.
    refreshDueAssessmentsCount();

    // Then, create a timer that runs the refresh function every 15 seconds.
    // This is efficient and ensures the UI is always up-to-date.
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      refreshDueAssessmentsCount();
    });
  }

  @override
  void dispose() {
    // It's crucial to cancel the timer when it's no longer needed.
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Helper method to get and cache profile ID
  Future<String?> _getProfileId() async {
    if (_profileId != null) return _profileId;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('Error: User is not logged in.');
      return null;
    }
    _profileId = userId;
    return _profileId;
  }

  // --- ASSESSMENT OPERATIONS ---
  Future<void> refreshDueAssessmentsCount() async {
    try {
      final count = await _supabase.rpc('count_due_assessments');
      // Only notify listeners if the count has actually changed.
      // This prevents unnecessary UI rebuilds and improves performance.
      if (count != _dueAssessmentsCount) {
        _dueAssessmentsCount = count as int;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error counting due assessments: $e');
      if (_dueAssessmentsCount != 0) {
        _dueAssessmentsCount = 0;
        notifyListeners();
      }
    }
  }

  // --- ALL OTHER FUNCTIONS (addTopic, fetchTopics, etc.) REMAIN EXACTLY THE SAME ---
  // ... (You can copy the rest of your functions from your existing file below this line)
  // ...
  Future<void> addTopic(String textFromUser, {String? description}) async {
    final profileId = await _getProfileId();
    if (profileId == null) return;

    try {
      await _supabase.from('topics').insert({
        'text': textFromUser,
        'desc': description,
        'profile_id': profileId,
      });
      await fetchTopics();
    } catch (e) {
      debugPrint('Error adding topic: $e');
    }
  }

  Future<void> fetchTopics() async {
    final profileId = await _getProfileId();
    if (profileId == null) return;

    try {
      final response = await _supabase
          .from('topics')
          .select('*, notes(*)')
          .eq('profile_id', profileId)
          .order('created_at');

      currentTopics.clear();
      currentTopics.addAll(
          response.map((json) => Topic.fromJson(json)).toList());
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching topics: $e');
    }
  }

  Future<Topic?> fetchTopicById(String id) async {
    final profileId = await _getProfileId();
    if (profileId == null) return null;

    try {
      final data = await _supabase
          .from('topics')
          .select('*, notes(*)')
          .eq('id', id)
          .eq('profile_id', profileId)
          .single();
      return Topic.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching topic by ID: $e');
      return null;
    }
  }

  Future<void> updateTopic(String id, String newText, {String? newDescription}) async {
    final profileId = await _getProfileId();
    if (profileId == null) return;

    try {
      await _supabase.from('topics').update({
        'text': newText,
        'desc': newDescription,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id).eq('profile_id', profileId);

      await fetchTopics();
    } catch (e) {
      debugPrint('Error updating topic: $e');
    }
  }

  Future<void> deleteTopic(String id) async {
    final profileId = await _getProfileId();
    if (profileId == null) return;

    try {
      await _supabase
          .from('topics')
          .delete()
          .eq('id', id)
          .eq('profile_id', profileId);

      await fetchTopics();
    } catch (e) {
      debugPrint('Error deleting topic: $e');
    }
  }

  // --- NOTE OPERATIONS ---
  Future<void> addNoteToTopic(String topicId, String title, String content) async {
    final profileId = await _getProfileId();
    if (profileId == null) return;

    try {
      await _supabase.from('notes').insert({
        'title': title,
        'content': content,
        'topic_id': topicId,
        'profile_id': profileId,
      });
      await fetchTopics();
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
  }

  Future<void> updateNote(String noteId, String newTitle, String newContent) async {
    final profileId = await _getProfileId();
    if (profileId == null) return;

    try {
      await _supabase.from('notes').update({
        'title': newTitle,
        'content': newContent,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', noteId).eq('profile_id', profileId);

      await fetchTopics();
    } catch (e) {
      debugPrint('Error updating note: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    final profileId = await _getProfileId();
    if (profileId == null) return;

    try {
      await _supabase
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('profile_id', profileId);

      await fetchTopics();
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }

  Future<List<Assessment>> fetchAssessmentsWithDueDates() async {
    final profileId = await _getProfileId();
    if (profileId == null) return [];

    try {
      // ✅ FIX: This query now fetches the actual IDs of the questions.
      // The !inner join ensures we only get assessments that have questions.
      final assessmentsData = await _supabase
          .from('assessment')
          .select('*, topic:topics(*), question!inner(id)')
          .eq('profile_id', profileId);

      final List<Assessment> assessments = [];
      for (var item in assessmentsData) {
        // Now, this part of the code will have a valid list of question IDs to work with.
        final questionIds = (item['question'] as List).map((q) => q['id'] as String).toList();

        if (questionIds.isNotEmpty) {
          final reviewResponse = await _supabase
              .from('card_reviews')
              .select('due')
              .inFilter('question_id', questionIds)
              .order('due', ascending: true)
              .limit(1);

          if (reviewResponse.isNotEmpty) {
            item['due'] = reviewResponse.first['due'];
          }
        }

        final topic = Topic.fromJson(item['topic']);
        assessments.add(Assessment.fromMap(item, topic));
      }
      return assessments;
    } catch (e) {
      debugPrint('Error fetching assessments with due dates: $e');
      return [];
    }
  }


  Future<int> countDueAssessments() async {
    await refreshDueAssessmentsCount();
    return _dueAssessmentsCount;
  }

  // ... (rest of the class remains the same)
  /// **Handles the entire process of generating a new assessment for a note.**
  Future<void> generateAssessmentForNote({
    required String noteId,
    required String topicId,
    required String assessmentTitle,
    required List<Question> questions,
  }) async {
    final profileId = await _getProfileId();
    if (profileId == null) return;

    try {
      // ... (Step 1 and 2 remain the same)
      await _supabase
          .from('question')
          .update({'is_archived': true})
          .eq('note_id', noteId);

      final assessmentResponse = await _supabase.from('assessment').insert({
        'topic_id': topicId,
        'profile_id': profileId,
        'title': assessmentTitle,
      }).select('id').single();

      final assessmentId = assessmentResponse['id'];

      for (final questionModel in questions) {
        // ✅ FIX: Added profile_id to the question insert map
        final questionResponse = await _supabase.from('question').insert({
          'assessment_id': assessmentId,
          'note_id': noteId,
          'question_text': questionModel.questionText,
          'question_type': 'multiple_choice',
          'is_archived': false,
          'profile_id': profileId,
          'topic_id': topicId,
        }).select('id').single();

        final questionId = questionResponse['id'];



        final optionsToInsert = questionModel.options.map((option) => {
          'question_id': questionId,
          'option_text': option.optionText,
          'is_correct': option.isCorrect,
        }).toList();

        await _supabase.from('answer_option').insert(optionsToInsert);
      }

      await refreshDueAssessmentsCount();

    } catch (e) {
      debugPrint('Error generating assessment for note: $e');
      rethrow;
    }
  }

  /// **Fetches all non-archived questions and their answers for a specific assessment.**
  Future<List<Question>> fetchQuestionsForAssessment(String assessmentId) async {
    try {
      final questionsData = await _supabase
          .from('question')
          .select('*, answer_option(*)') // Fetch questions and their options
          .eq('assessment_id', assessmentId)
          .eq('is_archived', false);

      final List<Question> questions = [];
      for (var qData in questionsData) {
        final optionsData = qData['answer_option'] as List;
        final options = optionsData.map((opt) {
          return AnswerOption(
            id: opt['id'],
            optionText: opt['option_text'],
            isCorrect: opt['is_correct'],
          );
        }).toList();

        options.shuffle(); // Shuffle options for display

        questions.add(Question(
          id: qData['id'],
          questionText: qData['question_text'],
          options: options,
        ));
      }
      return questions;
    } catch (e) {
      debugPrint('Error fetching questions for assessment: $e');
      return [];
    }
  }

  /// **Fetches all assessments for a specific topic.**
  Future<List<Assessment>> fetchAssessmentsForTopic(String topicId) async {
    final profileId = await _getProfileId();
    if (profileId == null) return [];

    try {
      final response = await _supabase
          .from('assessment')
          .select()
          .eq('topic_id', topicId)
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);

      // We need the topic object for the Assessment model, but we already have it
      final topic = await fetchTopicById(topicId);
      if (topic == null) return [];

      return response.map((data) => Assessment.fromMap(data, topic)).toList();
    } catch (e) {
      debugPrint('Error fetching assessments for topic: $e');
      return [];
    }
  }
}