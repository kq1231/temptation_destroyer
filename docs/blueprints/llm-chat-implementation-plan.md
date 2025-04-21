# LLM Chat Implementation Plan

## Current State Analysis

Based on the code review, the app already has:

1. **Basic AI Models**: 
   - `AIServiceType` enum including OpenAI, Anthropic, OpenRouter, and offline modes
   - `AIResponseModel` for storing AI responses
   - `ChatMessageModel` for chat messages
   - `AIServiceConfig` for service configuration

2. **API Key Management**:
   - UI for inputting and changing API keys
   - Storage in database

3. **Basic Chat Functionality**:
   - Message sending/receiving
   - Chat history (without pagination)
   - Offline fallback mode

## Updated Implementation Priorities

1. **API Key Persistence**
2. **OpenRouter Default Integration**
3. **Chat Pagination with AsyncNotifier**
4. **Message Encryption**
5. **Context Management**
6. **Emergency Mode Integration**

## Implementation Steps Overview

1. Fix API key persistence and make OpenRouter the default provider
2. Implement proper encryption for chat messages
3. Set up pagination with AsyncNotifier
4. Create context management for different models
5. Integrate AI chat with emergency mode

## Tasks Breakdown

### 1. API Key Persistence (2 days)

#### 1.1 Fix API Key Loading/Saving
```dart
// In AIRepository class:
Future<void> saveServiceConfig(AIServiceConfig config) async {
  try {
    // First check if config already exists
    final query = _configBox.query(AIServiceConfig_.serviceType.equals(config.serviceType.index)).build();
    final existing = query.findFirst();
    query.close();
    
    if (existing != null) {
      // Update existing config
      existing.apiKey = config.apiKey;
      existing.preferredModel = config.preferredModel;
      existing.allowDataTraining = config.allowDataTraining;
      _configBox.put(existing);
    } else {
      // Create new config
      _configBox.put(config);
    }
  } catch (e) {
    debugPrint('Error saving service config: $e');
    rethrow;
  }
}

Future<AIServiceConfig?> getServiceConfigByType(AIServiceType type) async {
  try {
    final query = _configBox.query(AIServiceConfig_.serviceType.equals(type.index)).build();
    final config = query.findFirst();
    query.close();
    return config;
  } catch (e) {
    debugPrint('Error loading service config: $e');
    return null;
  }
}
```

#### 1.2 Update AIServiceNotifier to Load Keys on Initialization
```dart
// In AIServiceNotifier class:
Future<void> initialize() async {
  state = state.copyWith(isLoading: true);
  try {
    final aiRepository = AIRepository();
    final configs = aiRepository.getAllServiceConfigs();
    
    // Default to OpenRouter if available, otherwise offline
    AIServiceConfig? config;
    
    // Try to get OpenRouter config first
    config = configs.firstWhere(
      (c) => c.serviceType == AIServiceType.openRouter,
      orElse: () => null,
    );
    
    // If no OpenRouter config, try other providers
    if (config == null) {
      config = configs.firstWhere(
        (c) => c.serviceType != AIServiceType.offline,
        orElse: () => null,
      );
    }
    
    // If no online provider configs, default to offline
    if (config == null) {
      config = AIServiceConfig(serviceType: AIServiceType.offline);
    }
    
    state = state.copyWith(
      config: config,
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Failed to load service configuration: $e',
    );
  }
}
```

### 2. OpenRouter Default Integration (1 day)

#### 2.1 Update UI to Prioritize OpenRouter
```dart
// In ai_settings_screen.dart:
// Change the order of dropdown items:
DropdownMenuItem(
  value: AIServiceType.openRouter,
  child: _buildServiceOption(
    'Open Router',
    'Multiple models through one API',
    Icons.router,
  ),
),
DropdownMenuItem(
  value: AIServiceType.anthropic,
  child: _buildServiceOption(
    'Anthropic',
    'Claude models',
    Icons.psychology,
  ),
),
DropdownMenuItem(
  value: AIServiceType.openAI,
  child: _buildServiceOption(
    'OpenAI',
    'GPT models (ChatGPT, GPT-4)',
    Icons.smart_toy,
  ),
),
DropdownMenuItem(
  value: AIServiceType.offline,
  child: _buildServiceOption(
    'Offline Mode',
    'No API key required',
    Icons.wifi_off,
  ),
),
```

