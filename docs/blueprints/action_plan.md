# Temptation Destroyer - Action Plan

## Initial Project Setup (2 Days)
1. [] Create Flutter project
2. [] Set up folder structure (data, domain, presentation layers)
3. [] Add core dependencies:
   ```yaml
   dependencies:
     flutter_riverpod: ^2.4.9
     objectbox: ^2.5.0
     shared_preferences: ^2.2.2
     encrypt: ^5.0.3
     uuid: ^4.3.3
     flutter_tts: ^3.8.5
     url_launcher: ^6.2.2
     flutter_secure_storage: ^9.0.0
     intl: ^0.18.1
     speech_to_text: ^6.4.1
     whisper_dart: ^0.1.1 # For offline speech recognition
     flutter_sound: ^9.3.8 # For recording audio
     http: ^1.1.0 # For HTTP requests to AssemblyAI
     web_socket_channel: ^2.4.0 # For WebSocket connections to AssemblyAI
   ```
4. [] Set up ObjectBox with encryption
5. [] Initialize Git repository

## Feature 1: Local Authentication (3 Days)
The user should be able to set up and use a password to protect their data.

### Data Layer
1. [] Create `UserModel` in ObjectBox:
   - [] hashedPassword
   - [] lastLoginDate
   - [] securityQuestions
   - [] customApiKey
2. [] Implement `AuthRepository`:
   - [] savePassword()
   - [] verifyPassword()
   - [] updatePassword()
   - [] saveApiKey()
   - [] getApiKey()
   - [] saveSecurityQuestions()
   - [] verifySecurityAnswers()

### Domain Layer
1. [] Create `AuthUseCase`:
   - [] login()
   - [] setInitialPassword()
   - [] validatePassword()
   - [] manageApiKey()
   - [] setupSecurityQuestions()
   - [] verifySecurityAnswers()

### Presentation Layer
1. [] Create `AuthProvider` using Riverpod
2. [] Build UI Components:
   - [] PasswordSetupScreen
   - [] LoginScreen
   - [] ForgotPasswordScreen
   - [] ApiKeySetupScreen
   - [] SecurityQuestionsSetupScreen

### Authentication Security Notices
1. [] Implement clear security warnings:
   - [] Add prominent warning during password creation that if password is forgotten, data cannot be recovered
   - [] Include confirmation dialog requiring users to type "I understand" before proceeding
   - [] Offer option to write down password in a safe place
   - [] Explain encryption simply: "Your data is locked with this password and cannot be unlocked without it"
   - [] Provide guidance on creating a memorable but secure password

### Password Recovery System
1. [] Implement security questions-based recovery:
   - [] Allow users to set up personal security questions during initial password setup
   - [] Store answers securely (encrypted with a key derived from the answers themselves)
   - [] Create a recovery flow that asks these questions
   - [] If answers are correct, show password hint or allow password reset
   - [] Clearly communicate that a password reset will make previously encrypted data inaccessible
2. [] Create backup recovery code system:
   - [] Generate recovery codes during initial setup
   - [] Encourage users to store these codes safely offline
   - [] Allow use of recovery codes as alternative to security questions

### Password Reset and Encryption Challenges
1. [] Address the issue of data loss during password reset:
   - [] Document the encryption challenge: data encrypted with old password can't be accessed with new password
   - [] Implement a robust user warning system explaining this limitation
   - [] Add clear documentation in recovery screens about data accessibility
   - [] Consider one of these advanced solutions for Phase 2:
     - [] Master Key Approach: Store a master encryption key that's encrypted with user password
     - [] Envelope Encryption: Encrypt data with random key, then encrypt that key with password
     - [] Key Recovery System: Store recovery keys in secure locations that survive password changes
   - [] For MVP (Phase 1): Accept data loss on password reset with clear warnings

### User Experience Considerations
1. [] Add appropriate humor and encouraging tone throughout the app:
   - [] Include light-hearted messages in loading screens
   - [] Use gentle humor in success messages for completed tasks
   - [] Add supportive messages that acknowledge the difficulty of the journey
   - [] Balance seriousness of addiction recovery with optimistic, hopeful messaging
   - [] Design encouragement messages that don't feel patronizing
   - [] Incorporate occasional appropriate Islamic humor where suitable
   - [] Create uplifting animations for achievements and milestones
   - [] Use friendly, conversational language rather than clinical terms

