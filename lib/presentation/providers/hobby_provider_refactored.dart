import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/hobby_model.dart';
import '../../data/repositories/hobby_repository.dart';
import '../../data/repositories/trigger_repository.dart';
import '../../domain/usecases/hobby/add_hobby_usecase.dart';
import '../../domain/usecases/hobby/delete_hobby_usecase.dart';
import '../../domain/usecases/hobby/get_hobbies_usecase.dart';
import '../../domain/usecases/hobby/update_hobby_usecase.dart';
import '../../domain/usecases/hobby/suggest_hobbies_usecase.dart';

part 'hobby_provider_refactored.g.dart';

// Provider for the HobbyRepository
final hobbyRepositoryProvider = Provider<HobbyRepository>((ref) {
  return HobbyRepository();
});

// Providers for the hobby use cases
final addHobbyUseCaseProvider = Provider<AddHobbyUseCase>((ref) {
  final repository = ref.watch(hobbyRepositoryProvider);
  return AddHobbyUseCase(repository);
});

final updateHobbyUseCaseProvider = Provider<UpdateHobbyUseCase>((ref) {
  final repository = ref.watch(hobbyRepositoryProvider);
  return UpdateHobbyUseCase(repository);
});

final getHobbiesUseCaseProvider = Provider<GetHobbiesUseCase>((ref) {
  final repository = ref.watch(hobbyRepositoryProvider);
  return GetHobbiesUseCase(repository);
});

final deleteHobbyUseCaseProvider = Provider<DeleteHobbyUseCase>((ref) {
  final repository = ref.watch(hobbyRepositoryProvider);
  return DeleteHobbyUseCase(repository);
});

final suggestHobbiesUseCaseProvider = Provider<SuggestHobbiesUseCase>((ref) {
  final hobbyRepository = ref.watch(hobbyRepositoryProvider);
  final triggerRepository = ref.watch(triggerRepositoryProvider);
  return SuggestHobbiesUseCase(hobbyRepository, triggerRepository);
});

// External dependency on TriggerRepository
final triggerRepositoryProvider = Provider<TriggerRepository>((ref) {
  return TriggerRepository();
});

// HobbyState - immutable state class for hobbies
class HobbyState {
  final List<HobbyModel> hobbies;
  final bool isLoading;
  final String? errorMessage;
  final List<HobbyModel> filteredHobbies;
  final String? currentFilter;
  final List<HobbyModel> suggestedHobbies;
  final Map<String, List<HobbyModel>> hobbiesByCategory;
  final List<HobbyModel> recentlyPracticedHobbies;

  HobbyState({
    this.hobbies = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filteredHobbies = const [],
    this.currentFilter,
    this.suggestedHobbies = const [],
    this.hobbiesByCategory = const {},
    this.recentlyPracticedHobbies = const [],
  });

  // Create a copy of the state with updated values
  HobbyState copyWith({
    List<HobbyModel>? hobbies,
    bool? isLoading,
    String? errorMessage,
    List<HobbyModel>? filteredHobbies,
    String? currentFilter,
    List<HobbyModel>? suggestedHobbies,
    Map<String, List<HobbyModel>>? hobbiesByCategory,
    List<HobbyModel>? recentlyPracticedHobbies,
  }) {
    return HobbyState(
      hobbies: hobbies ?? this.hobbies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filteredHobbies: filteredHobbies ?? this.filteredHobbies,
      currentFilter: currentFilter,
      suggestedHobbies: suggestedHobbies ?? this.suggestedHobbies,
      hobbiesByCategory: hobbiesByCategory ?? this.hobbiesByCategory,
      recentlyPracticedHobbies:
          recentlyPracticedHobbies ?? this.recentlyPracticedHobbies,
    );
  }
}

// HobbyNotifier using AsyncNotifier with Riverpod Generator
@riverpod
class HobbyNotifier extends _$HobbyNotifier {
  late final AddHobbyUseCase _addHobbyUseCase;
  late final UpdateHobbyUseCase _updateHobbyUseCase;
  late final GetHobbiesUseCase _getHobbiesUseCase;
  late final DeleteHobbyUseCase _deleteHobbyUseCase;
  late final SuggestHobbiesUseCase _suggestHobbiesUseCase;

