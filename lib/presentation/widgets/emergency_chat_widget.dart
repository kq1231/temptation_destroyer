import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/context/context_manager.dart';
import '../../data/models/ai_models.dart';
import '../../presentation/providers/chat_provider.dart';
import '../widgets/chat/chat_message_bubble.dart';

/// Widget for emergency response UI
/// Provides immediate help resources and quick response options
class EmergencyChatWidget extends ConsumerStatefulWidget {
  /// Message that triggered emergency mode
  final String triggerMessage;

  /// Callback when emergency mode is exited
  final VoidCallback? onExit;

  /// Callback when professional help is requested
  final VoidCallback? onRequestProfessionalHelp;

  const EmergencyChatWidget({
    super.key,
    required this.triggerMessage,
    this.onExit,
    this.onRequestProfessionalHelp,
  });

  @override
  ConsumerState<EmergencyChatWidget> createState() =>
      _EmergencyChatWidgetState();
}

class _EmergencyChatWidgetState extends ConsumerState<EmergencyChatWidget> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showResources = true;
  final ContextManager _contextManager = ContextManager();
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
      // Send the emergency message
      _sendEmergencyMessage();
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
      ref.read(chatProvider.notifier).loadMoreMessages();
    }
  }

  /// Sends the initial emergency notification to the AI
  void _sendEmergencyMessage() {
    // First, notify the assistant about emergency mode
    ref.read(chatProvider.notifier).sendMessage(
          "EMERGENCY MODE ACTIVATED: ${widget.triggerMessage}",
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade50,
      child: Column(
        children: [
          _buildEmergencyHeader(),
          if (_showResources) _buildQuickResources(),
          Expanded(
            child: _buildChatArea(),
          ),
          _buildEmergencyInput(),
        ],
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Emergency Support Mode',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onExit,
            tooltip: 'Exit emergency mode',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickResources() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Immediate Help Resources',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildResourceButton(
            icon: Icons.phone,
            title: 'Crisis Helpline',
            subtitle: '1-800-273-8255',
            onTap: () => _launchUrl('tel:18002738255'),
          ),
          _buildResourceButton(
            icon: Icons.message,
            title: 'Crisis Text Line',
            subtitle: 'Text HOME to 741741',
            onTap: () => _launchUrl('sms:741741?body=HOME'),
          ),
          _buildResourceButton(
            icon: Icons.people,
            title: 'Find Muslim Counselors',
            subtitle: 'Muslim Mental Health Initiative',
            onTap: () =>
                _launchUrl('https://muslimmentalhealth.org/mmhi-directory/'),
          ),
          _buildResourceButton(
            icon: Icons.mosque,
            title: 'Islamic Resources',
            subtitle: 'Prayers and Supplications for Difficulty',
            onTap: () => _navigateToIslamicResources(),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: Icon(
                _showResources
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 18,
              ),
              label: Text(_showResources ? 'Hide Resources' : 'Show Resources'),
              onPressed: () {
                setState(() {
                  _showResources = !_showResources;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    final chatState = ref.watch(chatProvider);

    return chatState.when(
      data: (state) {
        if (!state.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.messages.isEmpty) {
          return const Center(
            child: Text('Loading emergency response...'),
          );
        }

        List<ChatMessageModel> messages = state.messages.reversed.toList();

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh the chat provider by invalidating it
            ref.invalidate(chatProvider);
            _scrollController.jumpTo(0);
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
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () {
                // Refresh the chat provider by invalidating it
                ref.invalidate(chatProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
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

  Widget _buildEmergencyInput() {
    final chatState = ref.watch(chatProvider);
    final isLoading = chatState.isLoading;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.red.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: isLoading ? null : (_) => _sendMessage(),
              onEditingComplete: isLoading ? null : _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(isLoading ? Icons.hourglass_top : Icons.send),
            color: Colors.red,
            onPressed: isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Check if message indicates emergency escalation
    if (_contextManager.isEmergencyContext(message)) {
      _showEmergencyEscalationDialog();
    }

    ref.read(chatProvider.notifier).sendMessage(message);
    _messageController.clear();

    // Scroll to bottom after message is sent
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEmergencyEscalationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Immediate Help Available'),
        content: const Text(
          'Your message indicates you might need immediate professional help. '
          'Would you like to:',
        ),
        actions: [
          TextButton(
            child: const Text('Call Crisis Helpline'),
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl('tel:18002738255');
            },
          ),
          TextButton(
            child: const Text('Text Crisis Line'),
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl('sms:741741?body=HOME');
            },
          ),
          TextButton(
            child: const Text('Continue Chat'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  void _navigateToIslamicResources() {
    // TODO: Implement navigation to Islamic resources screen
    // This would be implemented based on your app's navigation structure
  }
}
