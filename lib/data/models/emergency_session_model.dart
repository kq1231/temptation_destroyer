import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

/// EmergencySessionModel tracks "loss cycles" when the user needs emergency help
///
/// This model stores data about emergency sessions, including start and end times,
/// active triggers, whether AI guidance was shown, and any notes.
@Entity()
class EmergencySession {
  /// Unique identifier for the session (automatically assigned by ObjectBox)
  @Id()
  int id = 0;

  /// External unique string identifier for cross-references
  @Unique()
  @Property()
  String sessionId;

  /// When the session/loss cycle started
  @Property(type: PropertyType.date)
  DateTime startTime;

  /// When the session/loss cycle ended (null if still active)
  @Property(type: PropertyType.date)
  DateTime? endTime;

  /// List of trigger IDs that were active during this session
  /// Stored as comma-separated string for simplicity
  @Property()
  String? activeTriggerIds;

  /// Whether AI guidance was shown during this session
  @Property()
  bool wasAIGuidanceShown;

  /// Any notes the user provided about this session
  @Property()
  String? notes;

  /// The severity/intensity of the loss cycle (1-10)
  @Property()
  int? intensity;

  /// Whether the user successfully resisted
  @Property()
  bool? wasSuccessful;

  /// The strategies that helped during this session
  @Property()
  String? helpfulStrategies;

  /// Constructor
  EmergencySession({
    this.id = 0,
    String? sessionId,
    required this.startTime,
    this.endTime,
    this.activeTriggerIds,
    this.wasAIGuidanceShown = false,
    this.notes,
    this.intensity,
    this.wasSuccessful,
    this.helpfulStrategies,
  }) : sessionId = sessionId ?? const Uuid().v4();

  /// Check if this session is currently active (no end time)
  bool get isActive => endTime == null;

  /// Get the duration of the session
  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    } else {
      return endTime!.difference(startTime);
    }
  }

  /// End the session with the current time
  void endSession({DateTime? customEndTime, bool? successful, String? notes}) {
    endTime = customEndTime ?? DateTime.now();
    if (successful != null) {
      wasSuccessful = successful;
    }
    if (notes != null && notes.isNotEmpty) {
      this.notes = notes;
    }
  }

  /// Add a trigger ID to the active triggers list
  void addTrigger(String triggerId) {
    if (activeTriggerIds == null || activeTriggerIds!.isEmpty) {
      activeTriggerIds = triggerId;
    } else if (!activeTriggerIds!.split(',').contains(triggerId)) {
      activeTriggerIds = '$activeTriggerIds,$triggerId';
    }
  }

  /// Get the list of active trigger IDs
  List<String> get triggerList {
    if (activeTriggerIds == null || activeTriggerIds!.isEmpty) {
      return [];
    }
    return activeTriggerIds!.split(',');
  }
}
