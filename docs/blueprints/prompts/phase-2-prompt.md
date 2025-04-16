# Temptation Destroyer - Phase 2 Developer Guide

## Introduction

Hello Developer! You'll be implementing Phase 2 of the Temptation Destroyer app, a privacy-focused Flutter application designed to help users overcome sinful behaviors and build positive streaks. The app emphasizes local data storage, encryption, and AI-powered guidance while maintaining user privacy.

We've successfully completed Phase 1, which includes the foundation and core emergency features. Your task is to implement Phase 2, focusing on supportive features and alternative activities.

## Current Implementation (Phase 1)

### Project Structure
We've implemented a clean architecture approach with data, domain, and presentation layers. The state management is handled using Riverpod, and local data storage uses ObjectBox with encryption.

### Completed Features

#### 1. Authentication System
- Password-based authentication with encryption
- Password strength validation
- Password recovery using recovery codes
- Rate limiting for recovery attempts
- Security question setup (in progress)
- Login/logout functionality
- API key management for AI services

#### 2. Emergency Response System
- Emergency help button that appears throughout the app
- Emergency session tracking with start and end times
- Active session detection and continuation
- Emergency resolution screen with notes
- Timer tracking during emergency sessions

#### 3. Trigger Management
- CRUD operations for triggers
- Categorization by type (emotional, situational, time-based)
- Filtering and searching capabilities
- Multi-select functionality for batch operations
- Detailed view with rich formatting
- Form with dynamic elements for adding/editing triggers
- Time and day pattern selection
- Intensity tracking with visual indicators

### Architecture Details
- **Data Layer**: Contains models, repositories, and data sources
- **Domain Layer**: Contains use cases for business logic
- **Presentation Layer**: Contains providers, screens, and widgets
- **Core**: Contains utilities, constants, and services

### Key Components
- **EncryptionService**: Handles encryption/decryption of sensitive data
- **ObjectBoxManager**: Manages the ObjectBox database with encryption
- **AuthProvider**: Manages authentication state and operations
- **EmergencySessionProvider**: Manages emergency sessions
- **TriggerProvider**: Manages trigger data and operations
- **AIServiceProvider**: Basic setup for AI service configuration (partially implemented)

## Phase 2 Implementation Requirements

Based on the implementation plan and action plan, your tasks for Phase 2 are:

### 1. AI Guidance Feature (High Priority)

#### Data Layer
1. Create `AIRepository` with:
   - `generateResponse(context, userInput)`: Sends request to API and returns response
   - `cacheResponse(context, response)`: Caches response for offline use
   - `getFallbackResponses()`: Returns predefined responses for offline use
   - Support for multiple AI providers (OpenAI, Anthropic, OpenRouter)

2. Create models:
   - `AIResponseModel`: Stores AI responses with timestamp, context, etc.
   - `ChatMessageModel`: Represents a single message in a conversation
   - `ChatHistorySettings`: User preferences for chat history

#### Domain Layer
1. Create use cases:
   - `GenerateAIGuidanceUseCase`: Handles generating responses based on user situation
   - `HandleOfflineGuidanceUseCase`: Provides fallback responses when offline

#### Presentation Layer
1. Enhance the existing `AIServiceProvider`
2. Create UI components:
   - `AIGuidanceCard`: Displays AI guidance during emergency sessions
   - `ResponseFeedback`: Allows users to rate the helpfulness of responses
   - `OfflineGuidanceView`: Shows offline guidance content
   - `AIServiceSelectionScreen`: Allows users to select and configure AI services

#### Implementation Details
- Securely store API keys using the existing encryption service
- Implement proper error handling for API failures
- Create offline fallback mechanisms
- Ensure no data is sent to the API without user consent
- Add clear indicators when AI is being used
- Include Islamic guidance in the default responses

### 2. Hobby Management Feature

#### Data Layer
1. Create `HobbyModel`:
   ```dart
   class HobbyModel {
     int id;
     String name;
     HobbyCategory category; // Enum (Physical, Mental, Social, Spiritual)
     int minutesRequired;
     bool requiresCompany;
     DateTime lastEngaged;
   }
   ```

2. Implement `HobbyRepository`:
   - `addHobby(hobby)`: Adds a new hobby
   - `updateHobby(hobby)`: Updates an existing hobby
   - `getHobbies(filters)`: Gets hobbies with optional filters
   - `trackEngagement(hobby)`: Tracks when user engaged in a hobby

