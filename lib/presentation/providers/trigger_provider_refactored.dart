import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temptation_destroyer/data/models/trigger_model.dart';
import 'package:temptation_destroyer/data/repositories/trigger_repository.dart';
import 'package:temptation_destroyer/domain/usecases/trigger/add_trigger_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/trigger/delete_trigger_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/trigger/get_triggers_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/trigger/update_trigger_usecase.dart';

part 'trigger_provider_refactored.g.dart';

// Provider for the TriggerRepository
final triggerRepositoryProvider = Provider<TriggerRepository>((ref) {
  return TriggerRepository();
});

// Providers for the trigger use cases
final addTriggerUseCaseProvider = Provider<AddTriggerUseCase>((ref) {
  final repository = ref.watch(triggerRepositoryProvider);
  return AddTriggerUseCase(repository);
});

final updateTriggerUseCaseProvider = Provider<UpdateTriggerUseCase>((ref) {
  final repository = ref.watch(triggerRepositoryProvider);
  return UpdateTriggerUseCase(repository);
});

final getTriggersUseCaseProvider = Provider<GetTriggersUseCase>((ref) {
  final repository = ref.watch(triggerRepositoryProvider);
  return GetTriggersUseCase(repository);
});

final deleteTriggerUseCaseProvider = Provider<DeleteTriggerUseCase>((ref) {
  final repository = ref.watch(triggerRepositoryProvider);
  return DeleteTriggerUseCase(repository);
});

// TriggerState - immutable state class for triggers
class TriggerState {
  final List<Trigger> triggers;
  final bool isLoading;
  final String? errorMessage;
  final List<Trigger> filteredTriggers;
  final String? currentFilter;
  final List<int> selectedTriggerIds;

  TriggerState({
    this.triggers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filteredTriggers = const [],
    this.currentFilter,
    this.selectedTriggerIds = const [],
  });

  // Create a copy of the state with updated values
  TriggerState copyWith({
    List<Trigger>? triggers,
    bool? isLoading,
    String? errorMessage,
    List<Trigger>? filteredTriggers,
    String? currentFilter,
    List<int>? selectedTriggerIds,
  }) {
    return TriggerState(
      triggers: triggers ?? this.triggers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filteredTriggers: filteredTriggers ?? this.filteredTriggers,
      currentFilter: currentFilter,
      selectedTriggerIds: selectedTriggerIds ?? this.selectedTriggerIds,
    );
  }
}

// TriggerNotifier using AsyncNotifier with Riverpod Generator
@riverpod
class TriggerNotifier extends _$TriggerNotifier {
  late final AddTriggerUseCase _addTriggerUseCase;
  late final UpdateTriggerUseCase _updateTriggerUseCase;
  late final GetTriggersUseCase _getTriggersUseCase;
  late final DeleteTriggerUseCase _deleteTriggerUseCase;

  @override
  Future<TriggerState> build() async {
    // Initialize use cases
    _addTriggerUseCase = ref.watch(addTriggerUseCaseProvider);
    _updateTriggerUseCase = ref.watch(updateTriggerUseCaseProvider);
    _getTriggersUseCase = ref.watch(getTriggersUseCaseProvider);
    _deleteTriggerUseCase = ref.watch(deleteTriggerUseCaseProvider);

    // Load triggers as part of initialization
    try {
      final triggers = await _getTriggersUseCase.getAllTriggers();
      return TriggerState(
        triggers: triggers,
        filteredTriggers: triggers,
        isLoading: false,
      );
    } catch (e) {
      return TriggerState(
        isLoading: false,
        errorMessage: 'Failed to load triggers: $e',
      );
    }
  }

