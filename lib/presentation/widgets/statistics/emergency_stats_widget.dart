import 'package:flutter/material.dart';

class EmergencyStatsWidget extends StatelessWidget {
  final int totalEmergenciesSurvived;
  final double weeklyImprovement;
  final double monthlyImprovement;

  const EmergencyStatsWidget({
    super.key,
    required this.totalEmergenciesSurvived,
    required this.weeklyImprovement,
    required this.monthlyImprovement,
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
              'Emergency Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Total Emergencies\nSurvived',
                  totalEmergenciesSurvived.toString(),
                  Icons.shield,
                  Colors.purple,
                ),
                _buildStatColumn(
                  'Weekly\nImprovement',
                  _formatPercentage(weeklyImprovement),
                  Icons.trending_up,
                  _getImprovementColor(weeklyImprovement),
                ),
                _buildStatColumn(
                  'Monthly\nImprovement',
                  _formatPercentage(monthlyImprovement),
                  Icons.calendar_month,
                  _getImprovementColor(monthlyImprovement),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatPercentage(double value) {
    if (value > 0) {
      return '+${value.toStringAsFixed(1)}%';
    } else if (value < 0) {
      return '${value.toStringAsFixed(1)}%';
    } else {
      return '0%';
    }
  }

  Color _getImprovementColor(double value) {
    if (value > 0) {
      return Colors.green;
    } else if (value < 0) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildInsightMessage() {
    // This would be more dynamic in a real app based on actual data
    String message;

    if (totalEmergenciesSurvived == 0) {
      message = 'Ma sha Allah! No emergency situations yet. Stay strong!';
    } else if (totalEmergenciesSurvived < 5) {
      message =
          'Alhamdulillah! You\'ve overcome $totalEmergenciesSurvived difficult situations.';
    } else if (weeklyImprovement > 0) {
      message =
          'SubhanAllah! You\'re improving this week. Keep up the great work!';
    } else if (monthlyImprovement > 0) {
      message = 'Alhamdulillah! Your monthly progress shows improvement.';
    } else {
      message =
          'Remember, every test is an opportunity for growth. Stay strong!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          color: Colors.blue,
        ),
      ),
    );
  }
}