#### Domain Layer
1. Create use cases:
   - `ManageHobbiesUseCase`: Handles CRUD operations for hobbies
   - `SuggestHobbiesUseCase`: Suggests hobbies based on available time and preferences
   - `TrackHobbyEngagementUseCase`: Tracks engagement with hobbies

#### Presentation Layer
1. Create `HobbyProvider`
2. Build UI components:
   - `HobbyManagementScreen`: Main screen for managing hobbies
   - `CategoryBasedHobbyList`: List of hobbies organized by category
   - `HobbyEngagementTracker`: Tracks when user engaged in a hobby
   - `HobbyDetailScreen`: Shows details of a hobby
   - `HobbyFormScreen`: Form for adding/editing hobbies

#### Implementation Details
- Include preset hobby suggestions in different categories
- Allow customization of presets and adding new hobbies
- Implement time tracking for hobby engagement
- Add reminders to engage in hobbies during vulnerable times
- Include difficulty ratings for hobbies

### 3. Aspirations & Goals Feature

#### Data Layer
1. Create `AspirationModel`:
   ```dart
   class AspirationModel {
     int id;
     String dua;
     String category;
     bool isAchieved;
     DateTime createdAt;
   }
   ```

2. Implement `AspirationRepository`:
   - `addAspiration(aspiration)`: Adds a new aspiration
   - `updateAspiration(aspiration)`: Updates an existing aspiration
   - `getAspirations(filters)`: Gets aspirations with optional filters

#### Domain Layer
1. Create use cases:
   - `ManageAspirationsUseCase`: Handles CRUD operations for aspirations
   - `TrackProgressUseCase`: Tracks progress toward aspirations

#### Presentation Layer
1. Create `AspirationProvider`
2. Build UI components:
   - `AspirationEntryScreen`: Screen for entering aspirations
   - `CategorySelector`: Widget for selecting aspiration categories
   - `DuaInput`: Input field for duas
   - `GoalsList`: List of goals and aspirations

#### Implementation Details
- Include preset duas and aspirations in different categories
- Allow users to customize and add new aspirations
- Implement progress tracking for long-term goals
- Add reminder system for revisiting aspirations
- Include Islamic guidance on setting goals

## Development Guidelines

1. **Follow the existing architecture**:
   - Maintain the separation of concerns between layers
   - Use repositories for data access
   - Use use cases for business logic
   - Use providers for state management

2. **Adhere to code conventions**:
   - Follow the existing naming conventions
   - Use proper documentation
   - Use const constructors where appropriate
   - Apply proper error handling

3. **Security considerations**:
   - All sensitive data should be encrypted using the EncryptionService
   - API keys should be stored securely
   - User consent should be obtained before using AI services

4. **Testing**:
   - Write unit tests for repository and use case implementations
   - Test edge cases for offline scenarios
   - Test error handling

5. **Documentation**:
   - Update the development log with your progress
   - Document any architectural decisions

## Project Structure

Here is the current project structure to help you understand what's already in place:

### Library Structure
```
lib
├── core
│   ├── constants
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   └── utils
│       ├── encryption_service.dart
│       └── object_box_manager.dart
├── data
│   ├── models
│   │   ├── emergency_session_model.dart
│   │   ├── trigger_model.dart
│   │   └── user_model.dart
│   ├── repositories
│   │   ├── auth_repository.dart
│   │   ├── emergency_repository.dart
│   │   └── trigger_repository.dart
│   ├── services
│   └── sources
├── domain
│   └── usecases
│       ├── auth
│       │   ├── get_user_status_usecase.dart
│       │   ├── login_usecase.dart
│       │   ├── manage_api_key_usecase.dart
│       │   ├── recovery_codes_usecase.dart
│       │   └── set_password_usecase.dart
│       ├── emergency
│       │   ├── end_emergency_session_usecase.dart
│       │   ├── get_active_session_usecase.dart
│       │   ├── get_emergency_sessions_usecase.dart
│       │   └── start_emergency_session_usecase.dart
│       └── trigger
│           ├── add_trigger_usecase.dart
│           ├── delete_trigger_usecase.dart
│           ├── get_triggers_usecase.dart
│           └── update_trigger_usecase.dart
├── main.dart
├── objectbox.g.dart
├── objectbox-model.json
└── presentation
    ├── app.dart
    ├── pages
    ├── providers
    │   ├── ai_service_provider.dart
    │   ├── auth_provider.dart
    │   ├── emergency_session_provider.dart
    │   ├── emergency_timer_provider.dart
    │   └── trigger_provider.dart
    ├── screens
    │   ├── auth
    │   │   ├── api_key
    │   │   │   └── api_key_setup_screen.dart
    │   │   ├── login_screen.dart
    │   │   ├── password_recovery_screen.dart
    │   │   ├── password_setup_screen.dart
    │   │   └── recovery_codes_screen.dart
    │   ├── emergency
    │   │   ├── emergency_resolution_form.dart
    │   │   └── emergency_screen.dart
    │   ├── home
    │   │   └── home_screen.dart
    │   └── triggers
    │       ├── trigger_collection_screen.dart
    │       ├── trigger_detail_screen.dart
    │       └── trigger_form_screen.dart
    └── widgets
        ├── common
        │   └── loading_indicator.dart
        └── emergency
            └── floating_help_button.dart
```

