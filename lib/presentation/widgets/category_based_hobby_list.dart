import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
import 'package:temptation_destroyer/presentation/screens/hobbies/hobby_details_screen.dart';

/// A widget that displays hobbies grouped by category
class CategoryBasedHobbyList extends ConsumerWidget {
  final Map<String, List<HobbyModel>> hobbiesByCategory;
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

    // Sort categories based on a predefined order
    categories.sort((a, b) {
      // Define the order of categories
      final order = [
        HobbyCategory.physical,
        HobbyCategory.mental,
        HobbyCategory.social,
        HobbyCategory.spiritual,
        HobbyCategory.creative,
        HobbyCategory.productive,
        HobbyCategory.relaxing,
      ];

      // Get the index of each category in the order list
      final indexA = order.indexOf(a);
      final indexB = order.indexOf(b);

      // If both categories are in the order list, sort by their position
      if (indexA >= 0 && indexB >= 0) {
        return indexA.compareTo(indexB);
      }

      // If only one is in the list, prioritize it
      if (indexA >= 0) return -1;
      if (indexB >= 0) return 1;

      // If neither is in the list, sort alphabetically
      return a.compareTo(b);
    });

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

  String _getCategoryName(String category) {
    if (category == HobbyCategory.physical) return 'Physical Activities';
    if (category == HobbyCategory.mental) return 'Mental Activities';
    if (category == HobbyCategory.social) return 'Social Activities';
    if (category == HobbyCategory.spiritual) return 'Spiritual Activities';
    if (category == HobbyCategory.creative) return 'Creative Activities';
    if (category == HobbyCategory.productive) return 'Productive Activities';
    if (category == HobbyCategory.relaxing) return 'Relaxing Activities';
    return category; // Fallback
  }

  IconData _getCategoryIcon(String category) {
    if (category == HobbyCategory.physical) return Icons.fitness_center;
    if (category == HobbyCategory.mental) return Icons.psychology;
    if (category == HobbyCategory.social) return Icons.people;
    if (category == HobbyCategory.spiritual) return Icons.self_improvement;
    if (category == HobbyCategory.creative) return Icons.brush;
    if (category == HobbyCategory.productive) return Icons.work;
    if (category == HobbyCategory.relaxing) return Icons.spa;
    return Icons.category; // Fallback
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
}
