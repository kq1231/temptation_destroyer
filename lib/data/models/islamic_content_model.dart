import 'package:objectbox/objectbox.dart';

/// Content type constants
class ContentType {
  static const String hadith = 'hadith';
  static const String quran = 'quran';
  static const String dua = 'dua';
  static const String quote = 'quote';
  static const String reflection = 'reflection';

  /// Get all available content types
  static List<String> get values => [
        hadith,
        quran,
        dua,
        quote,
        reflection,
      ];
}

/// Content category constants
class ContentCategory {
  static const String strength = 'strength';
  static const String patience = 'patience';
  static const String forgiveness = 'forgiveness';
  static const String gratitude = 'gratitude';
  static const String purification = 'purification';
  static const String repentance = 'repentance';
  static const String discipline = 'discipline';
  static const String selfControl = 'selfControl';
  static const String general = 'general';
  static const String charity = 'charity';
  static const String hope = 'hope';
  static const String determination = 'determination';
  static const String mercy = 'mercy';
  static const String relief = 'relief';
  static const String guidance = 'guidance';

  /// Get all available categories
  static List<String> get values => [
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
      ];
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

  String contentType = ContentType.hadith;

  String category = ContentCategory.general;

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
    if (contentType == ContentType.hadith) return 'Hadith';
    if (contentType == ContentType.quran) return 'Quran';
    if (contentType == ContentType.dua) return 'Dua';
    if (contentType == ContentType.quote) return 'Quote';
    if (contentType == ContentType.reflection) return 'Reflection';
    return contentType; // Fallback
  }

  String get categoryLabel {
    if (category == ContentCategory.strength) return 'Strength';
    if (category == ContentCategory.patience) return 'Patience';
    if (category == ContentCategory.forgiveness) return 'Forgiveness';
    if (category == ContentCategory.gratitude) return 'Gratitude';
    if (category == ContentCategory.purification) return 'Purification';
    if (category == ContentCategory.repentance) return 'Repentance';
    if (category == ContentCategory.discipline) return 'Discipline';
    if (category == ContentCategory.selfControl) return 'Self Control';
    if (category == ContentCategory.general) return 'General';
    if (category == ContentCategory.charity) return 'Charity';
    if (category == ContentCategory.hope) return 'Hope';
    if (category == ContentCategory.determination) return 'Determination';
    if (category == ContentCategory.mercy) return 'Mercy';
    if (category == ContentCategory.relief) return 'Relief';
    if (category == ContentCategory.guidance) return 'Guidance';
    return category; // Fallback
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
    String? contentType,
    String? category,
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
    String category = ContentCategory.general,
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
    String category = ContentCategory.general,
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
    String category = ContentCategory.general,
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
