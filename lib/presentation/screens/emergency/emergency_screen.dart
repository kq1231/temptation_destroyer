import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/emergency_session_provider.dart';
import '../../providers/emergency_timer_provider.dart';
import 'emergency_resolution_form.dart';

/// Screen that displays when the user is in an active emergency session
class EmergencyScreen extends ConsumerWidget {
  /// Constructor
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch emergency session state
    final emergencyState = ref.watch(emergencySessionProvider);

    // Watch timer state
    final timerState = ref.watch(emergencyTimerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.emergencyScreenTitle),
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: Colors.white,
      ),
      body: emergencyState.activeSession == null
          ? _buildNoActiveSessionView(context)
          : _buildActiveSessionView(context, ref, timerState),
    );
  }

  /// Build the view when there's no active session
  Widget _buildNoActiveSessionView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          const Text(
            'No active emergency session',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re doing great! Keep up the good work.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }

  /// Build the view when there's an active session
  Widget _buildActiveSessionView(
    BuildContext context,
    WidgetRef ref,
    EmergencyTimerState timerState,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency timer display
            _buildTimerCard(context, timerState),
            const SizedBox(height: 24),

            // Emergency tips
            _buildTipsCard(context),
            const SizedBox(height: 24),

            // Quick actions
            _buildActionsCard(context, ref),
            const SizedBox(height: 32),

            // End session button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showResolutionForm(context, ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  AppStrings.endSessionButtonText,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the timer card
  Widget _buildTimerCard(BuildContext context, EmergencyTimerState timerState) {
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

  /// Build the emergency tips card
  Widget _buildTipsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tips_and_updates, color: AppColors.info),
                SizedBox(width: 8),
                Text(
                  AppStrings.emergencyTipsHeading,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _EmergencyTip(
              title: 'Step away',
              description:
                  'Change your environment immediately. Walk outside, go to a different room, or just stand up.',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: 12),
            const _EmergencyTip(
              title: 'Deep breathing',
              description:
                  'Take 5 deep breaths, inhaling for 4 seconds and exhaling for 6 seconds.',
              icon: Icons.air,
            ),
            const SizedBox(height: 12),
            const _EmergencyTip(
              title: 'Call someone',
              description:
                  'Reach out to a trusted friend or family member who knows about your struggle.',
              icon: Icons.phone,
            ),
            const SizedBox(height: 12),
            const _EmergencyTip(
              title: 'Remember your "why"',
              description:
                  'Think about why you started this journey and the person you want to become.',
              icon: Icons.lightbulb,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the quick actions card
  Widget _buildActionsCard(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.warning),
                SizedBox(width: 8),
                Text(
                  AppStrings.emergencyActionsHeading,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionButton(
                    label: 'Call Friend',
                    icon: Icons.phone,
                    color: AppColors.secondary,
                    onPressed: () {
                      // TODO: Implement call friend action
                    },
                  ),
                  const SizedBox(width: 12),
                  _QuickActionButton(
                    label: 'Go for a Walk',
                    icon: Icons.directions_walk,
                    color: AppColors.primary,
                    onPressed: () {
                      // TODO: Implement go for a walk action
                    },
                  ),
                  const SizedBox(width: 12),
                  _QuickActionButton(
                    label: 'Cold Shower',
                    icon: Icons.shower,
                    color: AppColors.info,
                    onPressed: () {
                      // TODO: Implement cold shower action
                    },
                  ),
                  const SizedBox(width: 12),
                  _QuickActionButton(
                    label: 'Push-ups',
                    icon: Icons.fitness_center,
                    color: AppColors.emotionalTrigger,
                    onPressed: () {
                      // TODO: Implement push-ups action
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the resolution form to end the session
  void _showResolutionForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const EmergencyResolutionForm(),
    );
  }
}

/// Widget for displaying an emergency tip
class _EmergencyTip extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _EmergencyTip({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(51),
          radius: 20,
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget for a quick action button
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: Icon(icon, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