#### 2.2 Enhance OpenRouter API Integration
```dart
// In AIRepository._sendOpenRouterRequest:
// Add support for more OpenRouter models
Future<String> _sendOpenRouterRequest(
    String userInput, String context, AIServiceConfig config) async {
  // ... existing code ...
  
  // Default to "meta/llama3-70b-instruct" if no model specified
  final model = config.preferredModel ?? "meta/llama3-70b-instruct";
  
  // Add support for model-specific configurations
  int maxTokens = 500;
  double temperature = 0.7;
  
  // Adjust parameters based on the model
  if (model.contains("claude-3")) {
    maxTokens = 1000;
  } else if (model.contains("gpt-4")) {
    maxTokens = 800;
  }
  
  // ... rest of the code ...
  
  // Update the request body with model-specific parameters
  body: jsonEncode({
    'model': model,
    'messages': messages,
    'temperature': temperature,
    'max_tokens': maxTokens,
  }),
}
```

#### 2.3 Add Comprehensive OpenRouter Model Selection
```dart
// In ai_settings_screen.dart:
// Add a more comprehensive model selection for OpenRouter

// Expanded list of popular models for OpenRouter
final List<Map<String, String>> openRouterModels = [
  // Most popular models
  {'id': 'meta/llama3-70b-instruct', 'name': 'Meta Llama 3 70B'},
  {'id': 'anthropic/claude-3-opus', 'name': 'Claude 3 Opus'},
  {'id': 'anthropic/claude-3-sonnet', 'name': 'Claude 3 Sonnet'},
  {'id': 'anthropic/claude-3-haiku', 'name': 'Claude 3 Haiku'},
  {'id': 'mistralai/mistral-7b-instruct', 'name': 'Mistral 7B'},
  {'id': 'google/gemma-7b-it', 'name': 'Google Gemma 7B'},
  {'id': 'openai/gpt-4o', 'name': 'GPT-4o'},
  {'id': 'openai/gpt-4-turbo', 'name': 'GPT-4 Turbo'},
  {'id': 'openai/gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
  {'id': 'cohere/command-r', 'name': 'Cohere Command-R'},
  {'id': 'meta/llama3-8b-instruct', 'name': 'Meta Llama 3 8B'},
];

// Add a widget to allow custom model ID input
Widget _buildModelSelectionArea(WidgetRef ref, AIServiceState state) {
  // Only show for OpenRouter
  if (state.config.serviceType != AIServiceType.openRouter) {
    return const SizedBox.shrink();
  }
  
  final currentModelId = state.config.preferredModel ?? openRouterModels[0]['id'];
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Select Model',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      const SizedBox(height: 8),
      
      // Dropdown for popular models
      DropdownButtonFormField<String>(
        value: openRouterModels.any((m) => m['id'] == currentModelId) 
            ? currentModelId 
            : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Popular Models',
          border: OutlineInputBorder(),
        ),
        items: [
          // Add a "Custom" option
          const DropdownMenuItem<String>(
            value: 'custom',
            child: Text('Custom Model ID'),
          ),
          
          // Add all popular models
          ...openRouterModels.map((model) => DropdownMenuItem<String>(
            value: model['id'],
            child: Text(model['name'] ?? model['id']!),
          )),
        ],
        onChanged: (value) {
          if (value == 'custom') {
            // Show dialog to enter custom model
            _showCustomModelDialog(context, ref, currentModelId);
          } else if (value != null) {
            // Update selected model
            ref.read(aiServiceProvider.notifier).updatePreferredModel(value);
          }
        },
      ),
      
      // Show current custom model if it doesn't match any in the list
      if (!openRouterModels.any((m) => m['id'] == currentModelId) && currentModelId != 'custom')
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Current model: $currentModelId',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
    ],
  );
}

// Method to show custom model dialog
void _showCustomModelDialog(BuildContext context, WidgetRef ref, String currentModel) {
  final controller = TextEditingController(
    text: openRouterModels.any((m) => m['id'] == currentModel) ? '' : currentModel
  );
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enter Custom Model ID'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Model ID',
              hintText: 'e.g., anthropic/claude-3-opus',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'OpenRouter supports 300+ models. Visit openrouter.ai to see the full list.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              ref.read(aiServiceProvider.notifier).updatePreferredModel(controller.text);
            }
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
```

