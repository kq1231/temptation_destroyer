import 'package:flutter/foundation.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../data/models/challenge_model.dart';

class CreateDailyChallengeUseCase {
  final ChallengeRepository _repository;

  CreateDailyChallengeUseCase(this._repository);

  /// Create a new daily challenge
  Future<ChallengeModel> call({
    ChallengeDifficulty difficulty = ChallengeDifficulty.medium,
    ChallengeCategory? preferredCategory,
  }) async {
    try {
      return await _repository.createDailyChallenge(
        difficulty: difficulty,
        preferredCategory: preferredCategory,
      );
    } catch (e) {
      debugPrint('Error creating daily challenge: $e');
      rethrow;
    }
  }
}
