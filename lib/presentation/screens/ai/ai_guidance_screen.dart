import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/ai_service_provider.dart';
import '../../../presentation/providers/chat_provider.dart';
import '../../../data/models/ai_models.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/emergency_chat_widget.dart';
import '../../widgets/chat/chat_message_bubble.dart';
import '../../../core/context/context_manager.dart';

class AIGuidanceScreen extends ConsumerStatefulWidget {
  static const routeName = '/ai-guidance';

  const AIGuidanceScreen({super.key});

  @override
  ConsumerState<AIGuidanceScreen> createState() => _AIGuidanceScreenState();
}

class _AIGuidanceScreenState extends ConsumerState<AIGuidanceScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isInitialized = false;
  bool _isEmergencyMode = false;
  String _emergencyTriggerMessage = '';
  final ContextManager _contextManager = ContextManager();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Initialize the chat state when the screen first loads
      Future.microtask(() => ref.read(chatProvider.notifier).initialize());
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      print('Loading more messages');
      ref.read(chatProvider.notifier).loadMoreMessages();
    }
  }

  // void _scrollToBottom() {
  //   if (_scrollController.hasClients) {
  //     Future.delayed(const Duration(milliseconds: 100), () {
  //       _scrollController.animateTo(
  //         _scrollController.position.maxScrollExtent,
  //         duration: const Duration(milliseconds: 200),
  //         curve: Curves.easeOut,
  //       );
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final aiServiceState = ref.watch(aiServiceProvider);
    final isOffline =
        aiServiceState.config.serviceType == AIServiceType.offline;

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

    // Standard chat UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Guidance'),
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
          // Offline banner if in offline mode
          if (isOffline)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                  return const Center(child: AppLoadingIndicator());
                }

                if (state.messages.isEmpty) {
                  return _buildWelcomeScreen();
                }

                List<ChatMessageModel> messages =
                    state.messages.reversed.toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(chatProvider.notifier).initialize();
                    _scrollController.jumpTo(0);
                  },
                  child: ListView.builder(
                    reverse: true,
                    shrinkWrap: true,
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
              loading: () => const Center(child: AppLoadingIndicator()),
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
                        ref.read(chatProvider.notifier).initialize();
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
    return ChatMessageBubble(
      message: message.content,
      isUserMessage: message.isUserMessage,
      wasHelpful: message.wasHelpful,
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Voice input button (disabled for now)
          const IconButton(
            icon: Icon(Icons.mic),
            onPressed: null, // TODO: Implement voice input
            color: Colors.grey,
          ),

          // Text input field
          Expanded(
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
              onSubmitted: isLoading ? null : (_) => _sendMessage(),
              // Add key event handling
              onEditingComplete: isLoading ? null : _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),

          // Send button
          IconButton(
            icon: Icon(isLoading ? Icons.hourglass_top : Icons.send),
            onPressed: isLoading ? null : _sendMessage,
            color: Theme.of(context).primaryColor,
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

      ref.read(chatProvider.notifier).sendMessage(message);
      _messageController.clear();
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
