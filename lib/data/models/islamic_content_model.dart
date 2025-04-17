import 'package:objectbox/objectbox.dart';

enum ContentType { hadith, quran, dua, quote, reflection }

enum ContentCategory {
  strength,
  patience,
  forgiveness,
  gratitude,
  purification,
  repentance,
  discipline,
  selfControl,
  general,
  charity,
  hope,
  determination,
  mercy,
  relief,
  guidance,
}

@Entity()
class IslamicContentModel {
  @Id()
  int id;

  String content;
  String source;
  String reference;
  String? translation;
  String? explanation;

  ContentType contentType;

  ContentCategory category;

  int? get dbContentType {
    return contentType.index;
  }

  set dbContentType(int? value) {
    contentType = ContentType.values[value ?? 0];
  }

  int? get dbCategory {
    return category.index;
  }

  set dbCategory(int? value) {
    category = ContentCategory.values[value ?? 0];
  }

  bool isFavorite;
  DateTime dateAdded = DateTime.now(); // Initialize with default value
  DateTime? lastDisplayed;
  int displayCount;

  // Tags stored as comma-separated string
  String tags;

  // Get tags as a list
  List<String> get tagsList =>
      tags.split(',').where((tag) => tag.isNotEmpty).toList();
  // Set tags from a list
  set tagsList(List<String> tagList) => tags = tagList.join(',');

  IslamicContentModel({
    this.id = 0,
    required this.content,
    required this.source,
    required this.reference,
    this.translation,
    this.explanation,
    this.contentType = ContentType.hadith,
    this.category = ContentCategory.general,
    this.isFavorite = false,
    DateTime? dateAdded,
    this.lastDisplayed,
    this.displayCount = 0,
    this.tags = '',
  }) {
    if (dateAdded != null) {
      this.dateAdded = dateAdded;
    }
  }

  // For UI display
  String get contentTypeLabel {
    switch (contentType) {
      case ContentType.hadith:
        return 'Hadith';
      case ContentType.quran:
        return 'Quran';
      case ContentType.dua:
        return 'Dua';
      case ContentType.quote:
        return 'Quote';
      case ContentType.reflection:
        return 'Reflection';
    }
  }

  String get categoryLabel {
    switch (category) {
      case ContentCategory.strength:
        return 'Strength';
      case ContentCategory.patience:
        return 'Patience';
      case ContentCategory.forgiveness:
        return 'Forgiveness';
      case ContentCategory.gratitude:
        return 'Gratitude';
      case ContentCategory.purification:
        return 'Purification';
      case ContentCategory.repentance:
        return 'Repentance';
      case ContentCategory.discipline:
        return 'Discipline';
      case ContentCategory.selfControl:
        return 'Self Control';
      case ContentCategory.general:
        return 'General';
      case ContentCategory.charity:
        return 'Charity';
      case ContentCategory.hope:
        return 'Hope';
      case ContentCategory.determination:
        return 'Determination';
      case ContentCategory.mercy:
        return 'Mercy';
      case ContentCategory.relief:
        return 'Relief';
      case ContentCategory.guidance:
        return 'Guidance';
    }
  }

  // Helper method to update display tracking
  void markDisplayed() {
    lastDisplayed = DateTime.now();
    displayCount++;
  }

  // Toggle favorite status
  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  // Creates a copy of this content with given parameter updates
  IslamicContentModel copyWith({
    int? id,
    String? content,
    String? source,
    String? reference,
    String? translation,
    String? explanation,
    ContentType? contentType,
    ContentCategory? category,
    bool? isFavorite,
    DateTime? dateAdded,
    DateTime? lastDisplayed,
    int? displayCount,
    String? tags,
  }) {
    return IslamicContentModel(
      id: id ?? this.id,
      content: content ?? this.content,
      source: source ?? this.source,
      reference: reference ?? this.reference,
      translation: translation ?? this.translation,
      explanation: explanation ?? this.explanation,
      contentType: contentType ?? this.contentType,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      dateAdded: dateAdded ?? this.dateAdded,
      lastDisplayed: lastDisplayed ?? this.lastDisplayed,
      displayCount: displayCount ?? this.displayCount,
      tags: tags ?? this.tags,
    );
  }

  // Factory method to create a basic Hadith entry
  static IslamicContentModel createHadith({
    required String content,
    required String source,
    required String reference,
    String? translation,
    ContentCategory category = ContentCategory.general,
    List<String> tags = const [],
  }) {
    return IslamicContentModel(
      content: content,
      source: source,
      reference: reference,
      translation: translation,
      contentType: ContentType.hadith,
      category: category,
      tags: tags.join(','),
    );
  }

  // Factory method to create a basic Quran verse entry
  static IslamicContentModel createQuranVerse({
    required String content,
    required String reference, // e.g. "2:255" for Ayatul Kursi
    required String translation,
    String? explanation,
    ContentCategory category = ContentCategory.general,
    List<String> tags = const [],
  }) {
    return IslamicContentModel(
      content: content,
      source: 'Quran',
      reference: reference,
      translation: translation,
      explanation: explanation,
      contentType: ContentType.quran,
      category: category,
      tags: tags.join(','),
    );
  }

  // Factory method to create a basic Dua entry
  static IslamicContentModel createDua({
    required String content,
    required String source,
    required String reference,
    required String translation,
    ContentCategory category = ContentCategory.general,
    List<String> tags = const [],
  }) {
    return IslamicContentModel(
      content: content,
      source: source,
      reference: reference,
      translation: translation,
      contentType: ContentType.dua,
      category: category,
      tags: tags.join(','),
    );
  }
}
