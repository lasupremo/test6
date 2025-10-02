import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/topic.dart';
import '../models/topic_database.dart';
import '../components/note_tile.dart';
import 'note_editor_page.dart';
import 'assessment_page.dart';

class TopicNotesPage extends StatefulWidget {
  final Topic topic;
  
  const TopicNotesPage({
    super.key,
    required this.topic,
  });

  @override
  State<TopicNotesPage> createState() => _TopicNotesPageState();
}

class _TopicNotesPageState extends State<TopicNotesPage> {
  @override
  void initState() {
    super.initState();
    // Fetch the latest data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopicDatabase>().fetchTopics();
    });
  }

  void createNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          topicId: widget.topic.id!,
          topicTitle: widget.topic.text,
        ),
      ),
    );
  }

  void editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          topicId: widget.topic.id!,
          topicTitle: widget.topic.text,
          note: note,
        ),
      ),
    );
  }

  void deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Delete Note"),
        content: Text("Are you sure you want to delete '${note.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (note.id != null) {
                context.read<TopicDatabase>().deleteNote(note.id!);
              }
              Navigator.pop(context);
            },
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TopicDatabase>(
      builder: (context, topicDatabase, child) {
        // Find the current topic with updated notes
        final currentTopic = topicDatabase.currentTopics
            .firstWhere((topic) => topic.id == widget.topic.id);
        
        final notes = currentTopic.notes ?? [];

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(
              widget.topic.text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Start Assessment',
                icon: const Icon(Icons.quiz_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssessmentPage(topic: currentTopic),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: createNewNote,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic title and note count
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.topic.text,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Notes list
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notes yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to create your first note',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 80, // Add bottom padding so FAB doesn't block the last note's menu
                        ),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return NoteTile(
                            note: note,
                            onTap: () => editNote(note),
                            onDelete: () => deleteNote(note),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}