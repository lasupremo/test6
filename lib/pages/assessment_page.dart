import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rekindle/components/app_card.dart';
import 'package:rekindle/components/answer_option_widget.dart';
import 'package:rekindle/models/assessment.dart';
import 'package:rekindle/services/gemini_service.dart';
import 'package:rekindle/services/fsrs_service.dart';
// import 'package:rekindle/services/mock_assessment_service.dart'; // Keep for testing
import 'package:rekindle/theme/theme.dart';
import '../models/topic.dart';
import 'assessment_results_page.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:supabase_flutter/supabase_flutter.dart';

class AssessmentPage extends StatefulWidget {
  final Topic topic;
  const AssessmentPage({super.key, required this.topic});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  // --- STATE & LOGIC ---
  final FsrsService _fsrsService = FsrsService();
  final GeminiService _assessmentService = GeminiService();
  // final MockAssessmentService _assessmentService = MockAssessmentService(); // MOCK SERVICE

  List<Question> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _answered = false;
  int _score = 0;
  int? _selectedDifficultyIndex;
  bool _isDifficultyLocked = false;
  bool _isCorrectAnswer = false;
  String? _assessmentId;
  String? _attemptId;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _generateAssessment();
  }

  void _generateAssessment() async {
    setState(() {
      _isLoading = true;
      _score = 0;
      _currentIndex = 0;
      _answered = false;
      _selectedOptionIndex = null;
      _selectedDifficultyIndex = null;
      _isDifficultyLocked = false;
      _questions = [];
      _isCorrectAnswer = false;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _profileId = user.id;

      final assessmentResponse =
          await Supabase.instance.client.from('assessment').insert({
        'topic_id': widget.topic.id,
        'profile_id': _profileId,
        'status': 'in_progress'
      }).select();
      _assessmentId = assessmentResponse[0]['id'];

      final attemptResponse =
          await Supabase.instance.client.from('user_attempt').insert({
        'profile_id': _profileId,
        'assessment_id': _assessmentId,
        'attempt_date': DateTime.now().toIso8601String(),
        'total_points': 0
      }).select();
      _attemptId = attemptResponse[0]['id'];

      final notesContent =
          widget.topic.notes?.map((n) => n.content).join('\n\n') ?? '';
      if (notesContent.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "There are no notes in this topic to create an assessment from.")),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final generatedQuestions = await _assessmentService
          .generateFlashcardQuestions(notesContent, widget.topic.id!);

      setState(() {
        _questions = generatedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to generate assessment: $e")),
        );
      }
    }
  }

  void _handleAnswer(int? selectedIndex) {
    if (selectedIndex == null) return;
    final bool isCorrect =
        _questions[_currentIndex].options[selectedIndex].isCorrect;

    if (_attemptId != null) {
      Supabase.instance.client.from('user_answer').insert({
        'attempt_id': _attemptId,
        'question_id': _questions[_currentIndex].id,
        'answer_option_id': null,
        'answer_text':
            _questions[_currentIndex].options[selectedIndex].optionText,
        'earned_points': isCorrect ? 1 : 0,
      }).then((_) {}, onError: (e) {
        debugPrint('Error saving user answer: $e');
      });
    }

    setState(() {
      _answered = true;
      _selectedOptionIndex = selectedIndex;
      _isCorrectAnswer = isCorrect;
      if (isCorrect) {
        _score++;
        _isDifficultyLocked = false;
      } else {
        _selectedDifficultyIndex = 0;
        _isDifficultyLocked = true;
        _handleDifficultyFeedback(fsrs.Rating.again);
        Timer(const Duration(milliseconds: 1200), _nextCard);
      }
    });
  }

  void _handleDifficultyFeedback(fsrs.Rating rating) {
    final questionId = _questions[_currentIndex].id;
    
    if (_profileId != null && questionId != null) {
      _fsrsService.updateCardReview(questionId, _profileId!, rating);
    }
  }

  void _nextCard() async {
    if (!mounted) return;

    if (_isCorrectAnswer && _selectedDifficultyIndex != null) {
      final difficultyRatings = [
        fsrs.Rating.hard,
        fsrs.Rating.good,
        fsrs.Rating.easy
      ];
      _handleDifficultyFeedback(difficultyRatings[_selectedDifficultyIndex!]);
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedOptionIndex = null;
        _selectedDifficultyIndex = null;
        _isDifficultyLocked = false;
        _isCorrectAnswer = false;
      });
    } else {
      _finishAssessment();
    }
  }

  void _finishAssessment() async {
    if (_attemptId != null) {
      await Supabase.instance.client
          .from('user_attempt')
          .update({'total_points': _score}).eq('id', _attemptId!);
    }
    if (_assessmentId != null) {
      await Supabase.instance.client
          .from('assessment')
          .update({'status': 'completed'}).eq('id', _assessmentId!);
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentResultsPage(
          score: _score,
          totalQuestions: _questions.length,
          onFinish: () => Navigator.pop(context, false),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: getQuizTheme(context),
      child: Builder(builder: (context) {
        return Scaffold(
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? _buildErrorView(context)
                    : _buildQuizView(context),
          ),
        );
      }),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load quiz. Please go back and try again.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final progress =
        (_questions.isEmpty) ? 0.0 : (_currentIndex + 1) / _questions.length;

    return Column(
      children: [
        _buildAppBar(context, progress),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildQuestionCard(context, currentQuestion),
                if (_answered && _isCorrectAnswer) ...[
                  const SizedBox(height: 24),
                  _buildDifficultySelector(context),
                ]
              ],
            ),
          ),
        ),
        if (_answered && _isCorrectAnswer) _buildNextButton(context),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon:
                Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, Question question) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 24),
            Column(
              children: List.generate(question.options.length, (index) {
                return AnswerOptionWidget(
                  option: question.options[index],
                  index: index,
                  selectedOptionIndex: _selectedOptionIndex,
                  hasAnswered: _answered,
                  onSelected: _handleAnswer,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<String> difficulties = ["Hard", "Medium", "Easy"];
    final Map<int, Color> chipBackgroundColors = {
      0: colorScheme.tertiaryContainer,
      1: colorScheme.secondaryContainer,
      2: colorScheme.primaryContainer,
    };
    final Map<int, Color> chipTextColors = {
      0: colorScheme.onTertiaryContainer,
      1: colorScheme.onSecondaryContainer,
      2: colorScheme.onPrimaryContainer,
    };

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('How well did you know this?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(difficulties.length, (index) {
                final isSelected = _selectedDifficultyIndex == index;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(difficulties[index]),
                      selected: isSelected,
                      onSelected: _isDifficultyLocked
                          ? null
                          : (selected) {
                              setState(() {
                                _selectedDifficultyIndex = selected ? index : null;
                              });
                            },
                      backgroundColor: chipBackgroundColors[index],
                      selectedColor: chipBackgroundColors[index],
                      disabledColor: chipBackgroundColors[index]!.withAlpha(150),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: chipTextColors[index],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? chipTextColors[index]!
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    final bool isLastQuestion = _currentIndex == _questions.length - 1;
    final bool isEnabled = _selectedDifficultyIndex != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _nextCard : null,
        icon: Icon(isLastQuestion ? Icons.check_circle : Icons.arrow_forward),
        label: Text(isLastQuestion ? 'Finish Assessment' : 'Next Question'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor:
              Theme.of(context).colorScheme.primary.withAlpha(127),
          disabledForegroundColor:
              Theme.of(context).colorScheme.onPrimary.withAlpha(178),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }
}