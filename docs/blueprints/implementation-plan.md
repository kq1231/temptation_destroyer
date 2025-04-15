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
- **Repositories**: `AuthRepository` (savePassword, verifyPassword, updatePassword, saveApiKey, getApiKey, saveSecurityQuestions, verifySecurityAnswers)
- **Use Cases**: `AuthUseCase` (login, setInitialPassword, validatePassword, manageApiKey, setupSecurityQuestions, verifySecurityAnswers)
- **Providers**: `AuthProvider`
- **Views**: PasswordSetupScreen, LoginScreen, ForgotPasswordScreen, ApiKeySetupScreen, SecurityQuestionsSetupScreen

#### Security Implementation Details
- User's password will be used as the encryption/decryption key
- Implement clear warnings about password importance
- Store password securely with proper hashing and salting
- Ensure password is never stored in plaintext

#### Password Recovery System Implementation
- **Security Questions Approach**:
  - Create a model for storing security questions and encrypted answers
  - Implement a separate encryption key for answers, derived from the answers themselves
  - During setup, collect 3-5 personal questions and answers from the user
  - Design a recovery flow that verifies multiple answers before allowing password reset
  - Clearly warn users that data encrypted with the old password will be inaccessible
- **Recovery Codes Approach**:
  - Generate a set of recovery codes during initial password setup
  - Use cryptographically secure random generator for codes
  - Strongly encourage users to write these down and store them safely
  - Implement a recovery flow using these codes as an alternative to security questions
  - Provide clear instructions for using recovery codes

#### Advanced Encryption & Recovery Solutions (Phase 2)
- **Current Limitation**: When a user forgets their password and resets it with a recovery code, all previously encrypted data becomes inaccessible because:
  1. The encryption key is derived directly from the user's password
  2. When the password changes, the new key cannot decrypt data encrypted with the old key
  3. Recovery codes only verify identity but don't help with decryption

- **Potential Solutions to Implement in Phase 2**:
  1. **Master Key Approach**:
     - Generate a random master key to encrypt all sensitive data
     - Encrypt this master key with the user's password (instead of using password directly)
     - When password changes, decrypt master key with recovery mechanism and re-encrypt with new password
     - Data remains accessible since the actual encryption key (master key) doesn't change

  2. **Envelope Encryption**:
     - Generate a random data key for encrypting sensitive data
     - Create "envelopes" that contain this data key encrypted with different access methods:
       - Primary envelope: encrypted with user's password
       - Recovery envelope: encrypted with a key derived from recovery answers or codes
     - When password changes, use recovery envelope to access data key, then create new password envelope

  3. **Accept Data Loss with Clear Warnings (Current MVP Approach)**:
     - Explicitly inform users about the encryption limitation
     - Provide clear warnings during password setup and recovery
     - Suggest regular exports of critical data
     - Recommend keeping password in secure password manager

  4. **Two-Factor Derived Key**:
     - Derive encryption key from combination of password and recovery factor
     - Require both factors for normal operation but allow recovery with just recovery factor
     - Provides compromise between security and recoverability

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