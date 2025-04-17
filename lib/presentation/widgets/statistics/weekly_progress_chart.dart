import 'package:flutter/material.dart';
import '../../../data/models/statistics_model.dart';

class WeeklyProgressChart extends StatelessWidget {
  final StatisticsModel statistics;

  const WeeklyProgressChart({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
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
              child: _buildWeeklyChart(context),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    // For MVP, we're using a simple representation
    // In a real app, we would use a chart library
    // like fl_chart, charts_flutter or syncfusion_flutter_charts

    // This is hard-coded for demonstration
    // Eventually this would come from actual user data
    final weekData = [
      {'day': 'Mon', 'success': true},
      {'day': 'Tue', 'success': true},
      {'day': 'Wed', 'success': true},
      {'day': 'Thu', 'success': false},
      {'day': 'Fri', 'success': true},
      {'day': 'Sat', 'success': true},
      {'day': 'Sun', 'success': true},
    ];

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
