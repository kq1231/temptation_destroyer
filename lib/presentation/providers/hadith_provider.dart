import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hadith_model.dart';
import '../../data/repositories/hadith_repository.dart';

final dailyHadithProvider = FutureProvider<HadithModel>((ref) async {
  final repository = ref.watch(hadithRepositoryProvider);
  final today = DateTime.now();

  try {
    // First try to get today's hadith
    final hadith = await repository.getHadithForDate(today);
    if (hadith != null) {
      return hadith;
    }

    // If no hadith for today, get a random one
    final randomHadith = await repository.getRandomHadith();
    if (randomHadith == null) {
      throw Exception('No hadiths available');
    }
    return randomHadith;
  } catch (e) {
    throw Exception('Failed to load daily hadith: $e');
  }
});

final hadithListProvider = FutureProvider<List<HadithModel>>((ref) {
  return ref.watch(hadithRepositoryProvider).getAllHadiths();
});

final favoriteHadithsProvider = FutureProvider<List<HadithModel>>((ref) {
  return ref.watch(hadithRepositoryProvider).getFavoriteHadiths();
});
