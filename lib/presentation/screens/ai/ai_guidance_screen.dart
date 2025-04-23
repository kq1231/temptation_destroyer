import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/ai_service_provider.dart';
import '../../../presentation/providers/chat_provider.dart';
import '../../../data/models/ai_models.dart';
import '../../../data/models/chat_session_model.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/emergency_chat_widget.dart';
import '../../widgets/chat/chat_message_bubble.dart';
import '../../widgets/common/loading_overlay.dart' as overlay;
import '../../../core/context/context_manager.dart';

class AIGuidanceScreen extends ConsumerStatefulWidget {
  static const routeName = '/ai-guidance';
  final ChatSession? session;

  const AIGuidanceScreen({super.key, this.session});

  @override
  ConsumerState<AIGuidanceScreen> createState() => _AIGuidanceScreenState();
}

class _AIGuidanceScreenState extends ConsumerState<AIGuidanceScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isInitialized = false;
  bool _isEmergencyMode = false;
  String _emergencyTriggerMessage = '';
  final ContextManager _contextManager = ContextManager();
  late ChatSession? _session;

  // Add a state to toggle streaming mode
  bool _streamingMode = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _session = widget.session;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Get session from route arguments if not passed directly
      if (_session == null) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is ChatSession) {
          _session = args;
        }
      }

      // Initialize chat with the session
      Future.microtask(
          () => ref.read(chatProvider.notifier).initialize(session: _session));
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ref.read(chatProvider.notifier).loadMoreMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final aiServiceState = ref.watch(aiServiceProvider);
    final isOffline =
        aiServiceState.config.serviceType == AIServiceType.offline;
    final isAiServiceLoading = aiServiceState.isLoading;

    // If in emergency mode, show the emergency chat UI
    if (_isEmergencyMode) {
      return Scaffold(
        body: EmergencyChatWidget(
          triggerMessage: _emergencyTriggerMessage,
          onExit: () {
            setState(() {
              _isEmergencyMode = false;
            });
          },
          onRequestProfessionalHelp: () {
            // TODO: Implement professional help request
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Finding professional help resources...'),
              ),
            );
          },
        ),
      );
    }

    // Standard chat UI with loading overlay
    return overlay.LoadingOverlay(
      isLoading: isAiServiceLoading,
      message: 'Loading AI service...',
      animationType: overlay.LoadingAnimationType.staggeredDotsWave,
      child: Scaffold(
        appBar: AppBar(
          title: chatState.value?.currentSession == null
              ? const Text('AI Guidance')
              : Text(chatState.value?.currentSession?.title ?? 'AI Guidance'),
          actions: [
            // Settings button
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).pushNamed('/ai-settings');
              },
            ),

            // Clear chat history button
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: chatState.isLoading
                  ? null
                  : () => _showClearChatConfirmation(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Offline banner if in offline mode and not loading
            if (isOffline && !isAiServiceLoading)
              Container(
                color: Colors.amber.shade100,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline mode: Using built-in Islamic guidance',
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),

            // Main content
            Expanded(
              child: chatState.when(
                data: (state) {
                  if (!state.isInitialized) {
                    return const Center(
                        child: AppLoadingIndicator(
                      message: 'Initializing chat...',
                    ));
                  }

                  if (state.messages.isEmpty) {
                    return _buildWelcomeScreen();
                  }

                  List<ChatMessageModel> messages =
                      state.messages.reversed.toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(chatProvider.notifier).initialize(
                            session: state.currentSession,
                          );
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(
                              _scrollController.position.minScrollExtent);
                        }
                      });
                    },
                    child: ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildChatMessage(messages[index]);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                    child: AppLoadingIndicator(
                  message: 'Loading chat...',
                )),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(chatProvider.notifier).initialize(
                                session: _session,
                              );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Input area
            _buildMessageInput(chatState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_outlined,
            size: 72,
            color: Colors.black38,
          ),
          const SizedBox(height: 24),
          const Text(
            'Islamic Guidance Assistant',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ask for spiritual advice, practical tips, or guidance based on Islamic principles to help you overcome temptations and challenges.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          _buildSuggestedQuestions(),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    final questions = [
      'How can I resist temptation when I feel lonely?',
      'What Islamic practices help with controlling desire?',
      'How can I strengthen my willpower?',
      'What dua should I recite when tempted?',
      'How can I develop more taqwa in my daily life?',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: questions.map((question) {
        return ActionChip(
          label: Text(question),
          onPressed: () {
            _messageController.text = question;
            _sendMessage();
          },
        );
      }).toList(),
    );
  }

  Widget _buildChatMessage(ChatMessageModel message) {
    // Find if this is the latest AI message and we're still streaming
    final chatState = ref.watch(chatProvider);

    // Find the latest AI message
    ChatMessageModel? latestAiMessage;
    if (chatState.value != null && chatState.value!.messages.isNotEmpty) {
      for (final msg in chatState.value!.messages) {
        if (!msg.isUserMessage) {
          latestAiMessage = msg;
          break;
        }
      }
    }

    final isLatestAiMessage =
        latestAiMessage != null && message.uid == latestAiMessage.uid;
    final isTyping =
        chatState.isLoading && isLatestAiMessage && message.content.isEmpty;
    final isCurrentlyStreaming =
        _streamingMode && isLatestAiMessage && !isTyping && chatState.isLoading;

    return ChatMessageBubble(
      message: message.content,
      isUserMessage: message.isUserMessage,
      wasHelpful: message.wasHelpful,
      isError: message.isError,
      isStreaming: isCurrentlyStreaming,
      isTyping: isTyping,
      onRateResponse: (bool helpful) {
        ref.read(chatProvider.notifier).rateResponse(
              message.uid,
              helpful,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26), // 0.1 * 255 = 26
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Streaming toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Streaming mode",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              Switch(
                value: _streamingMode,
                activeColor: Theme.of(context).primaryColor,
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _streamingMode = value;
                        });
                      },
              ),
            ],
          ),

          // Input row
          Row(
            children: [
              // Voice input button (disabled for now)
              const IconButton(
                icon: Icon(Icons.mic),
                onPressed: null, // TODO: Implement voice input
                color: Colors.grey,
              ),

              // Text input field
              Expanded(
                child: KeyboardListener(
                  focusNode: _messageFocusNode,
                  onKeyEvent: (event) {
                    if (isLoading) return;
                    // Only handle key down events
                    if (HardwareKeyboard.instance
                            .isLogicalKeyPressed(LogicalKeyboardKey.enter) &&
                        event.runtimeType.toString().contains('KeyDownEvent')) {
                      // If Shift is NOT pressed, send message
                      if (!(HardwareKeyboard.instance.isShiftPressed)) {
                        // Prevent the default behavior (new line)
                        // Send the message
                        _sendMessage();
                      }
                      // If Shift is pressed, allow new line (do nothing)
                    }
                  },
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    enabled: !isLoading,
                  ),
                ),
              ),

              // Send button
              IconButton(
                icon: Icon(isLoading
                    ? Icons.hourglass_top
                    : _streamingMode
                        ? Icons.stream
                        : Icons.send),
                onPressed: isLoading ? null : _sendMessage,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      // Check if this is an emergency message
      if (_contextManager.isEmergencyContext(message) && !_isEmergencyMode) {
        // Activate emergency mode
        setState(() {
          _isEmergencyMode = true;
          _emergencyTriggerMessage = message;
        });
      }

      // Use streaming or regular mode based on toggle
      if (_streamingMode) {
        ref.read(chatProvider.notifier).sendStreamingMessage(message);
      } else {
        ref.read(chatProvider.notifier).sendMessage(message);
      }

      _messageController.clear();
      // Refocus the text field after sending
      FocusScope.of(context).requestFocus(_messageFocusNode);
      // Scroll to latest message after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showClearChatConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all chat history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearChatHistory();
              Navigator.of(ctx).pop();
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }
}
