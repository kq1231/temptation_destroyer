import 'dart:convert';
import 'dart:developer' as developer;

import '../models/statistics_model.dart';
import '../models/emergency_session_model.dart';
import '../../objectbox.g.dart';

class StatisticsRepository {
  final Box<StatisticsModel> _statisticsBox;
  final Box<EmergencySession> _emergencySessionBox;

  StatisticsRepository(Store store)
      : _statisticsBox = store.box<StatisticsModel>(),
        _emergencySessionBox = store.box<EmergencySession>();

  // Get the user's statistics, create if doesn't exist
  Future<StatisticsModel> getStatistics() async {
    try {
      // Get the first stats record or create one if it doesn't exist
      final stats = _statisticsBox.getAll();
      if (stats.isNotEmpty) {
        return stats.first;
      } else {
        final newStats = StatisticsModel.empty();
        _statisticsBox.put(newStats);
        return newStats;
      }
    } catch (e) {
      developer.log('Error getting statistics: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to get statistics: $e');
    }
  }

  // Save updated statistics
  Future<int> saveStatistics(StatisticsModel statistics) async {
    try {
      return _statisticsBox.put(statistics);
    } catch (e) {
      developer.log('Error saving statistics: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to save statistics: $e');
    }
  }

  // Calculate current streak
  Future<int> calculateCurrentStreak() async {
    try {
      final stats = await getStatistics();

      // Get all emergency sessions ordered by end time
      final query = _emergencySessionBox
          .query()
          .order(EmergencySession_.endTime, flags: Order.descending)
          .build();
      final sessions = query.find();
      query.close();

      if (sessions.isEmpty) {
        // No emergency sessions yet, start with 0 streak
        if (stats.currentStreak == 0) {
          return 0;
        }

        // Already has a streak, check if it's still valid
        final today = DateTime.now();
        final lastUpdate = stats.lastUpdatedDate;
        final difference = today.difference(lastUpdate).inDays;

        // If it's been more than 1 day since last update, streak is broken
        if (difference > 1) {
          stats.currentStreak = 0;
          stats.streakStartDate = null;
          await saveStatistics(stats);
          return 0;
        }

        // Streak is still valid
        return stats.currentStreak;
      }

      // Get the most recent session
      final latestSession = sessions.first;

      // If the latest session is still active, no streak calculation needed
      if (latestSession.isActive) {
        return stats.currentStreak;
      }

      // Get the date of the last slip
      final lastSlipDate = latestSession.endTime?.toLocal().midnight() ??
          DateTime.now().midnight();
      final today = DateTime.now().midnight();
      final difference = today.difference(lastSlipDate).inDays;

      // Count streak (days since last slip)
      int calculatedStreak = difference;

      // Update streak if different
      if (calculatedStreak != stats.currentStreak) {
        stats.currentStreak = calculatedStreak;

        // Reset streak start date if streak was broken
        if (calculatedStreak == 0 || calculatedStreak == 1) {
          stats.streakStartDate = lastSlipDate.add(const Duration(days: 1));
        }

        // Update best streak if current is better
        if (calculatedStreak > stats.bestStreak) {
          stats.bestStreak = calculatedStreak;
        }

        // Save updated stats
        stats.lastUpdatedDate = DateTime.now();
        await saveStatistics(stats);
      }

      return calculatedStreak;
    } catch (e) {
      developer.log('Error calculating streak: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to calculate streak: $e');
    }
  }

  // Record a slip date
  Future<void> recordSlip(DateTime slipDate) async {
    try {
      final stats = await getStatistics();

      // Parse existing slip dates
      List<DateTime> slipDates = [];
      if (stats.slipDatesJson.isNotEmpty) {
        final dateStrings = jsonDecode(stats.slipDatesJson) as List;
        slipDates = dateStrings
            .map((dateStr) => DateTime.parse(dateStr as String))
            .toList();
      }

      // Add new slip date
      slipDates.add(slipDate);

      // Sort by date (newest first)
      slipDates.sort((a, b) => b.compareTo(a));

      // Convert back to JSON
      final dateStrings =
          slipDates.map((date) => date.toIso8601String()).toList();
      stats.slipDatesJson = jsonEncode(dateStrings);

      // Reset streak
      stats.currentStreak = 0;
      stats.streakStartDate = slipDate.add(const Duration(days: 1));
      stats.lastUpdatedDate = DateTime.now();

      // Save updated stats
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error recording slip: $e', name: 'StatisticsRepository');
      throw Exception('Failed to record slip: $e');
    }
  }