## Feature 2: Emergency Response (5 Days)
The user should be able to get immediate help when facing temptation.

### Data Layer
1. [] Create Models:
   ```dart
   class EmergencySessionModel {
     String id
     DateTime startTime
     List<String> activeTriggerIds
     bool wasAIGuidanceShown
     String? notes
   }
   ```
2. [] Implement `EmergencyRepository`:
   - [] saveSession()
   - [] getActiveSession()
   - [] updateSession()
   - [] endSession()

### Domain Layer
1. [] Create Use Cases:
   - [] StartEmergencySessionUseCase
   - [] EndEmergencySessionUseCase
   - [] GetActiveSessionUseCase

### Presentation Layer
1. [] Create Providers:
   - [] EmergencySessionProvider
   - [] EmergencyTimerProvider
2. [] Build UI Components:
   - [] FloatingHelpButton
   - [] QuickResponseDialog
   - [] EmergencyScreen with timer
   - [] ResolutionForm
   - [] VoiceAssistantWidget

## Feature 3: Trigger Management (4 Days)
The user should be able to identify and manage their triggers.

### Data Layer
1. [] Create Models:
   ```dart
   class TriggerModel {
     int id
     String description
     TriggerType type
     int intensity
     DateTime createdAt
   }
   ```
2. [] Implement `TriggerRepository`:
   - [] addTrigger()
   - [] updateTrigger()
   - [] deleteTrigger()
   - [] getTriggers()

### Domain Layer
1. [] Create Use Cases:
   - [] AddTriggerUseCase
   - [] UpdateTriggerUseCase
   - [] GetTriggersUseCase

### Presentation Layer
1. [] Create `TriggerProvider`
2. [] Build UI Components:
   - [] TriggerCollectionScreen
   - [] TimePatternSelector
   - [] EmotionalTriggerList
   - [] CustomTriggerInput

## Feature 4: Aspirations & Goals (4 Days)
The user should be able to set and track their aspirations.

### Data Layer
1. [] Create Models:
   ```dart
   class AspirationModel {
     int id
     String dua
     String category
     bool isAchieved
     DateTime createdAt
   }
   ```
2. [] Implement `AspirationRepository`:
   - [] addAspiration()
   - [] updateAspiration()
   - [] getAspirations()

### Domain Layer
1. [] Create Use Cases:
   - [] ManageAspirationsUseCase
   - [] TrackProgressUseCase

### Presentation Layer
1. [] Create `AspirationProvider`
2. [] Build UI Components:
   - [] AspirationEntryScreen
   - [] CategorySelector
   - [] DuaInput
   - [] GoalsList

## Feature 5: Hobby Management (4 Days)
The user should be able to manage alternative activities.

### Data Layer
1. [] Create Models:
   ```dart
   class HobbyModel {
     int id
     String name
     HobbyCategory category
     int minutesRequired
     bool requiresCompany
     DateTime lastEngaged
   }
   ```
2. [] Implement `HobbyRepository`:
   - [] addHobby()
   - [] updateHobby()
   - [] getHobbies()
   - [] trackEngagement()

### Domain Layer
1. [] Create Use Cases:
   - [] ManageHobbiesUseCase
   - [] SuggestHobbiesUseCase
   - [] TrackHobbyEngagementUseCase

### Presentation Layer
1. [] Create `HobbyProvider`
2. [] Build UI Components:
   - [] HobbyManagementScreen
   - [] CategoryBasedHobbyList
   - [] HobbyEngagementTracker

## Feature 6: AI Guidance (5 Days)
The user should receive personalized AI guidance.

### Data Layer
1. [] Create Models:
   ```dart
   class AIResponseModel {
     String id
     String context
     String response
     DateTime timestamp
     bool wasHelpful
   }
   
   class ChatMessageModel {
     String id
     String content
     bool isUserMessage
     DateTime timestamp
     bool isEncrypted
   }
   
   class ChatHistorySettings {
     bool storeChatHistory
     int autoDeleteAfterDays
     DateTime lastCleared
   }
   
   class AIServiceConfig {
     AIServiceType serviceType
     String? apiKey
     String? preferredModel
     bool allowDataTraining
   }
   
   enum AIServiceType {
     openAI,
     anthropic,
     openRouter,
     offline
   }
   ```
