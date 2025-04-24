import '../../../data/models/hobby_model.dart';
import '../../../data/models/trigger_model.dart';
import '../../../data/repositories/hobby_repository.dart';
import '../../../data/repositories/trigger_repository.dart';
import 'dart:math';

/// Use case for suggesting hobbies based on various criteria
class SuggestHobbiesUseCase {
  final HobbyRepository _hobbyRepository;
  final TriggerRepository _triggerRepository;

  /// Constructor
  SuggestHobbiesUseCase(this._hobbyRepository, this._triggerRepository);

  /// Get hobbies suggested for countering a specific trigger
  ///
  /// Returns a list of hobbies suitable for the given trigger
  Future<List<HobbyModel>> getSuggestedHobbiesForTrigger(int triggerId) async {
    try {
      // Get the trigger
      final trigger = await _triggerRepository.getTrigger(triggerId);
      if (trigger == null) {
        throw Exception('Trigger not found');
      }

      // Get all hobbies
      final allHobbies = await _hobbyRepository.getAllHobbies();
      if (allHobbies.isEmpty) {
        return [];
      }

      // Filter hobbies based on trigger type
      List<HobbyModel> suggestedHobbies = [];

      if (trigger.triggerType == TriggerType.emotional) {
        // For emotional triggers, suggest creative and relaxing hobbies
        suggestedHobbies = allHobbies
            .where((hobby) =>
                hobby.category == HobbyCategory.creative ||
                hobby.category == HobbyCategory.relaxing ||
                hobby.category == HobbyCategory.spiritual)
            .toList();
      } else if (trigger.triggerType == TriggerType.physical) {
        // For physical triggers, suggest physical and productive hobbies
        suggestedHobbies = allHobbies
            .where((hobby) =>
                hobby.category == HobbyCategory.physical ||
                hobby.category == HobbyCategory.productive)
            .toList();
      } else if (trigger.triggerType == TriggerType.situational) {
        // For situational triggers, suggest social hobbies
        suggestedHobbies = allHobbies
            .where((hobby) =>
                hobby.category == HobbyCategory.social ||
                hobby.category == HobbyCategory.mental)
            .toList();
      } else if (trigger.triggerType == TriggerType.temporal) {
        // For temporal triggers, suggest quick hobbies
        suggestedHobbies = allHobbies
            .where((hobby) =>
                hobby.durationGoalMinutes != null &&
                hobby.durationGoalMinutes! <= 30)
            .toList();
      } else if (trigger.triggerType == TriggerType.custom) {
        // For custom triggers, provide a balanced mix
        suggestedHobbies = allHobbies;
        suggestedHobbies =
            _getRandomSubset(allHobbies, min(5, allHobbies.length));
      } else {
        // Default to suggesting all hobbies
        suggestedHobbies = allHobbies;
      }

      // If no specific suggestions, return a subset of all hobbies
      if (suggestedHobbies.isEmpty && allHobbies.isNotEmpty) {
        return _getRandomSubset(allHobbies, min(5, allHobbies.length));
      }

      // Sort by relevance (this is a simple implementation, can be improved)
      // Currently sorts by duration (shorter first)
      suggestedHobbies.sort((a, b) {
        final aDuration = a.durationGoalMinutes ?? 60;
        final bDuration = b.durationGoalMinutes ?? 60;
        return aDuration.compareTo(bDuration);
      });

      // Limit to 5 suggestions
      if (suggestedHobbies.length > 5) {
        return suggestedHobbies.sublist(0, 5);
      }

      return suggestedHobbies;
    } catch (e) {
      throw Exception('Failed to get suggested hobbies for trigger: $e');
    }
  }

  /// Get random subset of hobbies
  ///
  /// Helper method to select a random subset of hobbies
  List<HobbyModel> _getRandomSubset(List<HobbyModel> hobbies, int count) {
    if (hobbies.length <= count) {
      return hobbies;
    }

    final random = Random();
    final result = <HobbyModel>[];
    final indices = List<int>.generate(hobbies.length, (i) => i);

    // Shuffle indices
    indices.shuffle(random);

    // Take the first 'count' items
    for (int i = 0; i < count; i++) {
      result.add(hobbies[indices[i]]);
    }

    return result;
  }
}
