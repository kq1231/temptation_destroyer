import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../markdown/enhanced_markdown.dart';

class ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUserMessage;
  final bool? wasHelpful;
  final Function(bool)? onRateResponse;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isUserMessage,
    this.wasHelpful,
    this.onRateResponse,
  }) : super(key: key);

  bool get _isLoading => !isUserMessage && message.isEmpty;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          _copyToClipboard(context);
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUserMessage
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isUserMessage ? 16 : 4),
              topRight: Radius.circular(isUserMessage ? 4 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                LoadingAnimationWidget.staggeredDotsWave(
                  color: isUserMessage
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                  size: 30,
                )
              else
                EnhancedMarkdown(
                  data: message,
                  isUserMessage: isUserMessage,
                ),
              if (!isUserMessage && !_isLoading && onRateResponse != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRatingButton(
                        icon: Icons.thumb_up_outlined,
                        isSelected: wasHelpful == true,
                        onPressed: () => onRateResponse!(true),
                        context: context,
                      ),
                      const SizedBox(width: 8),
                      _buildRatingButton(
                        icon: Icons.thumb_down_outlined,
                        isSelected: wasHelpful == false,
                        onPressed: () => onRateResponse!(false),
                        context: context,
                      ),
                      const SizedBox(width: 16),
                      _buildRatingButton(
                        icon: Icons.copy_outlined,
                        isSelected: false,
                        onPressed: () => _copyToClipboard(context),
                        context: context,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
