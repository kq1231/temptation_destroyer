import 'package:flutter/foundation.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../../data/models/statistics_model.dart';

class GetStatisticsUseCase {
  final StatisticsRepository _statisticsRepository;

  GetStatisticsUseCase(this._statisticsRepository);

  /// Get the user's statistics
  Future<StatisticsModel> execute() async {
    try {
      return await _statisticsRepository.getStatistics();
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      rethrow;
    }
  }
}
