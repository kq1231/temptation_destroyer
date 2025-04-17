import 'package:flutter/foundation.dart';
import '../../../data/repositories/statistics_repository.dart';

class RecordSlipUseCase {
  final StatisticsRepository _statisticsRepository;

  RecordSlipUseCase(this._statisticsRepository);

  /// Record a slip date (resets streak)
  Future<void> execute({required DateTime slipDate}) async {
    try {
      await _statisticsRepository.recordSlip(slipDate);
    } catch (e) {
      debugPrint('Error recording slip: $e');
      rethrow;
    }
  }
}
