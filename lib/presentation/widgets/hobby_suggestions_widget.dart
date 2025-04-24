import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
import 'package:temptation_destroyer/data/models/trigger_model.dart';
import 'package:temptation_destroyer/presentation/providers/hobby_provider.dart';
import 'package:temptation_destroyer/presentation/screens/hobbies/hobby_details_screen.dart';

/// A widget that displays hobby suggestions based on a trigger
class HobbySuggestionsWidget extends ConsumerStatefulWidget {
  final Trigger trigger;
  final String title;
  final bool showTitle;
  final Function(HobbyModel)? onHobbySelected;

  const HobbySuggestionsWidget({
    super.key,
    required this.trigger,
    this.title = 'Suggested Activities',
    this.showTitle = true,
    this.onHobbySelected,
  });

  @override
  ConsumerState<HobbySuggestionsWidget> createState() =>
      _HobbySuggestionsWidgetState();
}

class _HobbySuggestionsWidgetState
    extends ConsumerState<HobbySuggestionsWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    // Load suggested hobbies for the trigger
    await ref
        .read(hobbyProvider.notifier)
        .getSuggestedHobbiesForTrigger(widget.trigger.id);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hobbyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.suggestedHobbies.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No hobby suggestions found',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try adding some hobbies first or import presets from the hobby management screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.suggestedHobbies.length,
              itemBuilder: (context, index) {
                final hobby = state.suggestedHobbies[index];
                return _buildHobbyCard(context, hobby);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHobbyCard(BuildContext context, HobbyModel hobby) {
    return GestureDetector(
      onTap: () {
        if (widget.onHobbySelected != null) {
          widget.onHobbySelected!(hobby);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HobbyDetailsScreen(hobby: hobby),
            ),
          );
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category banner
              Container(
                color: _getCategoryColor(hobby.category).withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(hobby.category),
                      color: _getCategoryColor(hobby.category),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getCategoryName(hobby.category),
                        style: TextStyle(
                          color: _getCategoryColor(hobby.category),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Hobby content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hobby.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hobby.description != null &&
                        hobby.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hobby.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Duration chip
              if (hobby.durationGoalMinutes != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Chip(
                    label: Text(
                      '${hobby.durationGoalMinutes} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: -2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
