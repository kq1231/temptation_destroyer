# Emergency Feature Implementation Plan

## Overview
The goal is to create a minimally viable emergency feature that:
1. Allows users to start an emergency session when facing temptations
2. Tracks active sessions in the ObjectBox database
3. Shows a timer for the active session
4. Checks for active sessions when the app starts
5. Allows users to end sessions and log details
6. Integrates with AI to provide personalized guidance based on user's hobbies and aspirations

## Implementation Tasks

### 1. Create a Dedicated Timer Widget
- [x] Create a `EmergencyTimerWidget` that updates every second
- [x] Ensure it only rebuilds the timer part, not the entire screen
- [x] Display elapsed time in a user-friendly format

### 2. Update Emergency Session Provider
- [x] Modify `emergency_session_provider_refactored.dart` to properly handle active sessions
- [x] Ensure it checks for active sessions on app startup
- [x] Add methods to start and end emergency sessions if not already present

### 3. Create App Initialization Provider
- [x] Create an app start provider using Riverpod's FutureProvider
- [x] Implement initialization logic to check for active emergency sessions
- [x] Initialize the emergency timer if an active session exists
- [x] Integrate app start provider with app initialization flow
- [x] Show notification or dialog when active session is detected on app startup

### 4. Update Emergency Screen
- [x] Add AI guidance section to display personalized advice
- [x] Implement the timer widget that updates every second
- [x] Add functionality to the quick action buttons
- [x] Ensure proper session management (start/end)

### 5. AI Context Integration
- [x] Use existing context manager to build AI context for emergency sessions
- [x] Fetch relevant hobbies and aspirations to provide to the AI
- [x] Ensure AI guidance is personalized to the user's situation

## App Initialization Flow

### App Start Provider
```dart
// Create a FutureProvider for app initialization
final appStartProvider = FutureProvider<void>((ref) async {
  // Initialize all required services
  await _initializeServices(ref);

  // Check for active emergency sessions
  await _checkForActiveEmergencySessions(ref);
});
```

### Emergency Session Check
```dart
Future<void> _checkForActiveEmergencySessions(Ref ref) async {
  // Get the active session use case
  final getActiveUseCase = ref.read(getActiveSessionUseCaseProvider);

  // Check if there's an active session
  final hasActiveSession = await getActiveUseCase.hasActiveSession();

  if (hasActiveSession) {
    // Initialize the emergency timer
    final timerNotifier = ref.read(emergencyTimerProvider.notifier);
    await timerNotifier.initialize();

    // Show notification to the user
    ref.read(notificationServiceProvider).showActiveSessionNotification();
  }
}
```

### Integration with App Startup
1. Add the app start provider to the main.dart file
2. Ensure it's called before the app UI is displayed
3. Use a splash screen while initialization is in progress
4. Show a notification or dialog if an active emergency session is detected
5. Provide options to navigate to the emergency screen or end the session

## Progress Tracking

### Completed
- Initial plan created
- Detailed app initialization flow
- Created dedicated timer widget

### In Progress
- None currently

### Pending
- None

### Completed
- Created dedicated timer widget
- Created app initialization provider
- Updated emergency screen with AI guidance section
- Added functionality to quick action buttons
- Integrated app start provider with app initialization flow
- Added notification service for active emergency sessions
- Implemented notification dialog when active session is detected
- Created emergency context builder for personalized AI guidance
- Integrated AI guidance with user's hobbies and aspirations
- Fixed all code analysis issues

## Notes
- Using existing providers and models where possible
- Creating dedicated widgets for components that need frequent updates
- Following Riverpod best practices for app initialization
- Using FutureProvider for initialization tasks to ensure they complete before the app is fully loaded

## Summary of Implementation

### What We've Accomplished
1. Created a dedicated timer widget that efficiently updates only the timer part of the screen
2. Implemented an app initialization provider that checks for active emergency sessions at app startup
3. Updated the emergency screen with:
   - AI guidance section
   - Dedicated timer widget
   - Functional quick action buttons with helpful dialogs
4. Added a notification service to show a dialog when an active emergency session is detected
5. Integrated everything with the app initialization flow

### What's Left to Do
All tasks have been completed successfully!

### Next Steps
1. Test the emergency feature with real user data
2. Gather feedback and make improvements as needed
3. Consider adding more personalized features based on user feedback
