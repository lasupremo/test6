import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../components/note_tile.dart';
import '../models/assessment.dart';
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
  void _showAssessmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Assessment>>(
          // ✅ FIX: Added a null check (!) because topic.id is required here.
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
                      title: Text(assessment.title),
                      subtitle: Text('Created on: ${assessment.createdAt.toLocal().toString().substring(0, 10)}'),
                      onTap: () {
                        Navigator.pop(context);
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

  void _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // ✅ FIX: Added a null check (!) on note.id.
      await context.read<TopicDatabase>().deleteNote(note.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${note.title}"')),
        );
      }
    }
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
                // ✅ FIX: Added null checks (!) as these are required.
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
          // ✅ FIX: Provide a default empty list if notes is null.
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
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(
                note: note,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorPage(
                        // ✅ FIX: Added null checks (!) as these are required.
                        topicId: widget.topic.id!,
                        topicTitle: widget.topic.text,
                        note: note,
                      ),
                    ),
                  );
                },
                onDelete: () => _deleteNote(note),
              );
            },
          );
        },
      ),
    );
  }
}