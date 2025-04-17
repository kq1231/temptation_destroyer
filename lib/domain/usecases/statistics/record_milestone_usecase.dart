import 'package:flutter/foundation.dart';
import '../../../data/repositories/statistics_repository.dart';

class RecordMilestoneUseCase {
  final StatisticsRepository _statisticsRepository;

  RecordMilestoneUseCase(this._statisticsRepository);

  /// Record a milestone achievement
  Future<void> execute(
      {required DateTime date, required String milestoneName}) async {
    try {
      await _statisticsRepository.recordMilestone(date, milestoneName);
    } catch (e) {
      debugPrint('Error recording milestone: $e');
      rethrow;
    }
  }
}
