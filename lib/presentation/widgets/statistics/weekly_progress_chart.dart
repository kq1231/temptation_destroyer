import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/statistics_model.dart';
import '../../providers/statistics_provider.dart';

class WeeklyProgressChart extends ConsumerWidget {
  final StatisticsModel statistics;

  const WeeklyProgressChart({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyProgressAsync = ref.watch(weeklyProgressProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: weeklyProgressAsync.when(
                data: (data) => _buildWeeklyChart(context, data),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error',
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(
      BuildContext context, Map<String, dynamic> weeklyData) {
    final List<String> labels = List<String>.from(weeklyData['labels']);
    final List<int> values = List<int>.from(weeklyData['values']);

    final weekData = List.generate(
      7,
      (index) => {
        'day': labels[index],
        'success': values[index] == 1,
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weekData.map((day) {
        final bool isSuccess = day['success'] as bool;
        return _buildDayColumn(
          context,
          day['day'] as String,
          isSuccess,
        );
      }).toList(),
    );
  }

  Widget _buildDayColumn(BuildContext context, String day, bool success) {
    final double height = success ? 100.0 : 30.0;
    final Color color = success ? Colors.green : Colors.red;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: color.withAlpha(180),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Success', Colors.green),
        const SizedBox(width: 24),
        _buildLegendItem('Slip', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withAlpha(180),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