  @override
  Future<HobbyState> build() async {
    // Initialize use cases
    _addHobbyUseCase = ref.watch(addHobbyUseCaseProvider);
    _updateHobbyUseCase = ref.watch(updateHobbyUseCaseProvider);
    _getHobbiesUseCase = ref.watch(getHobbiesUseCaseProvider);
    _deleteHobbyUseCase = ref.watch(deleteHobbyUseCaseProvider);
    _suggestHobbiesUseCase = ref.watch(suggestHobbiesUseCaseProvider);

    try {
      // Get all hobbies
      final hobbies = await _getHobbiesUseCase.getAllHobbies();

      // Get recently practiced hobbies
      final recentlyPracticed =
          await _getHobbiesUseCase.getRecentlyPracticedHobbies();

      // Group hobbies by category
      final hobbiesByCategory =
          await _getHobbiesUseCase.getHobbiesGroupedByCategory();

      return HobbyState(
        hobbies: hobbies,
        filteredHobbies: hobbies,
        isLoading: false,
        recentlyPracticedHobbies: recentlyPracticed,
        hobbiesByCategory: hobbiesByCategory,
      );
    } catch (e) {
      return HobbyState(
        isLoading: false,
        errorMessage: 'Failed to load hobbies: $e',
      );
    }
  }

  // Add a new hobby
  Future<void> addHobby({
    required String name,
    String? description,
    String category = HobbyCategory.physical,
    String? frequencyGoal,
    int? durationGoalMinutes,
    int? satisfactionRating,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _addHobbyUseCase.addHobby(
        name: name,
        description: description,
        category: category,
        frequencyGoal: frequencyGoal,
        durationGoalMinutes: durationGoalMinutes,
        satisfactionRating: satisfactionRating,
      );

      // Refresh hobbies by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add hobby: $e',
      ));
    }
  }

  // Update an existing hobby
  Future<void> updateHobby({
    required int id,
    String? name,
    String? description,
    String? category,
    String? frequencyGoal,
    int? durationGoalMinutes,
    int? satisfactionRating,
    DateTime? lastPracticedAt,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _updateHobbyUseCase.updateHobby(
        id: id,
        name: name,
        description: description,
        category: category,
        frequencyGoal: frequencyGoal,
        durationGoalMinutes: durationGoalMinutes,
        satisfactionRating: satisfactionRating,
        lastPracticedAt: lastPracticedAt,
      );

      // Refresh hobbies by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update hobby: $e',
      ));
    }
  }

  // Delete a hobby
  Future<void> deleteHobby(int hobbyId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _deleteHobbyUseCase.execute(hobbyId);

      // Refresh hobbies by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete hobby: $e',
      ));
    }
  }

  // Filter hobbies by category
  void filterByCategory(String? category) {
    if (category == null) {
      // Clear filter
      state = AsyncValue.data(state.value!.copyWith(
        filteredHobbies: state.value!.hobbies,
        currentFilter: null,
      ));
    } else {
      // Apply filter
      final filtered =
          state.value!.hobbies.where((hobby) => hobby.category == category).toList();
      state = AsyncValue.data(state.value!.copyWith(
        filteredHobbies: filtered,
        currentFilter: category,
      ));
    }
  }

  // Track engagement with a hobby
  Future<void> trackEngagement(int hobbyId, {DateTime? engagementTime}) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _updateHobbyUseCase.trackEngagement(
        hobbyId,
        engagementTime: engagementTime,
      );

      // Refresh hobbies by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to track hobby engagement: $e',
      ));
    }
  }

  // Get suggested hobbies for a specific trigger
  Future<void> getSuggestedHobbiesForTrigger(int triggerId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final suggestions =
          await _suggestHobbiesUseCase.getSuggestedHobbiesForTrigger(triggerId);

      state = AsyncValue.data(state.value!.copyWith(
        suggestedHobbies: suggestions,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get hobby suggestions: $e',
      ));
    }
  }

  // Import preset hobbies
  Future<void> importPresetHobbies() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _addHobbyUseCase.importPresetHobbies();

      // Refresh hobbies by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to import preset hobbies: $e',
      ));
    }
  }
}
