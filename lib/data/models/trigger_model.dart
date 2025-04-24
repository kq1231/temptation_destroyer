import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

/// Constants for different types of triggers
class TriggerType {
  static const String emotional = 'emotional';
  static const String situational = 'situational';
  static const String temporal = 'temporal';
  static const String physical = 'physical';
  static const String custom = 'custom';

  /// Get all available trigger types
  static List<String> get values => [
        emotional,
        situational,
        temporal,
        physical,
        custom,
      ];
}

/// TriggerModel represents things that trigger temptation for the user
///
/// This model stores information about triggers including description,
/// type, intensity, and creation date.
@Entity()
class Trigger {
  /// Unique identifier assigned by ObjectBox
  @Id()
  int id = 0;

  /// External unique string identifier for cross-references
  @Unique()
  @Property()
  String triggerId;

  /// Description of the trigger
  @Property()
  String description;

  /// Type of trigger (emotional, situational, etc.)
  @Property()
  String triggerType = TriggerType.emotional;

  /// Intensity/severity of the trigger (1-10)
  @Property()
  int intensity;

  /// When the trigger was created
  @Property(type: PropertyType.date)
  DateTime createdAt;

  /// Additional notes about the trigger
  @Property()
  String? notes;

  /// Specific times of day this trigger is active (e.g., "evening,night")
  @Property()
  String? activeTimes;

  /// Specific days of week this trigger is active (e.g., "1,3,5" for Mon,Wed,Fri)
  @Property()
  String? activeDays;

  /// Default constructor for ObjectBox
  Trigger({
    this.id = 0,
    String? triggerId,
    required this.description,
    String? triggerTypeParam,
    this.intensity = 5,
    DateTime? createdAt,
    this.notes,
    this.activeTimes,
    this.activeDays,
  })  : triggerId = triggerId ?? const Uuid().v4(),
        triggerType = triggerTypeParam ?? TriggerType.emotional,
        createdAt = createdAt ?? DateTime.now();

  /// Get list of active times
  List<String> get activeTimesList {
    if (activeTimes == null || activeTimes!.isEmpty) {
      return [];
    }
    return activeTimes!.split(',');
  }

  /// Set list of active times
  set activeTimesList(List<String> times) {
    activeTimes = times.join(',');
  }

  /// Get list of active days as integers (0 = Sunday, 1 = Monday, etc.)
  List<int> get activeDaysList {
    if (activeDays == null || activeDays!.isEmpty) {
      return [];
    }
    return activeDays!.split(',').map((day) => int.parse(day)).toList();
  }

  /// Set list of active days from integers
  set activeDaysList(List<int> days) {
    activeDays = days.map((day) => day.toString()).join(',');
  }

  /// Returns true if this trigger is active at the given time
  bool isActiveAt(DateTime time) {
    // If no specific times or days are set, consider always active
    if ((activeTimes == null || activeTimes!.isEmpty) &&
        (activeDays == null || activeDays!.isEmpty)) {
      return true;
    }

    // Check active days
    if (activeDays != null && activeDays!.isNotEmpty) {
      final dayOfWeek = time.weekday % 7; // 0-6 (0 = Sunday)
      if (!activeDaysList.contains(dayOfWeek)) {
        return false;
      }
    }

    // Check active times
    if (activeTimes != null && activeTimes!.isNotEmpty) {
      final timeOfDay = _getTimeOfDay(time);
      return activeTimesList.contains(timeOfDay);
    }

    return true;
  }

  /// Helper to determine time of day category
  String _getTimeOfDay(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
}
