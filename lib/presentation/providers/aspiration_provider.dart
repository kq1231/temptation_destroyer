import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/aspiration_model.dart';
import 'package:temptation_destroyer/data/repositories/aspiration_repository.dart';
import 'package:temptation_destroyer/domain/usecases/aspiration/add_aspiration_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/aspiration/delete_aspiration_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/aspiration/get_aspirations_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/aspiration/update_aspiration_usecase.dart';
import 'package:temptation_destroyer/domain/usecases/aspiration/track_progress_usecase.dart';

// Provider for the AspirationRepository
final aspirationRepositoryProvider = Provider<AspirationRepository>((ref) {
  return AspirationRepository();
});

// Providers for the aspiration use cases
final addAspirationUseCaseProvider = Provider<AddAspirationUseCase>((ref) {
  final repository = ref.watch(aspirationRepositoryProvider);
  return AddAspirationUseCase(repository);
});

final updateAspirationUseCaseProvider =
    Provider<UpdateAspirationUseCase>((ref) {
  final repository = ref.watch(aspirationRepositoryProvider);
  return UpdateAspirationUseCase(repository);
});

final getAspirationsUseCaseProvider = Provider<GetAspirationsUseCase>((ref) {
  final repository = ref.watch(aspirationRepositoryProvider);
  return GetAspirationsUseCase(repository);
});

final deleteAspirationUseCaseProvider =
    Provider<DeleteAspirationUseCase>((ref) {
  final repository = ref.watch(aspirationRepositoryProvider);
  return DeleteAspirationUseCase(repository);
});

final trackProgressUseCaseProvider = Provider<TrackProgressUseCase>((ref) {
  final repository = ref.watch(aspirationRepositoryProvider);
  return TrackProgressUseCase(repository);
});

// AspirationState - immutable state class for aspirations
class AspirationState {
  final List<AspirationModel> aspirations;
  final bool isLoading;
  final String? errorMessage;
  final List<AspirationModel> filteredAspirations;
  final AspirationCategory? currentFilter;
  final Map<AspirationCategory, List<AspirationModel>> aspirationsByCategory;
  final Map<String, dynamic>? achievementStats;
  final bool?
      statusFilter; // null = show all, true = achieved, false = not achieved

  AspirationState({
    this.aspirations = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filteredAspirations = const [],
    this.currentFilter,
    this.aspirationsByCategory = const {},
    this.achievementStats,
    this.statusFilter,
  });

  // Create a copy of the state with updated values
  AspirationState copyWith({
    List<AspirationModel>? aspirations,
    bool? isLoading,
    String? errorMessage,
    List<AspirationModel>? filteredAspirations,
    AspirationCategory? currentFilter,
    Map<AspirationCategory, List<AspirationModel>>? aspirationsByCategory,
    Map<String, dynamic>? achievementStats,
    bool? statusFilter,
  }) {
    return AspirationState(
      aspirations: aspirations ?? this.aspirations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filteredAspirations: filteredAspirations ?? this.filteredAspirations,
      currentFilter: currentFilter,
      aspirationsByCategory:
          aspirationsByCategory ?? this.aspirationsByCategory,
      achievementStats: achievementStats ?? this.achievementStats,
      statusFilter: statusFilter,
    );
  }
}

// AspirationNotifier - handles state changes
class AspirationNotifier extends StateNotifier<AspirationState> {
  final AddAspirationUseCase _addAspirationUseCase;
  final UpdateAspirationUseCase _updateAspirationUseCase;
  final GetAspirationsUseCase _getAspirationsUseCase;
  final DeleteAspirationUseCase _deleteAspirationUseCase;
  final TrackProgressUseCase _trackProgressUseCase;

  AspirationNotifier({
    required AddAspirationUseCase addAspirationUseCase,
    required UpdateAspirationUseCase updateAspirationUseCase,
    required GetAspirationsUseCase getAspirationsUseCase,
    required DeleteAspirationUseCase deleteAspirationUseCase,
    required TrackProgressUseCase trackProgressUseCase,
  })  : _addAspirationUseCase = addAspirationUseCase,
        _updateAspirationUseCase = updateAspirationUseCase,
        _getAspirationsUseCase = getAspirationsUseCase,
        _deleteAspirationUseCase = deleteAspirationUseCase,
        _trackProgressUseCase = trackProgressUseCase,
        super(AspirationState());

