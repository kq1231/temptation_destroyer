# Temptation Destroyer - Phased Implementation Plan

## Phase 1: Foundation & Core Emergency Features

### 1. Initial Project Setup
- Create Flutter project with clean architecture structure (data, domain, presentation)
- Set up core dependencies (flutter_riverpod, objectbox, shared_preferences, etc.)
- **Create custom encryption class** for ObjectBox data security
- Initialize Git repository

#### Custom Encryption Implementation
- Create `EncryptionService` class that will handle:
  - Encryption of data before storage in ObjectBox
  - Decryption of data when retrieved from ObjectBox
  - Using the user's password as the encryption key
  - Secure storage of temporary authentication token

### 2. Local Authentication
- **Models**: `UserModel` (hashedPassword, lastLoginDate, securityQuestions, customApiKey)
- **Repositories**: `AuthRepository` (savePassword, verifyPassword, updatePassword, saveApiKey, getApiKey)
- **Use Cases**: `AuthUseCase` (login, setInitialPassword, validatePassword, manageApiKey)
- **Providers**: `AuthProvider`
- **Views**: PasswordSetupScreen, LoginScreen, ForgotPasswordScreen, ApiKeySetupScreen

#### Security Implementation Details
- User's password will be used as the encryption/decryption key
- Implement clear warnings about password importance
- Store password securely with proper hashing and salting
- Ensure password is never stored in plaintext

### 3. Emergency Response (Loss Cycle Tracking)
- **Models**: `EmergencySessionModel` (id, startTime, endTime, activeTriggerIds, wasAIGuidanceShown, notes)
- **Repositories**: `EmergencyRepository` (saveSession, getActiveSession, updateSession, endSession)
- **Use Cases**: StartEmergencySessionUseCase, EndEmergencySessionUseCase, GetActiveSessionUseCase
- **Providers**: EmergencySessionProvider, EmergencyTimerProvider
- **Views**: FloatingHelpButton, QuickResponseDialog, EmergencyScreen, ResolutionForm

#### Loss Cycle Implementation Details
- Record start time when user initiates emergency session
- Check for active, unresolved emergency sessions at app startup
- Allow user to:
  - Confirm the loss cycle has ended
  - Specify approximate end time (if app wasn't opened immediately after)
  - Add notes about what helped
- Avoid background services - use simpler session tracking approach

### 4. Trigger Management
- **Models**: `TriggerModel` (id, description, type, intensity, createdAt)
- **Repositories**: `TriggerRepository` (addTrigger, updateTrigger, deleteTrigger, getTriggers)
- **Use Cases**: AddTriggerUseCase, UpdateTriggerUseCase, GetTriggersUseCase
- **Providers**: `TriggerProvider`
- **Views**: TriggerCollectionScreen, TimePatternSelector, EmotionalTriggerList, CustomTriggerInput

## Phase 2: Supportive Features & Alternative Activities

### 5. Hobby Management
- **Models**: `HobbyModel` (id, name, category, minutesRequired, requiresCompany, lastEngaged)
- **Repositories**: `HobbyRepository` (addHobby, updateHobby, getHobbies, trackEngagement)
- **Use Cases**: ManageHobbiesUseCase, SuggestHobbiesUseCase, TrackHobbyEngagementUseCase
- **Providers**: `HobbyProvider`
- **Views**: HobbyManagementScreen, CategoryBasedHobbyList, HobbyEngagementTracker

### 6. Aspirations & Goals
- **Models**: `AspirationModel` (id, dua, category, isAchieved, createdAt)
- **Repositories**: `AspirationRepository` (addAspiration, updateAspiration, getAspirations)
- **Use Cases**: ManageAspirationsUseCase, TrackProgressUseCase
- **Providers**: `AspirationProvider`
- **Views**: AspirationEntryScreen, CategorySelector, DuaInput, GoalsList

### 7. Basic AI Guidance
- **Models**: `AIResponseModel`, `ChatMessageModel`, `ChatHistorySettings`, `AIServiceConfig`
- **Repositories**: `AIRepository` (generateResponse, cacheResponse, getFallbackResponses)
- **Use Cases**: GenerateAIGuidanceUseCase, HandleOfflineGuidanceUseCase
- **Providers**: `AIGuidanceProvider`
- **Views**: AIGuidanceCard, ResponseFeedback, OfflineGuidanceView, AIServiceSelectionScreen

#### AI Service Integration Details
- Support for multiple AI providers:
  - OpenAI API (ChatGPT, GPT-4)
  - Anthropic API (Claude models)
  - Open Router (unified interface for multiple LLMs)
- Allow users to select their preferred provider
- Configure different model parameters for each provider
- Implement fallback options for offline or error scenarios
- Properly handle API quotas and rate limits for each service
- Securely store API keys with encryption

## Phase 3: Progress Tracking & Motivation

### 8. Statistics & Progress
- **Models**: `StatisticsModel` (id, intensityByDay, currentStreak, bestStreak, slipDates)
- **Repositories**: `StatisticsRepository` (updateStats, getStats, calculateStreak)
- **Use Cases**: TrackProgressUseCase, GenerateInsightsUseCase, CalculateStreakUseCase
- **Providers**: `StatisticsProvider`
- **Views**: DashboardStats, ProgressCharts, InsightsView, WeeklyProgressView, StreakCalendar

### 9. Daily Challenges & Reminders
- **Models**: `ChallengeModel`, `DailyHadithModel`
- **Repositories**: `ChallengeRepository`, `HadithRepository`
- **Use Cases**: GenerateDailyChallengeUseCase, GetDailyHadithUseCase, TrackChallengeCompletionUseCase
- **Providers**: `DailyChallengeProvider`
- **Views**: DailyHadithCard, ChallengeOfTheDayWidget, ChallengeTypeSelector, ChallengeHistoryScreen

## Phase 4: Advanced Features

### 10. Educational Resources
- **Models**: `ResourceModel`
- **Repositories**: `ResourceRepository`
- **Use Cases**: GetResourcesUseCase, ManageFavoritesUseCase, AddCustomResourceUseCase
- **Providers**: `ResourceProvider`
- **Views**: ResourceLibraryScreen, ArticleViewer, VideoPlayerWidget, ResourceDetailScreen

### 11. Voice Transcription & Input
- **Models**: `VoiceTranscriptionConfig`, `VoiceInputSession`
- **Repositories**: `VoiceRepository`
- **Use Cases**: ConfigureVoiceTranscriptionUseCase, GetTranscriptionUseCase
- **Providers**: `VoiceInputProvider`
- **Views**: VoiceInputButton, TranscriptionConfirmationDialog, VoiceRecordingIndicator

### 12. Achievements & Gamification
- **Models**: `Achievement`, `UserLevel`, `UserAchievements`
- **Repositories**: `AchievementRepository`
- **Services**: `AchievementService`
- **Views**: AchievementsOverviewScreen, AchievementDetailScreen, UserLevelScreen

## Today's Implementation Focus

1. **Project Setup**
   - Create Flutter project
   - Set up folder structure (data, domain, presentation)
   - Configure core dependencies
   - Create custom encryption service

2. **Core Data Models & Storage**
   - `UserModel`
   - `EmergencySessionModel` (with loss cycle tracking)
   - `TriggerModel`
   - ObjectBox setup with custom encryption

3. **Emergency Response Flow**
   - Implement emergency button
   - Create session tracking logic
   - Build session resolution UI with time adjustment option 