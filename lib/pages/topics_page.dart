import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/drawer.dart';
import '../components/topic_tile.dart';
import '../models/topic.dart';
import '../models/topic_database.dart';
import 'package:provider/provider.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  // text controllers to access what the user typed
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  
  // validation state
  String? titleError;
  bool isCreating = false; // to track if we're creating or editing

  @override
  void initState() {
    super.initState();
    // on app startup, fetch existing topics
    readTopics();
  }

  // Helper method to check for duplicate titles
  bool isDuplicateTitle(String title, {String? excludeTopicId}) {
    final topicDatabase = context.read<TopicDatabase>();
    final currentTopics = topicDatabase.currentTopics;
    
    return currentTopics.any((topic) => 
      topic.text.toLowerCase() == title.toLowerCase() && 
      topic.id != excludeTopicId
    );
  }
  
  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // create a topic
  void createTopic() {
    // Reset validation state for creating
    isCreating = true;
    titleError = null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text("New Topic"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title label and input
                  Text(
                    "Title",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Enter topic name...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: titleError != null ? Colors.red : Colors.grey,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: titleError != null ? Colors.red : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: titleError != null ? Colors.red : Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    autofocus: true,
                    onChanged: (value) {
                      // Real-time validation
                      setDialogState(() {
                        final title = value.trim();
                        if (title.isEmpty) {
                          titleError = null;
                        } else if (isDuplicateTitle(title)) {
                          titleError = "This topic already exists.";
                        } else {
                          titleError = null;
                        }
                      });
                    },
                    onSubmitted: (value) {
                      // Allow creating by pressing enter if title is valid
                      if (value.trim().isNotEmpty && titleError == null) {
                        final description = descriptionController.text.trim();
                        context.read<TopicDatabase>().addTopic(
                          value.trim(),
                          description: description.isEmpty ? null : description,
                        );
                        titleController.clear();
                        descriptionController.clear();
                        Navigator.pop(context);
                      }
                    },
                  ),
                  
                  // Error message
                  if (titleError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      titleError!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Description label and input
                  Text(
                    "Description (Optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: "Enter description...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  titleController.clear();
                  descriptionController.clear();
                  titleError = null;
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: titleController,
                builder: (context, value, child) {
                  final isTitleEmpty = value.text.trim().isEmpty;
                  final hasError = titleError != null;
                  final isButtonDisabled = isTitleEmpty || hasError;
                  
                  return TextButton(
                    onPressed: isButtonDisabled ? null : () {
                      final title = titleController.text.trim();
                      final description = descriptionController.text.trim();
                      
                      // add to db with optional description
                      context.read<TopicDatabase>().addTopic(
                        title,
                        description: description.isEmpty ? null : description,
                      );
                      
                      // clear controllers and reset error
                      titleController.clear();
                      descriptionController.clear();
                      titleError = null;
                      
                      // pop dialog box
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Create",
                      style: TextStyle(
                        color: isButtonDisabled 
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // read topics
  void readTopics() {
    context.read<TopicDatabase>().fetchTopics();
  }

  // update a topic
  void updateTopic(Topic topic) {
    // Reset validation state for editing
    isCreating = false;
    titleError = null;
    
    // pre-fill the current topic text and description
    titleController.text = topic.text;
    descriptionController.text = topic.desc ?? '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text("Edit Topic"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title label and input
                  Text(
                    "Title",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Enter topic name...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: titleError != null ? Colors.red : Colors.grey,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: titleError != null ? Colors.red : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: titleError != null ? Colors.red : Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    autofocus: true,
                    onChanged: (value) {
                      // Real-time validation (exclude current topic from duplicate check)
                      setDialogState(() {
                        final title = value.trim();
                        if (title.isEmpty) {
                          titleError = null;
                        } else if (isDuplicateTitle(title, excludeTopicId: topic.id)) {
                          titleError = "This topic already exists.";
                        } else {
                          titleError = null;
                        }
                      });
                    },
                    onSubmitted: (value) {
                      // Allow updating by pressing enter if text is valid
                      if (value.trim().isNotEmpty && titleError == null && topic.id != null) {
                        final description = descriptionController.text.trim();
                        context.read<TopicDatabase>().updateTopic(
                          topic.id!, 
                          value.trim(),
                          newDescription: description.isEmpty ? null : description,
                        );
                        titleController.clear();
                        descriptionController.clear();
                        Navigator.pop(context);
                      }
                    },
                  ),
                  
                  // Error message
                  if (titleError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      titleError!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Description label and input
                  Text(
                    "Description (Optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: "Enter description...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  titleController.clear();
                  descriptionController.clear();
                  titleError = null;
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: titleController,
                builder: (context, value, child) {
                  final isTitleEmpty = value.text.trim().isEmpty;
                  final hasError = titleError != null;
                  final isButtonDisabled = isTitleEmpty || hasError;
                  
                  return TextButton(
                    onPressed: isButtonDisabled ? null : () {
                      if (topic.id != null) {
                        final title = titleController.text.trim();
                        final description = descriptionController.text.trim();
                        
                        context.read<TopicDatabase>().updateTopic(
                          topic.id!, 
                          title,
                          newDescription: description.isEmpty ? null : description,
                        );
                      }
                      // clear controllers and reset error
                      titleController.clear();
                      descriptionController.clear();
                      titleError = null;
                      // pop dialog box
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Update",
                      style: TextStyle(
                        color: isButtonDisabled 
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // delete a topic
  void deleteTopic(Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text("Delete Topic"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete the topic:",
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        if (topic.desc != null && topic.desc!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            topic.desc!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if ((topic.notes?.length ?? 0) > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${topic.notes!.length} ${topic.notes!.length == 1 ? 'note' : 'notes'}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if ((topic.notes?.length ?? 0) > 0) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "This will also delete all ${topic.notes!.length} note${topic.notes!.length == 1 ? '' : 's'} in this topic.",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              "This action cannot be undone.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (topic.id != null) {
                context.read<TopicDatabase>().deleteTopic(topic.id!);
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
            ),
            child: Text(
              "Delete",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // topic database
    final topicDatabase = context.watch<TopicDatabase>();

    // current topics
    List<Topic> currentTopics = topicDatabase.currentTopics;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: createTopic,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      drawer: const MyDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADING
          Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: Text(
              'Topics',
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),

          // LIST OF TOPICS
          Expanded(
            child: currentTopics.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.topic_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No topics yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to create your first topic',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: currentTopics.length,
                    // Add padding to bottom so FAB doesn't block the last item's menu
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      // get individual topic
                      final topic = currentTopics[index];

                      // list tile UI - now passing the whole topic object
                      return TopicTile(
                        topic: topic,
                        onEditPressed: () => updateTopic(topic),
                        onDeletePressed: () => deleteTopic(topic),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}