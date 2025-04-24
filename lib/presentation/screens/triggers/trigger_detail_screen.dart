import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/trigger_model.dart';
import '../../providers/trigger_provider.dart';
import 'trigger_form_screen.dart';

/// Screen that displays detailed information about a trigger
class TriggerDetailScreen extends ConsumerWidget {
  /// The trigger to display
  final Trigger trigger;

  /// Constructor
  const TriggerDetailScreen({super.key, required this.trigger});

  String _getActiveTimesText(Trigger trigger) {
    if (trigger.activeTimesList.isEmpty) {
      return 'Any time';
    }
    return trigger.activeTimesList.join(', ');
  }

  String _getActiveDaysText(Trigger trigger) {
    if (trigger.activeDaysList.isEmpty) {
      return 'Any day';
    }

    final dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    final activeDays =
        trigger.activeDaysList.map((dayIndex) => dayNames[dayIndex]).toList();
    return activeDays.join(', ');
  }

  Color _getTriggerTypeColor(String type) {
    if (type == TriggerType.emotional) return AppColors.emotionalTrigger;
    if (type == TriggerType.situational) return AppColors.socialTrigger;
    if (type == TriggerType.temporal) return AppColors.timeTrigger;
    if (type == TriggerType.physical) return AppColors.locationTrigger;
    if (type == TriggerType.custom) return AppColors.customTrigger;
    return Colors.grey; // Fallback
  }

  String _getTriggerTypeLabel(String type) {
    if (type == TriggerType.emotional) return AppStrings.triggerEmotion;
    if (type == TriggerType.situational) return AppStrings.triggerSocial;
    if (type == TriggerType.temporal) return AppStrings.triggerTime;
    if (type == TriggerType.physical) return AppStrings.triggerLocation;
    if (type == TriggerType.custom) return AppStrings.triggerCustom;
    return type; // Fallback
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteTrigger),
        content: const Text('Are you sure you want to delete this trigger?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(triggerProvider.notifier).deleteTrigger(trigger.id);
              Navigator.of(context).pop(); // Return to the previous screen
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  void _editTrigger(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TriggerFormScreen(trigger: trigger),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triggerTypeColor = _getTriggerTypeColor(trigger.triggerType);
    final triggerTypeLabel = _getTriggerTypeLabel(trigger.triggerType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trigger Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editTrigger(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and intensity
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: triggerTypeColor.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: triggerTypeColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: triggerTypeColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          triggerTypeLabel,
                          style: TextStyle(
                            color: triggerTypeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Intensity: ${trigger.intensity}/10',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trigger.description,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Notes (if available)
            if (trigger.notes != null && trigger.notes!.isNotEmpty) ...[
              const Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trigger.notes!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
            ],

            // Active times
            const Text(
              'Active Times',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getActiveTimesText(trigger),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Active days
            const Text(
              'Active Days',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getActiveDaysText(trigger),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Created date
            const Text(
              'Created',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${trigger.createdAt.day}/${trigger.createdAt.month}/${trigger.createdAt.year}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
