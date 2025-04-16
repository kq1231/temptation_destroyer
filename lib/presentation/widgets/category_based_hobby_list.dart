import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
import 'package:temptation_destroyer/presentation/screens/hobbies/hobby_details_screen.dart';

/// A widget that displays hobbies grouped by category
class CategoryBasedHobbyList extends ConsumerWidget {
  final Map<HobbyCategory, List<HobbyModel>> hobbiesByCategory;
  final void Function(HobbyModel)? onHobbyTap;
  final bool showEmptyCategories;

  const CategoryBasedHobbyList({
    super.key,
    required this.hobbiesByCategory,
    this.onHobbyTap,
    this.showEmptyCategories = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter out empty categories if not showing them
    final categories = showEmptyCategories
        ? HobbyCategory.values
        : hobbiesByCategory.keys.toList();

    // Sort categories by enum order
    categories.sort((a, b) => a.index.compareTo(b.index));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final hobbiesInCategory = hobbiesByCategory[category] ?? [];

        // Skip empty categories if not showing them
        if (!showEmptyCategories && hobbiesInCategory.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(category),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(category),
                    ),
                  ),
                ],
              ),
            ),

            // Hobbies list
            if (hobbiesInCategory.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32.0, bottom: 16.0),
                child: Text(
                  'No hobbies in this category',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hobbiesInCategory.length,
                itemBuilder: (context, i) {
                  final hobby = hobbiesInCategory[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                    child: ListTile(
                      title: Text(hobby.name),
                      subtitle: hobby.description != null &&
                              hobby.description!.isNotEmpty
                          ? Text(
                              hobby.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: hobby.durationGoalMinutes != null
                          ? Chip(
                              label: Text('${hobby.durationGoalMinutes} min'),
                              backgroundColor:
                                  Colors.blue.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: Colors.blue),
                            )
                          : null,
                      onTap: () {
                        if (onHobbyTap != null) {
                          onHobbyTap!(hobby);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  HobbyDetailsScreen(hobby: hobby),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _getCategoryName(HobbyCategory category) {
    switch (category) {
      case HobbyCategory.physical:
        return 'Physical Activities';
      case HobbyCategory.mental:
        return 'Mental Activities';
      case HobbyCategory.social:
        return 'Social Activities';
      case HobbyCategory.spiritual:
        return 'Spiritual Activities';
      case HobbyCategory.creative:
        return 'Creative Activities';
      case HobbyCategory.productive:
        return 'Productive Activities';
      case HobbyCategory.relaxing:
        return 'Relaxing Activities';
    }
  }

  IconData _getCategoryIcon(HobbyCategory category) {
    switch (category) {
      case HobbyCategory.physical:
        return Icons.fitness_center;
      case HobbyCategory.mental:
        return Icons.psychology;
      case HobbyCategory.social:
        return Icons.people;
      case HobbyCategory.spiritual:
        return Icons.self_improvement;
      case HobbyCategory.creative:
        return Icons.brush;
      case HobbyCategory.productive:
        return Icons.work;
      case HobbyCategory.relaxing:
        return Icons.spa;
    }
  }

  Color _getCategoryColor(HobbyCategory category) {
    switch (category) {
      case HobbyCategory.physical:
        return Colors.green;
      case HobbyCategory.mental:
        return Colors.purple;
      case HobbyCategory.social:
        return Colors.orange;
      case HobbyCategory.spiritual:
        return Colors.indigo;
      case HobbyCategory.creative:
        return Colors.pink;
      case HobbyCategory.productive:
        return Colors.teal;
      case HobbyCategory.relaxing:
        return Colors.blue;
    }
  }
}
