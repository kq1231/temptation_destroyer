import 'package:flutter/material.dart';
import 'package:temptation_destroyer/data/models/aspiration_model.dart';

/// A widget that displays a list of goals/aspirations with achievement status
class GoalsList extends StatelessWidget {
  final List<AspirationModel> aspirations;
  final Function(AspirationModel) onTap;
  final Function(AspirationModel) onToggleAchieved;
  final Function(AspirationModel)? onDelete;
  final Function(AspirationModel)? onEdit;
  final bool showActions;

  const GoalsList({
    super.key,
    required this.aspirations,
    required this.onTap,
    required this.onToggleAchieved,
    this.onDelete,
    this.onEdit,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    if (aspirations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No aspirations found. Add some to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: aspirations.length,
      itemBuilder: (context, index) {
        final aspiration = aspirations[index];
        return _buildGoalItem(context, aspiration);
      },
    );
  }

  Widget _buildGoalItem(BuildContext context, AspirationModel aspiration) {
    final textStyle = TextStyle(
      decoration: aspiration.isAchieved ? TextDecoration.lineThrough : null,
      color: aspiration.isAchieved ? Colors.grey : Colors.black,
    );

    // Check if the text contains Arabic characters
    final bool containsArabic = _containsArabic(aspiration.dua);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        onTap: () => onTap(aspiration),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row with text and checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox for achievement status
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: aspiration.isAchieved,
                      onChanged: (value) {
                        if (value != null) {
                          onToggleAchieved(aspiration);
                        }
                      },
                      activeColor: _getCategoryColor(aspiration.category!),
                    ),
                  ),

                  // Aspiration text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aspiration.dua,
                          style: textStyle.copyWith(
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textDirection: containsArabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),

                        const SizedBox(height: 8),

                        // Category chip
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                _getCategoryName(aspiration.category!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _getCategoryColor(aspiration.category!),
                                ),
                              ),
                              backgroundColor:
                                  _getCategoryColor(aspiration.category!)
                                      .withValues(alpha: 40),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            ),

                            // Due date chip if available
                            if (aspiration.targetDate != null)
                              Chip(
                                label: Text(
                                  'Due: ${_formatDate(aspiration.targetDate!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor:
                                    Colors.blue.withValues(alpha: 40),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ),

                            // Achievement date chip if achieved
                            if (aspiration.isAchieved &&
                                aspiration.achievedDate != null)
                              Chip(
                                label: Text(
                                  'Achieved: ${_formatDate(aspiration.achievedDate!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor:
                                    Colors.green.withValues(alpha: 40),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action buttons if enabled
              if (showActions && (onEdit != null || onDelete != null))
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        onPressed: () => onEdit!(aspiration),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => onDelete!(aspiration),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format date as readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  /// Check if text contains Arabic characters
  bool _containsArabic(String text) {
    // Unicode range for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
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
