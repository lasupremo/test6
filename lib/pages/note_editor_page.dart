import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:rekindle/models/assessment.dart';
import 'package:rekindle/services/gemini_service.dart';
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
  late QuillController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  String? _titleError;

  final GeminiService _geminiService = GeminiService();
  bool _isGeneratingAssessment = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    final initialContent = widget.note?.content ?? '';
    try {
      // FIX: Correctly initialize QuillController from plain text
      _contentController = QuillController(
        document: initialContent.isNotEmpty
            ? Document.fromDelta(Delta()..insert(initialContent))
            : Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      _contentController = QuillController.basic();
    }

    _titleController.addListener(_onTitleChanged);
    _contentController.addListener(_onContentChanged);

    if (widget.note == null) {
      _hasUnsavedChanges = true;
    }

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
    _onContentChanged();
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _generateAssessment() async {
    if (widget.note?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the note before generating an assessment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_isGeneratingAssessment) return;

    setState(() {
      _isGeneratingAssessment = true;
    });

    final noteContent = _contentController.document.toPlainText();
    final localContext = context; // FIX: Capture context before async gap

    final aiResponse = await _geminiService.generateQuestionsFromNote(
      noteContent: noteContent,
      context: localContext,
    );

    if (!mounted) return; // FIX: Guard against async gaps

    if (aiResponse.containsKey('error')) {
      setState(() {
        _isGeneratingAssessment = false;
      });
      return;
    }

    final String assessmentTitle = aiResponse['title'];
    final List<dynamic> questionsJson = aiResponse['questions'];
    final List<Question> questions = questionsJson
        .map((json) => Question.fromJson(json))
        .toList();

    try {
      await context.read<TopicDatabase>().generateAssessmentForNote(
        noteId: widget.note!.id!,
        topicId: widget.topicId,
        assessmentTitle: assessmentTitle,
        questions: questions,
      );

      if (!mounted) return; // FIX: Guard against async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New assessment generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return; // FIX: Guard against async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save the assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if(mounted) {
        setState(() {
          _isGeneratingAssessment = false;
        });
      }
    }
  }

  bool _isDuplicateNoteTitle(String title, {String? excludeNoteId}) {
    if (!mounted) return false;
    final topicDatabase = context.read<TopicDatabase>();
    final currentTopic = topicDatabase.currentTopics
        .firstWhere((topic) => topic.id == widget.topicId, orElse: () => Topic(id: '', text: '', profileId: ''));
    
    final notes = currentTopic.notes ?? [];
    return notes.any((note) =>
        note.title.toLowerCase() == title.toLowerCase() &&
        note.id != excludeNoteId);
  }

  String _generateUniqueUntitledTitle({String? excludeNoteId}) {
    String baseTitle = "Untitled";
    String finalTitle = baseTitle;
    int counter = 1;
    while (_isDuplicateNoteTitle(finalTitle, excludeNoteId: excludeNoteId)) {
      finalTitle = "$baseTitle ($counter)";
      counter++;
    }
    return finalTitle;
  }

  void _validateTitle() {
    final title = _titleController.text.trim();
    String? newError;
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
    setState(() => _isSaving = true);

    try {
      final userTitle = _titleController.text.trim();
      final content = _contentController.document.toPlainText().trim();
      String finalTitle;

      if (userTitle.isEmpty) {
        finalTitle = _generateUniqueUntitledTitle(excludeNoteId: widget.note?.id);
      } else if (_isDuplicateNoteTitle(userTitle, excludeNoteId: widget.note?.id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("A note with this title already exists. Please choose a different title."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
        }
        return;
      } else {
        finalTitle = userTitle;
      }

      final topicDatabase = context.read<TopicDatabase>();

      if (widget.note == null) {
        await topicDatabase.addNoteToTopic(widget.topicId, finalTitle, content);
      } else {
        await topicDatabase.updateNote(widget.note!.id!, finalTitle, content);
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
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
          TextButton(onPressed: () => Navigator.of(context).pop('discard'), child: const Text('Discard')),
          TextButton(onPressed: () => Navigator.of(context).pop('cancel'), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop('save'), child: const Text('Save')),
        ],
      ),
    );

    switch (result) {
      case 'discard':
        return true;
      case 'save':
        final userTitle = _titleController.text.trim();
        if (userTitle.isNotEmpty && _isDuplicateNoteTitle(userTitle, excludeNoteId: widget.note?.id)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cannot save: A note with this title already exists."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
        await _saveNote();
        return false;
      case 'cancel':
      default:
        return false;
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
    final title = _titleController.text.trim();
    final content = _contentController.document.toPlainText().trim();
    final hasContent = title.isNotEmpty || content.isNotEmpty;
    final hasBlockingError = title.isNotEmpty && _titleError != null;
    final canSave = (_hasUnsavedChanges || hasContent) && !hasBlockingError;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.topicTitle, style: const TextStyle(fontSize: 16)),
          actions: [
            if (_isGeneratingAssessment)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(
                icon: const Icon(Icons.quiz_outlined),
                tooltip: 'Generate Assessment',
                onPressed: widget.note?.id != null ? _generateAssessment : null,
              ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      border: InputBorder.none,
                      errorStyle: const TextStyle(height: 0),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _contentFocusNode.requestFocus(),
                  ),
                  if (_titleError != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(_titleError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(
              color: _titleError != null
                  ? Colors.red.withOpacity(0.3)
                  : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              indent: 20,
              endIndent: 20,
            ),
            Expanded(
              child: Column(
                children: [
                  QuillToolbar.simple(
                    configurations: QuillSimpleToolbarConfigurations(
                      controller: _contentController,
                      showAlignmentButtons: true,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: QuillEditor.basic(
                        configurations: QuillEditorConfigurations(
                          controller: _contentController,
                          padding: EdgeInsets.zero,
                          autoFocus: false,
                          expands: true,
                          placeholder: 'Start writing...',
                        ),
                        focusNode: _contentFocusNode,
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