import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/emergency_context_builder.dart';
import '../../providers/emergency_session_provider_refactored.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/emergency/emergency_widgets.dart';
import '../../widgets/emergency/emergency_timer_widget.dart';
import '../../widgets/emergency_chat_widget.dart';
import 'emergency_resolution_form.dart';

/// Screen that displays when the user is in an active emergency session
class EmergencyScreen extends ConsumerWidget {
  /// Constructor
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch emergency session state
    final asyncEmergencyState = ref.watch(emergencySessionNotifierProvider);

    return asyncEmergencyState.when(
      loading: () => _buildLoadingView(),
      error: (error, stackTrace) => _buildErrorView(error),
      data: (emergencyState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.emergencyScreenTitle),
            backgroundColor: AppColors.emergencyRed,
            foregroundColor: Colors.white,
          ),
          body: emergencyState.activeSession == null
              ? _buildNoActiveSessionView(context)
              : _buildActiveSessionView(context, ref),
        );
      },
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
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency timer display - using dedicated widget
            const EmergencyTimerWidget(),
            const SizedBox(height: 24),

            // AI Guidance section
            _buildAIGuidanceCard(context, ref),
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

  /// Build the AI guidance card
  Widget _buildAIGuidanceCard(BuildContext context, WidgetRef ref) {
    // Get the active emergency session
    final emergencyState = ref.watch(emergencySessionNotifierProvider).value;
    final activeSession = emergencyState?.activeSession;

    // Get personalized context for AI guidance
    final guidanceText = ref.watch(emergencyContextProvider(activeSession));

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
                Icon(Icons.psychology, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'AI Guidance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              guidanceText,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Clear any existing chat session
                ref.invalidate(chatProvider);

                // Navigate to AI guidance screen with emergency mode activated
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Consumer(
                      builder: (context, ref, _) {
                        // Activate emergency mode directly
                        return Scaffold(
                          body: EmergencyChatWidget(
                            triggerMessage:
                                'Emergency Session: ${activeSession?.sessionId ?? "Active"}',
                            onExit: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.chat),
              label: const Text('Get Personalized Guidance'),
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
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            SizedBox(height: 16),
            EmergencyTip(
              title: 'Step away',
              description:
                  'Change your environment immediately. Walk outside, go to a different room, or just stand up.',
              icon: Icons.directions_walk,
            ),
            SizedBox(height: 12),
            EmergencyTip(
              title: 'Deep breathing',
              description:
                  'Take 5 deep breaths, inhaling for 4 seconds and exhaling for 6 seconds.',
              icon: Icons.air,
            ),
            SizedBox(height: 12),
            EmergencyTip(
              title: 'Call someone',
              description:
                  'Reach out to a trusted friend or family member who knows about your struggle.',
              icon: Icons.phone,
            ),
            SizedBox(height: 12),
            EmergencyTip(
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
                  QuickActionButton(
                    label: 'Call Friend',
                    icon: Icons.phone,
                    color: AppColors.secondary,
                    onPressed: () {
                      // Show a dialog with suggested contacts
                      _showContactsDialog(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  QuickActionButton(
                    label: 'Go for a Walk',
                    icon: Icons.directions_walk,
                    color: AppColors.primary,
                    onPressed: () {
                      // Show a dialog with walking suggestions
                      _showWalkingTipsDialog(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  QuickActionButton(
                    label: 'Cold Shower',
                    icon: Icons.shower,
                    color: AppColors.info,
                    onPressed: () {
                      // Show a dialog with cold shower benefits
                      _showColdShowerDialog(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  QuickActionButton(
                    label: 'Push-ups',
                    icon: Icons.fitness_center,
                    color: AppColors.emotionalTrigger,
                    onPressed: () {
                      // Show a dialog with exercise suggestions
                      _showExerciseDialog(context);
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

  /// Show a dialog with suggested contacts
  void _showContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call a Friend'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reaching out to someone you trust can help during difficult moments.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Consider calling:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• A close friend who knows about your struggles'),
            Text('• A family member who supports you'),
            Text('• A mentor or religious leader'),
            Text('• A support group member'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show a dialog with walking suggestions
  void _showWalkingTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go for a Walk'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Walking can help clear your mind and reduce temptation.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Tips for an effective walk:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Leave your devices at home if possible'),
            Text('• Focus on your surroundings and nature'),
            Text('• Practice deep breathing while walking'),
            Text('• Set a destination goal (e.g., walk to the park and back)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show a dialog with cold shower benefits
  void _showColdShowerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cold Shower'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cold showers can help reset your mind and body during moments of temptation.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Benefits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Increases alertness and focus'),
            Text('• Reduces stress hormones'),
            Text('• Builds mental resilience'),
            Text('• Shifts your attention away from temptation'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show a dialog with exercise suggestions
  void _showExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Exercise'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Physical exercise can help redirect energy and reduce temptation.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Try this quick workout:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• 20 push-ups (or as many as you can)'),
            Text('• 20 jumping jacks'),
            Text('• 20 squats'),
            Text('• 30-second plank'),
            Text('• Repeat 2-3 times if needed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build a loading view
  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.emergencyScreenTitle),
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.emergencyRed,
            ),
            SizedBox(height: 16),
            Text(
              'Loading emergency session...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build an error view
  Widget _buildErrorView(Object error) {
    // We need to use a Consumer widget here to get access to the ref
    return Consumer(
      builder: (context, ref, child) => Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.emergencyScreenTitle),
          backgroundColor: AppColors.emergencyRed,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.emergencyRed,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Emergency Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Refresh the provider and ignore the result
                    final _ = ref.refresh(emergencySessionNotifierProvider);
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
