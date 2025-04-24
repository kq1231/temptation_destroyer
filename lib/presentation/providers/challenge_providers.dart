import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/challenge_model.dart';
import '../../data/repositories/challenge_repository.dart';
import '../../domain/usecases/challenge/create_daily_challenge_usecase.dart';
import '../../domain/usecases/challenge/get_active_challenges_usecase.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  // TODO: Get ObjectBox store from a provider
  throw UnimplementedError();
});

final createDailyChallengeUseCaseProvider =
    Provider<CreateDailyChallengeUseCase>((ref) {
  final repository = ref.watch(challengeRepositoryProvider);
  return CreateDailyChallengeUseCase(repository);
});

final getActiveChallengesUseCaseProvider =
    Provider<GetActiveChallengesUseCase>((ref) {
  final repository = ref.watch(challengeRepositoryProvider);
  return GetActiveChallengesUseCase(repository);
});

final activeChallengesProvider =
    FutureProvider<List<ChallengeModel>>((ref) async {
  final useCase = ref.watch(getActiveChallengesUseCaseProvider);
  return await useCase();
});

final dailyChallengeProvider = FutureProvider.autoDispose
    .family<ChallengeModel, ({String? difficulty, String? category})>(
        (ref, params) async {
  final useCase = ref.watch(createDailyChallengeUseCaseProvider);
  return await useCase(
    difficulty: params.difficulty ?? ChallengeDifficulty.medium,
    preferredCategory: params.category,
  );
});