  // Add a new trigger
  Future<void> addTrigger({
    required String description,
    required String triggerType,
    int intensity = 5,
    String? notes,
    List<String>? activeTimes,
    List<int>? activeDays,
  }) async {
    state = AsyncValue.data(
        state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _addTriggerUseCase.addTrigger(
        description: description,
        triggerType: triggerType,
        intensity: intensity,
        notes: notes,
        activeTimes: activeTimes,
        activeDays: activeDays,
      );

      // Refresh triggers after adding by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add trigger: $e',
      ));
    }
  }

  // Update an existing trigger
  Future<void> updateTrigger(Trigger trigger) async {
    state = AsyncValue.data(
        state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _updateTriggerUseCase.execute(trigger);

      // Refresh triggers after updating by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update trigger: $e',
      ));
    }
  }

  // Delete a trigger
  Future<void> deleteTrigger(int triggerId) async {
    state = AsyncValue.data(
        state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _deleteTriggerUseCase.execute(triggerId);

      // Refresh triggers after deleting by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete trigger: $e',
      ));
    }
  }

  // Delete selected triggers
  Future<void> deleteSelectedTriggers() async {
    if (state.value!.selectedTriggerIds.isEmpty) return;

    state = AsyncValue.data(
        state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _deleteTriggerUseCase
          .deleteMultipleTriggers(state.value!.selectedTriggerIds);

      // Clear selection and refresh triggers
      state = AsyncValue.data(state.value!.copyWith(selectedTriggerIds: []));
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete selected triggers: $e',
      ));
    }
  }

  // Filter triggers by type
  void filterByType(String? type) {
    if (type == null) {
      // Clear filter
      state = AsyncValue.data(state.value!.copyWith(
        filteredTriggers: state.value!.triggers,
        currentFilter: null,
      ));
    } else {
      // Apply filter
      final filtered =
          state.value!.triggers.where((t) => t.triggerType == type).toList();
      state = AsyncValue.data(state.value!.copyWith(
        filteredTriggers: filtered,
        currentFilter: type,
      ));
    }
  }

  // Search triggers
  Future<void> searchTriggers(String query) async {
    try {
      if (query.trim().isEmpty) {
        // If query is empty, show all triggers or apply current filter
        if (state.value!.currentFilter != null) {
          filterByType(state.value!.currentFilter);
        } else {
          state = AsyncValue.data(
              state.value!.copyWith(filteredTriggers: state.value!.triggers));
        }
        return;
      }

      state = AsyncValue.data(
          state.value!.copyWith(isLoading: true, errorMessage: null));

      final results = await _getTriggersUseCase.searchTriggers(query);

      // If there's an active type filter, apply it to the search results
      if (state.value!.currentFilter != null) {
        final filteredResults = results
            .where((t) => t.triggerType == state.value!.currentFilter)
            .toList();
        state = AsyncValue.data(state.value!.copyWith(
          filteredTriggers: filteredResults,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          filteredTriggers: results,
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to search triggers: $e',
      ));
    }
  }

  // Toggle trigger selection for multi-select operations
  void toggleTriggerSelection(int triggerId) {
    List<int> updatedSelection = List.from(state.value!.selectedTriggerIds);

    if (updatedSelection.contains(triggerId)) {
      updatedSelection.remove(triggerId);
    } else {
      updatedSelection.add(triggerId);
    }

    state = AsyncValue.data(
        state.value!.copyWith(selectedTriggerIds: updatedSelection));
  }

  // Clear all selections
  void clearSelection() {
    state = AsyncValue.data(state.value!.copyWith(selectedTriggerIds: []));
  }

  // Select all visible triggers
  void selectAllVisible() {
    final visibleIds = state.value!.filteredTriggers.map((t) => t.id).toList();
    state =
        AsyncValue.data(state.value!.copyWith(selectedTriggerIds: visibleIds));
  }

  // Get active triggers for emergency session
  Future<List<Trigger>> getActiveTriggersNow() async {
    try {
      return await _getTriggersUseCase.getActiveTriggersNow();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        errorMessage: 'Failed to get active triggers: $e',
      ));
      return [];
    }
  }
}
