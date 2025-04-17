import 'package:flutter/foundation.dart';
import '../../../data/repositories/statistics_repository.dart';

class UpdatePatternsUseCase {
  final StatisticsRepository _statisticsRepository;

  UpdatePatternsUseCase(this._statisticsRepository);

  /// Update trigger patterns
  Future<void> updateTriggerPatterns(
      {required Map<String, int> patterns}) async {
    try {
      await _statisticsRepository.updateTriggerPatterns(patterns);
    } catch (e) {
      debugPrint('Error updating trigger patterns: $e');
      rethrow;
    }
  }

  /// Update time patterns
  Future<void> updateTimePatterns({required Map<String, int> patterns}) async {
    try {
      await _statisticsRepository.updateTimePatterns(patterns);
    } catch (e) {
      debugPrint('Error updating time patterns: $e');
      rethrow;
    }
  }
}