2. [] Implement `AIRepository`:
   - [] generateResponse()
   - [] cacheResponse()
   - [] getFallbackResponses()
   - [] configureApiService()
   - [] saveApiKey()
   - [] getAvailableModels()
   - [] textToSpeech()
   - [] speechToText()
   - [] storeChatMessage()
   - [] getChatHistory()
   - [] clearChatHistory()
   - [] updateChatSettings()

### Domain Layer
1. [] Create Use Cases:
   - [] GenerateAIGuidanceUseCase
   - [] BuildContextUseCase
   - [] HandleOfflineGuidanceUseCase
   - [] VoiceInteractionUseCase
   - [] ManageChatHistoryUseCase
   - [] ConfigureAIServiceUseCase
   - [] SelectAIProviderUseCase

### Presentation Layer
1. [] Create `AIGuidanceProvider`
2. [] Build UI Components:
   - [] AIGuidanceCard
   - [] ResponseFeedback
   - [] OfflineGuidanceView
   - [] VoiceAssistantInterface
   - [] ChatHistoryScreen
   - [] ChatSettingsScreen
   - [] AIServiceSelectionScreen with provider options (OpenAI, Anthropic, Open Router)
   - [] APIKeyInputForm with validation

### Chat Storage Strategy
1. [] Implement secure chat storage:
   - [] Store chats locally only (no remote storage)
   - [] Make chat history optional (disabled by default)
   - [] Encrypt all stored messages using the same encryption as other app data
   - [] Add settings to control chat retention period (7, 30, 90 days options)
   - [] Create clear history button with confirmation dialog
   - [] Implement automatic history deletion based on settings
   - [] Add privacy notice explaining chat storage approach
   - [] Implement history browsing with date filtering
   - [] Add message-level deletion for individual messages

### AI Service Integration
1. [] Implement user-friendly AI service options:
   - [] Add support for three AI services:
     - [] OpenAI API integration (GPT models)
     - [] Anthropic API integration (Claude models)
     - [] OpenRouter API integration (unified access to multiple models)
   - [] Add clear explanations about how each AI service works
   - [] Inform users that communications are encrypted via HTTPS
   - [] Provide information about each service's data usage policies
   - [] Include guidance on how to opt out of data training for each service
   - [] Implement API key management for each service
   - [] Create model selection options for each service
   - [] Implement offline mode with pre-built responses
   - [] Add minimal context building to protect privacy
   - [] Allow users to easily switch between services

### Multi-Provider Support
1. [] Implement service integrations:
   - [] OpenAI API client
   - [] Anthropic API client
   - [] Open Router API client
2. [] Create provider-specific configurations:
   - [] Model selection options for each provider
   - [] Default parameters for different models
   - [] Cost estimation information
3. [] Build fallback mechanism for offline or quota exceeded scenarios

## Feature 7: Statistics & Progress (4 Days)
The user should be able to track their progress.

### Data Layer
1. [] Create Models:
   ```dart
   class StatisticsModel {
     int id
     Map<DateTime, int> intensityByDay
     int currentStreak
     int bestStreak
     List<DateTime> slipDates
   }
   ```
2. [] Implement `StatisticsRepository`:
   - [] updateStats()
   - [] getStats()
   - [] calculateStreak()

### Domain Layer
1. [] Create Use Cases:
   - [] TrackProgressUseCase
   - [] GenerateInsightsUseCase
   - [] CalculateStreakUseCase

### Presentation Layer
1. [] Create `StatisticsProvider`
2. [] Build UI Components:
   - [] DashboardStats
   - [] ProgressCharts
   - [] InsightsView
   - [] WeeklyProgressView
   - [] StreakCalendar

## Feature 8: Daily Challenges & Reminders (4 Days)
The user should receive daily challenges and reminders to stay motivated.

