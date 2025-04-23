# Enum Replacement Implementation Plan

## Overview
This document outlines the implementation plan for replacing enums with string constants in the Temptation Destroyer app.

## Current Status
We have successfully replaced the following enums with string constants:
- `AIServiceType` in `lib/data/models/ai_models.dart`
- `ChatSessionType` in `lib/data/models/chat_session_model.dart`

We have also updated the `ChatSession` model to use string properties instead of enum properties.

## Next Steps

### 1. Fix ObjectBox Model Issues
The ObjectBox model is still expecting `dbSessionType` and `dbServiceType` properties. We need to:
- Run `flutter pub run build_runner build` to regenerate the ObjectBox model

### 2. Update AI Repository
The `AIRepository` class needs to be updated to use string constants instead of enums:
- Update method parameters to accept strings instead of enums
- Update switch statements to work with strings
- Update method calls to pass strings instead of enums

### 3. Update Context Manager
The `ContextManager` class needs to be updated to use string constants instead of enums:
- Update the `_defaultTokenLimits` map to use strings as keys
- Update method parameters to accept strings instead of enums
- Update switch statements to work with strings

### 4. Update VAPI Service
The `VapiService` class needs to be updated to use string constants instead of enums:
- Update the `_publicKeyType` and `_privateKeyType` constants to use strings

### 5. Update AI Service Provider
The `AIServiceProvider` class needs to be updated to use string constants instead of enums:
- Update method parameters to accept strings instead of enums
- Update method calls to pass strings instead of enums

### 6. Update Chat Async Notifier
The `ChatAsyncNotifier` class needs to be updated to use string constants instead of enums:
- Update method parameters to accept strings instead of enums
- Update method calls to pass strings instead of enums

### 7. Update Chat Session Provider
The `ChatSessionProvider` class needs to be updated to use string constants instead of enums:
- Update method parameters to accept strings instead of enums
- Update method calls to pass strings instead of enums

### 8. Update AI Settings Screen
The `AISettingsScreen` class needs to be updated to use string constants instead of enums:
- Update method parameters to accept strings instead of enums
- Update method calls to pass strings instead of enums
- Update switch statements to work with strings

### 9. Update Chat Sessions Screen
The `ChatSessionsScreen` class needs to be updated to use string constants instead of enums:
- Update switch statements to work with strings

### 10. Update API Key Setup Screen
The `APIKeySetupScreen` class needs to be updated to use string constants instead of enums:
- Update the `_serviceTypeMap` and `_vapiPrivateKeyMap` maps to use strings as values
- Update method calls to pass strings instead of enums

### 11. Update Chat Session Drawer
The `ChatSessionDrawer` class needs to be updated to use string constants instead of enums:
- Update method parameters to accept strings instead of enums
- Update method calls to pass strings instead of enums
- Update switch statements to work with strings

### 12. Update New Chat Session Dialog
The `NewChatSessionDialog` class needs to be updated to use string constants instead of enums:
- Update method parameters to accept strings instead of enums
- Update method calls to pass strings instead of enums

## Testing
After each change, we will run `flutter analyze` to check for any remaining issues.
