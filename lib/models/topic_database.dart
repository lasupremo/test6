import 'package:flutter/material.dart';
import 'package:rekindle/models/assessment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'topic.dart';

class TopicDatabase extends ChangeNotifier {
  final SupabaseClient _supabase;
  String? _profileId; // Cache the profile ID

  TopicDatabase()
      : _supabase = Supabase.instance.client,
        _profileId = Supabase.instance.client.auth.currentUser?.id;

  TopicDatabase.test(SupabaseClient mockClient, {String dummyUserId = "test-user"})
      : _supabase = mockClient,
        _profileId = dummyUserId;

  final List<Topic> currentTopics = [];

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

  // --- TOPIC OPERATIONS ---
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

  // --- ASSESSMENT OPERATIONS ---

  /// **Fetches assessments and joins them with their topic and earliest due date.**
  /// This uses the `get_assessments_with_due_dates` PostgreSQL function in Supabase.
  Future<List<Assessment>> fetchAssessmentsWithDueDates() async {
    final profileId = await _getProfileId();
    if (profileId == null) return [];

    try {
      final assessmentsData = await _supabase.rpc('get_assessments_with_due_dates');
      final List<Assessment> assessments = [];

      for (var item in assessmentsData) {
        final topic = await fetchTopicById(item['topic_id']);
        if (topic != null) {
          assessments.add(Assessment.fromMap(item, topic));
        }
      }
      return assessments;
    } catch (e) {
      debugPrint('Error fetching assessments with due dates: $e');
      return [];
    }
  }

  /// **Counts how many assessments are currently due.**
  /// Used for the summary card on the home page.
  Future<int> countDueAssessments() async {
    final profileId = await _getProfileId();
    if (profileId == null) return 0;
    
    try {
      final response = await _supabase
          .rpc('get_assessments_with_due_dates')
          .lte('due', DateTime.now().toIso8601String());

      return response.length;
    } catch (e) {
      debugPrint('Error counting due assessments: $e');
      return 0;
    }
  }

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
      // **Step 1: Archive old questions related to this note.**
      await _supabase
          .from('question')
          .update({'is_archived': true})
          .eq('note_id', noteId);

      // **Step 2: Create a new assessment record.**
      final assessmentResponse = await _supabase.from('assessment').insert({
        'topic_id': topicId,
        'profile_id': profileId,
        'title': assessmentTitle,
      }).select('id').single();

      final assessmentId = assessmentResponse['id'];

      // **Step 3: Prepare and insert the new questions and their answer options.**
      for (final questionModel in questions) {
        // Insert the question and get its new ID
        final questionResponse = await _supabase.from('question').insert({
          'assessment_id': assessmentId,
          'note_id': noteId,
          'question_text': questionModel.questionText,
          'question_type': 'multiple_choice', // default type
          'is_archived': false,
        }).select('id').single();

        final questionId = questionResponse['id'];

        // Prepare all answer options for this question
        final optionsToInsert = questionModel.options.map((option) => {
          'question_id': questionId,
          'option_text': option.optionText,
          'is_correct': option.isCorrect,
        }).toList();

        // Bulk insert the answer options
        await _supabase.from('answer_option').insert(optionsToInsert);
      }

      // Optionally, you might want to trigger the initial FSRS card review creation here.
      
    } catch (e) {
      debugPrint('Error generating assessment for note: $e');
      // Optionally re-throw or handle the error in the UI
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