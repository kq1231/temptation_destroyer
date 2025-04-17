import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/statistics_model.dart';
import '../../data/repositories/statistics_repository.dart';
import '../../core/utils/object_box_manager.dart';

// Provider for the statistics repository
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ObjectBoxManager.instance.store);
});

// Provider for getting the user's statistics
final statisticsProvider = FutureProvider<StatisticsModel>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getStatistics();
});

// Provider for getting the current streak
final streakProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.calculateCurrentStreak();
});

// Provider for the weekly progress data
final weeklyProgressProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final statistics = await ref.watch(statisticsProvider.future);

  // In a real implementation, we would parse the JSON data from statistics
  // and transform it into a format suitable for charts
  // For MVP, we'll return a simple placeholder

  return {
    'labels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'values': [1, 1, 1, 0, 1, 1, 1], // 1 for success days, 0 for slip days
  };
});

// Provider for milestones data
final milestonesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final statistics = await ref.watch(statisticsProvider.future);

  if (statistics.milestoneDatesJson.isEmpty ||
      statistics.milestoneDatesJson == '[]') {
    return [];
  }

  try {
    final List<dynamic> milestones = statistics.milestoneDatesJson.isNotEmpty
        ? List<dynamic>.from(statistics.milestoneDatesJson as List)
        : [];

    return milestones
        .map((milestone) => milestone as Map<String, dynamic>)
        .toList();
  } catch (e) {
    return [];
  }
});