### Data Layer
1. [] Create Models:
   ```dart
   class ChallengeModel {
     int id
     String title
     String description
     ChallengeCategory category
     bool isCompleted
     DateTime assignedDate
     DateTime? completedDate
     int difficultyLevel
     List<String> tags
     int rewardPoints
   }
   
   class DailyHadithModel {
     int id
     String text
     String source
     String narratedBy
     DateTime date
     bool isFavorite
     String category
   }
   
   enum ChallengeCategory {
     digitalDetox,    // Reducing screen time, social media breaks
     fajrChampion,    // Morning prayer and early rising
     knowledgeSeeker, // Learning about religion, addiction science
     physicalStrength, // Exercise and physical health
     general          // Other challenges
   }
   ```
2. [] Implement `ChallengeRepository`:
   - [] getChallenge()
   - [] getChallengesByCategory()
   - [] getAssignedChallenges()
   - [] saveAssignedChallenge()
   - [] updateChallenge()
   - [] markCompleted()
   - [] getCompletionStats()
   - [] getActiveChallenges()

3. [] Implement `HadithRepository`:
   - [] getDailyHadith()
   - [] getHadithForDate()
   - [] getRandomHadith()
   - [] saveDailyHadith()
   - [] toggleFavorite()
   - [] getFavoriteHadiths()

### Domain Layer
1. [] Create Use Cases:
   - [] GenerateDailyChallengeUseCase
   - [] GetDailyChallengeUseCase
   - [] TrackChallengeCompletionUseCase
   - [] GetDailyHadithUseCase
   - [] ManageFavoriteHadithsUseCase
   - [] GetChallengeStatisticsUseCase
   - [] AwardBonusStreakDayUseCase

### Presentation Layer
1. [] Create `DailyChallengeProvider`
   - [] dailyChallenge state
   - [] challengeHistory state
   - [] completionRates state
   - [] dailyHadith state
   - [] favoriteHadiths state

2. [] Build UI Components:
   - [] DailyHadithCard
   - [] ChallengeOfTheDayWidget
   - [] ChallengeTypeSelector (Digital Detox, Fajr Champion, Knowledge Seeker, Physical Strength)
   - [] ChallengeHistoryScreen
   - [] ChallengeCompletionDialog
   - [] CategoryBasedChallengeList
   - [] ChallengeSettingsScreen

### Challenge Integration
1. [] Integrate challenges with other app features:
   - [] Link with streak system (challenge difficulty based on streak)
   - [] Connect with statistics (track completion rates)
   - [] Award bonus streak days for difficult challenges
   - [] Store challenge completion in user statistics
   - [] Generate personalized challenges based on user triggers
   - [] Display appropriate challenges during vulnerable times
   - [] Include challenge progress in daily notifications

### Hadith Management
1. [] Implement Hadith content and management:
   - [] Create initial hadith database
   - [] Develop algorithm for daily hadith selection
   - [] Ensure no repetition within 30 days
   - [] Create favorite hadith storage
   - [] Add sharing functionality
   - [] Include hadith categories relevant to addiction recovery
   - [] Create audio playback for hadiths
   - [] Add copy to clipboard functionality

## Feature 9: Educational Resources (3 Days)
The user should have access to educational content about addiction.

### Data Layer
1. [] Create Models:
   ```dart
   class ResourceModel {
     int id
     String title
     String description
     ResourceType type
     String url
     bool isFavorite
     List<String> tags
     DateTime addedDate
   }
   
   enum ResourceType {
     article,
     video,
     audio,
     pdf,
     custom
   }
   ```
2. [] Implement `ResourceRepository`:
   - [] getResources()
   - [] getResourcesByCategory()
   - [] toggleFavorite()
   - [] addCustomResource()
   - [] getFavoriteResources()
   - [] saveResource()
   - [] searchResources()

### Domain Layer
1. [] Create Use Cases:
   - [] GetResourcesUseCase
   - [] ManageFavoritesUseCase
   - [] AddCustomResourceUseCase
   - [] OpenResourceUseCase
   - [] SearchResourcesUseCase

### Presentation Layer
1. [] Create `ResourceProvider`
   - [] resources state
   - [] favoriteResources state
   - [] selectedCategory state

2. [] Build UI Components:
   - [] ResourceLibraryScreen
   - [] ArticleViewer
   - [] VideoPlayerWidget
   - [] ResourceCategoryTabs (Science of Addiction, Islamic Perspective, Success Stories)
   - [] ResourceDetailScreen
   - [] AddCustomResourceForm
   - [] ResourceSearchWidget

