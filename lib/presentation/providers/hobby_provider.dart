import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
import 'package:temptation_destroyer/data/repositories/hobby_repository.dart';
import 'package:temptation_destroyer/domain/usecases/hobby/add_hobby_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/hobby/delete_hobby_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/hobby/get_hobbies_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/hobby/update_hobby_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/hobby/suggest_hobbies_usecase.dart';
import 'package:temptation_destroyer/data/repositories/trigger_repository.dart';

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

// HobbyNotifier - handles state changes
class HobbyNotifier extends StateNotifier<HobbyState> {
  final AddHobbyUseCase _addHobbyUseCase;
  final UpdateHobbyUseCase _updateHobbyUseCase;
  final GetHobbiesUseCase _getHobbiesUseCase;
  final DeleteHobbyUseCase _deleteHobbyUseCase;
  final SuggestHobbiesUseCase _suggestHobbiesUseCase;

  HobbyNotifier({
    required AddHobbyUseCase addHobbyUseCase,
    required UpdateHobbyUseCase updateHobbyUseCase,
    required GetHobbiesUseCase getHobbiesUseCase,
    required DeleteHobbyUseCase deleteHobbyUseCase,
    required SuggestHobbiesUseCase suggestHobbiesUseCase,
  })  : _addHobbyUseCase = addHobbyUseCase,
        _updateHobbyUseCase = updateHobbyUseCase,
        _getHobbiesUseCase = getHobbiesUseCase,
        _deleteHobbyUseCase = deleteHobbyUseCase,
        _suggestHobbiesUseCase = suggestHobbiesUseCase,
        super(HobbyState());

  // Initialize the state by loading all hobbies
  Future<void> loadHobbies() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Get all hobbies
      final hobbies = await _getHobbiesUseCase.getAllHobbies();

      // Get recently practiced hobbies
      final recentlyPracticed =
          await _getHobbiesUseCase.getRecentlyPracticedHobbies();

      // Group hobbies by category
      final hobbiesByCategory =
          await _getHobbiesUseCase.getHobbiesGroupedByCategory();

      state = state.copyWith(
        hobbies: hobbies,
        filteredHobbies: hobbies,
        isLoading: false,
        recentlyPracticedHobbies: recentlyPracticed,
        hobbiesByCategory: hobbiesByCategory,
      );
    } catch (e) {
      state = state.copyWith(
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
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _addHobbyUseCase.addHobby(
        name: name,
        description: description,
        category: category,
        frequencyGoal: frequencyGoal,
        durationGoalMinutes: durationGoalMinutes,
        satisfactionRating: satisfactionRating,
      );

      // Refresh hobbies after adding
      await loadHobbies();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add hobby: $e',
      );
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
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

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

      // Refresh hobbies after updating
      await loadHobbies();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update hobby: $e',
      );
    }
  }

  // Delete a hobby
  Future<void> deleteHobby(int hobbyId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _deleteHobbyUseCase.execute(hobbyId);

      // Refresh hobbies after deleting
      await loadHobbies();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete hobby: $e',
      );
    }
  }

  // Filter hobbies by category
  void filterByCategory(String? category) {
    if (category == null) {
      // Clear filter
      state = state.copyWith(
        filteredHobbies: state.hobbies,
        currentFilter: null,
      );
    } else {
      // Apply filter
      final filtered =
          state.hobbies.where((hobby) => hobby.category == category).toList();
      state = state.copyWith(
        filteredHobbies: filtered,
        currentFilter: category,
      );
    }
  }

  // Track engagement with a hobby
  Future<void> trackEngagement(int hobbyId, {DateTime? engagementTime}) async {
    try {
      await _updateHobbyUseCase.trackEngagement(
        hobbyId,
        engagementTime: engagementTime,
      );

      // Refresh hobbies to update last practiced info
      await loadHobbies();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to track hobby engagement: $e',
      );
    }
  }

  // Get suggested hobbies for a specific trigger
  Future<void> getSuggestedHobbiesForTrigger(int triggerId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final suggestions =
          await _suggestHobbiesUseCase.getSuggestedHobbiesForTrigger(triggerId);

      state = state.copyWith(
        suggestedHobbies: suggestions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get hobby suggestions: $e',
      );
    }
  }

  // Import preset hobbies
  Future<void> importPresetHobbies() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _addHobbyUseCase.importPresetHobbies();

      // Refresh hobbies after importing
      await loadHobbies();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to import preset hobbies: $e',
      );
    }
  }
}

// Provider for the HobbyNotifier
final hobbyProvider = StateNotifierProvider<HobbyNotifier, HobbyState>((ref) {
  final addUseCase = ref.watch(addHobbyUseCaseProvider);
  final updateUseCase = ref.watch(updateHobbyUseCaseProvider);
  final getUseCase = ref.watch(getHobbiesUseCaseProvider);
  final deleteUseCase = ref.watch(deleteHobbyUseCaseProvider);
  final suggestUseCase = ref.watch(suggestHobbiesUseCaseProvider);

  return HobbyNotifier(
    addHobbyUseCase: addUseCase,
    updateHobbyUseCase: updateUseCase,
    getHobbiesUseCase: getUseCase,
    deleteHobbyUseCase: deleteUseCase,
    suggestHobbiesUseCase: suggestUseCase,
  );
});
