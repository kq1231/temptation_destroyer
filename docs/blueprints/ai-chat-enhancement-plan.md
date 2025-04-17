# AI Chat Enhancement Plan

## Overview
This document outlines the plan to transform the current AI Guidance feature into a more robust, full-featured AI Chat system. The enhancement will leverage the existing infrastructure for API key management while implementing additional features for chat history, encryption, context management, and support for various LLM providers.

## Core Components to Implement

### 1. Data Models Enhancement

#### Chat Model (New)
```dart
@Entity()
class ChatModel {
  @Id()
  int id = 0;
  
  @Unique()
  final String uid;
  
  String title;
  
  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  
  AIServiceType serviceType;
  
  String? modelName;
  
  bool isPinned;
  
  bool isEncrypted = false;
  
  // One-to-many relationship with messages
  @Backlink('chat')
  final ToMany<ChatMessageModel> messages = ToMany<ChatMessageModel>();
}
```

#### ChatMessageModel Enhancement
```dart
// Add relationship to parent chat
final ToOne<ChatModel> chat = ToOne<ChatModel>();

// Add metadata for token usage
int? promptTokens;
int? completionTokens;
int? totalTokens;

// Add metadata for AI-generated responses
String? modelName;
double? temperature;
int? maxTokens;
```

### 2. Repository Enhancements

#### AIRepository
- Update the repository to support CRUD operations for chats
- Implement methods for managing chat history
- Add support for different types of conversations (general, emergency, etc.)
- Implement methods for context management and prompt engineering

```dart
// Example new methods
Future<ChatModel> createChat({String? title, AIServiceType? serviceType, String? modelName});
Future<void> deleteChat(String chatId);
Future<void> renameChat(String chatId, String newTitle);
Future<void> pinChat(String chatId, bool isPinned);
Future<List<ChatModel>> getChats({int limit = 20, int offset = 0, bool includeDeleted = false});
Future<ChatModel> getChatById(String chatId);
Future<void> clearAllChats();
```

### 3. Encryption Framework

#### SecurityService Enhancement
- Implement chat-specific encryption/decryption
- Add support for selective encryption (per-chat basis)
- Ensure all sensitive data is encrypted at rest

```dart
// Example of encryption/decryption methods for chats
Future<ChatModel> encryptChat(ChatModel chat, String encryptionKey);
Future<ChatModel> decryptChat(ChatModel chat, String encryptionKey);
Future<List<ChatMessageModel>> encryptMessages(List<ChatMessageModel> messages, String encryptionKey);
Future<List<ChatMessageModel>> decryptMessages(List<ChatMessageModel> messages, String encryptionKey);
```

### 4. LLM Integration

#### AIService
- Create a unified service for all LLM interactions
- Implement provider-specific adaptors for OpenAI, Anthropic, and OpenRouter
- Add support for streaming responses

```dart
abstract class AIService {
  Future<String> generateResponse(String prompt, {ChatModel? chat, Map<String, dynamic>? options});
  Stream<String> streamResponse(String prompt, {ChatModel? chat, Map<String, dynamic>? options});
  Future<Map<String, dynamic>> getModelInfo(String modelName);
  List<String> getAvailableModels();
}

// Implementation for each provider
class OpenAIService implements AIService { ... }
class AnthropicService implements AIService { ... }
class OpenRouterService implements AIService { ... }
```

### 5. Context Management

#### ContextManager
- Create a dedicated class for managing conversation context
- Implement token counting and context window management
- Support for different summarization strategies

```dart
class ContextManager {
  // Initialize with max tokens for the model
  ContextManager({required this.maxContextTokens});
  
  final int maxContextTokens;
  
  // Build prompt with context window management
  Future<String> buildPrompt(ChatModel chat, String userMessage);
  
  // Count tokens in a message
  int countTokens(String text);
  
  // Summarize conversation if needed
  Future<String> summarizeConversation(List<ChatMessageModel> messages);
  
  // Strategies for context management
  enum ContextStrategy {
    slidingWindow,     // Keep most recent N messages
    summarization,     // Summarize older messages
    selective,         // Keep important messages based on relevance
    hierarchical       // Maintain hierarchy of summaries
  }
}
```

### 6. UI Components

#### Rename AIGuidanceScreen to AIChatScreen
- Redesign to support full chat functionality
- Add support for chat listing, creation, and management
- Implement chat settings and customization options

#### Chat Interface Enhancements
- Add support for markdown rendering in chat
- Implement code highlighting for code blocks
- Add support for image generation and viewing
- Add typing indicators and loading states

#### Chat Management Components
- Create a ChatListScreen for browsing and managing chats
- Implement chat search functionality
- Add support for chat archiving and deletion

## Implementation Plan

