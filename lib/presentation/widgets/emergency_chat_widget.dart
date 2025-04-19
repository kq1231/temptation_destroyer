import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/context/context_manager.dart';
import '../../data/models/ai_models.dart';
import '../../presentation/providers/chat_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _sendEmergencyMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);
        return chatState.when(
          data: (state) {
            if (state.messages.isEmpty) {
              return const Center(
                child: Text('Loading emergency response...'),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final message = state.messages[index];
                return _buildMessageBubble(message);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.isUserMessage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatarIcon(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.red.shade200 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (!isUser) _buildEmergencyActions(),
                ],
              ),
            ),
          ),
          if (isUser) _buildAvatarIcon(),
        ],
      ),
    );
  }

  Widget _buildAvatarIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.support_agent,
        color: Colors.red.shade700,
        size: 20,
      ),
    );
  }

  Widget _buildEmergencyActions() {
    return Wrap(
      spacing: 8,
      children: [
        ActionChip(
          label: const Text('Get Professional Help'),
          onPressed: widget.onRequestProfessionalHelp,
          backgroundColor: Colors.red.shade100,
        ),
        ActionChip(
          label: const Text('Call Helpline'),
          onPressed: () => _launchUrl('tel:18002738255'),
          backgroundColor: Colors.red.shade100,
        ),
        ActionChip(
          label: const Text('Islamic Resources'),
          onPressed: _navigateToIslamicResources,
          backgroundColor: Colors.red.shade100,
        ),
      ],
    );
  }

  Widget _buildEmergencyInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.red,
            onPressed: _sendMessage,
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
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _navigateToIslamicResources() {
    // TODO: Implement navigation to Islamic resources screen
    // This would be implemented based on your app's navigation structure
  }
}
