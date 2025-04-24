import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/emergency_session_provider_refactored.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// A floating action button that provides quick access to emergency help
class FloatingHelpButton extends ConsumerWidget {
  /// Maximum size of the button when expanded
  final double maxSize;

  /// Minimum size of the button when idle
  final double minSize;

  /// Animation duration
  final Duration animationDuration;

  /// Callback when the button is pressed
  final VoidCallback? onPressed;

  /// Constructor
  const FloatingHelpButton({
    super.key,
    this.maxSize = 120.0,
    this.minSize = 70.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get emergency session state
    final asyncEmergencyState = ref.watch(emergencySessionNotifierProvider);

    // Determine if the button should be expanded based on AsyncValue state
    final isExpanded = asyncEmergencyState.when(
      data: (state) => state.activeSession == null,
      loading: () => true, // Expanded when loading
      error: (_, __) => true, // Expanded on error
    );

    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      width: isExpanded ? maxSize : minSize,
      height: isExpanded ? maxSize : minSize,
      child: FloatingActionButton(
        backgroundColor: AppColors.emergencyRed,
        elevation: 8.0,
        highlightElevation: 12.0,
        shape: const CircleBorder(),
        child: AnimatedSwitcher(
          duration: animationDuration,
          child: isExpanded
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emergency,
                      size: 32.0,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      AppStrings.helpButtonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Icon(
                  Icons.emergency,
                  size: 32.0,
                  color: Colors.white,
                ),
        ),
        onPressed: () {
          if (onPressed != null) {
            onPressed!();
          } else {
            _handleEmergencyButtonPress(context, ref);
          }
        },
      ),
    );
  }

  /// Handle the emergency button press
  void _handleEmergencyButtonPress(BuildContext context, WidgetRef ref) {
    final asyncEmergencyState = ref.read(emergencySessionNotifierProvider);

    // Handle based on AsyncValue state
    asyncEmergencyState.when(
      data: (state) {
        if (state.activeSession == null) {
          // Show quick response dialog if no active session
          _showQuickResponseDialog(context, ref);
        } else {
          // Navigate to the emergency screen if there's an active session
          Navigator.of(context).pushNamed('/emergency');
        }
      },
      loading: () {
        // Show quick response dialog when loading
        _showQuickResponseDialog(context, ref);
      },
      error: (_, __) {
        // Show quick response dialog on error
        _showQuickResponseDialog(context, ref);
      },
    );
  }

  /// Show the quick response dialog
  void _showQuickResponseDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.emergencyDialogTitle),
        content: const Text(AppStrings.emergencyDialogContent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.cancelButtonText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Start a new emergency session
              ref
                  .read(emergencySessionNotifierProvider.notifier)
                  .startEmergencySession();

              // Close dialog and navigate to emergency screen
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/emergency');
            },
            child: const Text(AppStrings.startSessionButtonText),
          ),
        ],
      ),
    );
  }
}