### 3. Chat Pagination with AsyncNotifier (2 days)

#### 3.1 Update Repository Method for Paginated Chat Loading
```dart
// In AIRepository:
Future<List<ChatMessageModel>> getChatMessages({
  int limit = 20,
  int offset = 0,
}) async {
  try {
    final query = _chatBox.query()
      ..order(ChatMessageModel_.timestamp, flags: Order.descending)
      ..offset(offset)
      ..limit(limit);
    
    final messages = query.find().reversed.toList();
    query.close();
    return messages;
  } catch (e) {
    debugPrint('Error fetching chat messages: $e');
    return [];
  }
}

Future<int> getChatMessageCount() async {
  return _chatBox.count();
}
```

#### 3.2 Create AsyncNotifier for Chat Pagination
```dart
// Create a new file: lib/presentation/providers/chat_messages_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/ai_repository.dart';

// State class for chat messages
class ChatMessagesState {
  final List<ChatMessage> messages;
  final int totalLoaded;
  final bool hasMoreMessages;
  final String? errorMessage;

  ChatMessagesState({
    this.messages = const [],
    this.totalLoaded = 0,
    this.hasMoreMessages = false,
    this.errorMessage,
  });

  ChatMessagesState copyWith({
    List<ChatMessage>? messages,
    int? totalLoaded,
    bool? hasMoreMessages,
    String? errorMessage,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      errorMessage: errorMessage,
    );
  }
}

// AsyncNotifier for chat messages
class ChatMessagesNotifier extends AsyncNotifier<ChatMessagesState> {
  static const int _pageSize = 20;
  
  Future<ChatMessagesState> _loadMessages({
    required int offset,
    required int limit,
    required bool isInitialLoad,
  }) async {
    final repo = ref.read(aiRepositoryProvider);
    
    // Get total count for determining if more messages exist
    final totalCount = await repo.getChatMessageCount();
    
    // Load messages with pagination
    final messages = await repo.getChatMessages(
      offset: offset,
      limit: limit,
    );
    
    // Convert models to UI representation
    final uiMessages = messages.map(
      (m) => ChatMessage.fromModel(m)
    ).toList();
    
    if (isInitialLoad) {
      return ChatMessagesState(
        messages: uiMessages,
        totalLoaded: uiMessages.length,
        hasMoreMessages: uiMessages.length < totalCount,
      );
    } else {
      // For loading more, combine with existing messages
      return state.value!.copyWith(
        messages: [...uiMessages, ...state.value!.messages],
        totalLoaded: state.value!.totalLoaded + uiMessages.length,
        hasMoreMessages: state.value!.totalLoaded + uiMessages.length < totalCount,
      );
    }
  }
  
  @override
  Future<ChatMessagesState> build() async {
    return _loadMessages(
      offset: 0,
      limit: _pageSize,
      isInitialLoad: true,
    );
  }
  
  Future<void> loadMoreMessages() async {
    if (!state.value!.hasMoreMessages) return;
    
    state = const AsyncValue.loading();
    
    try {
      state = AsyncValue.data(
        await _loadMessages(
          offset: state.value!.totalLoaded,
          limit: _pageSize,
          isInitialLoad: false,
        )
      );
    } catch (e, st) {
      state = AsyncValue.error(
        'Failed to load more messages: $e',
        st,
      );
    }
  }
  
  Future<void> sendMessage(String content) async {
    final repo = ref.read(aiRepositoryProvider);
    
    // Create user message
    final userMessage = ChatMessageModel(
      content: content,
      isUserMessage: true,
    );
    
    try {
      // Save to database
      await repo.storeChatMessage(userMessage);
      
      // Update state with new message
      state = AsyncValue.data(
        state.value!.copyWith(
          messages: [
            ChatMessage.fromModel(userMessage),
            ...state.value!.messages,
          ],
          totalLoaded: state.value!.totalLoaded + 1,
        )
      );
      
      // Generate AI response
      final response = await repo.generateResponse(userInput: content);
      
      // Create and save AI message
      final aiMessage = ChatMessageModel(
        content: response.response,
        isUserMessage: false,
      );
      
      await repo.storeChatMessage(aiMessage);
      
      // Update state with AI response
      state = AsyncValue.data(
        state.value!.copyWith(
          messages: [
            ChatMessage.fromModel(aiMessage),
            ...state.value!.messages,
          ],
          totalLoaded: state.value!.totalLoaded + 1,
        )
      );
    } catch (e, st) {
      state = AsyncValue.error(
        'Failed to send message: $e',
        st,
      );
    }
  }
  
  Future<void> clearChatHistory() async {
    final repo = ref.read(aiRepositoryProvider);
    
    try {
      await repo.clearChatHistory();
      
      state = const AsyncValue.data(
        ChatMessagesState(
          messages: [],
          totalLoaded: 0,
          hasMoreMessages: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(
        'Failed to clear chat history: $e',
        st,
      );
    }
  }
}

// Provider definition
final chatMessagesProvider = AsyncNotifierProvider<ChatMessagesNotifier, ChatMessagesState>(
  () => ChatMessagesNotifier(),
);

// Repository provider
final aiRepositoryProvider = Provider<AIRepository>((ref) => AIRepository());
```

