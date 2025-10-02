import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AssessmentResultsPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final VoidCallback onFinish;
  final DateTime? averageNextReviewDate;
  final DateTime? earliestReviewDate;
  final DateTime? latestReviewDate;

  const AssessmentResultsPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.onFinish,
    this.averageNextReviewDate,
    this.earliestReviewDate,
    this.latestReviewDate,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quiz Complete!',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Score',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$score / $totalQuestions',
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              
              // FSRS Review Information Section
              if (earliestReviewDate != null) ...[
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Next Review',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Next Review Date (when you should start studying again)
                      _buildReviewInfo(
                        context,
                        'Study this topic again',
                        earliestReviewDate!,
                        Icons.school_outlined,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              TextButton(
                onPressed: onFinish,
                child: Text(
                  'Finish',
                  style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewInfo(
    BuildContext context,
    String label,
    DateTime date,
    IconData icon, {
    bool isCompact = false,
  }) {
    final now = DateTime.now();
    final difference = date.difference(now);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    String timeUntil;
    if (difference.inDays > 0) {
      timeUntil = '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      timeUntil = '${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      timeUntil = '${difference.inMinutes} minutes';
    } else {
      timeUntil = 'Now';
    }

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeUntil,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            timeUntil,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${dateFormat.format(date)} at ${timeFormat.format(date)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}