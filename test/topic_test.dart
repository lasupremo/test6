import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:rekindle/models/topic_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockSupabaseHttpClient mockHttpClient;
  late SupabaseClient mockClient;
  late TopicDatabase topicDb;

  setUpAll(() {
    mockHttpClient = MockSupabaseHttpClient();
    mockClient = SupabaseClient(
      'https://mock.supabase.co',
      'fakeAnonKey',
      httpClient: mockHttpClient,
    );
    topicDb = TopicDatabase.test(mockClient);
  });

  tearDown(() async {
    // Reset the mock data after each test
    mockHttpClient.reset();
  });

  tearDownAll(() {
    // Close the mock client after all tests
    mockHttpClient.close();
  });

  test('creating topics works', () async {
    await topicDb.addTopic("Sample");

    expect(topicDb.currentTopics.length, 1);
    expect(topicDb.currentTopics.first.text, "Sample");
  });

  test('fetching topics works', () async {
    await mockClient.from('topics').insert({
      'id': '1',
      'user_id': 'test-user',
      'text': 'Hello world',
    });

    await topicDb.fetchTopics();
    expect(topicDb.currentTopics.length, 1);
  });

  test('updating topics works', () async {
    await mockClient.from('topics').insert({
      'id': '1',
      'user_id': 'test-user',
      'text': 'Old Text',
    });
    await topicDb.updateTopic('1','New Text');

    expect(topicDb.currentTopics.first.text, "New Text");
  });

  test('deleting topics works', () async {
    await mockClient.from('topics').insert([
  {
    'id': '1',
    'user_id': 'test-user',
    'text': 'Testing',
    'created_at': DateTime.now().toIso8601String(),
  },
  {
    'id': '2',
    'user_id': 'test-user',
    'text': 'Testing 2',
    'created_at': DateTime.now().toIso8601String(),
  },
  {
    'id': '3',
    'user_id': 'test-user',
    'text': 'Testing 3',
    'created_at': DateTime.now().toIso8601String(),
  },
]);
    await topicDb.fetchTopics();
    expect(topicDb.currentTopics.length, 3);
    await topicDb.deleteTopic('1');
    expect(topicDb.currentTopics.length, 2);
  });
}