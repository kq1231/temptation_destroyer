import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/statistics_model.dart';
import '../../data/repositories/statistics_repository.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../core/utils/object_box_manager.dart';

// Provider for the statistics repository
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ObjectBoxManager.instance.store);
});

// Provider for the emergency repository
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository();
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
  final emergencyRepo = ref.watch(emergencyRepositoryProvider);
  // Make sure statistics are loaded (dependency)
  await ref.watch(statisticsProvider.future);

  // Get emergency sessions from the past week
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  // Get all emergency sessions from the past week
  final sessions = await emergencyRepo.getSessionsByTimeRange(
    startDate: weekAgo,
    endDate: now,
  );

  // Create a map of day of week to success/failure
  final Map<int, bool> dayResults = {};

  // Process sessions to determine success/failure by day
  for (final session in sessions) {
    if (session.endTime != null) {
      final dayOfWeek = session.endTime!.weekday; // 1 = Monday, 7 = Sunday
      final wasSuccessful = session.wasSuccessful ?? false;

      // If we already have a failure for this day, keep it as failure
      if (dayResults.containsKey(dayOfWeek)) {
        dayResults[dayOfWeek] = dayResults[dayOfWeek]! && wasSuccessful;
      } else {
        dayResults[dayOfWeek] = wasSuccessful;
      }
    }
  }

  // Create the values array (1 for success, 0 for failure)
  final values = List<int>.filled(7, 1); // Default to success

  // Update with actual data
  dayResults.forEach((day, wasSuccessful) {
    // Convert to 0-based index (0 = Monday, 6 = Sunday)
    final index = day - 1;
    values[index] = wasSuccessful ? 1 : 0;
  });

  return {
    'labels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'values': values,
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
