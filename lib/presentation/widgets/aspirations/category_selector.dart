import 'package:flutter/material.dart';
import 'package:temptation_destroyer/data/models/aspiration_model.dart';

/// A widget that displays a horizontal scrollable list of category chips
/// for filtering aspirations by category.
class CategorySelector extends StatelessWidget {
  final AspirationCategory? selectedCategory;
  final Function(AspirationCategory?) onCategorySelected;

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
  String _getCategoryName(AspirationCategory category) {
    switch (category) {
      case AspirationCategory.personal:
        return 'Personal';
      case AspirationCategory.family:
        return 'Family';
      case AspirationCategory.career:
        return 'Career';
      case AspirationCategory.spiritual:
        return 'Spiritual';
      case AspirationCategory.health:
        return 'Health';
      case AspirationCategory.social:
        return 'Social';
      case AspirationCategory.financial:
        return 'Financial';
      case AspirationCategory.customized:
        return 'Custom';
    }
  }

  /// Get a color for a category
  Color _getCategoryColor(AspirationCategory category) {
    switch (category) {
      case AspirationCategory.personal:
        return Colors.blue;
      case AspirationCategory.family:
        return Colors.green;
      case AspirationCategory.career:
        return Colors.amber.shade700;
      case AspirationCategory.spiritual:
        return Colors.purple;
      case AspirationCategory.health:
        return Colors.red;
      case AspirationCategory.social:
        return Colors.teal;
      case AspirationCategory.financial:
        return Colors.indigo;
      case AspirationCategory.customized:
        return Colors.grey;
    }
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
      alpha ?? this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}