  // Add trigger date
  Future<void> recordTrigger(DateTime triggerDate) async {
    try {
      final stats = await getStatistics();

      // Parse existing trigger dates
      List<DateTime> triggerDates = [];
      if (stats.triggerDatesJson.isNotEmpty) {
        final dateStrings = jsonDecode(stats.triggerDatesJson) as List;
        triggerDates = dateStrings
            .map((dateStr) => DateTime.parse(dateStr as String))
            .toList();
      }

      // Add new trigger date
      triggerDates.add(triggerDate);

      // Sort by date (newest first)
      triggerDates.sort((a, b) => b.compareTo(a));

      // Convert back to JSON
      final dateStrings =
          triggerDates.map((date) => date.toIso8601String()).toList();
      stats.triggerDatesJson = jsonEncode(dateStrings);

      // Save updated stats
      stats.lastUpdatedDate = DateTime.now();
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error recording trigger: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to record trigger: $e');
    }
  }

  // Record a milestone
  Future<void> recordMilestone(
      DateTime milestoneDate, String milestoneName) async {
    try {
      final stats = await getStatistics();

      // Parse existing milestone dates
      List<Map<String, dynamic>> milestones = [];
      if (stats.milestoneDatesJson.isNotEmpty) {
        final milestonesData = jsonDecode(stats.milestoneDatesJson) as List;
        milestones = milestonesData.cast<Map<String, dynamic>>();
      }

      // Add new milestone
      milestones.add({
        'date': milestoneDate.toIso8601String(),
        'name': milestoneName,
      });

      // Sort by date (newest first)
      milestones.sort((a, b) => DateTime.parse(b['date'] as String)
          .compareTo(DateTime.parse(a['date'] as String)));

      // Convert back to JSON
      stats.milestoneDatesJson = jsonEncode(milestones);

      // Save updated stats
      stats.lastUpdatedDate = DateTime.now();
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error recording milestone: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to record milestone: $e');
    }
  }

  // Update trigger patterns
  Future<void> updateTriggerPatterns(Map<String, int> patterns) async {
    try {
      final stats = await getStatistics();
      stats.triggerPatternJson = jsonEncode(patterns);
      stats.lastUpdatedDate = DateTime.now();
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error updating trigger patterns: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to update trigger patterns: $e');
    }
  }

  // Update time patterns
  Future<void> updateTimePatterns(Map<String, int> patterns) async {
    try {
      final stats = await getStatistics();
      stats.timePatternJson = jsonEncode(patterns);
      stats.lastUpdatedDate = DateTime.now();
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error updating time patterns: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to update time patterns: $e');
    }
  }

  // Increment emergencies survived count
  Future<void> incrementEmergenciesSurvived() async {
    try {
      final stats = await getStatistics();
      stats.totalEmergenciesSurvived++;
      stats.lastUpdatedDate = DateTime.now();
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error incrementing emergencies survived: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to increment emergencies survived: $e');
    }
  }

  // Increment challenges completed count
  Future<void> incrementChallengesCompleted() async {
    try {
      final stats = await getStatistics();
      stats.totalChallengesCompleted++;
      stats.lastUpdatedDate = DateTime.now();
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error incrementing challenges completed: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to increment challenges completed: $e');
    }
  }

  // Update weekly improvement
  Future<void> updateWeeklyImprovement(double percentage) async {
    try {
      final stats = await getStatistics();
      stats.weeklyImprovement = percentage;
      stats.lastUpdatedDate = DateTime.now();
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error updating weekly improvement: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to update weekly improvement: $e');
    }
  }

  // Update monthly improvement
  Future<void> updateMonthlyImprovement(double percentage) async {
    try {
      final stats = await getStatistics();
      stats.monthlyImprovement = percentage;
      stats.lastUpdatedDate = DateTime.now();
      await saveStatistics(stats);
    } catch (e) {
      developer.log('Error updating monthly improvement: $e',
          name: 'StatisticsRepository');
      throw Exception('Failed to update monthly improvement: $e');
    }
  }
}

// Extension to get midnight of a date (for streak calculation)
extension DateTimeExtension on DateTime {
  DateTime midnight() {
    return DateTime(year, month, day);
  }
}