#### 3.3 Update UI to Work with AsyncNotifier
```dart
// In AIGuidanceScreen:
@override
Widget build(BuildContext context) {
  // Watch the chat messages provider
  final chatMessagesAsync = ref.watch(chatMessagesProvider);
  
  return Scaffold(
    appBar: AppBar(title: const Text('AI Guidance')),
    body: Column(
      children: [
        // Messages area
        Expanded(
          child: chatMessagesAsync.when(
            data: (state) {
              if (state.messages.isEmpty) {
                return _buildWelcomeScreen();
              }
              
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: state.hasMoreMessages 
                    ? state.messages.length + 1 
                    : state.messages.length,
                itemBuilder: (context, index) {
                  // Load more indicator
                  if (index == state.messages.length && state.hasMoreMessages) {
                    return _buildLoadMoreIndicator();
                  }
                  
                  return _buildChatMessage(state.messages[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
        
        // Input area
        _buildMessageInput(),
      ],
    ),
  );
}

Widget _buildLoadMoreIndicator() {
  return GestureDetector(
    onTap: () {
      ref.read(chatMessagesProvider.notifier).loadMoreMessages();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const Text('Load earlier messages'),
    ),
  );
}

// Add scroll listener
@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
}

void _onScroll() {
  if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) {
    // At the top, load more
    ref.read(chatMessagesProvider.notifier).loadMoreMessages();
  }
}
```

### 4. Message Encryption (1 day)

#### 4.1 Updating Models to Support Encryption
```dart
// First ensure all models consistently handle the isEncrypted flag
// For example, in ChatMessageModel:

@Entity()
class ChatMessageModel {
  // ... existing properties ...
  
  // For encrypted storage
  bool isEncrypted = false;
  
  // ... existing methods ...
  
  /// Create a copy with updated values
  ChatMessageModel copyWith({
    // ... existing parameters ...
    bool? isEncrypted,
  }) {
    return ChatMessageModel(
      // ... existing assignments ...
    )..isEncrypted = isEncrypted ?? this.isEncrypted;
  }
}
```

