import 'package:flutter/foundation.dart';
import '../../../data/repositories/statistics_repository.dart';

class CalculateStreakUseCase {
  final StatisticsRepository _statisticsRepository;

  CalculateStreakUseCase(this._statisticsRepository);

  /// Calculate the current streak
  Future<int> execute() async {
    try {
      return await _statisticsRepository.calculateCurrentStreak();
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      rethrow;
    }
  }
}
