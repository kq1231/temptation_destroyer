import 'package:objectbox/objectbox.dart';
import 'package:intl/intl.dart';

enum AchievementType {
  streak,
  emergency,
  challenge,
  quran,
  prayer,
  community,
  knowledge,
  general
}

enum AchievementRarity { common, uncommon, rare, epic, legendary }

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

  @Transient()
  AchievementType type;

  @Transient()
  AchievementRarity rarity;

  int? get dbType {
    return type.index;
  }

  set dbType(int? value) {
    type = AchievementType.values[value ?? 0];
  }

  int? get dbRarity {
    return rarity.index;
  }

  set dbRarity(int? value) {
    rarity = AchievementRarity.values[value ?? 0];
  }

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
    switch (type) {
      case AchievementType.streak:
        return 'Streak';
      case AchievementType.emergency:
        return 'Emergency';
      case AchievementType.challenge:
        return 'Challenge';
      case AchievementType.quran:
        return 'Quran';
      case AchievementType.prayer:
        return 'Prayer';
      case AchievementType.community:
        return 'Community';
      case AchievementType.knowledge:
        return 'Knowledge';
      case AchievementType.general:
        return 'General';
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
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
    AchievementType? type,
    AchievementRarity? rarity,
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
    AchievementRarity rarity = AchievementRarity.common,
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
    AchievementRarity rarity = AchievementRarity.uncommon,
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
    AchievementRarity rarity = AchievementRarity.uncommon,
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