#### 4.2 Add Encryption Service Integration
```dart
// Create or update lib/core/services/encryption_service.dart

import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../../data/models/ai_models.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  
  EncryptionService._internal();
  
  // Encryption key - in production this should be securely stored
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;
  bool _isInitialized = false;
  
  /// Initialize encryption with a secure key
  Future<void> initialize(String encryptionKey) async {
    if (_isInitialized) return;
    
    try {
      _key = encrypt.Key.fromUtf8(encryptionKey.padRight(32).substring(0, 32));
      _iv = encrypt.IV.fromLength(16);
      _encrypter = encrypt.Encrypter(encrypt.AES(_key));
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize encryption: $e');
      rethrow;
    }
  }
  
  /// Encrypt a string
  String encryptString(String plainText) {
    if (!_isInitialized) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption error: $e');
      return plainText; // Fallback to plaintext
    }
  }
  
  /// Decrypt a string
  String decryptString(String encryptedText) {
    if (!_isInitialized) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return encryptedText; // Return as is if decryption fails
    }
  }
  
  /// Encrypt a chat message
  ChatMessageModel encryptChatMessage(ChatMessageModel message) {
    if (message.isEncrypted) return message;
    
    return message.copyWith(
      content: encryptString(message.content),
      isEncrypted: true,
    );
  }
  
  /// Decrypt a chat message
  ChatMessageModel decryptChatMessage(ChatMessageModel message) {
    if (!message.isEncrypted) return message;
    
    return message.copyWith(
      content: decryptString(message.content),
      isEncrypted: false,
    );
  }
  
  /// Encrypt an AI response
  AIResponseModel encryptAIResponse(AIResponseModel response) {
    if (response.isEncrypted) return response;
    
    return response.copyWith(
      context: encryptString(response.context),
      response: encryptString(response.response),
      isEncrypted: true,
    );
  }
  
  /// Decrypt an AI response
  AIResponseModel decryptAIResponse(AIResponseModel response) {
    if (!response.isEncrypted) return response;
    
    return response.copyWith(
      context: decryptString(response.context),
      response: decryptString(response.response),
      isEncrypted: false,
    );
  }
}
```

#### 4.3 Update Repository Methods to Use Encryption
```dart
// Update AIRepository to use encryption service

// Add to constructor:
final EncryptionService _encryptionService = EncryptionService();

// Update storeChatMessage method:
Future<void> storeChatMessage(ChatMessageModel message) async {
  try {
    // Encrypt the message before storing
    if (!message.isEncrypted) {
      message = _encryptionService.encryptChatMessage(message);
    }
    
    _chatBox.put(message);
  } catch (e) {
    debugPrint('Error storing chat message: $e');
    rethrow;
  }
}

// Update getChatMessages method:
Future<List<ChatMessageModel>> getChatMessages({
  int limit = 20,
  int offset = 0,
}) async {
  try {
    final query = _chatBox.query()
      ..order(ChatMessageModel_.timestamp, flags: Order.descending)
      ..offset(offset)
      ..limit(limit);
    
    final encryptedMessages = query.find().reversed.toList();
    query.close();
    
    // Decrypt messages before returning
    return encryptedMessages.map((message) {
      if (message.isEncrypted) {
        return _encryptionService.decryptChatMessage(message);
      }
      return message;
    }).toList();
  } catch (e) {
    debugPrint('Error fetching chat messages: $e');
    return [];
  }
}

// Similarly update AI response methods
Future<void> saveAIResponse(AIResponseModel response) async {
  try {
    // Encrypt the response before storing
    if (!response.isEncrypted) {
      response = _encryptionService.encryptAIResponse(response);
    }
    
    _responseBox.put(response);
  } catch (e) {
    debugPrint('Error saving AI response: $e');
    rethrow;
  }
}

Future<AIResponseModel?> getAIResponse(String id) async {
  try {
    final query = _responseBox.query(AIResponseModel_.uid.equals(id)).build();
    final response = query.findFirst();
    query.close();
    
    if (response != null && response.isEncrypted) {
      return _encryptionService.decryptAIResponse(response);
    }
    
    return response;
  } catch (e) {
    debugPrint('Error getting AI response: $e');
    return null;
  }
}
```

