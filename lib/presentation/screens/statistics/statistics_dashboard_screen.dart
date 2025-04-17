import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/statistics_model.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/statistics/streak_counter_widget.dart';
import '../../widgets/statistics/weekly_progress_chart.dart';
import '../../widgets/statistics/milestone_list_widget.dart';
import '../../widgets/statistics/emergency_stats_widget.dart';
import '../../widgets/common/loading_indicator.dart';

class StatisticsDashboardScreen extends ConsumerWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(statisticsProvider),
            tooltip: 'Refresh statistics',
          ),
        ],
      ),
      body: statisticsAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Failed to load statistics: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (statistics) => _buildStatisticsContent(context, statistics),
      ),
    );
  }

  Widget _buildStatisticsContent(
      BuildContext context, StatisticsModel statistics) {
    return RefreshIndicator(
      onRefresh: () async {
        // This will be handled by the provider
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak counter card
            StreakCounterWidget(
              currentStreak: statistics.currentStreak,
              bestStreak: statistics.bestStreak,
              streakStartDate: statistics.streakStartDate,
            ),

            const SizedBox(height: 20),

            // Weekly progress chart
            WeeklyProgressChart(statistics: statistics),

            const SizedBox(height: 20),

            // Emergency stats
            EmergencyStatsWidget(
              totalEmergenciesSurvived: statistics.totalEmergenciesSurvived,
              weeklyImprovement: statistics.weeklyImprovement,
              monthlyImprovement: statistics.monthlyImprovement,
            ),

            const SizedBox(height: 20),

            // Recent milestones
            const Text(
              'Recent Milestones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            MilestoneListWidget(
                milestoneDatesJson: statistics.milestoneDatesJson),
          ],
        ),
      ),
    );
  }
}