### Resource Integration
1. [] Implement educational content features:
   - [] YouTube video integration
   - [] In-app article reader
   - [] Downloadable content for offline access
   - [] Resource sharing functionality
   - [] Progressive content recommendation
   - [] Content filtering based on user preferences
   - [] Save reading/watching progress
   - [] Create resource bookmarking system

## Feature 10: Voice Transcription & Input (4 Days)
The user should be able to use voice input throughout the app to reduce friction and increase ease of use.

### Data Layer
1. [] Create Models:
   ```dart
   class VoiceTranscriptionConfig {
     TranscriptionProvider provider
     String? apiKey
     TranscriptionModel model
     bool isActiveGlobally
     Map<String, bool> featureSpecificSettings
     int maxRecordingSeconds
     bool autoSubmitAfterTranscription
     bool showConfirmationBeforeSubmit
   }
   
   enum TranscriptionProvider {
     openAI,     // Using OpenAI Whisper/GPT-4o models
     assemblyAI, // Using Assembly AI
     localWhisper, // Using local on-device Whisper model
     systemSpeechRecognition // Using built-in speech recognition
   }
   
   enum TranscriptionModel {
     // OpenAI models
     whisper,
     gpt4oMiniTranscribe,  // GPT-4o-mini-transcribe
     gpt4oTranscribe,      // GPT-4o-transcribe
     
     // AssemblyAI models
     assemblyBest,         // Best quality
     assemblyNano,         // Fastest, lightweight
     
     // Local models
     localTiny,
     localBase,
     
     // System
     systemDefault
   }
   
   class VoiceInputSession {
     String id
     DateTime timestamp
     String rawAudioPath
     String transcribedText
     TranscriptionProvider provider
     TranscriptionModel model
     double confidenceScore
     String targetFeature
     bool wasEdited
     String? editedText
   }
   ```

2. [] Implement `VoiceRepository`:
   - [] configureTranscriptionService()
   - [] startRecording()
   - [] stopRecording()
   - [] getTranscription()
   - [] saveTranscriptionResult()
   - [] getRecentTranscriptions()
   - [] deleteRecording()
   - [] updateTranscriptionSettings()
   - [] selectTranscriptionModel()
   - [] getAvailableModels()

### Domain Layer
1. [] Create Use Cases:
   - [] ConfigureVoiceTranscriptionUseCase
   - [] StartVoiceRecordingUseCase
   - [] GetTranscriptionUseCase
   - [] ExtractEntitiesFromTranscriptionUseCase
   - [] ProcessVoiceCommandUseCase
   - [] SelectTranscriptionModelUseCase
   - [] GetModelPerformanceStatsUseCase

### Presentation Layer
1. [] Create `VoiceInputProvider`
   - [] recordingState
   - [] transcriptionResult
   - [] processingState
   - [] confidenceLevel
   - [] micPermission
   - [] selectedModel

2. [] Build UI Components:
   - [] VoiceInputButton (universal component for all screens)
   - [] TranscriptionConfirmationDialog
   - [] VoiceRecordingIndicator
   - [] TranscriptionSettingsScreen
   - [] MicPermissionHandler
   - [] VoiceCommandHelpScreen
   - [] ModelSelectionDropdown

### Feature Integration
1. [] Integrate voice input across app features:
   - [] Onboarding
     - [] Voice input for triggers ("What triggers your temptations?")
     - [] Voice input for hobbies ("What activities do you enjoy?")
     - [] Voice input for aspirations ("What are your goals?")
   
   - [] Emergency Response
     - [] Voice activation of emergency help ("I need help now")
     - [] Voice notes during emergency sessions
     - [] Voice commands for selecting activities
   
   - [] Journal Entries
     - [] Voice dictation for journal content
     - [] Voice commands for setting intensity levels
     - [] Voice input for resolution notes
   
   - [] Chat Interface
     - [] Full voice conversation support
     - [] Real-time transcription during chat
     - [] Voice response playback option
   
   - [] Hobby Management
     - [] Voice input for adding new hobbies
     - [] Voice commands for hobby details (time required, etc.)
     - [] Voice search for hobbies
   
   - [] Trigger Management
     - [] Voice description of triggers
     - [] Voice commands for categorizing triggers
     - [] Voice input for trigger intensity

