import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/aspiration_model.dart';
import '../../data/repositories/aspiration_repository.dart';
import '../../domain/usecases/aspiration/add_aspiration_usecase.dart';
import '../../domain/usecases/aspiration/delete_aspiration_usecase.dart';
import '../../domain/usecases/aspiration/get_aspirations_usecase.dart';
import '../../domain/usecases/aspiration/update_aspiration_usecase.dart';
import '../../domain/usecases/aspiration/track_progress_usecase.dart';

part 'aspiration_provider_refactored.g.dart';

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
  final String? currentFilter;
  final Map<String, List<AspirationModel>> aspirationsByCategory;
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
    String? currentFilter,
    Map<String, List<AspirationModel>>? aspirationsByCategory,
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

// AspirationNotifier using AsyncNotifier with Riverpod Generator
@riverpod
class AspirationNotifier extends _$AspirationNotifier {
  late final AddAspirationUseCase _addAspirationUseCase;
  late final UpdateAspirationUseCase _updateAspirationUseCase;
  late final GetAspirationsUseCase _getAspirationsUseCase;
  late final DeleteAspirationUseCase _deleteAspirationUseCase;
  late final TrackProgressUseCase _trackProgressUseCase;

  @override
  Future<AspirationState> build() async {
    // Initialize use cases
    _addAspirationUseCase = ref.watch(addAspirationUseCaseProvider);
    _updateAspirationUseCase = ref.watch(updateAspirationUseCaseProvider);
    _getAspirationsUseCase = ref.watch(getAspirationsUseCaseProvider);
    _deleteAspirationUseCase = ref.watch(deleteAspirationUseCaseProvider);
    _trackProgressUseCase = ref.watch(trackProgressUseCaseProvider);

    try {
      // Get all aspirations
      final aspirations = await _getAspirationsUseCase.getAllAspirations();

      // Group aspirations by category
      final aspirationsByCategory =
          await _getAspirationsUseCase.getAspirationsGroupedByCategory();

      // Get achievement stats
      final achievementStats =
          await _trackProgressUseCase.getAchievementStats();

      return AspirationState(
        aspirations: aspirations,
        filteredAspirations: _applyFilters(aspirations, null, null),
        isLoading: false,
        aspirationsByCategory: aspirationsByCategory,
        achievementStats: achievementStats,
      );
    } catch (e) {
      return AspirationState(
        isLoading: false,
        errorMessage: 'Failed to load aspirations: $e',
      );
    }
  }

  // Add a new aspiration
  Future<void> addAspiration({
    required String dua,
    String category = AspirationCategory.personal,
    bool isAchieved = false,
    DateTime? targetDate,
    String? note,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _addAspirationUseCase.addAspiration(
        dua: dua,
        category: category,
        isAchieved: isAchieved,
        targetDate: targetDate,
        note: note,
      );

      // Refresh aspirations by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add aspiration: $e',
      ));
    }
  }

  // Update an existing aspiration
  Future<void> updateAspiration({
    required int id,
    String? dua,
    String? category,
    bool? isAchieved,
    DateTime? targetDate,
    String? note,
    DateTime? achievedDate,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _updateAspirationUseCase.updateAspiration(
        id: id,
        dua: dua,
        category: category,
        isAchieved: isAchieved,
        targetDate: targetDate,
        note: note,
        achievedDate: achievedDate,
      );

      // Refresh aspirations by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update aspiration: $e',
      ));
    }
  }

  // Delete an aspiration
  Future<void> deleteAspiration(int aspirationId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _deleteAspirationUseCase.execute(aspirationId);

      // Refresh aspirations by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete aspiration: $e',
      ));
    }
  }

  // Filter aspirations by category
  void filterByCategory(String? category) {
    final filtered =
        _applyFilters(state.value!.aspirations, category, state.value!.statusFilter);
    state = AsyncValue.data(state.value!.copyWith(
      filteredAspirations: filtered,
      currentFilter: category,
    ));
  }

  // Filter aspirations by status
  void filterByStatus(bool? isAchieved) {
    final filtered =
        _applyFilters(state.value!.aspirations, state.value!.currentFilter, isAchieved);
    state = AsyncValue.data(state.value!.copyWith(
      filteredAspirations: filtered,
      statusFilter: isAchieved,
    ));
  }

  // Clear all filters
  void clearFilters() {
    state = AsyncValue.data(state.value!.copyWith(
      filteredAspirations: state.value!.aspirations,
      currentFilter: null,
      statusFilter: null,
    ));
  }

  // Apply both category and status filters
  List<AspirationModel> _applyFilters(
    List<AspirationModel> aspirations,
    String? category,
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
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _trackProgressUseCase.toggleAchievementStatus(aspirationId);

      // Refresh aspirations by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to toggle aspiration status: $e',
      ));
    }
  }

  // Import preset aspirations
  Future<void> importPresetAspirations() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      await _addAspirationUseCase.importPresetAspirations();

      // Refresh aspirations by invalidating the provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to import preset aspirations: $e',
      ));
    }
  }
}
