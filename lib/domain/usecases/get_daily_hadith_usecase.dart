import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hadith_model.dart';
import '../../data/repositories/hadith_repository.dart';

final getDailyHadithUseCaseProvider = Provider<GetDailyHadithUseCase>((ref) {
  final repository = ref.watch(hadithRepositoryProvider);
  return GetDailyHadithUseCase(repository);
});

class GetDailyHadithUseCase {
  final HadithRepository _repository;

  GetDailyHadithUseCase(this._repository);

  Future<HadithModel?> execute([DateTime? date]) async {
    date ??= DateTime.now();

    // First try to get hadith assigned for today
    final todaysHadith = await _repository.getHadithForDate(date);
    if (todaysHadith != null) {
      return todaysHadith;
    }

    // If no hadith for today, get a random one
    return _repository.getRandomHadith(excludeRecentlyShown: true);
  }
}
