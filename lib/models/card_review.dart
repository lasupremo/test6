import 'package:fsrs/fsrs.dart' as fsrs;

class CardReview {
  final String? id;
  final String profileId;
  final String questionId;
  DateTime due;
  double? stability;
  double? difficulty;
  fsrs.State state;
  DateTime? lastReview;
  int lapses;
  int reps;

  CardReview({
    this.id,
    required this.profileId,
    required this.questionId,
    required this.due,
    this.stability,
    this.difficulty,
    required this.state,
    this.lastReview,
    required this.lapses,
    required this.reps,
  });

  factory CardReview.fromCard(fsrs.Card card, String profileId, String questionId) {
    return CardReview(
      profileId: profileId,
      questionId: questionId,
      due: card.due,
      stability: card.stability,
      difficulty: card.difficulty,
      state: card.state,
      lastReview: card.lastReview,
      lapses: 0,
      reps: 0,
    );
  }

  Future<fsrs.Card> toCard() async {
    final card = await fsrs.Card.create();
    card.due = due;
    card.stability = stability;
    card.difficulty = difficulty;
    card.state = state;
    card.lastReview = lastReview;
    return card;
  }

  factory CardReview.fromJson(Map<String, dynamic> json) {
    return CardReview(
      id: json['id'],
      profileId: json['profile_id'],
      questionId: json['question_id'],
      due: DateTime.parse(json['due']),
      stability: (json['stability'] as num?)?.toDouble(),
      difficulty: (json['difficulty'] as num?)?.toDouble(),
      state: fsrs.State.values[json['state']],
      lastReview: json['last_review'] != null
          ? DateTime.parse(json['last_review'])
          : null,
      lapses: json['lapses'] ?? 0,
      reps: json['reps'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'question_id': questionId,
      'due': due.toIso8601String(),
      'stability': stability,
      'difficulty': difficulty,
      'state': state.index,
      'last_review': lastReview?.toIso8601String(),
      'lapses': lapses,
      'reps': reps,
    };
  }
}