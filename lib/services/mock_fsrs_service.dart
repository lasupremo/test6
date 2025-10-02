/*
import 'package:fsrs/fsrs.dart' as fsrs;
import '../models/card_review.dart';

class MockFsrsService {
  final fsrs.Scheduler _algorithm = fsrs.Scheduler();
  final Map<String, CardReview> _cardReviews = {};

  Future<void> updateCardReview(String questionId, fsrs.Rating rating) async {
    CardReview? currentReview = _cardReviews[questionId];
    fsrs.Card cardToRepeat = currentReview?.card ?? await fsrs.Card.create();

    final result = _algorithm.reviewCard(cardToRepeat, rating);
    final newCard = result.card;

    final updatedReview = CardReview(
      id: currentReview?.id ?? questionId,
      userId: 'mock_user',
      questionId: questionId,
      card: newCard,
      nextDueDate: newCard.due,
    );

    _cardReviews[questionId] = updatedReview;

    // These print statements are useful for debugging your FSRS logic
    print('Updated FSRS state for question "$questionId":');
    print('  - New Stability: ${newCard.stability?.toStringAsFixed(2) ?? 'N/A'}');
    print('  - Next Review Date: ${newCard.due.toLocal()}');
  }

  /// Get the average next review date for all cards that were reviewed in this session
  /// Returns null if no cards have been reviewed
  DateTime? getAverageNextReviewDate(List<String> questionIds) {
    if (questionIds.isEmpty) return null;

    final reviewedCards = questionIds
        .map((id) => _cardReviews[id])
        .where((review) => review != null)
        .cast<CardReview>()
        .toList();

    if (reviewedCards.isEmpty) return null;

    // Calculate average timestamp
    final totalMilliseconds = reviewedCards
        .map((review) => review.nextDueDate.millisecondsSinceEpoch)
        .reduce((sum, timestamp) => sum + timestamp);

    final averageTimestamp = totalMilliseconds ~/ reviewedCards.length;
    return DateTime.fromMillisecondsSinceEpoch(averageTimestamp);
  }

  /// Get all review dates for the given question IDs (for debugging/detailed view)
  List<DateTime> getReviewDates(List<String> questionIds) {
    return questionIds
        .map((id) => _cardReviews[id]?.nextDueDate)
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();
  }

  /// Get the earliest next review date (when you should start studying again)
  DateTime? getEarliestReviewDate(List<String> questionIds) {
    final dates = getReviewDates(questionIds);
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  /// Get the latest next review date (when you'll finish all reviews)
  DateTime? getLatestReviewDate(List<String> questionIds) {
    final dates = getReviewDates(questionIds);
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }
}
*/