2. [] Implement AI-powered entity extraction:
   - [] Extract hobby names from voice transcriptions
   - [] Identify trigger descriptions in spoken content
   - [] Recognize time periods mentioned in voice input
   - [] Detect aspiration goals in voice recordings
   - [] Parse intensity levels from spoken descriptions
   - [] Recognize Islamic phrases and duas

3. [] Add accessibility features:
   - [] Voice feedback for visually impaired users
   - [] Simplified voice commands for users with limited mobility
   - [] Support for multiple languages in voice recognition
   - [] Voice-based navigation through app screens
   - [] Voice confirmation of actions taken

### Transcription Service Integration
1. [] Implement service providers:
   - [] OpenAI API integration
     - [] Whisper API integration
     - [] GPT-4o-mini-transcribe integration (nearly real-time)
     - [] GPT-4o-transcribe integration (highest quality)
     - [] Support multiple languages
     - [] Handle streaming for near real-time transcription
     - [] Implement fallback mechanisms
   
   - [] Assembly AI integration
     - [] Implement custom HTTP client for Assembly AI API
     - [] Create WebSocket connection handler for real-time streaming
     - [] Implement HTTP endpoints for non-streaming transcription
     - [] Add request/response serialization and error handling
     - [] Support "best" model for highest accuracy
     - [] Support "nano" model for faster performance
     - [] Handle streaming transcription with WebSockets
     - [] Process results and confidence scores
     - [] Implement language detection
     - [] Add proper authentication headers
     - [] Implement retry logic for failed API calls
     - [] Create audio chunking for optimal streaming performance
   
   - [] Local Whisper model (for offline use)
     - [] Integrate whisper_dart package
     - [] Implement lightweight model for offline transcription
     - [] Handle model loading and management
   
   - [] System speech recognition fallback
     - [] Integrate with speech_to_text package
     - [] Handle platform-specific implementations
     - [] Manage permissions and errors

2. [] Implement audio recording service:
   - [] Handle microphone permissions
   - [] Implement recording with visual feedback
   - [] Support cancellation during recording
   - [] Manage temporary file storage
   - [] Implement audio compression for API uploads
   - [] Add background noise reduction
   - [] Handle recording time limits
   - [] Implement auto-stop on silence detection

### Model Selection Logic
1. [] Implement smart model selection:
   - [] Auto-select based on internet connectivity
   - [] Choose model based on speech duration
   - [] Consider language requirements
   - [] Adapt to user preferences
   - [] Balance accuracy vs. speed needs
   - [] Track model performance metrics
   - [] Allow manual override in settings

## Feature 12: Achievements & Gamification System (4 Days)
### Data Layer
1. [] Create Models:
   ```dart
   class Achievement {
     String id
     String name
     String description
     String iconPath
     AchievementCategory category
     int requiredCount
     String unlockInstructions
     bool isUnlocked
     DateTime? unlockedDate
   }
   
   enum AchievementCategory {
     prayer,
     dailyChallenges,
     reflection,
     emergency,
     streak,
     learning
   }
   
   class UserLevel {
     int level
     int currentPoints
     int pointsForNextLevel
     String title // "New Journeyer", "Seeker", etc.
   }
   
   class UserAchievements {
     String userId
     List<Achievement> unlockedAchievements
     List<Achievement> inProgressAchievements
     UserLevel level
     Map<String, int> progressCounters // Tracks various counted activities
   }
   ```

2. [] Implement `AchievementRepository`:
   - [] getAvailableAchievements()
   - [] getUserAchievements()
   - [] unlockAchievement()
   - [] updateAchievementProgress()
   - [] getUserLevel()
   - [] addExperiencePoints()
   - [] calculateLevelFromPoints()
   - [] saveAchievementProgress()

### Business Logic
1. [] Create `AchievementService`:
   - [] checkAndUpdateAchievements() - Called after relevant activities
   - [] handlePrayerTracking() - For prayer mat achievement
   - [] handleDailyChallengeCompletion() - For ruby lantern achievement
   - [] handleReflectionEntry() - For jade manuscript achievement
   - [] handleEmergencyToolUse() - For amethyst shield achievement
   - [] calculateUserLevel()
   - [] getNextLevelRequirements()
   - [] awardPointsForActivity()

