import '../models/emergency_session_model.dart';
import '../../core/utils/object_box_manager.dart';
import '../../objectbox.g.dart'; // Import generated ObjectBox code
import 'dart:developer' as dev;

/// Repository for managing emergency sessions (loss cycles)
class EmergencyRepository {
  /// Save an emergency session to the database
  ///
  /// Returns the saved session with its ID
  Future<EmergencySession> saveSession(EmergencySession session) async {
    final box = ObjectBoxManager.instance.box<EmergencySession>();
    final id = box.put(session);

    // Return the session with the updated ID
    return session..id = id;
  }

  /// Get the currently active emergency session (if any)
  ///
  /// Returns null if there is no active session
  Future<EmergencySession?> getActiveSession() async {
    final box = ObjectBoxManager.instance.box<EmergencySession>();

    // Query for sessions where endTime is null (active sessions)
    final query = box.query(EmergencySessionModel_.endTime.isNull()).build();
    final activeSessions = query.find();
    query.close();

    // Return the most recent active session if there are any
    if (activeSessions.isNotEmpty) {
      // Sort by start time (most recent first)
      activeSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return activeSessions.first;
    }

    return null;
  }

  /// Update an existing emergency session
  ///
  /// Returns true if the update was successful
  Future<bool> updateSession(EmergencySession session) async {
    try {
      final box = ObjectBoxManager.instance.box<EmergencySession>();
      box.put(session);
      return true;
    } catch (e) {
      dev.log('Error updating emergency session: $e');
      return false;
    }
  }

  /// End an active emergency session
  ///
  /// Marks the session as ended with the current time or the specified custom end time
  Future<bool> endSession({
    required int sessionId,
    DateTime? customEndTime,
    bool? wasSuccessful,
    String? notes,
    String? helpfulStrategies,
    int? intensity,
  }) async {
    try {
      final box = ObjectBoxManager.instance.box<EmergencySession>();
      final session = box.get(sessionId);

      if (session == null) {
        return false; // Session not found
      }

      // End the session
      session.endSession(
          customEndTime: customEndTime,
          successful: wasSuccessful,
          notes: notes);

      // Update additional data if provided
      if (helpfulStrategies != null) {
        session.helpfulStrategies = helpfulStrategies;
      }

      if (intensity != null) {
        session.intensity = intensity;
      }

      // Save the updated session
      box.put(session);
      return true;
    } catch (e) {
      dev.log('Error ending emergency session: $e');
      return false;
    }
  }

  /// Get all emergency sessions, sorted by start time (most recent first)
  Future<List<EmergencySession>> getAllSessions() async {
    final box = ObjectBoxManager.instance.box<EmergencySession>();
    final sessions = box.getAll();

    // Sort by start time (most recent first)
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return sessions;
  }

  /// Get sessions from a specific time period
  Future<List<EmergencySession>> getSessionsByTimeRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final box = ObjectBoxManager.instance.box<EmergencySession>();

    // Query for sessions in the specified time range
    final query = box
        .query(
          EmergencySessionModel_.startTime.between(
            startDate.millisecondsSinceEpoch,
            endDate.millisecondsSinceEpoch,
          ),
        )
        .build();

    final sessions = query.find();
    query.close();

    // Sort by start time (most recent first)
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return sessions;
  }

  /// Add a trigger to an active session
  Future<bool> addTriggerToSession(int sessionId, String triggerId) async {
    try {
      final box = ObjectBoxManager.instance.box<EmergencySession>();
      final session = box.get(sessionId);

      if (session == null) {
        return false; // Session not found
      }

      // Add the trigger ID
      session.addTrigger(triggerId);

      // Save the updated session
      box.put(session);
      return true;
    } catch (e) {
      dev.log('Error adding trigger to session: $e');
      return false;
    }
  }

  /// Get the duration of an emergency session
  ///
  /// If the session is still active, returns the time since it started
  Duration getSessionDuration(EmergencySession session) {
    return session.duration;
  }

  /// Check if there are any active emergency sessions
  Future<bool> hasActiveSession() async {
    final activeSession = await getActiveSession();
    return activeSession != null;
  }
}
