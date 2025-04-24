import 'package:objectbox/objectbox.dart';
import 'package:intl/intl.dart';

/// Challenge category constants
class ChallengeCategory {
  static const String prayer = 'prayer';
  static const String quran = 'quran';
  static const String dhikr = 'dhikr';
  static const String selfImprovement = 'selfImprovement';
  static const String charity = 'charity';
  static const String knowledge = 'knowledge';
  static const String social = 'social';
  static const String physical = 'physical';
  static const String custom = 'custom';

  /// Get all available categories
  static List<String> get values => [
        prayer,
        quran,
        dhikr,
        selfImprovement,
        charity,
        knowledge,
        social,
        physical,
        custom,
      ];
}

/// Challenge difficulty constants
class ChallengeDifficulty {
  static const String easy = 'easy';
  static const String medium = 'medium';
  static const String hard = 'hard';

  /// Get all available difficulties
  static List<String> get values => [
        easy,
        medium,
        hard,
      ];
}

/// Challenge status constants
class ChallengeStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String skipped = 'skipped';

  /// Get all available statuses
  static List<String> get values => [
        pending,
        completed,
        failed,
        skipped,
      ];
}

@Entity()
class ChallengeModel {
  @Id()
  int id;

  String title;
  String description;

  String category = ChallengeCategory.custom;
  String difficulty = ChallengeDifficulty.easy;
  String status = ChallengeStatus.pending;

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
  });

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
    if (category == ChallengeCategory.prayer) return 'Prayer';
    if (category == ChallengeCategory.quran) return 'Quran';
    if (category == ChallengeCategory.dhikr) return 'Dhikr';
    if (category == ChallengeCategory.selfImprovement) {
      return 'Self Improvement';
    }
    if (category == ChallengeCategory.charity) return 'Charity';
    if (category == ChallengeCategory.knowledge) return 'Knowledge';
    if (category == ChallengeCategory.social) return 'Social';
    if (category == ChallengeCategory.physical) return 'Physical';
    if (category == ChallengeCategory.custom) return 'Custom';
    return category; // Fallback
  }

  String get difficultyLabel {
    if (difficulty == ChallengeDifficulty.easy) return 'Easy';
    if (difficulty == ChallengeDifficulty.medium) return 'Medium';
    if (difficulty == ChallengeDifficulty.hard) return 'Hard';
    return difficulty; // Fallback
  }

  String get statusLabel {
    if (status == ChallengeStatus.pending) return 'Pending';
    if (status == ChallengeStatus.completed) return 'Completed';
    if (status == ChallengeStatus.failed) return 'Failed';
    if (status == ChallengeStatus.skipped) return 'Skipped';
    return status; // Fallback
  }

  // Helper methods
  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isPending => status == ChallengeStatus.pending;
  bool get isFailed => status == ChallengeStatus.failed;
  bool get isSkipped => status == ChallengeStatus.skipped;

  // Mark challenge as completed
  void complete() {
    status = ChallengeStatus.completed;
    completedDate = DateTime.now();
  }

  // Mark challenge as failed
  void fail() {
    status = ChallengeStatus.failed;
  }

  // Mark challenge as skipped
  void skip() {
    status = ChallengeStatus.skipped;
  }

  // Reset challenge to pending
  void reset() {
    status = ChallengeStatus.pending;
    completedDate = null;
  }

  // Creates a copy of this challenge with given parameter updates
  ChallengeModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    String? status,
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
