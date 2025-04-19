import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/ai_service_provider.dart';
import '../../../presentation/providers/chat_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/ai_models.dart';
import '../../widgets/app_loading_indicator.dart';

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
    if (_scrollController.position.pixels <= 200) {
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

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(chatProvider.notifier).initialize();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildChatMessage(state.messages[index]);
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
    final isUser = message.isUserMessage;

    // Choose colors based on sender
    final backgroundColor =
        isUser ? Colors.blue.shade100 : Colors.grey.shade100;

    final textColor = isUser ? Colors.blue.shade900 : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Content
            Text(
              message.content,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),

            // Timestamp
            const SizedBox(height: 4),
            Text(
              DateFormatter.formatTime(message.timestamp),
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 12,
              ),
            ),

            // Feedback buttons for AI messages
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    onPressed: () {
                      ref.read(chatProvider.notifier).rateResponse(
                            message.uid,
                            true,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Helpful',
                    color: Colors.green,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(maxHeight: 24),
                  ),
                  IconButton(
                    icon: const Icon(Icons.thumb_down_outlined, size: 16),
                    onPressed: () {
                      ref.read(chatProvider.notifier).rateResponse(
                            message.uid,
                            false,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Not helpful',
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(maxHeight: 24),
                  ),
                ],
              ),
          ],
        ),
      ),
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
          IconButton(
            icon: const Icon(Icons.mic),
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
