import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/emergency_timer_provider.dart';

/// A dedicated widget for displaying the emergency timer
/// This widget is optimized to only rebuild when the timer changes
class EmergencyTimerWidget extends ConsumerWidget {
  /// Constructor
  const EmergencyTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only the timer state to minimize rebuilds
    final timerState = ref.watch(emergencyTimerProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              AppStrings.emergencyTimerLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              timerState.formattedTime,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.emergencyRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timerState.humanReadableTime,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
