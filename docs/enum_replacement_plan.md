# Enum Replacement Plan

## Overview
This document outlines the plan to replace redundant enums in AI models and ObjectBox entities with strings. This change will improve flexibility and reduce bugs associated with enum usage in ObjectBox.

## Identified Enums to Replace

### 1. AI Models
- `AIServiceType` in `lib/data/models/ai_models.dart`
  - Used in `ChatSession` model

### 2. Chat Session Models
- `ChatSessionType` in `lib/data/models/chat_session_model.dart`

### 3. Achievement Models
- `AchievementType` in `lib/data/models/achievement_model.dart`
- `AchievementRarity` in `lib/data/models/achievement_model.dart`

### 4. Aspiration Models
- `AspirationCategory` in `lib/data/models/aspiration_model.dart`

### 5. Challenge Models
- `ChallengeCategory` in `lib/data/models/challenge_model.dart`
- `ChallengeDifficulty` in `lib/data/models/challenge_model.dart`
- `ChallengeStatus` in `lib/data/models/challenge_model.dart`

### 6. Hobby Models
- `HobbyCategory` in `lib/data/models/hobby_model.dart`

### 7. Islamic Content Models
- `ContentType` in `lib/data/models/islamic_content_model.dart`
- `ContentCategory` in `lib/data/models/islamic_content_model.dart`

### 8. Trigger Models
- `TriggerType` in `lib/data/models/trigger_model.dart`

## Implementation Approach

For each enum, we will:

1. Replace the enum with a class containing static string constants
2. Update the model class to use string properties instead of enum properties
3. Update the getters and setters to work with strings
4. Update any references to the enum in the codebase

## Example Implementation

Before:
```dart
enum AIServiceType {
  offline,
  openAI,
  anthropic,
  openRouter,
  vapiPublic,
  vapiPrivate,
}

class SomeModel {
  @Transient()
  AIServiceType? _serviceType;
  
  int? get dbServiceType => _serviceType?.index;
  
  set dbServiceType(int? value) {
    if (value == null) {
      _serviceType = null;
    } else {
      _serviceType = AIServiceType.values[value];
    }
  }
}
```

After:
```dart
class AIServiceType {
  static const String offline = 'offline';
  static const String openAI = 'openAI';
  static const String anthropic = 'anthropic';
  static const String openRouter = 'openRouter';
  static const String vapiPublic = 'vapiPublic';
  static const String vapiPrivate = 'vapiPrivate';
  
  static const List<String> values = [
    offline,
    openAI,
    anthropic,
    openRouter,
    vapiPublic,
    vapiPrivate
  ];
}

class SomeModel {
  @Property()
  String? serviceType;
  
  // No need for dbServiceType anymore
}
```

## Testing Strategy

1. Run Flutter analyze after each change to identify any issues
2. Update and run unit tests to ensure functionality is preserved
3. Manually test the app to verify the changes work as expected

## Implementation Order

1. Start with `AIServiceType` and `ChatSessionType` as they appear to be most critical
2. Move on to other model enums
3. Run Flutter analyze after each change to catch any issues early
