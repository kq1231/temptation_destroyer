import 'package:flutter/foundation.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../data/models/challenge_model.dart';

class GetActiveChallengesUseCase {
  final ChallengeRepository _repository;

  GetActiveChallengesUseCase(this._repository);

  /// Get all active (not completed) challenges
  Future<List<ChallengeModel>> call() async {
    try {
      return _repository.getActiveChallenges();
    } catch (e) {
      debugPrint('Error retrieving active challenges: $e');
      return [];
    }
  }
}
