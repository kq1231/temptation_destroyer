import 'package:flutter/material.dart';
import 'package:temptation_destroyer/data/models/aspiration_model.dart';

/// A widget that displays a horizontal scrollable list of category chips
/// for filtering aspirations by category.
class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" category chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedCategory == null,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(null);
                }
              },
            ),
          ),

          // Category chips for each aspiration category
          ...AspirationCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(_getCategoryName(category)),
                selected: selectedCategory == category,
                backgroundColor:
                    _getCategoryColor(category).withValues(alpha: 0.1),
                selectedColor:
                    _getCategoryColor(category).withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selectedCategory == category
                      ? _getCategoryColor(category)
                      : Colors.black54,
                ),
                onSelected: (selected) {
                  onCategorySelected(selected ? category : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Get a user-friendly name for a category
  String _getCategoryName(String category) {
    if (category == AspirationCategory.personal) return 'Personal';
    if (category == AspirationCategory.family) return 'Family';
    if (category == AspirationCategory.career) return 'Career';
    if (category == AspirationCategory.spiritual) return 'Spiritual';
    if (category == AspirationCategory.health) return 'Health';
    if (category == AspirationCategory.social) return 'Social';
    if (category == AspirationCategory.financial) return 'Financial';
    if (category == AspirationCategory.customized) return 'Custom';
    return category; // Fallback
  }

  /// Get a color for a category
  Color _getCategoryColor(String category) {
    if (category == AspirationCategory.personal) return Colors.blue;
    if (category == AspirationCategory.family) return Colors.green;
    if (category == AspirationCategory.career) return Colors.amber.shade700;
    if (category == AspirationCategory.spiritual) return Colors.purple;
    if (category == AspirationCategory.health) return Colors.red;
    if (category == AspirationCategory.social) return Colors.teal;
    if (category == AspirationCategory.financial) return Colors.indigo;
    if (category == AspirationCategory.customized) return Colors.grey;
    return Colors.grey; // Fallback
  }
}

/// Extension to help with color manipulation
extension ColorExtension on Color {
  Color withValues({
    int? red,
    int? green,
    int? blue,
    int? alpha,
  }) {
    return Color.fromARGB(
      alpha ?? a.toInt(),
      red ?? b.toInt(),
      green ?? g.toInt(),
      blue ?? b.toInt(),
    );
  }
}
