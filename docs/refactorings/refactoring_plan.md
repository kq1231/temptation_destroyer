# Refactoring Plan: Converting StateNotifier to AsyncNotifier/Notifier

## Overview
This plan outlines the conversion of StateNotifier providers to AsyncNotifier or Notifier providers using Riverpod Generator. The goal is to simplify state management by:

1. Converting StateNotifier providers to AsyncNotifier providers where appropriate
2. Moving initialization logic from separate methods to the build method
3. Removing Future.microtask calls from screens
4. Using ref.invalidate() for refreshing providers instead of explicit initialization

## Providers to Refactor

### 1. TriggerProvider
- Currently uses StateNotifier
- Had loadTriggers method called in initState with Future.microtask
- Converted to AsyncNotifier with build method for initialization
- Status: ✅ Completed

### 2. AuthProvider
- Currently used StateNotifier
- Had an initialize method called in initState with Future.microtask in SplashScreen
- Converted to AsyncNotifier with build method for initialization
- Status: ✅ Completed

### 3. EmergencySessionProvider
- Currently used StateNotifier
- Had an initialize method
- Converted to AsyncNotifier with build method for initialization
- Status: ✅ Completed

### 4. AspirationProvider
- Currently used StateNotifier
- Had loadAspirations method called in initState with Future.microtask
- Converted to AsyncNotifier with build method for initialization
- Status: ✅ Completed

### 5. HobbyProvider
- Currently used StateNotifier
- Had loadHobbies method called in initState with Future.microtask
- Converted to AsyncNotifier with build method for initialization
- Status: ✅ Completed

## Implementation Steps for Each Provider

1. Create a new file with the @riverpod annotation
2. Convert the StateNotifier class to extend _$ProviderName
3. Move initialization logic to the build method
4. Update screens to remove Future.microtask calls
5. Test the refactored code

## Progress Tracking

- [✅] TriggerProvider
- [✅] AuthProvider
- [✅] EmergencySessionProvider
- [✅] AspirationProvider
- [✅] HobbyProvider
