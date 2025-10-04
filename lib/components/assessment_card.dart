import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekindle/models/assessment.dart';
import 'app_card.dart';

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:${twoDigitMinutes}:$twoDigitSeconds";
}

class AssessmentCard extends StatefulWidget {
  final Assessment assessment;
  const AssessmentCard({super.key, required this.assessment});

  @override
  State<AssessmentCard> createState() => _AssessmentCardState();
}

class _AssessmentCardState extends State<AssessmentCard> {
  Timer? _timer;
  Duration _timeUntilDue = Duration.zero;
  bool _isOverdue = false;

  @override
  void initState() {
    super.initState();
    _updateTimeUntilDue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeUntilDue();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeUntilDue() {
    // Use the correct 'due' field from the assessment model.
    if (widget.assessment.due != null) {
      final now = DateTime.now();
      
      // Use the corrected variable here as well.
      final dueDate = widget.assessment.due!.toLocal(); 
      
      final difference = dueDate.difference(now);

      if (mounted) {
        setState(() {
          _timeUntilDue = difference.isNegative ? Duration.zero : difference;
          _isOverdue = difference.isNegative && difference.abs() > const Duration(days: 1);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Card is interactable only if the status is correct AND the countdown is finished.
    final bool isReady = _timeUntilDue == Duration.zero;
    // The card is now interactable if it is brand new ('Pending'),
    // or if it is ready for review ('Due', 'Overdue').
    final bool isInteractable =
        widget.assessment.status == 'Pending' ||
        widget.assessment.status == 'Due' ||
        widget.assessment.status == 'Overdue';

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_isOverdue) {
      statusText = 'Overdue';
      statusColor = Colors.red;
      statusIcon = Icons.warning_amber_rounded;
    } else if (isReady) {
      statusText = 'Ready to Review';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = formatDuration(_timeUntilDue);
      statusColor = Theme.of(context).colorScheme.onSurface;
      statusIcon = Icons.timer_outlined;
    }

    return Opacity(
      opacity: isInteractable ? 1.0 : 0.6,
      child: AppCard(
        child: InkWell(
          onTap: isInteractable
              ? () => context.go('/home/assessment/${widget.assessment.id}')
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.assessment.topic.text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.assessment.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(context, Icons.question_answer_outlined, '${widget.assessment.questionCount} Questions'),
                    _buildStat(context, statusIcon, statusText, color: statusColor),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String text, {Color? color}) {
    final defaultColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? defaultColor.withAlpha(204)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color ?? defaultColor.withAlpha(204),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}