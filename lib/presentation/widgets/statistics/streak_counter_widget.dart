import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StreakCounterWidget extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final DateTime? streakStartDate;

  const StreakCounterWidget({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    this.streakStartDate,
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
              'Your Streak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakCounter(
                  context,
                  'Current',
                  currentStreak,
                  Colors.green,
                ),
                _buildStreakCounter(
                  context,
                  'Best',
                  bestStreak,
                  Colors.blue,
                ),
              ],
            ),
            if (streakStartDate != null) ...[
              const SizedBox(height: 16),
              Text(
                'Started on: ${DateFormat('MMM d, yyyy').format(streakStartDate!)}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
            if (currentStreak > 0) ...[
              const SizedBox(height: 8),
              _buildMotivationalMessage(currentStreak),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCounter(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count == 1 ? '1 day' : '$count days',
          style: TextStyle(
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalMessage(int streak) {
    String message;

    if (streak < 3) {
      message = 'Ma sha Allah! Great start! Keep going!';
    } else if (streak < 7) {
      message = 'Alhamdulillah! You\'re doing well!';
    } else if (streak < 30) {
      message = 'SubhanAllah! You\'re building strength!';
    } else if (streak < 90) {
      message = 'Allahu Akbar! Amazing consistency!';
    } else if (streak < 180) {
      message = 'Ma sha Allah! This is truly remarkable!';
    } else {
      message = 'Allahu Akbar! You are an inspiration!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          color: Colors.green,
        ),
      ),
    );
  }
}