2. [] Achievement triggers:
   - [] Track 30 days of consistent prayers → Turquoise Prayer Mat
   - [] Complete 10 daily challenges → Ruby Lantern
   - [] Complete 20 daily reflections → Jade Manuscript
   - [] Successfully use emergency tool 5 times → Amethyst Shield
   - [] Maintain streaks of good habits
   - [] Level up system (New Journeyer → higher levels)

### Presentation Layer
1. [] Create screens:
   - [] AchievementsOverviewScreen
   - [] AchievementDetailScreen
   - [] UserLevelScreen with progress visualization
   - [] PerksScreen showing benefits of leveling up

2. [] Create UI components:
   - [] AchievementCard
   - [] AchievementDetailModal
   - [] LevelProgressIndicator
   - [] UnlockInstructionsCard
   - [] LevelBenefitsCard
   - [] TrophiesGrid
   - [] AchievementCategoryFilter

3. [] Implement animations:
   - [] Achievement unlock celebration
   - [] Level-up animation
   - [] Progress indicator animations

4. [] User experience flows:
   - [] First achievement introduction
   - [] Achievement notification system
   - [] Level up celebration
   - [] Daily/weekly progress summaries

### Testing
1. [] Unit tests:
   - [] Achievement unlocking logic
   - [] Progress tracking accuracy
   - [] Point calculation

2. [] Integration tests:
   - [] Achievement system with activity tracking
   - [] UI updates on achievement changes

3. [] UI tests:
   - [] Achievement screens rendering
   - [] Interaction with achievement cards

### Documentation
1. [] Create documentation:
   - [] Achievement system overview
   - [] Adding new achievements
   - [] Achievement triggering events
   - [] Leveling system mechanics

## Implementation Strategy (Clean Architecture Approach)

### Architecture Layers Order
1. **Models (Data Classes)**
   - Start with core models: `UserModel`, `TriggerModel`, `HobbyModel`, `AspirationModel`, `EmergencySessionModel`
   - These will form the foundation of all app features

2. **Repositories**
   - Set up ObjectBox with encryption for local storage
   - Create repositories for each core feature starting with `UserRepository`
   - Implement data persistence and retrieval logic

3. **Providers/Controllers**
   - Set up Riverpod providers for state management
   - Create providers for each feature: `OnboardingProvider`, `EmergencyProvider`, etc.
   - Implement business logic for each feature

4. **Views (Pages)**
   - Implement UI components following the design system
   - Create navigation flow between screens

### Implementation Sequence

1. **Basic App Structure (Days 1-2)**
   - Project setup with proper folder structure
   - Core dependencies configuration
   - Routing setup

2. **Onboarding Flow (Days 3-4)**
   - Welcome Screen with encouraging message about taking first step
   - Trigger Collection Screen for identifying triggers
   - Hobbies Selection Screen for alternative activities
   - Aspirations/Goals/Duas Screen for motivation
   - Connect to repositories to save user data

3. **Dashboard & Emergency Feature (Days 5-7)**
   - Dashboard with streak display and quick access buttons
   - Emergency response screen with timer
   - Suggested activities during emergency
   - Resolution form for tracking outcomes

4. **Chat & Progress Features (Days 8-10)**
   - Chat interface for AI interaction
   - Progress tracking screen
   - Settings page with API key input option
   - Voice interaction features

### User Flow

1. **First Launch**
   - User sees welcome message with encouragement
   - App explains its purpose and how it can help
   - No login required initially to reduce barriers

2. **Onboarding**
   - User identifies their triggers (times, emotions, situations)
   - User selects hobbies and alternative activities
   - User sets goals and makes duas for motivation

3. **Main App Usage**
   - Dashboard shows progress and provides quick access to features
   - Emergency button always available for immediate help
   - Chat functionality for ongoing support
   - Progress tracking for accountability

4. **Advanced Features**
   - Daily challenges for continued motivation
   - Educational resources for deeper understanding
   - Voice interaction for hands-free support