#### 4.4 Initialize Encryption Service on App Startup
```dart
// In main.dart or app initialization:
await EncryptionService().initialize('your-secure-key-source');

// Better approach: Use a secure storage solution to store and retrieve the encryption key
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> initializeEncryption() async {
  const secureStorage = FlutterSecureStorage();
  
  // Check if we have a stored encryption key
  String? encryptionKey = await secureStorage.read(key: 'encryption_key');
  
  if (encryptionKey == null) {
    // Generate a new key if none exists
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    encryptionKey = base64UrlEncode(values);
    
    // Save the key securely
    await secureStorage.write(key: 'encryption_key', value: encryptionKey);
  }
  
  // Initialize the encryption service with the key
  await EncryptionService().initialize(encryptionKey);
}
```

### 5. Context Management (3 days)

#### 5.1 Create ContextManager Class
```dart
// Add new file: lib/domain/services/context_manager.dart
import '../../data/models/ai_models.dart';

class ContextManager {
  // Token counting weights for different models
  final Map<String, double> _modelTokenRatios = {
    'gpt-3.5': 1.0,
    'gpt-4': 1.0,
    'claude-3': 1.0,
    'llama3': 0.85, // Estimates
    'mistral': 0.9,
  };
  
  // Context window sizes (approximate token limits)
  final Map<String, int> _modelContextWindows = {
    'gpt-3.5': 16000,
    'gpt-4': 128000,
    'claude-3-opus': 200000,
    'claude-3-sonnet': 180000,
    'claude-3-haiku': 48000,
    'llama3-70b': 8000,
    'mistral-7b': 8000,
  };

  // Approximate tokens per message
  int estimateTokenCount(String text, String modelFamily) {
    // Very rough estimate: ~4 chars per token for English text
    final ratio = _modelTokenRatios[modelFamily] ?? 1.0;
    return (text.length / 4 * ratio).ceil();
  }
  
  // Get context window size for a model
  int getContextWindowSize(String model) {
    // Try to match the model name with known models
    for (final entry in _modelContextWindows.entries) {
      if (model.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Default: conservative 4K tokens
    return 4000;
  }
  
  // Build a prompt with context management
  String buildPrompt(List<ChatMessageModel> messages, AIServiceConfig config) {
    final modelName = config.preferredModel ?? '';
    final contextWindow = getContextWindowSize(modelName);
    
    // Determine which model family for token estimation
    String modelFamily = 'gpt-3.5'; // Default
    if (modelName.contains('gpt-4')) modelFamily = 'gpt-4';
    else if (modelName.contains('claude')) modelFamily = 'claude-3';
    else if (modelName.contains('llama')) modelFamily = 'llama3';
    else if (modelName.contains('mistral')) modelFamily = 'mistral';
    
    // Reserve tokens for system message and response
    final reservedTokens = 1000;
    final availableTokens = contextWindow - reservedTokens;
    
    List<ChatMessageModel> contextMessages = [];
    int totalTokens = 0;
    
    // Add messages from newest to oldest until we hit the token limit
    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      final tokenEstimate = estimateTokenCount(message.content, modelFamily);
      
      if (totalTokens + tokenEstimate <= availableTokens) {
        contextMessages.insert(0, message);
        totalTokens += tokenEstimate;
      } else {
        // Can't fit more messages in context window
        break;
      }
    }
    
    return contextMessages.map((m) => 
      "${m.isUserMessage ? "User" : "Assistant"}: ${m.content}"
    ).join("\n\n");
  }
}
```

