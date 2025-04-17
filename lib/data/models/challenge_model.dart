import 'package:objectbox/objectbox.dart';
import 'package:intl/intl.dart';

enum ChallengeCategory {
  prayer,
  quran,
  dhikr,
  selfImprovement,
  charity,
  knowledge,
  social,
  physical,
  custom
}

enum ChallengeDifficulty { easy, medium, hard }

enum ChallengeStatus { pending, completed, failed, skipped }

@Entity()
class ChallengeModel {
  @Id()
  int id;

  String title;
  String description;

  @Transient()
  ChallengeCategory category;

  @Property()
  int? dbCategory;

  @Transient()
  ChallengeDifficulty difficulty;

  @Property()
  int? dbDifficulty;

  @Transient()
  ChallengeStatus status;

  @Property()
  int? dbStatus;

  DateTime assignedDate;
  DateTime? completedDate;
  bool isCustom;
  int pointValue;
  String verificationSteps;

  ChallengeModel({
    this.id = 0,
    required this.title,
    required this.description,
    this.category = ChallengeCategory.custom,
    this.difficulty = ChallengeDifficulty.easy,
    this.status = ChallengeStatus.pending,
    required this.assignedDate,
    this.completedDate,
    this.isCustom = false,
    required this.pointValue,
    required this.verificationSteps,
  }) {
    // Initialize db fields from enums
    dbCategory = category.index;
    dbDifficulty = difficulty.index;
    dbStatus = status.index;
  }

  // Getters and setters for db fields
  int? get dbCategoryValue => dbCategory;
  set dbCategoryValue(int? value) {
    dbCategory = value;
    category = ChallengeCategory.values[value ?? 0];
  }

  int? get dbDifficultyValue => dbDifficulty;
  set dbDifficultyValue(int? value) {
    dbDifficulty = value;
    difficulty = ChallengeDifficulty.values[value ?? 0];
  }

  int? get dbStatusValue => dbStatus;
  set dbStatusValue(int? value) {
    dbStatus = value;
    status = ChallengeStatus.values[value ?? 0];
  }

  // Formatted date getters for UI display
  String get assignedDateFormatted {
    return DateFormat('MMM d, yyyy').format(assignedDate);
  }

  String get completedDateFormatted {
    return completedDate != null
        ? DateFormat('MMM d, yyyy').format(completedDate!)
        : 'Not completed';
  }

  // For UI display
  String get categoryLabel {
    switch (category) {
      case ChallengeCategory.prayer:
        return 'Prayer';
      case ChallengeCategory.quran:
        return 'Quran';
      case ChallengeCategory.dhikr:
        return 'Dhikr';
      case ChallengeCategory.selfImprovement:
        return 'Self Improvement';
      case ChallengeCategory.charity:
        return 'Charity';
      case ChallengeCategory.knowledge:
        return 'Knowledge';
      case ChallengeCategory.social:
        return 'Social';
      case ChallengeCategory.physical:
        return 'Physical';
      case ChallengeCategory.custom:
        return 'Custom';
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
    }
  }

  String get statusLabel {
    switch (status) {
      case ChallengeStatus.pending:
        return 'Pending';
      case ChallengeStatus.completed:
        return 'Completed';
      case ChallengeStatus.failed:
        return 'Failed';
      case ChallengeStatus.skipped:
        return 'Skipped';
    }
  }

  // Helper methods
  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isPending => status == ChallengeStatus.pending;
  bool get isFailed => status == ChallengeStatus.failed;
  bool get isSkipped => status == ChallengeStatus.skipped;

  // Mark challenge as completed
  void complete() {
    status = ChallengeStatus.completed;
    dbStatus = status.index;
    completedDate = DateTime.now();
  }

  // Mark challenge as failed
  void fail() {
    status = ChallengeStatus.failed;
    dbStatus = status.index;
  }

  // Mark challenge as skipped
  void skip() {
    status = ChallengeStatus.skipped;
    dbStatus = status.index;
  }

  // Reset challenge to pending
  void reset() {
    status = ChallengeStatus.pending;
    dbStatus = status.index;
    completedDate = null;
  }

  // Creates a copy of this challenge with given parameter updates
  ChallengeModel copyWith({
    int? id,
    String? title,
    String? description,
    ChallengeCategory? category,
    ChallengeDifficulty? difficulty,
    ChallengeStatus? status,
    DateTime? assignedDate,
    DateTime? completedDate,
    bool? isCustom,
    int? pointValue,
    String? verificationSteps,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      assignedDate: assignedDate ?? this.assignedDate,
      completedDate: completedDate ?? this.completedDate,
      isCustom: isCustom ?? this.isCustom,
      pointValue: pointValue ?? this.pointValue,
      verificationSteps: verificationSteps ?? this.verificationSteps,
    );
  }
}
