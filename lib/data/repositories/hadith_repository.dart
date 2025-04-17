import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/core/utils/object_box_manager.dart';
import 'package:temptation_destroyer/objectbox.g.dart';
import '../models/hadith_model.dart';

final hadithRepositoryProvider = Provider<HadithRepository>((ref) {
  final box = ObjectBoxManager.instance.store.box<HadithModel>();
  return HadithRepository(box);
});

class HadithRepository {
  final Box<HadithModel> _box;

  HadithRepository(this._box);

  // Get a random hadith that hasn't been shown recently
  Future<HadithModel?> getRandomHadith(
      {bool excludeRecentlyShown = true}) async {
    QueryBuilder query = _box.query()
      ..order(HadithModel_.id, flags: Order.descending);

    if (excludeRecentlyShown) {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      query = _box.query(HadithModel_.lastShownDate.isNull() |
          HadithModel_.lastShownDate
              .lessThan(cutoffDate.millisecondsSinceEpoch))
        ..order(HadithModel_.lastShownDate, flags: Order.descending);
    }

    final hadith = query.build().findFirst();
    if (hadith != null) {
      hadith.lastShownDate = DateTime.now();
      _box.put(hadith);
    }
    return hadith;
  }

  // Get hadith for a specific date
  Future<HadithModel?> getHadithForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _box
        .query(HadithModel_.lastShownDate.between(
            startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch))
        .build()
        .findFirst();
  }

  // Save a hadith
  Future<int> saveHadith(HadithModel hadith) async {
    return _box.put(hadith);
  }

  // Get all favorite hadiths
  Future<List<HadithModel>> getFavoriteHadiths() async {
    return _box.query(HadithModel_.isFavorite.equals(true)).build().find();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(int hadithId) async {
    final hadith = _box.get(hadithId);
    if (hadith != null) {
      hadith.isFavorite = !hadith.isFavorite;
      _box.put(hadith);
    }
  }

  // Import preset hadiths
  Future<void> importPresetHadiths(List<HadithModel> hadiths) async {
    _box.putMany(hadiths);
  }

  // Get all hadiths
  Future<List<HadithModel>> getAllHadiths() async {
    return _box.getAll();
  }

  // Delete a hadith
  Future<void> deleteHadith(int hadithId) async {
    _box.remove(hadithId);
  }
}
