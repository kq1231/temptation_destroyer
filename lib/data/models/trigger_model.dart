import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

/// Enum for different types of triggers
enum TriggerType { emotional, situational, temporal, physical, custom }

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

  /// The actual enum type as a transient property
  @Transient()
  TriggerType? triggerType;

  /// Type of trigger (emotional, situational, etc.) stored as integer
  int? get dbTriggerType {
    _ensureStableEnumValues();
    return triggerType?.index;
  }

  /// Set the trigger type value
  set dbTriggerType(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      triggerType = null;
    } else {
      if (value >= 0 && value < TriggerType.values.length) {
        triggerType = TriggerType.values[value];
      } else {
        triggerType = TriggerType.emotional;
      }
    }
  }

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
    TriggerType triggerType = TriggerType.emotional,
    this.intensity = 5,
    DateTime? createdAt,
    this.notes,
    this.activeTimes,
    this.activeDays,
  })  : triggerId = triggerId ?? const Uuid().v4(),
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

  /// Ensure enum values have stable indices
  void _ensureStableEnumValues() {
    assert(TriggerType.emotional.index == 0);
    assert(TriggerType.situational.index == 1);
    assert(TriggerType.temporal.index == 2);
    assert(TriggerType.physical.index == 3);
    assert(TriggerType.custom.index == 4);
  }
}
