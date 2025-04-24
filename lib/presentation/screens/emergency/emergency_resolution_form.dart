import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/emergency_session_provider_refactored.dart';

/// Form for completing an emergency session
class EmergencyResolutionForm extends ConsumerStatefulWidget {
  /// Constructor
  const EmergencyResolutionForm({super.key});

  @override
  ConsumerState<EmergencyResolutionForm> createState() =>
      _EmergencyResolutionFormState();
}

class _EmergencyResolutionFormState
    extends ConsumerState<EmergencyResolutionForm> {
  bool? _wasSuccessful;
  final _notesController = TextEditingController();
  final _strategiesController = TextEditingController();
  int _intensity = 5; // Default to medium intensity
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _strategiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get bottom inset for keyboard handling
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      // Add extra padding at the bottom to account for keyboard
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.endSessionDialogTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.endSessionDialogContent,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Success/failure selection
              const Text(
                AppStrings.successQuestion,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _OutcomeButton(
                      label: AppStrings.yes,
                      icon: Icons.check_circle,
                      color: AppColors.success,
                      isSelected: _wasSuccessful == true,
                      onPressed: () {
                        setState(() {
                          _wasSuccessful = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OutcomeButton(
                      label: AppStrings.no,
                      icon: Icons.cancel,
                      color: AppColors.error,
                      isSelected: _wasSuccessful == false,
                      onPressed: () {
                        setState(() {
                          _wasSuccessful = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Intensity slider
              const Text(
                AppStrings.intensityQuestion,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('1'),
                  Expanded(
                    child: Slider(
                      value: _intensity.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _intensity.toString(),
                      onChanged: (value) {
                        setState(() {
                          _intensity = value.toInt();
                        });
                      },
                    ),
                  ),
                  const Text('10'),
                ],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.lowIntensity,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    AppStrings.highIntensity,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes field
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: AppStrings.sessionNotesHint,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Helpful strategies field
              TextField(
                controller: _strategiesController,
                decoration: const InputDecoration(
                  labelText: AppStrings.sessionHelpfulStrategiesHint,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          AppStrings.done,
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Submit the form and end the emergency session
  void _submitForm() async {
    // Validation
    if (_wasSuccessful == null) {
      _showValidationError('Please select whether you were successful or not.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the active session from the AsyncValue
      final asyncState = ref.read(emergencySessionNotifierProvider);

      // Handle possible error states
      if (asyncState is AsyncError) {
        throw Exception('Error loading emergency session: ${asyncState.error}');
      }

      // Get the value from AsyncData
      final state = asyncState.value;
      if (state == null) {
        throw Exception('Emergency session state is null');
      }

      final activeSession = state.activeSession;
      if (activeSession == null) {
        throw Exception('No active session found');
      }

      // End the emergency session
      await ref
          .read(emergencySessionNotifierProvider.notifier)
          .endEmergencySession(
            wasSuccessful: _wasSuccessful,
            notes: _notesController.text,
            helpfulStrategies: _strategiesController.text,
            intensity: _intensity,
          );

      // Close the form and navigate back
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Also pop the emergency screen

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _wasSuccessful == true
                  ? 'Great job! Your success has been recorded.'
                  : 'Your session has been recorded. Stay strong!',
            ),
            backgroundColor:
                _wasSuccessful == true ? AppColors.success : AppColors.info,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Show validation error message
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// Button for selecting outcome (success/failure)
class _OutcomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const _OutcomeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
