import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

/// Hobby Category Enum
enum HobbyCategory {
  physical, // Physical activities like sports
  mental, // Mental activities like reading, puzzles
  social, // Social activities like gatherings
  spiritual, // Spiritual activities like meditation
  creative, // Creative activities like art, music
  productive, // Productive activities like learning new skills
  relaxing, // Relaxing activities like nature walks
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

  /// The actual enum type as a transient property
  @Transient()
  HobbyCategory? category;

  /// Category stored as an integer in the database
  int? get dbCategory {
    _ensureStableEnumValues();
    return category?.index;
  }

  /// Setter for the category integer
  set dbCategory(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      category = null;
    } else {
      if (value >= 0 && value < HobbyCategory.values.length) {
        category = HobbyCategory.values[value];
      } else {
        category = HobbyCategory.physical;
      }
    }
  }

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
    HobbyCategory category = HobbyCategory.physical,
    this.frequencyGoal,
    this.durationGoalMinutes,
    this.satisfactionRating,
    DateTime? createdAt,
    this.lastPracticedAt,
  })  : uid = uid ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create a copy with updated values
  HobbyModel copyWith({
    int? id,
    String? uid,
    String? name,
    String? description,
    HobbyCategory? category,
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
      category: category ?? this.category!,
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
    required HobbyCategory category,
    String? description,
    String? frequencyGoal,
    int? durationGoalMinutes,
  }) {
    return HobbyModel(
      name: name,
      category: category,
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

  /// Ensure enum values have stable indices
  void _ensureStableEnumValues() {
    assert(HobbyCategory.physical.index == 0);
    assert(HobbyCategory.mental.index == 1);
    assert(HobbyCategory.social.index == 2);
    assert(HobbyCategory.spiritual.index == 3);
    assert(HobbyCategory.creative.index == 4);
    assert(HobbyCategory.productive.index == 5);
    assert(HobbyCategory.relaxing.index == 6);
  }
}