#### 5.2 Update Repository to Use ContextManager
```dart
// Add to AIRepository:
final ContextManager _contextManager = ContextManager();

// Update the generateResponse method:
Future<AIResponseModel> generateResponse({
  required String userInput,
  String? context,
  AIServiceConfig? config,
}) async {
  // Get the current AI service config if not provided
  final serviceConfig = config ?? getServiceConfig();

  if (serviceConfig.serviceType == AIServiceType.offline) {
    return _getFallbackResponse(userInput, context ?? '');
  }

  try {
    // Get recent chat history for context
    final chatHistory = getRecentChatHistory(100); // Get enough for context window
    
    // Use context manager to build prompt with proper context management
    final chatContext = _contextManager.buildPrompt(chatHistory, serviceConfig);
    
    // Combine with any additional context provided
    final combinedContext = context != null && context.isNotEmpty
        ? "$context\n\n$chatContext"
        : chatContext;
    
    // Send the request to the appropriate AI service
    final response = await _sendRequestToAIService(
      userInput: userInput,
      context: combinedContext,
      config: serviceConfig,
    );

    // Create and save the AI response
    final aiResponse = AIResponseModel(
      context: combinedContext,
      response: response,
      wasHelpful: false,
    );

    _cacheResponse(aiResponse);
    return aiResponse;
  } catch (e) {
    debugPrint('Error generating AI response: $e');
    return _getFallbackResponse(userInput, context ?? '');
  }
}
```

### 5. Emergency Mode Integration (2 days)

#### 5.1 Add Chat to Emergency Screen
Create a new widget for the emergency chat component that can be included in the emergency screen:

```dart
// New file: lib/presentation/widgets/emergency/emergency_chat_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/ai_guidance_provider.dart';

class EmergencyChatWidget extends ConsumerStatefulWidget {
  final String emergencyContext;
  
  const EmergencyChatWidget({
    Key? key,
    required this.emergencyContext,
  }) : super(key: key);

  @override
  ConsumerState<EmergencyChatWidget> createState() => _EmergencyChatWidgetState();
}

class _EmergencyChatWidgetState extends ConsumerState<EmergencyChatWidget> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Initialize with emergency context
    Future.microtask(() {
      ref.read(aiGuidanceProvider.notifier).setEmergencyContext(widget.emergencyContext);
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiGuidanceProvider);
    
    return Column(
      children: [
        // Messages area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: aiState.messages.length,
            itemBuilder: (context, index) {
              final message = aiState.messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        
        // Input area
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ask for guidance...',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: Icon(
                  aiState.isLoading ? Icons.hourglass_top : Icons.send,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: aiState.isLoading
                    ? null
                    : () {
                        _sendMessage();
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      ref.read(aiGuidanceProvider.notifier).sendMessage(message);
      _messageController.clear();
    }
  }
  
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUserMessage
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUserMessage
              ? Theme.of(context).primaryColor.withValues(alpha: 0.8)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isUserMessage ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
```

#### 5.2 Update AI Provider for Emergency Mode
```dart
// Add to AIGuidanceNotifier:
String? _emergencyContext;

Future<void> setEmergencyContext(String context) async {
  _emergencyContext = context;
  
  // Auto-generate an initial response based on the emergency context
  await _generateEmergencyResponse();
}

Future<void> _generateEmergencyResponse() async {
  if (_emergencyContext == null || _emergencyContext!.isEmpty) return;
  
  try {
    state = state.copyWith(isLoading: true);
    
    // Generate AI response for emergency
    final response = await _generateAIGuidanceUseCase.execute(
      "I'm in an emergency situation. Please help me.",
      context: _emergencyContext,
    );
    
    // Create AI message
    final aiMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      isUserMessage: false,
    );
    
    state = state.copyWith(
      messages: [aiMessage],
      isLoading: false,
    );
    
    // Save AI message
    _aiRepository.storeChatMessage(aiMessage.toModel());
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Failed to generate emergency response: $e',
    );
  }
}
```

