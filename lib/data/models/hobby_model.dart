import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

/// Hobby Category constants
class HobbyCategory {
  static const String physical = 'physical'; // Physical activities like sports
  static const String mental =
      'mental'; // Mental activities like reading, puzzles
  static const String social = 'social'; // Social activities like gatherings
  static const String spiritual =
      'spiritual'; // Spiritual activities like meditation
  static const String creative =
      'creative'; // Creative activities like art, music
  static const String productive =
      'productive'; // Productive activities like learning new skills
  static const String relaxing =
      'relaxing'; // Relaxing activities like nature walks

  /// Get all available categories
  static List<String> get values => [
        physical,
        mental,
        social,
        spiritual,
        creative,
        productive,
        relaxing,
      ];
}

/// Hobby Model for tracking activities
@Entity()
class HobbyModel {
  @Id()
  int id = 0;

  /// Unique identifier for the hobby
  @Unique()
  final String uid;

  /// The name of the hobby
  String name;

  /// Description of the hobby
  String? description;

  /// Category of the hobby (physical, mental, etc.)
  String category = HobbyCategory.physical;

  /// Frequency goal (e.g., daily, weekly)
  String? frequencyGoal;

  /// Duration goal in minutes
  int? durationGoalMinutes;

  /// User satisfaction rating (1-5)
  int? satisfactionRating;

  /// When the hobby was added
  @Property(type: PropertyType.date)
  final DateTime createdAt;

  /// When the hobby was last practiced
  @Property(type: PropertyType.date)
  DateTime? lastPracticedAt;

  /// For encrypted storage
  bool isEncrypted = false;

  HobbyModel({
    this.id = 0,
    String? uid,
    required this.name,
    this.description,
    String? categoryParam,
    this.frequencyGoal,
    this.durationGoalMinutes,
    this.satisfactionRating,
    DateTime? createdAt,
    this.lastPracticedAt,
  })  : uid = uid ?? const Uuid().v4(),
        category = categoryParam ?? HobbyCategory.physical,
        createdAt = createdAt ?? DateTime.now();

  /// Create a copy with updated values
  HobbyModel copyWith({
    int? id,
    String? uid,
    String? name,
    String? description,
    String? category,
    String? frequencyGoal,
    int? durationGoalMinutes,
    int? satisfactionRating,
    DateTime? createdAt,
    DateTime? lastPracticedAt,
    bool? isEncrypted,
  }) {
    return HobbyModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryParam: category ?? this.category,
      frequencyGoal: frequencyGoal ?? this.frequencyGoal,
      durationGoalMinutes: durationGoalMinutes ?? this.durationGoalMinutes,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      createdAt: createdAt ?? this.createdAt,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
    )..isEncrypted = isEncrypted ?? this.isEncrypted;
  }

  /// Create a preset hobby
  static HobbyModel preset({
    required String name,
    required String category,
    String? description,
    String? frequencyGoal,
    int? durationGoalMinutes,
  }) {
    return HobbyModel(
      name: name,
      categoryParam: category,
      description: description,
      frequencyGoal: frequencyGoal,
      durationGoalMinutes: durationGoalMinutes,
    );
  }

  /// Get a list of default presets
  static List<HobbyModel> getPresets() {
    return [
      // Physical
      preset(
        name: 'Walking',
        category: HobbyCategory.physical,
        description: 'Regular walking for exercise and reflection',
        frequencyGoal: 'Daily',
        durationGoalMinutes: 30,
      ),
      preset(
        name: 'Swimming',
        category: HobbyCategory.physical,
        description: 'Swimming for fitness and relaxation',
        frequencyGoal: 'Twice weekly',
        durationGoalMinutes: 45,
      ),

      // Mental
      preset(
        name: 'Reading',
        category: HobbyCategory.mental,
        description: 'Reading books for knowledge and enjoyment',
        frequencyGoal: 'Daily',
        durationGoalMinutes: 30,
      ),
      preset(
        name: 'Learning a language',
        category: HobbyCategory.mental,
        description: 'Studying a new language',
        frequencyGoal: 'Daily',
        durationGoalMinutes: 20,
      ),

      // Spiritual
      preset(
        name: 'Quran recitation',
        category: HobbyCategory.spiritual,
        description: 'Regular recitation of the Quran',
        frequencyGoal: 'Daily',
        durationGoalMinutes: 15,
      ),
      preset(
        name: 'Dhikr',
        category: HobbyCategory.spiritual,
        description: 'Remembrance of Allah through dhikr',
        frequencyGoal: 'Daily',
        durationGoalMinutes: 10,
      ),

      // Creative
      preset(
        name: 'Calligraphy',
        category: HobbyCategory.creative,
        description: 'Islamic or Arabic calligraphy practice',
        frequencyGoal: 'Weekly',
        durationGoalMinutes: 60,
      ),

      // Social
      preset(
        name: 'Community volunteering',
        category: HobbyCategory.social,
        description: 'Volunteering at local masjid or community',
        frequencyGoal: 'Weekly',
        durationGoalMinutes: 120,
      ),

      // Productive
      preset(
        name: 'Gardening',
        category: HobbyCategory.productive,
        description: 'Growing plants and maintaining a garden',
        frequencyGoal: 'Weekly',
        durationGoalMinutes: 90,
      ),

      // Relaxing
      preset(
        name: 'Nature walks',
        category: HobbyCategory.relaxing,
        description: 'Walking in natural settings for relaxation',
        frequencyGoal: 'Weekly',
        durationGoalMinutes: 60,
      ),
    ];
  }
}
