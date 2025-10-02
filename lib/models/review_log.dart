import 'package:fsrs/fsrs.dart' as fsrs;

class ReviewLog {
  final String cardId;
  final String profileId;
  final fsrs.Rating rating;
  final DateTime reviewTime;
  final double? previousStability;
  final double? newStability;
  final double? previousDifficulty;
  final double? newDifficulty;
  final fsrs.State? previousState;
  final fsrs.State? newState;

  ReviewLog({
    required this.cardId,
    required this.profileId,
    required this.rating,
    required this.reviewTime,
    this.previousStability,
    this.newStability,
    this.previousDifficulty,
    this.newDifficulty,
    this.previousState,
    this.newState,
  });

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'profile_id': profileId,
      'rating': rating.index,
      'review_time': reviewTime.toIso8601String(),
      'previous_stability': previousStability,
      'new_stability': newStability,
      'previous_difficulty': previousDifficulty,
      'new_difficulty': newDifficulty,
      'previous_state': previousState?.index,
      'new_state': newState?.index,
    };
  }
}