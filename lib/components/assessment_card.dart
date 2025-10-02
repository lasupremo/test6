import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/assessment.dart';

class AssessmentCard extends StatefulWidget {
  final Assessment assessment;
  const AssessmentCard({super.key, required this.assessment});

  @override
  State<AssessmentCard> createState() => _AssessmentCardState();
}

class _AssessmentCardState extends State<AssessmentCard> with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _timeUntilDue = Duration.zero;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _updateDuration();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _updateDuration();
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _isDueOrPastDue()) {
              _animationController.forward();
            }
          });
        }
      });

    if (_isDueOrPastDue()) {
      _animationController.forward();
    }
  }

  void _updateDuration() {
    // The dueDate is retrieved from the associated card_review record
    final dueDate = widget.assessment.dueDate;
    if (dueDate != null) {
      setState(() {
        _timeUntilDue = dueDate.difference(DateTime.now());
      });
    }
  }

  bool _isDueOrPastDue() {
    return _timeUntilDue.isNegative;
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).colorScheme.inversePrimary;
    String statusText = '';

    if (_isDueOrPastDue()) {
      if (_timeUntilDue.abs() > const Duration(days: 1)) {
        cardColor = Colors.red[800]!;
        textColor = Colors.white;
        statusText = '• Past Due';
      } else {
        cardColor = Colors.green[800]!;
        textColor = Colors.white;
        statusText = '• Due Now';
      }
    }

    return GestureDetector(
      onTap: () {
        // Navigate to the assessment page to begin the quiz
        context.go('/home/assessment/${widget.assessment.id}');
      },
      child: ScaleTransition(
        scale: _animation,
        child: Card(
          color: cardColor,
          margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            title: Text(
              widget.assessment.title ?? 'Untitled Assessment', // Use the new title field
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Topic: ${widget.assessment.topic.text} $statusText',
              style: TextStyle(color: textColor.withOpacity(0.9)),
            ),
            trailing: Text(
              _formatDuration(_timeUntilDue),
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}