## Step-by-Step Implementation Guide

To achieve the comprehensive improvements to the LLM chat functionality, follow this structured implementation approach:

### Phase 1: API Key Persistence and OpenRouter Integration (3 days)

#### Day 1:
1. Update `AIRepository` to properly save and load API keys for all services
2. Implement the `initialize()` method in `AIServiceNotifier` to load saved configurations
3. Update the service type dropdown in `ai_settings_screen.dart` to prioritize OpenRouter

#### Day 2:
1. Create the comprehensive OpenRouter model selection UI
2. Implement the custom model input dialog
3. Update `_sendOpenRouterRequest` method to handle various models with appropriate parameters

#### Day 3:
1. Test API key persistence across app restarts
2. Test OpenRouter integration with various models
3. Fix any bugs in the implementation

### Phase 2: Message Encryption and AsyncNotifier for Pagination (4 days)

#### Day 4:
1. Create/Update the `EncryptionService` class
2. Implement secure key storage and initialization
3. Update the model classes to properly handle encryption flags

#### Day 5:
1. Modify repository methods to automatically encrypt/decrypt data
2. Create tests to verify encryption is working correctly
3. Fix any issues with encryption implementation

#### Day 6:
1. Create the `ChatMessagesState` class for AsyncNotifier
2. Implement the `ChatMessagesNotifier` class with pagination support
3. Create the provider and repository dependencies

#### Day 7:
1. Update the UI to use the AsyncNotifier provider
2. Implement scrolling behavior for pagination
3. Test the pagination functionality with a large number of messages

### Phase 3: Context Management and Emergency Mode (3 days)

#### Day 8:
1. Implement the `ContextManager` class
2. Add token counting and context window size estimation
3. Update the repository to use context management for prompts

#### Day 9:
1. Create the `EmergencyChatWidget` component
2. Update the AI provider to handle emergency contexts
3. Integrate the chat widget into the emergency screen

#### Day 10:
1. Comprehensive testing of all implemented features
2. Fix any remaining issues or bugs
3. Documentation and code cleanup

## Testing Plan

For each implemented feature, perform the following testing:

1. **API Key Persistence**
   - Save API keys for all providers and restart the app
   - Verify keys are loaded correctly
   - Test switching between providers

2. **OpenRouter Integration**
   - Verify OpenRouter is the default selection
   - Test with different models (both from dropdown and custom input)
   - Verify model-specific parameters are applied correctly

3. **Message Encryption**
   - Use ObjectBox admin panel to verify messages are encrypted in the database
   - Test encryption/decryption performance with large messages
   - Verify app startup initializes encryption correctly

4. **AsyncNotifier Pagination**
   - Add more than 50 messages to test pagination
   - Verify scrolling behavior loads more messages
   - Test error handling when loading fails

5. **Context Management**
   - Test with different models and context window sizes
   - Verify conversation coherence across context boundaries
   - Test with very long message histories

6. **Emergency Mode Integration**
   - Test activating emergency mode
   - Verify AI responses are appropriate for emergency context
   - Test message sending/receiving in emergency mode

## Timeline

- **Week 1 (Days 1-3):** API Key Persistence and OpenRouter Integration
  - Day 1: Update API key persistence implementation
  - Day 2: Enhance OpenRouter integration and model selection
  - Day 3: Testing and bug fixing for key persistence and OpenRouter features

- **Week 1-2 (Days 4-7):** Message Encryption and AsyncNotifier for Pagination
  - Day 4: Implement encryption service and secure key storage
  - Day 5: Update repository methods for encryption/decryption
  - Day 6: Create AsyncNotifier for pagination
  - Day 7: Update UI for AsyncNotifier and test pagination

- **Week 2 (Days 8-10):** Context Management, Emergency Mode and Final Testing
  - Day 8: Implement context management for different models
  - Day 9: Create emergency chat component and integration
  - Day 10: Comprehensive testing and bug fixing 