## Daily Development Process
1. Start with Bismillah and clear intention
2. For each feature component:
   - Write tests first
   - Implement the feature
   - Document the code
   - Test edge cases
3. Take breaks for salah
4. End day with code backup

## Success Criteria
- [] Each feature works offline
- [] Data is properly encrypted
- [] UI is responsive and intuitive
- [] Emergency help is accessible within 2 taps
- [] AI responses are helpful and quick
- [] All critical paths are tested
- [] Voice interaction is smooth and responsive
- [] Daily challenges are engaging and varied
- [] Educational resources are informative and accessible

## Notes
- Focus on one feature at a time
- Test on both high-end and low-end devices
- Keep privacy and security as top priority
- Regular testing with real-world scenarios
- Document all assumptions and decisions
- Allow custom API key input to make AI features accessible to all users
- Integrate text-to-speech for accessibility and voice interaction

## MVP Development Plan (April, 2025)

### Core MVP Features (Essential)
1. Basic App Structure
   - Project setup with dependencies
   - Basic navigation
   - Simple UI components

2. User Authentication & Data Security
   - Local password protection
   - Data encryption setup
   - Secure storage implementation

3. Emergency Response System
   - Emergency help button
   - Simple timer
   - Basic distraction suggestions
   - Resolution tracking

4. Trigger Management
   - Trigger input and storage
   - Basic trigger categorization
   - Trigger viewing interface

5. AI Guidance (Basic Implementation)
   - Simple HTTP-based API integration with OpenAI
   - Basic prompt engineering
   - Minimal context building
   - Simple chat interface

### Today's Implementation Plan
1. **Morning Session:**
   - Project setup and dependencies
   - Create core data models
   - Implement basic encryption
   - Set up ObjectBox with encryption

2. **Midday Session:**
   - Build authentication screens
   - Implement trigger management
   - Create emergency response UI

3. **Evening Session:**
   - Implement basic AI integration
   - Connect all components
   - Test core functionality

### Implementation Priority
1. **Data Models & Storage (Highest Priority)**
   - `UserModel`
   - `TriggerModel`
   - `EmergencySessionModel`
   - ObjectBox setup with encryption

2. **Core User Flows (High Priority)**
   - Authentication flow
   - Emergency response flow
   - Trigger management screens

3. **Basic AI Integration (Medium Priority)**
   - Simple HTTP client for OpenAI
   - Basic chat UI
   - Minimal context building

### Features to Defer
1. Voice transcription (AssemblyAI integration)
2. Complex statistics and analytics
3. Advanced hobby management
4. Daily challenges
5. Educational resources library

### Success Criteria for Today
- User can set up password protection
- Data is properly encrypted
- Emergency help is accessible within 2 taps
- User can add and view triggers
- Basic AI chat works for guidance
- App runs offline with core functionality

With Allah's help, we will focus on these essentials to create a functional MVP today. Later we can enhance it with additional features like voice transcription and more advanced functionality.

## Voice Integration Phase (2025-04-20 to 2025-04-22)

### Day 1 (Sunday, 2025-04-20)

#### 1. Habib Voice Agent Integration
- Configure Habib's personality and prompts
- Set up voice and model settings
- Implement error handling
- Test voice quality and responses

#### 2. Speech-to-Text Services
- Integrate multiple STT providers:
  * Whisper (offline processing)
  * LemonFox (real-time)
  * Assembly AI (high accuracy)
- Create service fallback chain
- Add offline support with caching
- Implement language detection

#### 3. Bug Fixes & Testing
- Fix ObjectBox model issues
- Test VAPI integration
- Verify UI and animations
- Test error handling

### Day 2 (Monday, 2025-04-22)

#### 1. Voice Feature Enhancement
- Voice agent customization
- Voice preferences system
- Command system implementation
- Voice shortcuts creation

#### 2. Testing & Integration
- End-to-end voice testing
- Performance optimization
- Load testing
- Error recovery verification

#### 3. Documentation
- Voice configuration docs
- User guide creation
- Debugging documentation
- Performance optimization guide

Success Criteria:
- Smooth voice interaction
- Reliable STT across services
- Proper error handling
- Good offline support
- Clear documentation

Ya Allah, guide us in implementing these features effectively and help us create a system that truly benefits Your servants. Ameen. 