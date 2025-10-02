import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'topic.dart';

class TopicDatabase extends ChangeNotifier {
  final SupabaseClient _supabase;
  // final String? _userId;
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

    // The user's ID from authentication IS the profile ID. No database query needed.
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
      // Fetch topics with their associated notes using a JOIN
      final response = await _supabase
          .from('topics')
          .select('*, notes(*)')
          .eq('profile_id', profileId)
          .order('created_at');
          
      currentTopics.clear();
      currentTopics.addAll(
        response.map((json) => Topic.fromJson(json)).toList()
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching topics: $e');
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
      // This will cascade delete all notes in this topic
      await _supabase.from('topics')
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
      await _supabase.from('notes')
          .delete()
          .eq('id', noteId)
          .eq('profile_id', profileId);
      
      await fetchTopics();
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }
}
