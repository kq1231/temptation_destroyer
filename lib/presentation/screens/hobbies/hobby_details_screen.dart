import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
import 'package:temptation_destroyer/presentation/providers/hobby_provider.dart';
import 'package:temptation_destroyer/presentation/screens/hobbies/hobby_form_screen.dart';

class HobbyDetailsScreen extends ConsumerWidget {
  static const routeName = '/hobbies/details';

  final HobbyModel hobby;

  const HobbyDetailsScreen({super.key, required this.hobby});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hobby.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditHobby(context, hobby),
            tooltip: 'Edit hobby',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category chip
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(_getCategoryName(hobby.category)),
                  backgroundColor:
                      _getCategoryColor(hobby.category).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _getCategoryColor(hobby.category),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hobby.durationGoalMinutes != null)
                  Chip(
                    label: Text('${hobby.durationGoalMinutes} minutes'),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: Colors.blue),
                  ),
                if (hobby.frequencyGoal != null)
                  Chip(
                    label: Text(hobby.frequencyGoal!),
                    backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: Colors.purple),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if (hobby.description != null && hobby.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hobby.description!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
            ],

            // Engagement tracking
            const Text(
              'Track Engagement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hobby.lastPracticedAt != null) ...[
                      Text(
                        'Last practiced: ${_formatDate(hobby.lastPracticedAt!)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _trackEngagement(context, ref),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Log Activity Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _trackEngagementWithDate(context, ref),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Log Past Activity'),
                    ),
                  ],
                ),
              ),
            ),

            // Satisfaction rating
            if (hobby.satisfactionRating != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Satisfaction Rating',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  return Icon(
                    Icons.star,
                    size: 28,
                    color: rating <= hobby.satisfactionRating!
                        ? Colors.amber
                        : Colors.grey.shade300,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingDescription(hobby.satisfactionRating!),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            // Stats section (for future implementation)
            const SizedBox(height: 24),
            const Text(
              'Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coming soon! In future updates, you\'ll be able to track your engagement with this hobby over time.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditHobby(BuildContext context, HobbyModel hobby) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HobbyFormScreen(hobby: hobby),
      ),
    );
  }

  void _trackEngagement(BuildContext context, WidgetRef ref) {
    ref.read(hobbyProvider.notifier).trackEngagement(hobby.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Activity logged for ${hobby.name}')),
    );
  }

  Future<void> _trackEngagementWithDate(
      BuildContext context, WidgetRef ref) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Select when you practiced this hobby',
    );

    if (pickedDate != null && context.mounted) {
      // Show time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        helpText: 'Select time',
      );

      if (pickedTime != null && context.mounted) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        ref.read(hobbyProvider.notifier).trackEngagement(
              hobby.id,
              engagementTime: fullDateTime,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Activity logged for ${hobby.name} on ${_formatDate(fullDateTime)}',
              ),
            ),
          );
        }
      }
    }
  }

  String _getCategoryName(String category) {
    if (category == HobbyCategory.physical) return 'Physical';
    if (category == HobbyCategory.mental) return 'Mental';
    if (category == HobbyCategory.social) return 'Social';
    if (category == HobbyCategory.spiritual) return 'Spiritual';
    if (category == HobbyCategory.creative) return 'Creative';
    if (category == HobbyCategory.productive) return 'Productive';
    if (category == HobbyCategory.relaxing) return 'Relaxing';
    return category; // Fallback
  }

  Color _getCategoryColor(String category) {
    if (category == HobbyCategory.physical) return Colors.green;
    if (category == HobbyCategory.mental) return Colors.purple;
    if (category == HobbyCategory.social) return Colors.orange;
    if (category == HobbyCategory.spiritual) return Colors.indigo;
    if (category == HobbyCategory.creative) return Colors.pink;
    if (category == HobbyCategory.productive) return Colors.teal;
    if (category == HobbyCategory.relaxing) return Colors.blue;
    return Colors.grey; // Fallback
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Not enjoyable';
      case 2:
        return 'Somewhat enjoyable';
      case 3:
        return 'Moderately enjoyable';
      case 4:
        return 'Very enjoyable';
      case 5:
        return 'Extremely enjoyable';
      default:
        return '';
    }
  }
}
