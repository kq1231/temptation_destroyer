import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vapi/Vapi.dart';

class VoiceChatMessages extends ConsumerWidget {
  final List<VapiEvent> messages;
  final bool isCallActive;
  final bool isProcessing;

  const VoiceChatMessages({
    super.key,
    required this.messages,
    required this.isCallActive,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    reverse: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return AnimatedSlide(
                        offset: Offset(0, index == 0 ? 0 : 0),
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 300),
                          child: _buildMessageBubble(context, message),
                        ),
                      );
                    },
                  ),
          ),
          // Processing Indicator
          if (isProcessing)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // Active Call Indicator
          if (isCallActive)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPulsingDot(),
                  const SizedBox(width: 8),
                  Text(
                    'Call Active',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Press play to start a voice chat',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildMessageBubble(BuildContext context, VapiEvent message) {
    final isUser = message.label == 'transcript';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.value.toString(),
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: Colors.blue,
      child: Icon(Icons.person, size: 20, color: Colors.white),
    );
  }
}