  // Initialize the state by loading all aspirations
  Future<void> loadAspirations() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Get all aspirations
      final aspirations = await _getAspirationsUseCase.getAllAspirations();

      // Group aspirations by category
      final aspirationsByCategory =
          await _getAspirationsUseCase.getAspirationsGroupedByCategory();

      // Get achievement stats
      final achievementStats =
          await _trackProgressUseCase.getAchievementStats();

      state = state.copyWith(
        aspirations: aspirations,
        filteredAspirations:
            _applyFilters(aspirations, state.currentFilter, state.statusFilter),
        isLoading: false,
        aspirationsByCategory: aspirationsByCategory,
        achievementStats: achievementStats,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load aspirations: $e',
      );
    }
  }

  // Add a new aspiration
  Future<void> addAspiration({
    required String dua,
    AspirationCategory category = AspirationCategory.personal,
    bool isAchieved = false,
    DateTime? targetDate,
    String? note,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _addAspirationUseCase.addAspiration(
        dua: dua,
        category: category,
        isAchieved: isAchieved,
        targetDate: targetDate,
        note: note,
      );

      // Refresh aspirations after adding
      await loadAspirations();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add aspiration: $e',
      );
    }
  }

  // Update an existing aspiration
  Future<void> updateAspiration({
    required int id,
    String? dua,
    AspirationCategory? category,
    bool? isAchieved,
    DateTime? targetDate,
    String? note,
    DateTime? achievedDate,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _updateAspirationUseCase.updateAspiration(
        id: id,
        dua: dua,
        category: category,
        isAchieved: isAchieved,
        targetDate: targetDate,
        note: note,
        achievedDate: achievedDate,
      );

      // Refresh aspirations after updating
      await loadAspirations();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update aspiration: $e',
      );
    }
  }

  // Delete an aspiration
  Future<void> deleteAspiration(int aspirationId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _deleteAspirationUseCase.execute(aspirationId);

      // Refresh aspirations after deleting
      await loadAspirations();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete aspiration: $e',
      );
    }
  }

  // Filter aspirations by category
  void filterByCategory(AspirationCategory? category) {
    final filtered =
        _applyFilters(state.aspirations, category, state.statusFilter);
    state = state.copyWith(
      filteredAspirations: filtered,
      currentFilter: category,
    );
  }

  // Filter aspirations by status
  void filterByStatus(bool? isAchieved) {
    final filtered =
        _applyFilters(state.aspirations, state.currentFilter, isAchieved);
    state = state.copyWith(
      filteredAspirations: filtered,
      statusFilter: isAchieved,
    );
  }

  // Clear all filters
  void clearFilters() {
    state = state.copyWith(
      filteredAspirations: state.aspirations,
      currentFilter: null,
      statusFilter: null,
    );
  }

  // Apply both category and status filters
  List<AspirationModel> _applyFilters(
    List<AspirationModel> aspirations,
    AspirationCategory? category,
    bool? isAchieved,
  ) {
    var result = aspirations;

    // Apply category filter if specified
    if (category != null) {
      result = result
          .where((aspiration) => aspiration.category == category)
          .toList();
    }

    // Apply status filter if specified
    if (isAchieved != null) {
      result = result
          .where((aspiration) => aspiration.isAchieved == isAchieved)
          .toList();
    }

    return result;
  }

  // Toggle achievement status
  Future<void> toggleAchievementStatus(int aspirationId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _trackProgressUseCase.toggleAchievementStatus(aspirationId);

      // Refresh aspirations after toggling status
      await loadAspirations();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to toggle aspiration status: $e',
      );
    }
  }

  // Import preset aspirations
  Future<void> importPresetAspirations() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await _addAspirationUseCase.importPresetAspirations();

      // Refresh aspirations after importing
      await loadAspirations();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to import preset aspirations: $e',
      );
    }
  }
}

// Provider for aspirations
final aspirationProvider =
    StateNotifierProvider<AspirationNotifier, AspirationState>((ref) {
  return AspirationNotifier(
    addAspirationUseCase: ref.watch(addAspirationUseCaseProvider),
    updateAspirationUseCase: ref.watch(updateAspirationUseCaseProvider),
    getAspirationsUseCase: ref.watch(getAspirationsUseCaseProvider),
    deleteAspirationUseCase: ref.watch(deleteAspirationUseCaseProvider),
    trackProgressUseCase: ref.watch(trackProgressUseCaseProvider),
  );
});
