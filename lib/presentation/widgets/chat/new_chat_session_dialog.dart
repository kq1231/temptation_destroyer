import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/chat_session_model.dart';
import '../../providers/chat_session_provider.dart';

class NewChatSessionDialog extends ConsumerStatefulWidget {
  final Function(ChatSession)? onSessionCreated;

  const NewChatSessionDialog({
    super.key,
    this.onSessionCreated,
  });

  @override
  ConsumerState<NewChatSessionDialog> createState() =>
      _NewChatSessionDialogState();
}

class _NewChatSessionDialogState extends ConsumerState<NewChatSessionDialog> {
  final _titleController = TextEditingController();
  ChatSessionType _sessionType = ChatSessionType.normal;
  String? _topic;
  final List<String> _tags = [];
  bool _isCreating = false;

  final List<String> _predefinedTopics = [
    'Prayer',
    'Fasting',
    'Charity',
    'Self-control',
    'Relationships',
    'Mental health',
    'Spirituality',
    'Temptations',
    'Worship',
    'Daily life',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Conversation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a title for your conversation',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            const Text('Conversation Type:'),
            _buildSessionTypeSelector(),
            const SizedBox(height: 16),
            const Text('Topic (optional):'),
            _buildTopicDropdown(),
            const SizedBox(height: 16),
            const Text('Tags (optional):'),
            _buildTagsSelector(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        _isCreating
            ? const CircularProgressIndicator.adaptive()
            : TextButton(
                onPressed: _createSession,
                child: const Text('Create'),
              ),
      ],
    );
  }

  Widget _buildSessionTypeSelector() {
    return SegmentedButton<ChatSessionType>(
      segments: const [
        ButtonSegment<ChatSessionType>(
          value: ChatSessionType.normal,
          label: Text('Normal'),
          icon: Icon(Icons.chat_bubble_outline),
        ),
        ButtonSegment<ChatSessionType>(
          value: ChatSessionType.guided,
          label: Text('Guided'),
          icon: Icon(Icons.mosque),
        ),
      ],
      selected: {_sessionType},
      onSelectionChanged: (Set<ChatSessionType> selected) {
        setState(() {
          _sessionType = selected.first;
        });
      },
    );
  }

  Widget _buildTopicDropdown() {
    return DropdownButtonFormField<String>(
      value: _topic,
      decoration: const InputDecoration(
        hintText: 'Select a topic',
      ),
      items: _predefinedTopics.map((String topic) {
        return DropdownMenuItem<String>(
          value: topic,
          child: Text(topic),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _topic = newValue;
        });
      },
    );
  }

  Widget _buildTagsSelector() {
    return Wrap(
      spacing: 8.0,
      children: [
        ..._buildTagChips(),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Add Tag'),
          onPressed: _showAddTagDialog,
        ),
      ],
    );
  }

  List<Widget> _buildTagChips() {
    return _tags.map((tag) {
      return InputChip(
        label: Text(tag),
        onDeleted: () {
          setState(() {
            _tags.remove(tag);
          });
        },
      );
    }).toList();
  }

  void _showAddTagDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Tag'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Tag Name',
              hintText: 'Enter a tag',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final tagName = textController.text.trim();
                if (tagName.isNotEmpty && !_tags.contains(tagName)) {
                  setState(() {
                    _tags.add(tagName);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _createSession() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Create a default title if none is provided
      final finalTitle = title.isEmpty
          ? 'Conversation ${DateTime.now().toString().substring(0, 10)}'
          : title;

      await ref.read(chatSessionsProvider.notifier).createSession(
            title: finalTitle,
            sessionType: _sessionType,
            topic: _topic,
            tags: _tags.isEmpty ? null : _tags,
          );

      if (mounted) {
        // Close the dialog
        Navigator.of(context).pop();

        // Get the created session
        final sessions = await ref.read(chatSessionsProvider.future);

        // Find the session we just created (should be at the top since sorted by lastModified)
        if (sessions.isNotEmpty) {
          final newSession = sessions.first;
          widget.onSessionCreated?.call(newSession);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
