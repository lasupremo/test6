import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../components/note_tile.dart';
import '../models/assessment.dart'; // Import Assessment model
import '../models/topic.dart';
import '../models/topic_database.dart';
import 'note_editor_page.dart';

class TopicNotesPage extends StatefulWidget {
  final Topic topic;
  const TopicNotesPage({super.key, required this.topic});

  @override
  State<TopicNotesPage> createState() => _TopicNotesPageState();
}

class _TopicNotesPageState extends State<TopicNotesPage> {
  // NEW: Method to show the list of assessments for this topic
  void _showAssessmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Assessment>>(
          // You need to add this method to your TopicDatabase
          future: context
              .read<TopicDatabase>()
              .fetchAssessmentsForTopic(widget.topic.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text('Assessments'),
                content: const Text('No assessments found for this topic. Generate one from a note!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            final assessments = snapshot.data!;
            return AlertDialog(
              title: Text('Assessments for ${widget.topic.text}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: assessments.length,
                  itemBuilder: (context, index) {
                    final assessment = assessments[index];
                    return ListTile(
                      title: Text(assessment.title ?? 'Untitled Assessment'),
                      subtitle: Text('Created on: ${assessment.createdAt.toLocal().toString().substring(0, 10)}'),
                      onTap: () {
                        // Pop the dialog first
                        Navigator.pop(context);
                        // Then navigate to the assessment page
                        context.go('/home/assessment/${assessment.id}');
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic.text,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // This is the new button to view the list of assessments
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'View Assessments',
            onPressed: () => _showAssessmentsDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorPage(
                topicId: widget.topic.id!,
                topicTitle: widget.topic.text,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<TopicDatabase>(
        builder: (context, topicDatabase, child) {
          final currentTopic = topicDatabase.currentTopics
              .firstWhere((t) => t.id == widget.topic.id);
          final notes = currentTopic.notes ?? [];

          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'No notes yet. Add one to get started!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(note: note, topic: currentTopic);
            },
          );
        },
      ),
    );
  }
}