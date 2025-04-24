import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

/// Aspiration Category constants
class AspirationCategory {
  static const String personal = 'personal'; // Personal growth goals
  static const String family = 'family'; // Family-related goals
  static const String career = 'career'; // Career or educational goals
  static const String spiritual = 'spiritual'; // Spiritual growth goals
  static const String health = 'health'; // Health and fitness goals
  static const String social = 'social'; // Social life goals
  static const String financial = 'financial'; // Financial goals
  static const String customized = 'customized'; // User-defined category

  /// Get all available categories
  static List<String> get values => [
        personal,
        family,
        career,
        spiritual,
        health,
        social,
        financial,
        customized,
      ];
}

/// Aspiration Model for goals and duas
@Entity()
class AspirationModel {
  @Id()
  int id = 0;

  /// Unique identifier for the aspiration
  @Unique()
  final String uid;

  /// The dua or aspiration text
  String dua;

  /// Category stored as a string in the database
  String category = AspirationCategory.personal;

  /// Whether the aspiration has been achieved
  bool isAchieved;

  /// Optional target date
  @Property(type: PropertyType.date)
  DateTime? targetDate;

  /// Optional note for the aspiration
  String? note;

  /// When the aspiration was created
  @Property(type: PropertyType.date)
  final DateTime createdAt;

  /// When the aspiration was achieved (if applicable)
  @Property(type: PropertyType.date)
  DateTime? achievedDate;

  /// For encrypted storage
  bool isEncrypted = false;

  AspirationModel({
    this.id = 0,
    String? uid,
    required this.dua,
    String category = AspirationCategory.personal,
    this.isAchieved = false,
    this.targetDate,
    this.note,
    DateTime? createdAt,
    this.achievedDate,
  })  : uid = uid ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create a copy with updated values
  AspirationModel copyWith({
    int? id,
    String? uid,
    String? dua,
    String? category,
    bool? isAchieved,
    DateTime? targetDate,
    String? note,
    DateTime? createdAt,
    DateTime? achievedDate,
    bool? isEncrypted,
  }) {
    return AspirationModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      dua: dua ?? this.dua,
      category: category ?? this.category,
      isAchieved: isAchieved ?? this.isAchieved,
      targetDate: targetDate ?? this.targetDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      achievedDate: achievedDate ?? this.achievedDate,
    )..isEncrypted = isEncrypted ?? this.isEncrypted;
  }

  /// Create a preset aspiration
  static AspirationModel preset({
    required String dua,
    required String category,
    String? note,
  }) {
    return AspirationModel(
      dua: dua,
      category: category,
      note: note,
    );
  }

  /// Get a list of default presets
  static List<AspirationModel> getPresets() {
    return [
      // Spiritual
      preset(
        dua:
            'O Allah, help me to remember You, to thank You, and to worship You in the best way',
        category: AspirationCategory.spiritual,
        note: 'Dua for divine assistance in worship',
      ),
      preset(
        dua:
            'O Allah, I seek refuge in You from the evil of what I have done and from the evil of what I have not done',
        category: AspirationCategory.spiritual,
        note: 'Dua for protection from evil',
      ),
      preset(
        dua:
            'O Allah, distance me from my sins as You have distanced the East from the West',
        category: AspirationCategory.spiritual,
        note: 'Dua for forgiveness',
      ),

      // Personal
      preset(
        dua: 'Complete memorization of Surah Al-Baqarah',
        category: AspirationCategory.personal,
        note: 'Long-term Quran memorization goal',
      ),
      preset(
        dua: 'Learn to control anger in challenging situations',
        category: AspirationCategory.personal,
        note: 'Emotional control goal',
      ),

      // Health
      preset(
        dua: 'Establish a regular exercise routine',
        category: AspirationCategory.health,
        note: 'Health goal',
      ),
      preset(
        dua: 'Improve sleep habits by having a consistent schedule',
        category: AspirationCategory.health,
        note: 'Sleep improvement goal',
      ),

      // Family
      preset(
        dua: 'Spend more quality time with family members',
        category: AspirationCategory.family,
        note: 'Family relationship goal',
      ),
      preset(
        dua: 'O Allah, make me and my offspring those who establish prayer',
        category: AspirationCategory.family,
        note: 'Dua from Surah Ibrahim',
      ),

      // Career
      preset(
        dua: 'Complete professional certification or course',
        category: AspirationCategory.career,
        note: 'Career development goal',
      ),

      // Social
      preset(
        dua: 'Strengthen ties with the Muslim community',
        category: AspirationCategory.social,
        note: 'Community engagement goal',
      ),

      // Financial
      preset(
        dua: 'Save money for Hajj or Umrah',
        category: AspirationCategory.financial,
        note: 'Savings goal for pilgrimage',
      ),
    ];
  }
}
