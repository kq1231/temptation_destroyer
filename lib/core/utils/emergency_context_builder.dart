import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hobby_model.dart';
import '../../data/models/aspiration_model.dart';
import '../../data/models/emergency_session_model.dart';
import '../../presentation/providers/hobby_provider_refactored.dart';
import '../../presentation/providers/aspiration_provider.dart';

/// Utility class to build AI context for emergency sessions
class EmergencyContextBuilder {
  /// Build context for AI guidance based on user's hobbies and aspirations
  static Future<String> buildContext(
      WidgetRef ref, EmergencySession? session) async {
    final hobbiesAsync = ref.read(hobbyNotifierProvider);
    final aspirationsAsync = ref.read(aspirationProvider);

    // Default context if we can't load hobbies or aspirations
    String context = 'The user is experiencing temptation and needs guidance.';

    // Add session information if available
    if (session != null) {
      final duration = session.duration;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;

      context +=
          '\n\nThe user has been in an emergency session for $minutes minutes and $seconds seconds.';

      if (session.intensity != null) {
        context +=
            '\nThe user reported an intensity level of ${session.intensity}/10.';
      }

      if (session.activeTriggerIds != null &&
          session.activeTriggerIds!.isNotEmpty) {
        context +=
            '\nThe user reported the following triggers: ${session.activeTriggerIds}';
      }
    }

    // Add hobbies information if available
    if (hobbiesAsync is AsyncData && hobbiesAsync.value != null) {
      final hobbyState = hobbiesAsync.value;
      if (hobbyState != null && hobbyState.hobbies.isNotEmpty) {
        context += '\n\nThe user enjoys the following hobbies:';

        // Group hobbies by category
        final Map<String, List<HobbyModel>> hobbiesByCategory = {};
        for (final hobby in hobbyState.hobbies) {
          if (!hobbiesByCategory.containsKey(hobby.category)) {
            hobbiesByCategory[hobby.category] = [];
          }
          hobbiesByCategory[hobby.category]!.add(hobby);
        }

        // Add hobbies by category
        hobbiesByCategory.forEach((category, categoryHobbies) {
          context +=
              '\n- $category: ${categoryHobbies.map((h) => h.name).join(', ')}';
        });

        // Add recently practiced hobbies if available
        if (hobbyState.recentlyPracticedHobbies.isNotEmpty) {
          context +=
              '\n\nRecently practiced hobbies: ${hobbyState.recentlyPracticedHobbies.map((h) => h.name).join(', ')}';
        }
      }
    }

    // Add aspirations information if available
    final aspirationState = aspirationsAsync;
    if (aspirationState.aspirations.isNotEmpty) {
      context += '\n\nThe user has the following aspirations and goals:';

      // Group aspirations by category
      final Map<String, List<AspirationModel>> aspirationsByCategory = {};
      for (final aspiration in aspirationState.aspirations) {
        if (!aspirationsByCategory.containsKey(aspiration.category)) {
          aspirationsByCategory[aspiration.category] = [];
        }
        aspirationsByCategory[aspiration.category]!.add(aspiration);
      }

      // Add aspirations by category
      aspirationsByCategory.forEach((category, categoryAspirations) {
        context +=
            '\n- $category: ${categoryAspirations.map((a) => a.dua).join('; ')}';
      });
    }

    // Add Islamic guidance context
    context += '''

    As an AI assistant, provide Islamic guidance to help the user overcome this temptation.
    Focus on:
    1. Reminding them of their aspirations and goals
    2. Suggesting specific hobbies they enjoy that could help redirect their energy
    3. Providing relevant Quranic verses or Hadith that might help
    4. Offering practical strategies based on Islamic teachings
    5. Being compassionate and non-judgmental

    Keep your response concise, practical, and focused on immediate actions they can take.
    ''';

    return context;
  }
}

/// Provider for emergency context
final emergencyContextProvider =
    FutureProvider.family<String, EmergencySession?>((ref, session) async {
  // Create a WidgetRef-compatible reference
  return await EmergencyContextBuilder.buildContext(ref as WidgetRef, session);
});
