import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rekindle/components/app_card.dart';
import 'package:rekindle/components/answer_option_widget.dart';
import 'package:rekindle/models/assessment.dart';
import 'package:rekindle/services/fsrs_service.dart';
import 'package:rekindle/theme/theme.dart';
import 'package:rekindle/models/topic_database.dart';
import 'assessment_results_page.dart';

class AssessmentPage extends StatefulWidget {
  final String assessmentId;
  const AssessmentPage({super.key, required this.assessmentId});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final FsrsService _fsrsService = FsrsService();

  List<Question> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _answered = false;
  int _score = 0;
  int? _selectedDifficultyIndex;
  bool _isDifficultyLocked = false;
  bool _isCorrectAnswer = false;
  String? _attemptId;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _loadAssessmentAndStartAttempt();
  }

  Future<void> _loadAssessmentAndStartAttempt() async {
    // This now correctly calls the method you added to TopicDatabase
    final questions = await context
        .read<TopicDatabase>()
        .fetchQuestionsForAssessment(widget.assessmentId);
    
    final user = Supabase.instance.client.auth.currentUser;
    if (!mounted || user == null || questions.isEmpty) {
      if(mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    
    _profileId = user.id;

    final attemptResponse = await Supabase.instance.client.from('user_attempt').insert({
      'profile_id': _profileId,
      'assessment_id': widget.assessmentId,
      'attempt_date': DateTime.now().toIso8601String(),
    }).select('id').single();

    if (mounted) {
      setState(() {
        _questions = questions;
        _attemptId = attemptResponse['id'];
        _isLoading = false;
      });
    }
  }

  void _handleAnswer(int? selectedIndex) {
    if (_answered || selectedIndex == null) return;

    final isCorrect = _questions[_currentIndex].options[selectedIndex].isCorrect;

    if (_attemptId != null && _questions[_currentIndex].id != null) {
      Supabase.instance.client.from('user_answer').insert({
        'attempt_id': _attemptId,
        'question_id': _questions[_currentIndex].id,
        'answer_text': _questions[_currentIndex].options[selectedIndex].optionText,
        'earned_points': isCorrect ? 1 : 0,
      }).onError((e, _) => debugPrint('Error saving user answer: $e'));
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

  void _nextCard() {
    if (!mounted) return;

    if (_isCorrectAnswer && _selectedDifficultyIndex != null) {
      final difficultyRatings = [fsrs.Rating.hard, fsrs.Rating.good, fsrs.Rating.easy];
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

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentResultsPage(
          score: _score,
          totalQuestions: _questions.length,
          onFinish: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
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
            const Text('Could not load quiz questions. Please go back and try again.',
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
    final progress = (_questions.isEmpty) ? 0.0 : (_currentIndex + 1) / _questions.length;

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
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
      0: colorScheme.errorContainer,
      1: colorScheme.secondaryContainer,
      2: colorScheme.primaryContainer,
    };
    final Map<int, Color> chipTextColors = {
      0: colorScheme.onErrorContainer,
      1: colorScheme.onSecondaryContainer,
      2: colorScheme.onPrimaryContainer,
    };

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('How well did you know this?', style: Theme.of(context).textTheme.titleMedium),
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
                          color: isSelected ? chipTextColors[index]! : Colors.transparent,
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
          disabledBackgroundColor: Theme.of(context).colorScheme.primary.withAlpha(127),
          disabledForegroundColor: Theme.of(context).colorScheme.onPrimary.withAlpha(178),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }
}