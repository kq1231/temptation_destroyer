import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/trigger_model.dart';
import 'package:temptation_destroyer/data/repositories/trigger_repository.dart';
import 'package:temptation_destroyer/domain/usecases/trigger/add_trigger_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/trigger/delete_trigger_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/trigger/get_triggers_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/trigger/update_trigger_usecase.dart';

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

// TriggerNotifier - handles state changes
class TriggerNotifier extends StateNotifier<TriggerState> {
  final AddTriggerUseCase _addTriggerUseCase;
  final UpdateTriggerUseCase _updateTriggerUseCase;
  final GetTriggersUseCase _getTriggersUseCase;
  final DeleteTriggerUseCase _deleteTriggerUseCase;

  TriggerNotifier({
    required AddTriggerUseCase addTriggerUseCase,
    required UpdateTriggerUseCase updateTriggerUseCase,
    required GetTriggersUseCase getTriggersUseCase,
    required DeleteTriggerUseCase deleteTriggerUseCase,
  })  : _addTriggerUseCase = addTriggerUseCase,
        _updateTriggerUseCase = updateTriggerUseCase,
        _getTriggersUseCase = getTriggersUseCase,
        _deleteTriggerUseCase = deleteTriggerUseCase,
        super(TriggerState());

  // Initialize the state by loading all triggers
  Future<void> loadTriggers() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final triggers = await _getTriggersUseCase.getAllTriggers();
      state = state.copyWith(
        triggers: triggers,
        filteredTriggers: triggers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
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
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _addTriggerUseCase.addTrigger(
        description: description,
        triggerType: triggerType,
        intensity: intensity,
        notes: notes,
        activeTimes: activeTimes,
        activeDays: activeDays,
      );

      // Refresh triggers after adding
      await loadTriggers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add trigger: $e',
      );
    }
  }

  // Update an existing trigger
  Future<void> updateTrigger(Trigger trigger) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _updateTriggerUseCase.execute(trigger);

      // Refresh triggers after updating
      await loadTriggers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update trigger: $e',
      );
    }
  }

  // Delete a trigger
  Future<void> deleteTrigger(int triggerId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _deleteTriggerUseCase.execute(triggerId);

      // Refresh triggers after deleting
      await loadTriggers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete trigger: $e',
      );
    }
  }

  // Delete selected triggers
  Future<void> deleteSelectedTriggers() async {
    try {
      if (state.selectedTriggerIds.isEmpty) return;

      state = state.copyWith(isLoading: true, errorMessage: null);

      await _deleteTriggerUseCase
          .deleteMultipleTriggers(state.selectedTriggerIds);

      // Clear selection and refresh triggers
      state = state.copyWith(selectedTriggerIds: []);
      await loadTriggers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete selected triggers: $e',
      );
    }
  }

  // Filter triggers by type
  void filterByType(String? type) {
    if (type == null) {
      // Clear filter
      state = state.copyWith(
        filteredTriggers: state.triggers,
        currentFilter: null,
      );
    } else {
      // Apply filter
      final filtered =
          state.triggers.where((t) => t.triggerType == type).toList();
      state = state.copyWith(
        filteredTriggers: filtered,
        currentFilter: type,
      );
    }
  }

  // Search triggers
  Future<void> searchTriggers(String query) async {
    try {
      if (query.trim().isEmpty) {
        // If query is empty, show all triggers or apply current filter
        if (state.currentFilter != null) {
          filterByType(state.currentFilter);
        } else {
          state = state.copyWith(filteredTriggers: state.triggers);
        }
        return;
      }

      state = state.copyWith(isLoading: true, errorMessage: null);

      final results = await _getTriggersUseCase.searchTriggers(query);

      // If there's an active type filter, apply it to the search results
      if (state.currentFilter != null) {
        final filteredResults =
            results.where((t) => t.triggerType == state.currentFilter).toList();
        state = state.copyWith(
          filteredTriggers: filteredResults,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          filteredTriggers: results,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to search triggers: $e',
      );
    }
  }

  // Toggle trigger selection for multi-select operations
  void toggleTriggerSelection(int triggerId) {
    List<int> updatedSelection = List.from(state.selectedTriggerIds);

    if (updatedSelection.contains(triggerId)) {
      updatedSelection.remove(triggerId);
    } else {
      updatedSelection.add(triggerId);
    }

    state = state.copyWith(selectedTriggerIds: updatedSelection);
  }

  // Clear all selections
  void clearSelection() {
    state = state.copyWith(selectedTriggerIds: []);
  }

  // Select all visible triggers
  void selectAllVisible() {
    final visibleIds = state.filteredTriggers.map((t) => t.id).toList();
    state = state.copyWith(selectedTriggerIds: visibleIds);
  }

  // Get active triggers for emergency session
  Future<List<Trigger>> getActiveTriggersNow() async {
    try {
      return await _getTriggersUseCase.getActiveTriggersNow();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to get active triggers: $e',
      );
      return [];
    }
  }
}

// Provider for the trigger state
final triggerProvider =
    StateNotifierProvider<TriggerNotifier, TriggerState>((ref) {
  final addTriggerUseCase = ref.watch(addTriggerUseCaseProvider);
  final updateTriggerUseCase = ref.watch(updateTriggerUseCaseProvider);
  final getTriggersUseCase = ref.watch(getTriggersUseCaseProvider);
  final deleteTriggerUseCase = ref.watch(deleteTriggerUseCaseProvider);

  return TriggerNotifier(
    addTriggerUseCase: addTriggerUseCase,
    updateTriggerUseCase: updateTriggerUseCase,
    getTriggersUseCase: getTriggersUseCase,
    deleteTriggerUseCase: deleteTriggerUseCase,
  );
});
