import 'package:flutter/foundation.dart';
import '../../../data/repositories/statistics_repository.dart';

class RecordTriggerUseCase {
  final StatisticsRepository _statisticsRepository;

  RecordTriggerUseCase(this._statisticsRepository);

  /// Record a trigger occurrence date
  Future<void> execute({required DateTime triggerDate}) async {
    try {
      await _statisticsRepository.recordTrigger(triggerDate);
    } catch (e) {
      debugPrint('Error recording trigger: $e');
      rethrow;
    }
  }
}
