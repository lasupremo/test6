import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../models/topic.dart';
import '../models/topic_database.dart';

class NoteEditorPage extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final Note? note;

  const NoteEditorPage({
    super.key,
    required this.topicId,
    required this.topicTitle,
    this.note,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    // Initialize Quill controller with existing content or empty
    final initialContent = widget.note?.content ?? '';
    if (initialContent.isNotEmpty) {
      try {
        _contentController = quill.QuillController(
          document: quill.Document()..insert(0, initialContent),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _contentController = quill.QuillController.basic();
      }
    } else {
      _contentController = quill.QuillController.basic();
    }

    // Listen for changes
    _titleController.addListener(_onTitleChanged);
    _contentController.addListener(_onContentChanged);

    // For new notes, mark as having changes immediately so save button is enabled
    if (widget.note == null) {
      _hasUnsavedChanges = true;
    }

    // Auto-focus title for new notes, content for existing notes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.note == null) {
        _titleFocusNode.requestFocus();
      } else {
        _contentFocusNode.requestFocus();
      }
    });
  }

  void _onTitleChanged() {
    _validateTitle();
    _onContentChanged(); // Also trigger the general content change handler
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  // Helper method to check for duplicate note titles within the same topic
  bool _isDuplicateNoteTitle(String title, {String? excludeNoteId}) {
    if (!mounted) return false;
    
    final topicDatabase = context.read<TopicDatabase>();
    final currentTopic = topicDatabase.currentTopics
        .firstWhere((topic) => topic.id == widget.topicId);
    
    final notes = currentTopic.notes ?? [];
    
    return notes.any((note) => 
      note.title.toLowerCase() == title.toLowerCase() && 
      note.id != excludeNoteId
    );
  }

  // Generate a unique "Untitled" title with incrementing numbers
  String _generateUniqueUntitledTitle({String? excludeNoteId}) {
    String baseTitle = "Untitled";
    String finalTitle = baseTitle;
    int counter = 1;
    
    // Keep incrementing until we find a unique title
    while (_isDuplicateNoteTitle(finalTitle, excludeNoteId: excludeNoteId)) {
      finalTitle = "$baseTitle ($counter)";
      counter++;
    }
    
    return finalTitle;
  }

  void _validateTitle() {
    final title = _titleController.text.trim();
    String? newError;
    
    // Only show error if user has entered a title that duplicates an existing one
    if (title.isNotEmpty && _isDuplicateNoteTitle(title, excludeNoteId: widget.note?.id)) {
      newError = "A note with this title already exists in this topic.";
    }
    
    if (_titleError != newError) {
      setState(() {
        _titleError = newError;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final userTitle = _titleController.text.trim();
      final content = _contentController.document.toPlainText().trim();

      // Determine the final title
      String finalTitle;
      if (userTitle.isEmpty) {
        // Generate unique "Untitled" title (even if content is empty)
        finalTitle = _generateUniqueUntitledTitle(excludeNoteId: widget.note?.id);
      } else if (_isDuplicateNoteTitle(userTitle, excludeNoteId: widget.note?.id)) {
        // User entered a duplicate title, show error and don't save
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("A note with this title already exists in this topic. Please choose a different title."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else {
        // User entered a valid unique title
        finalTitle = userTitle;
      }

      final topicDatabase = context.read<TopicDatabase>();

      if (widget.note == null) {
        // Create new note (even if both title and content are empty)
        await topicDatabase.addNoteToTopic(
          widget.topicId,
          finalTitle,
          content,
        );
      } else {
        // Update existing note
        await topicDatabase.updateNote(
          widget.note!.id!,
          finalTitle,
          content,
        );
      }

      if (!mounted) return;
      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
      });

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving note: $e')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Unsaved Changes'),
        content: const Text('Do you want to save your changes before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    switch (result) {
      case 'discard':
        // Just exit without saving
        return true;
      case 'save':
        // Try to save, but validate first
        final userTitle = _titleController.text.trim();
        
        // Check if user entered a duplicate title (non-empty)
        if (userTitle.isNotEmpty && _isDuplicateNoteTitle(userTitle, excludeNoteId: widget.note?.id)) {
          // Show error and don't exit
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Cannot save: A note with this title already exists in this topic."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false; // Don't exit, let user fix the issue
        }
        
        // Save the note (even if empty - will auto-generate "Untitled")
        await _saveNote();
        return false; // _saveNote() will handle the navigation
      case 'cancel':
      default:
        return false; // Don't exit
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if save button should be enabled
    final title = _titleController.text.trim();
    final content = _contentController.document.toPlainText().trim();
    final hasContent = title.isNotEmpty || content.isNotEmpty;
    
    // Only disable save if user entered a duplicate title (not when empty)
    final hasBlockingError = title.isNotEmpty && _titleError != null;
    final canSave = _hasUnsavedChanges || hasContent || !hasBlockingError;

    return PopScope(
      canPop: false,
      // Flutter >= 3.22
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await _onWillPop();
          if (shouldExit && mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(
            widget.topicTitle,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: canSave ? _saveNote : null,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: canSave
                        ? Theme.of(context).colorScheme.inversePrimary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Title input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Untitled',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      border: InputBorder.none,
                      errorStyle: const TextStyle(height: 0), // Hide default error text
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _contentFocusNode.requestFocus(),
                  ),
                  
                  // Custom error message for title validation (only for duplicate titles)
                  if (_titleError != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _titleError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Divider
            Divider(
              color: _titleError != null 
                  ? Colors.red.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
              indent: 20,
              endIndent: 20,
            ),

            // Content editor with toolbar
            Expanded(
              child: Column(
                children: [
                  // Quill toolbar
                  Container(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    child: quill.QuillSimpleToolbar(
                      controller: _contentController,
                      // flutter_quill uses `config` here
                      config: const quill.QuillSimpleToolbarConfig(
                        showAlignmentButtons: true,
                        showBackgroundColorButton: false,
                        showClearFormat: true,
                        showCodeBlock: true,
                        showColorButton: false,
                        showDirection: false,
                        showFontFamily: false,
                        showFontSize: false,
                        showHeaderStyle: true,
                        showIndent: true,
                        showInlineCode: true,
                        showLink: true,
                        showListBullets: true,
                        showListCheck: true,
                        showListNumbers: true,
                        showQuote: true,
                        showSmallButton: false,
                        showStrikeThrough: true,
                        showUnderLineButton: true,
                      ),
                    ),
                  ),

                  // Content editor
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: quill.QuillEditor.basic(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        // and `config` here
                        config: const quill.QuillEditorConfig(
                          placeholder: 'Start writing...',
                          padding: EdgeInsets.zero,
                          autoFocus: false,
                          expands: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}