### Documentation Structure
```
docs
├── blueprints
│   ├── action_plan.md
│   ├── phase-2-prompt.md
│   ├── design-system.html
│   ├── development-log.md
│   ├── implementation-plan.md
│   ├── plan.html
│   ├── plan.md
│   └── README.md
└── combined_objectbox_docs.txt
```

## Getting Started

1. Review the codebase to understand the existing implementation
2. Familiarize yourself with the AI service setup (the AIServiceProvider is already partially implemented)
3. Start with implementing the AIRepository as it's the most critical component of Phase 2
4. Then proceed with the HobbyRepository and AspirationRepository
5. Implement the UI components for each feature
6. Test everything thoroughly, especially the AI functionality

## Important Notes

1. The app follows a privacy-first approach, so all data should be stored locally
2. The encryption service uses the user's password to derive the encryption key
3. The ObjectBoxManager handles database encryption
4. The app currently supports auth, emergency response, and trigger management
5. The AIServiceProvider has basic setup but needs to be enhanced

I'm available if you have any questions during the implementation. Good luck with Phase 2!

---

# Temptation Destroyer App - Phase 2 Development Tasks

## Project Overview
You'll be working on Phase 2 of the Temptation Destroyer app, an addiction recovery application with Islamic principles. We've completed Phase 1 (core features) and part of Phase 2 (hobby management), and now need to implement the remaining Phase 2 features.

## Current Project State
- Project follows clean architecture (data/domain/presentation layers)
- Core features implemented (auth, emergency response, trigger management)
- Hobby management feature fully implemented with CRUD operations
- ObjectBox database with encryption set up and working
- Models properly handle ObjectBox integration, especially for enums

## Documentation Resources
- docs/blueprints/design-system.html - UI components and design specs
- docs/blueprints/action_plan.md - Detailed feature roadmap
- docs/blueprints/implementation-plan.md - Phased approach with priorities
- docs/blueprints/development-log.md - Progress log with technical details

## Project Structure
- Run `find lib -type d | sort` to see the directory structure
- Run `tree lib` for a more visual representation of the codebase structure
- Look at existing implementations (especially in lib/data/models, lib/data/repositories, lib/domain/usecases/hobby, and lib/presentation/screens/hobbies) for reference

## Your Tasks for Phase 2 Completion
You'll be working on two main features:

### 1. Aspirations & Goals Feature
Implement functionality for users to set and track Islamic aspirations and duas.

**Required Components:**
- Complete `AspirationModel` with proper ObjectBox integration
- Implement `AspirationRepository` with CRUD operations
- Create domain layer use cases:
  - ManageAspirationsUseCase
  - TrackProgressUseCase
- Build UI components:
  - AspirationEntryScreen
  - CategorySelector
  - DuaInput
  - GoalsList
- Integrate with the main app flow

### 2. AI Guidance Feature
Implement personalized AI assistance system with Islamic guidance.

**Required Components:**
- Complete `AIRepository` implementation
- Integrate with multiple AI providers (OpenAI, Anthropic, Open Router)
- Create chat interface with proper state management
- Add offline fallback mechanism
- Implement voice-to-text and text-to-speech functionality

## Technical Considerations
- Follow clean architecture patterns established in the codebase
- Use Riverpod for state management
- Handle ObjectBox entities properly, especially enum types
- Ensure proper error handling and loading states
- Follow UI design system in design-system.html
- Add unit tests for critical components

## Getting Started
1. Use the tree command to understand the project structure
2. Check the development log to see implementation details of completed features
3. Look at hobby management implementation as a reference
4. Start with the `AspirationModel` and work your way up through the layers

Please reach out if you have any questions. JazakAllah Khair!