### Phase 1: Core Chat Functionality (1 week)
1. Update data models (ChatModel, enhanced ChatMessageModel)
2. Update repositories to support chat operations
3. Implement basic chat UI (renaming AIGuidanceScreen to AIChatScreen)
4. Add support for chat creation, deletion, and listing

### Phase 2: Enhanced LLM Integration (1 week)
1. Implement the unified AIService
2. Create provider-specific adaptors
3. Add streaming response support
4. Implement model selection UI
5. Enhance prompt engineering

### Phase 3: Context Management (3-4 days)
1. Implement the ContextManager
2. Add token counting functionality
3. Implement different context strategies
4. Add UI for context management settings

### Phase 4: Chat History and Encryption (3-4 days)
1. Enhance encryption framework for chats
2. Implement selective encryption
3. Add chat history browsing and search
4. Implement chat export/import functionality

### Phase 5: UI Polish and Advanced Features (1 week)
1. Improve chat rendering with markdown support
2. Add support for code highlighting
3. Implement system message customization
4. Add support for chat templates and predefined conversations
5. Implement relevance ranking for emergency chats

## Technical Considerations

### Token Management
- Implement efficient token counting for different models
- Track token usage for monitoring and optimiazation
- Implement intelligent context window management

### Model Support
- OpenAI models: GPT-3.5-Turbo, GPT-4o, GPT-4-Turbo
- Anthropic models: Claude 3 Haiku, Claude 3 Sonnet, Claude 3 Opus
- OpenRouter models: Various models supported by OpenRouter

### Error Handling
- Implement comprehensive error handling for API failures
- Add fallback mechanisms for offline operation
- Support for retry logic with exponential backoff

### Privacy and Security
- Implement end-to-end encryption for chat data
- Add options for automatic chat history deletion
- Implement secure credential storage

## UI Mockups

### Chat List Screen
```
+-----------------------------------------------+
| AI Chat                            + New Chat |
+-----------------------------------------------+
| [Search chats...]                             |
+-----------------------------------------------+
| > Islamic Guidance Chat                   📌 |
|   Last message: Yesterday                     |
+-----------------------------------------------+
| > Emergency Support                           |
|   Last message: 3 days ago                    |
+-----------------------------------------------+
| > Daily Reflection                            |
|   Last message: 1 week ago                    |
+-----------------------------------------------+
|                                               |
|                                               |
|                                               |
+-----------------------------------------------+
| [Bottom Navigation]                           |
+-----------------------------------------------+
```

### Chat Screen
```
+-----------------------------------------------+
| < Back  Islamic Guidance Chat          ⋮      |
+-----------------------------------------------+
|                                               |
|   [AI Message with Markdown Support]          |
|                                               |
|   [User Message]                              |
|                                               |
|   [AI Message with Code Block]                |
|                                               |
|   [User Message]                              |
|                                               |
+-----------------------------------------------+
| [Type a message...]                  🎤  📷  |
+-----------------------------------------------+
```

### Chat Settings
```
+-----------------------------------------------+
| < Back  Chat Settings                         |
+-----------------------------------------------+
| Chat Title                                    |
| [Islamic Guidance Chat]                       |
+-----------------------------------------------+
| Model                                         |
| [Claude 3 Sonnet]                 ▼           |
+-----------------------------------------------+
| Temperature                                   |
| [0.7] --------------------------------o--     |
+-----------------------------------------------+
| Max Response Tokens                           |
| [1024]                                        |
+-----------------------------------------------+
| System Message                                |
| [Customize the AI's behavior...]              |
+-----------------------------------------------+
| [Delete Chat]                                 |
+-----------------------------------------------+
```

## Integration with Emergency Feature

The enhanced AI Chat system will integrate closely with the Emergency feature:
- Automatically create emergency-specific chats when emergency mode is activated
- Use specialized prompts for emergency support
- Implement quick-access to emergency chats
- Provide contextual information from trigger analysis to the AI
- Record emergency chat interactions as part of the emergency session data

## Implementation Schedule

1. **Week 1 (Phase 1)**: Core Chat Functionality
   - Data model updates
   - Repository enhancements
   - Basic UI implementation

2. **Week 2 (Phase 2)**: Enhanced LLM Integration
   - AIService implementation
   - Provider-specific adaptors
   - Streaming response support

3. **Week 3 (Phase 3 & 4)**: Context Management and Chat History
   - ContextManager implementation
   - Encryption enhancements
   - Chat history management

4. **Week 4 (Phase 5)**: UI Polish and Advanced Features
   - Markdown support
   - Code highlighting
   - Templates and predefined conversations

This implementation plan will transform the current AI Guidance feature into a comprehensive AI Chat system that provides valuable support for users while maintaining the app's commitment to privacy and security. 