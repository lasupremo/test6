import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_review.dart';
import '../models/review_log.dart';

class FsrsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final fsrs.Scheduler _scheduler = fsrs.Scheduler();

  Future<CardReview?> getCardReview(String questionId, String profileId) async {
    final response = await _supabase
        .from('card_reviews')
        .select()
        .eq('question_id', questionId)
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return CardReview.fromJson(response);
  }

  Future<void> updateCardReview(
      String questionId, String profileId, fsrs.Rating rating) async {
    final existingReview = await getCardReview(questionId, profileId);

    fsrs.Card card;
    if (existingReview != null) {
      card = await existingReview.toCard();
    } else {
      card = await fsrs.Card.create();
    }

    // *** THIS IS THE FIX: Capture the "before" state ***
    final previousState = card.state;
    final previousStability = card.stability;
    final previousDifficulty = card.difficulty;

    final result = _scheduler.reviewCard(card, rating);
    final newReview = CardReview.fromCard(result.card, profileId, questionId);

    // Save or update the card review
    String cardReviewId;
    if (existingReview != null) {
      final updatedRows = await _supabase
          .from('card_reviews')
          .update(newReview.toJson())
          .eq('id', existingReview.id!)
          .select();
      cardReviewId = updatedRows[0]['id'];
    } else {
      final insertedRows =
          await _supabase.from('card_reviews').insert(newReview.toJson()).select();
      cardReviewId = insertedRows[0]['id'];
    }
    
    // *** THIS IS THE FIX: Create and insert the review log ***
    final log = ReviewLog(
      cardId: cardReviewId,
      profileId: profileId,
      rating: rating,
      reviewTime: DateTime.now(),
      previousStability: previousStability,
      newStability: newReview.stability,
      previousDifficulty: previousDifficulty,
      newDifficulty: newReview.difficulty,
      previousState: previousState,
      newState: newReview.state,
    );
    
    await _supabase.from('review_logs').insert(log.toJson());
  }

  Future<List<CardReview>> getDueCards(String profileId) async {
    final response = await _supabase
        .from('card_reviews')
        .select()
        .eq('profile_id', profileId)
        .lte('due', DateTime.now().toIso8601String());

    return (response as List)
        .map((json) => CardReview.fromJson(json))
        .toList();
  }
}