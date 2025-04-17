import 'package:objectbox/objectbox.dart';
import 'package:intl/intl.dart';

@Entity()
class StatisticsModel {
  @Id()
  int id;

  // Streak tracking
  int currentStreak;
  int bestStreak;
  DateTime? streakStartDate;
  DateTime lastUpdatedDate;

  // Serialized date lists
  String triggerDatesJson;
  String slipDatesJson;
  String milestoneDatesJson;

  // Milestone tracking
  int totalEmergenciesSurvived;
  int totalChallengesCompleted;

  // Progress metrics
  double weeklyImprovement;
  double monthlyImprovement;

  // Pattern analysis
  String triggerPatternJson;
  String timePatternJson;

  StatisticsModel({
    this.id = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.streakStartDate,
    DateTime? lastUpdatedDate,
    this.triggerDatesJson = '[]',
    this.slipDatesJson = '[]',
    this.milestoneDatesJson = '[]',
    this.totalEmergenciesSurvived = 0,
    this.totalChallengesCompleted = 0,
    this.weeklyImprovement = 0.0,
    this.monthlyImprovement = 0.0,
    this.triggerPatternJson = '{}',
    this.timePatternJson = '{}',
  }) : lastUpdatedDate = lastUpdatedDate ?? DateTime.now();

  // Formatted date getters for UI display
  String get streakStartFormatted {
    if (streakStartDate == null) return 'Not started';
    return DateFormat('MMM d, yyyy').format(streakStartDate!);
  }

  String get lastUpdatedFormatted {
    return DateFormat('MMM d, yyyy').format(lastUpdatedDate);
  }

  // Formatted metrics for UI display
  String get currentStreakFormatted {
    if (currentStreak == 0) return 'No active streak';
    if (currentStreak == 1) return '1 day';
    return '$currentStreak days';
  }

  String get bestStreakFormatted {
    if (bestStreak == 0) return 'No streak yet';
    if (bestStreak == 1) return '1 day';
    return '$bestStreak days';
  }

  // Streak status for UI display
  bool get hasActiveStreak => currentStreak > 0;

  // Progress labels
  String get weeklyImprovementLabel {
    if (weeklyImprovement > 0) {
      return '+${weeklyImprovement.toStringAsFixed(1)}%';
    } else if (weeklyImprovement < 0) {
      return '${weeklyImprovement.toStringAsFixed(1)}%';
    } else {
      return '0%';
    }
  }

  String get monthlyImprovementLabel {
    if (monthlyImprovement > 0) {
      return '+${monthlyImprovement.toStringAsFixed(1)}%';
    } else if (monthlyImprovement < 0) {
      return '${monthlyImprovement.toStringAsFixed(1)}%';
    } else {
      return '0%';
    }
  }

  // Factory method to create an empty statistics model
  factory StatisticsModel.empty() {
    return StatisticsModel(
      id: 0,
      currentStreak: 0,
      bestStreak: 0,
      lastUpdatedDate: DateTime.now(),
      streakStartDate: null,
      triggerDatesJson: '[]',
      slipDatesJson: '[]',
      milestoneDatesJson: '[]',
      totalEmergenciesSurvived: 0,
      totalChallengesCompleted: 0,
      weeklyImprovement: 0.0,
      monthlyImprovement: 0.0,
      triggerPatternJson: '{}',
      timePatternJson: '{}',
    );
  }
}
