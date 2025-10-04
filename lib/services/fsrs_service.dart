import 'dart:math';
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

    final previousState = card.state;
    final previousStability = card.stability;
    final previousDifficulty = card.difficulty;

    final result = _scheduler.reviewCard(card, rating);
    final newReview = CardReview.fromCard(result.card, profileId, questionId);

    String cardReviewId;
    if (existingReview != null) {
      final updatedRows = await _supabase
          .from('card_reviews')
          .update(newReview.toJson())
          .eq('id', existingReview.id!)
          .eq('profile_id', profileId) 
          .select();
      cardReviewId = updatedRows[0]['id'];
    } else {
      final insertedRows =
          await _supabase.from('card_reviews').insert(newReview.toJson()).select();
      cardReviewId = insertedRows[0]['id'];
    }

    final log = ReviewLog(
      // ✅ FIX: Use 'cardId' to match the ReviewLog model, which maps to 'card_id' in toJson.
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
    
    // ✅ FIX: Corrected the table name from 'review_log' to 'review_logs'.
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
  
  double calculateRetrievability(DateTime lastReview, double stability) {
    final double elapsedDays =
        DateTime.now().difference(lastReview).inMilliseconds / (1000 * 60 * 60 * 24);

    if (elapsedDays < 0 || stability <= 0) {
      return 1.0;
    }

    return exp(-elapsedDays / stability);
  }
}