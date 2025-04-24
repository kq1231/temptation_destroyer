import 'package:objectbox/objectbox.dart';
import 'package:intl/intl.dart';

/// Achievement type constants
class AchievementType {
  static const String streak = 'streak';
  static const String emergency = 'emergency';
  static const String challenge = 'challenge';
  static const String quran = 'quran';
  static const String prayer = 'prayer';
  static const String community = 'community';
  static const String knowledge = 'knowledge';
  static const String general = 'general';

  /// Get all available achievement types
  static List<String> get values => [
        streak,
        emergency,
        challenge,
        quran,
        prayer,
        community,
        knowledge,
        general,
      ];
}

/// Achievement rarity constants
class AchievementRarity {
  static const String common = 'common';
  static const String uncommon = 'uncommon';
  static const String rare = 'rare';
  static const String epic = 'epic';
  static const String legendary = 'legendary';

  /// Get all available rarities
  static List<String> get values => [
        common,
        uncommon,
        rare,
        epic,
        legendary,
      ];
}

@Entity()
class AchievementModel {
  @Id()
  int id;

  String title;
  String description;
  String iconName;
  int pointValue;

  // Progress tracking
  int progressCurrent;
  int progressTarget;
  bool isUnlocked;
  DateTime? unlockedDate;

  String type = AchievementType.general;
  String rarity = AchievementRarity.common;

  AchievementModel({
    this.id = 0,
    required this.title,
    required this.description,
    required this.iconName,
    required this.pointValue,
    this.type = AchievementType.general,
    this.rarity = AchievementRarity.common,
    required this.progressTarget,
    this.progressCurrent = 0,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  // For UI display
  String get typeLabel {
    if (type == AchievementType.streak) return 'Streak';
    if (type == AchievementType.emergency) return 'Emergency';
    if (type == AchievementType.challenge) return 'Challenge';
    if (type == AchievementType.quran) return 'Quran';
    if (type == AchievementType.prayer) return 'Prayer';
    if (type == AchievementType.community) return 'Community';
    if (type == AchievementType.knowledge) return 'Knowledge';
    if (type == AchievementType.general) return 'General';
    return type; // Fallback
  }

  String get rarityLabel {
    if (rarity == AchievementRarity.common) return 'Common';
    if (rarity == AchievementRarity.uncommon) return 'Uncommon';
    if (rarity == AchievementRarity.rare) return 'Rare';
    if (rarity == AchievementRarity.epic) return 'Epic';
    if (rarity == AchievementRarity.legendary) return 'Legendary';
    return rarity; // Fallback
  }

  // Formatted date for UI display
  String get unlockedDateFormatted {
    return unlockedDate != null
        ? DateFormat('MMM d, yyyy').format(unlockedDate!)
        : 'Not yet unlocked';
  }

  // Progress percentage for UI display
  double get progressPercentage {
    if (progressTarget == 0) return 0.0;
    return (progressCurrent / progressTarget).clamp(0.0, 1.0);
  }

  String get progressFormatted => '$progressCurrent/$progressTarget';

  // Update progress and check if achievement unlocked
  bool updateProgress(int newProgress) {
    progressCurrent = newProgress;

    if (!isUnlocked && progressCurrent >= progressTarget) {
      isUnlocked = true;
      unlockedDate = DateTime.now();
      return true; // Achievement newly unlocked
    }

    return false; // No unlock change
  }

  // Increment progress by one and check if achievement unlocked
  bool incrementProgress() {
    return updateProgress(progressCurrent + 1);
  }

  // Creates a copy of this achievement with given parameter updates
  AchievementModel copyWith({
    int? id,
    String? title,
    String? description,
    String? iconName,
    int? pointValue,
    String? type,
    String? rarity,
    int? progressCurrent,
    int? progressTarget,
    bool? isUnlocked,
    DateTime? unlockedDate,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      pointValue: pointValue ?? this.pointValue,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTarget: progressTarget ?? this.progressTarget,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }

  // Factory methods for common achievement types
  static AchievementModel createStreakAchievement({
    required String title,
    required String description,
    required String iconName,
    required int daysRequired,
    int pointValue = 10,
    String rarity = AchievementRarity.common,
  }) {
    return AchievementModel(
      title: title,
      description: description,
      iconName: iconName,
      pointValue: pointValue,
      type: AchievementType.streak,
      rarity: rarity,
      progressTarget: daysRequired,
    );
  }

  static AchievementModel createEmergencyAchievement({
    required String title,
    required String description,
    required String iconName,
    required int emergenciesResolved,
    int pointValue = 15,
    String rarity = AchievementRarity.uncommon,
  }) {
    return AchievementModel(
      title: title,
      description: description,
      iconName: iconName,
      pointValue: pointValue,
      type: AchievementType.emergency,
      rarity: rarity,
      progressTarget: emergenciesResolved,
    );
  }

  static AchievementModel createChallengeAchievement({
    required String title,
    required String description,
    required String iconName,
    required int challengesCompleted,
    int pointValue = 20,
    String rarity = AchievementRarity.uncommon,
  }) {
    return AchievementModel(
      title: title,
      description: description,
      iconName: iconName,
      pointValue: pointValue,
      type: AchievementType.challenge,
      rarity: rarity,
      progressTarget: challengesCompleted,
    );
  }
}
